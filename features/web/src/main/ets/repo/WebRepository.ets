/**
 * @file WebRepository.ets
 * @description Web 容器数据层。S21 升级:真实 API 优先,MockData 降级为 fallback。
 *
 * 设计要点(对齐 SearchRepository / HomeRepository 同源底线):
 *
 * 1. 零装饰器(plain class),可整段平移 Kotlin。
 *
 * 2. S21 Fallback 策略(fetchRules):
 *    ① 缓存有效 → 直接返回缓存
 *    ② HttpClient.baseUrl 非空 → 尝试真实 API → catch 降级到 ③
 *    ③ Mock fallback(sleep + MockData 调用)
 *
 * 3. matchRule / authHeader / shouldInjectToken / resolveAction 不变 — 操作缓存数据。
 */

import { WebInterceptRule, WebInterceptAction } from "@flowsearch/base";
import { HttpClient, HttpError, ApiResponse } from "@flowsearch/base";
import { WebMock } from "@flowsearch/mockdata";
import { hilog } from "@kit.PerformanceAnalysisKit";

/** 缓存 TTL:30 分钟(PRD §07 §2.13 "启动后缓存到本地,30 分钟过期")。 */
const RULES_CACHE_TTL_MS: number = 30 * 60 * 1000;

/** 模拟首次拉规则的网络延时,体现 PageState.loading。 */
const FETCH_RULES_DELAY_MS: number = 150;

const TAG: string = "WebRepo";
const DOMAIN: number = 0x0000;

/** Repository 抛出的错误对象(沿用 SearchRepoError 风格)。 */
export class WebRepoError extends Error {
  readonly errorCode: string = "";

  constructor(errorCode: string, message: string) {
    super(message);
    this.errorCode = errorCode;
  }
}

export class WebRepository {
  /** 缓存的规则列表。null 表示未拉过。 */
  private cachedRules: Array<WebInterceptRule> | null = null;

  /** 缓存时间戳(ms)。0 表示未拉过。 */
  private cachedAt: number = 0;

  /**
   * 拉取拦截规则。30 分钟内复用缓存,超期自动重拉。
   * forceRefresh=true 强制走网络。
   * S21:真实 API 优先 → Mock fallback。
   */
  async fetchRules(forceRefresh: boolean = false): Promise<Array<WebInterceptRule>> {
    const now: number = Date.now();
    const cacheValid: boolean = !forceRefresh
      && this.cachedRules !== null
      && (now - this.cachedAt) < RULES_CACHE_TTL_MS;

    if (cacheValid) {
      return (this.cachedRules as Array<WebInterceptRule>).slice();
    }

    // 真实 API 尝试
    if (HttpClient.baseUrl.length > 0) {
      try {
        const resp: ApiResponse = await HttpClient.get("/api/web/intercept-rules");
        if (resp.data !== null) {
          const d = resp.data as Record<string, object>;
          const rawList = d.list as Array<object>;
          const rules: Array<WebInterceptRule> = new Array();
          for (let i: number = 0; i < rawList.length; i++) {
            rules.push(WebRepository.mapRule(rawList[i]));
          }
          this.cachedRules = rules;
          this.cachedAt = Date.now();
          hilog.info(DOMAIN, TAG, "fetchRules API ok, count=%{public}d", rules.length);
          return rules.slice();
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, "fetchRules API fallback: %{public}s", JSON.stringify(err));
      }
    }

    // Mock fallback
    await WebRepository.sleep(FETCH_RULES_DELAY_MS);

    // mock 永不抛;真接口阶段失败抛 WebRepoError("RULES_LOAD_FAIL", ...)
    const rules: Array<WebInterceptRule> = WebMock.getInterceptRules();
    this.cachedRules = rules;
    this.cachedAt = now;
    return rules.slice();
  }

