/**
 * @file WebModels.ets
 * @description Web 容器域业务实体。字段严格对齐 PRD §04-04(WebContainer)、§07-2.13、§08-§4.7。
 *
 * 设计要点(对齐 HomeModels / SearchModels 同源底线):
 *
 * 1. 放 commons/base:mockdata 和 features/web 都要消费,放基础层依赖方向干净。
 *    类比 Kotlin: 这相当于 :core:model 的扩展。
 *
 * 2. 零 ArkUI 装饰器,纯 readonly + 构造器,等价 Kotlin data class,可 1:1 平移。
 *
 * 3. action 用 string 字面量联合,与服务端大写枚举对齐。
 *
 * 4. WebInterceptRule 是 PRD §08 §4.7 的精确镜像 -- 服务端 5 字段全部到位,
 *    本期 mock 接口 GET /api/web/intercept-rules 直接返回这个数组。
 *
 * 5. WebContainerData 是为 PageState.data 准备的内容态聚合:
 *    Content 时携带 currentUrl / displayTitle / domain / isHttps / rulesLoaded 几个字段,
 *    UI 层 cast 到这个类型读字段。其他 4 个变体(LoginExpired / ExternalConfirm /
 *    SlowLoad / ErrorPage)用 @Local 弹层标志位控制,不进 PageState -- 同 SearchResult。
 */

/**
 * URL 命中拦截规则后采取的动作(PRD §04-04 §3 拦截行为表):
 * - ALLOW             直接加载;needTokenInject=true 时静默注入 token
 * - INTERCEPT_LOGIN   弹"登录过期"层 -> 关闭 Web 容器 -> 跳 SearchEntry
 * - INTERCEPT_PAY     Toast "演示版不支持真实支付",停留当前页
 * - INTERCEPT_DOWNLOAD Toast "已识别下载链接(演示)",停留当前页
 * - OPEN_EXTERNAL     弹"即将打开外部应用"确认层 -> 调系统
 */
export type WebInterceptAction =
  "ALLOW" | "INTERCEPT_LOGIN" | "INTERCEPT_PAY" | "INTERCEPT_DOWNLOAD" | "OPEN_EXTERNAL";

/**
 * 拦截规则(PRD §08 §4.7 WebInterceptRule)。
 * pattern 是 glob 字符串(支持 `*` 通配),Repository 内部转 RegExp 匹配。
 */
export class WebInterceptRule {
  readonly ruleId: string = "";
  readonly pattern: string = "";
  readonly action: WebInterceptAction = "ALLOW";
  readonly needTokenInject: boolean = false;

  constructor(ruleId: string, pattern: string, action: WebInterceptAction, needTokenInject: boolean) {
    this.ruleId = ruleId;
    this.pattern = pattern;
    this.action = action;
    this.needTokenInject = needTokenInject;
  }
}

/**
 * Web 容器 Content 态的内容聚合。
 *
 * - currentUrl   当前 WebView 加载的 URL(随用户内部跳转更新)
 * - displayTitle 顶栏第一行展示的标题(优先 WebView 抽到的 document.title,
 *                fallback 路由入参 args.title,再 fallback domain)
 * - domain       URL 的 host 部分,顶栏第二行展示,带 🔒/⚠ icon
 * - isHttps      true=展示 🔒 绿锁; false=展示 ⚠ 黄警告
 * - rulesLoaded  拦截规则是否已就绪(false 时弹层不工作)
 */
export class WebContainerData {
  readonly currentUrl: string = "";
  readonly displayTitle: string = "";
  readonly domain: string = "";
  readonly isHttps: boolean = true;
  readonly rulesLoaded: boolean = false;

  constructor(currentUrl: string, displayTitle: string, domain: string, isHttps: boolean, rulesLoaded: boolean) {
    this.currentUrl = currentUrl;
    this.displayTitle = displayTitle;
    this.domain = domain;
    this.isHttps = isHttps;
    this.rulesLoaded = rulesLoaded;
  }

  /** 不可变更新:换 URL 时新建对象,@Trace 才稳触发。 */
  withUrl(url: string, displayTitle: string, domain: string, isHttps: boolean): WebContainerData {
    return new WebContainerData(url, displayTitle, domain, isHttps, this.rulesLoaded);
  }

  /** 不可变更新:文档标题回填(WebView onTitleReceive 触发)。 */
  withTitle(displayTitle: string): WebContainerData {
    return new WebContainerData(this.currentUrl, displayTitle, this.domain, this.isHttps, this.rulesLoaded);
  }
}
