/**
 * @file HttpClient.ets
 * @description HTTP 客户端工具类。基于 @kit.NetworkKit 的 http API。
 *
 * 鸿蒙文档依据:
 *   - http.createHttp() → 创建 HttpRequest 实例(单次使用,不可复用)
 *   - httpRequest.request(url, options) → 发起请求(返回 Promise)
 *   - HttpRequestOptions: method, expectDataType, connectTimeout, readTimeout, header
 *   - HttpResponse: responseCode, result, header, cookies
 *   - httpRequest.destroy() → 释放资源(必须调用,否则内存泄漏)
 *   - 权限: ohos.permission.INTERNET (已在 entry module.json5 声明)
 *
 * 设计要点:
 *   1. 静态工具类,零装饰器 — 与 HomeRepository / SearchRepository 同源底线。
 *   2. baseUrl 为空时 get() 立即抛 HttpError("NO_API"),调用方 catch 后 fallback 到 Mock。
 *   3. 每次请求 createHttp() 新实例,finally 中 destroy() 确保资源释放。
 *   4. expectDataType 设为 STRING,手动 JSON.parse — ArkTS 的 Object 类型不能直接当 Map 用。
 *
 * ArkTS 踩坑:
 *   - catch 子句不能写类型: try {} catch (e) {} — 无 `: BusinessError`
 *   - response.result 是 string | Object | ArrayBuffer,用 expectDataType 统一为 string
 *   - 不允许 obj["field"] 括号访问 — 用 obj.field 或 JSON.parse 后强制转换
 *   - HttpRequest 每个实例只能用一次,不可复用
 */

import { http } from "@kit.NetworkKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "HttpClient";
const DOMAIN: number = 0x0000;

/**
 * HTTP 请求错误。对齐 HomeRepoError / SearchRepoError / WebRepoError 模式。
 *
 * errorCode 映射:
 *   - "NO_API"        baseUrl 未配置,跳过 HTTP
 *   - "NETWORK_ERROR" 连接失败 / DNS 解析失败
 *   - "TIMEOUT"       连接超时 / 读取超时
 *   - "HTTP_xxx"      HTTP 状态码错误(如 "HTTP_404", "HTTP_500")
 *   - "PARSE_ERROR"   JSON 解析失败
 */
export class HttpError extends Error {
  readonly errorCode: string = "";
  readonly httpStatus: number = -1;

  constructor(errorCode: string, message: string, httpStatus: number) {
    super(message);
    this.errorCode = errorCode;
    this.httpStatus = httpStatus;
  }
}

/**
 * API 通用响应包装。对应 PRD §07 通用约定:
 *   { code: "0", message: "success", data: T }
 *
 * Repository 层解析后取出 data 字段,映射为领域模型。
 */
export class ApiResponse {
  readonly code: string = "";
  readonly message: string = "";
  readonly data: Object | null = null;

  constructor(code: string, message: string, data: Object | null) {
    this.code = code;
    this.message = message;
    this.data = data;
  }
}

/**
 * HTTP 客户端。纯静态,无实例状态。
 *
 * 使用方式:
 *   1. SettingsRepository.loadAll() 中设置 HttpClient.baseUrl
 *   2. Repository 方法内: HttpClient.get("/api/xxx", params)
 *   3. 返回 ApiResponse,调用方解析 data 字段
 */
export class HttpClient {
  /**
   * API 基础地址。由 SettingsRepository 在 loadAll 时设置。
   * 空字符串 = 未配置,所有 get() 调用立即抛 HttpError("NO_API")。
   */
  static baseUrl: string = "";

  /** 连接超时(毫秒)。 */
  static readonly CONNECT_TIMEOUT_MS: number = 5000;

  /** 读取超时(毫秒)。 */
  static readonly READ_TIMEOUT_MS: number = 10000;

  /**
   * 发起 GET 请求。
   *
   * @param path   API 路径(如 "/api/tool/home")
   * @param params 查询参数(可选),Map<string, string> 形式
   * @returns      ApiResponse(包含 code / message / data)
   * @throws       HttpError — NO_API / NETWORK_ERROR / TIMEOUT / HTTP_xxx / PARSE_ERROR
   */
  static async get(path: string, params?: Map<string, string>): Promise<ApiResponse> {
    if (HttpClient.baseUrl.length === 0) {
      throw new HttpError("NO_API", "API 基础地址未配置", -1);
    }

    const url: string = HttpClient.buildUrl(path, params);
    hilog.info(DOMAIN, TAG, "GET %{public}s", url);

    const httpRequest: http.HttpRequest = http.createHttp();

    try {
      const response: http.HttpResponse = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: HttpClient.CONNECT_TIMEOUT_MS,
        readTimeout: HttpClient.READ_TIMEOUT_MS,
        header: { "Content-Type": "application/json" }
      });

      const statusCode: number = response.responseCode;
      const bodyStr: string = response.result as string;

      if (statusCode !== 200) {
        throw HttpClient.mapHttpError(statusCode, bodyStr);
      }

      const parsed: Object = JSON.parse(bodyStr);
      return HttpClient.parseApiResponse(parsed);
    } catch (err) {
      // 如果已经是 HttpError,直接抛出(来自 mapHttpError 或 parseApiResponse)
      if (err instanceof HttpError) {
        throw err;
      }

      // BusinessError: 网络/超时/权限等底层错误
      const msg: string = JSON.stringify(err);
      hilog.warn(DOMAIN, TAG, "Request failed: %{public}s", msg);

      // 超时错误码 2300028
      if (msg.indexOf("2300028") >= 0) {
        throw new HttpError("TIMEOUT", "请求超时", -1);
      }

      throw new HttpError("NETWORK_ERROR", "网络请求失败: " + msg, -1);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 拼接完整 URL: baseUrl + path + 查询参数。
   *
   * @param path   API 路径
   * @param params 查询参数(Map)
   * @returns      完整 URL 字符串
   */
  private static buildUrl(path: string, params?: Map<string, string>): string {
    let url: string = HttpClient.baseUrl + path;

    if (params === undefined || params.size === 0) {
      return url;
    }

    // ArkTS: Map.keys() 返回 IterableIterator,不能直接当数组用
    // forEach 回调内修改外部变量,ArkTS 支持闭包捕获
    let first: boolean = true;
    params.forEach((val: string, key: string): void => {
      if (first) {
        url += "?";
        first = false;
      } else {
        url += "&";
      }
      url += encodeURIComponent(key) + "=" + encodeURIComponent(val);
    });

    return url;
  }

  /**
   * 将 HTTP 状态码映射为 HttpError。
   */
  private static mapHttpError(statusCode: number, body: string): HttpError {
    const codeStr: string = "HTTP_" + String(statusCode);
    const msg: string = "HTTP " + String(statusCode) + ": " + body;
    hilog.warn(DOMAIN, TAG, "%{public}s", msg);
    return new HttpError(codeStr, msg, statusCode);
  }

  /**
   * 将 JSON.parse 的结果解析为 ApiResponse。
   *
   * 期望结构: { code: string, message: string, data: Object | null }
   * ArkTS 不允许泛型类或 obj["field"] 括号访问,手动逐字段提取。
   */
  private static parseApiResponse(obj: Object): ApiResponse {
    // JSON.parse 返回的 Object 实际是 Record,但 ArkTS 不支持 Record 类型标注
    // 通过 as 转换后用 . 访问字段
    const record = obj as Record<string, Object>;
    const code: string = String(record.code);
    const message: string = String(record.message);
    const data: Object | null = record.data !== undefined ? record.data : null;
    return new ApiResponse(code, message, data);
  }
}