  /**
   * URL 命中规则匹配。遍历当前缓存的规则,返回第一个 pattern 命中的规则。
   * 没有命中 -> null,Page 层视为 ALLOW 且 needTokenInject=false(PRD §04-04 §3 默认)。
   *
   * 注意:必须先 fetchRules 把缓存灌起来,否则一直返 null。
   * VM 在 init 时确保 await fetchRules 后才允许加载首个 URL。
   */
  matchRule(url: string): WebInterceptRule | null {
    if (this.cachedRules === null) {
      return null;
    }
    const rules: Array<WebInterceptRule> = this.cachedRules as Array<WebInterceptRule>;
    for (let i: number = 0; i < rules.length; i++) {
      const rule: WebInterceptRule = rules[i];
      if (WebRepository.matchGlob(rule.pattern, url)) {
        return rule;
      }
    }
    return null;
  }

  /**
   * 取 mock token 的鉴权头值(简历主线 2"登录态透传"占位)。
   * 真接口阶段移到 commons/network/AuthInterceptor + Preferences。
   */
  authHeader(): string {
    return `Bearer ${WebMock.getMockToken()}`;
  }

  /**
   * 根据 URL 决定本次加载是否要注入 token。
   * 命中且 needTokenInject=true -> 注入。
   */
  shouldInjectToken(url: string): boolean {
    const rule: WebInterceptRule | null = this.matchRule(url);
    if (rule === null) {
      return false;
    }
    return rule.needTokenInject;
  }

  /**
   * 推断 URL 应该走的动作。命中规则用规则的 action,未命中默认 ALLOW。
   */
  resolveAction(url: string): WebInterceptAction {
    const rule: WebInterceptRule | null = this.matchRule(url);
    if (rule === null) {
      return "ALLOW";
    }
    return rule.action;
  }

  // ============================================================
  // 内部:API 响应映射
  // ============================================================

  private static mapRule(obj: object): WebInterceptRule {
    const o = obj as Record<string, object>;
    const actionStr: string = typeof o.action === "string" ? o.action : "ALLOW";
    return new WebInterceptRule(
      typeof o.ruleId === "string" ? o.ruleId : "",
      typeof o.pattern === "string" ? o.pattern : "",
      actionStr as WebInterceptAction,
      typeof o.needTokenInject === "boolean" ? o.needTokenInject as boolean : false
    );
  }

  // ============================================================
  // 内部:glob 转 regex 匹配
  // ============================================================

  /**
   * glob 简易匹配。支持:
   *   - `*` 通配任意字符(贪婪)
   *   - 其他字符按字面量匹配
   * 例如:
   *   "https://mock-pay/*" 命中 "https://mock-pay/order/123"
   *   "tel:*"              命中 "tel:10086"
   *   "https://*.download/*" 命中 "https://x.download/y"
   *
   * 实现思路:逐字符扫 pattern,转义正则元字符,把 `*` 换成 `.*`,
   * 首尾加 `^` / `$`,然后用 RegExp 测试。
   */
  private static matchGlob(pattern: string, url: string): boolean {
    const regex: RegExp = WebRepository.globToRegExp(pattern);
    return regex.test(url);
  }

  private static globToRegExp(pattern: string): RegExp {
    // ArkTS 没有 String.prototype.replace 的 callback 形式支持(不安全),手动逐字符拼
    let escaped: string = "";
    for (let i: number = 0; i < pattern.length; i++) {
      const ch: string = pattern.charAt(i);
      if (ch === "*") {
        escaped += ".*";
        continue;
      }
      // 正则元字符转义,防止 pattern 里有 `.` `/` `?` `(` 等被当成元字符
      if (WebRepository.isRegexSpecial(ch)) {
        escaped += "\\" + ch;
        continue;
      }
      escaped += ch;
    }
    return new RegExp(`^${escaped}$`);
  }

  private static isRegexSpecial(ch: string): boolean {
    // 不含 `*`(已单独处理)
    return ch === "." || ch === "+" || ch === "?" || ch === "/"
        || ch === "(" || ch === ")" || ch === "[" || ch === "]"
        || ch === "{" || ch === "}" || ch === "^" || ch === "$"
        || ch === "|" || ch === "\\";
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => { resolve(); }, ms);
    });
  }
}
