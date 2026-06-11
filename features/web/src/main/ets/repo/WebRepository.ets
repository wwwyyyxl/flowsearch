/**
 * @file WebRepository.ets
 * @description Web 容器数据层。三件事:
 *
 *   1. 拉取拦截规则(/api/web/intercept-rules,PRD §07 §2.13)+ 本地 30 分钟缓存
 *   2. URL 命中规则匹配 -> 返回 WebInterceptAction 决策
 *   3. needTokenInject=true 时把 mock token 注入到请求头(返回 Authorization header value)
 *
 * 设计要点(对齐 SearchRepository / HomeRepository 同源底线):
 *
 * 1. 零装饰器(plain class),可整段平移 Kotlin:
 *      class WebRepository {
 *        suspend fun fetchRules(forceRefresh: Boolean = false): List<WebInterceptRule>
 *        fun matchRule(url: String): WebInterceptRule?
 *        fun authHeader(): String
 *      }
 *
 * 2. 缓存策略:首次 fetchRules 后内存持有 + 时间戳;
 *    30 分钟内复用,过期清缓存重拉。简单可控,无需 Preferences。
 *    真接口阶段会移到 commons/network/CacheInterceptor。
 *
 * 3. glob -> regex:
 *    PRD pattern 用 glob(`https://mock-pay/*`、`tel:*`),ArkTS 没内置 glob 库,
 *    我们手转 RegExp:把 `.` 转义、`*` 替换成 `.*`、首尾加 `^` `$`,
 *    其他正则元字符也要转义防注入。
 *
 * 4. 错误码:
 *    - "RULES_LOAD_FAIL"   拦截规则拉取失败(VM 层会把 page state -> Error)
 *    本期 mock 不会真失败,留位给真实接口阶段。
 *
 * 5. authHeader():
 *    返回 `Bearer ${mockToken}`,供 Page 层装到 Web 组件请求头里。
 *    这是简历主线 2"登录态透传"的精确证据点。
 */

import { WebInterceptRule, WebInterceptAction } from "@flowsearch/base";
import { WebMock } from "@flowsearch/mockdata";

/** 缓存 TTL:30 分钟(PRD §07 §2.13 "启动后缓存到本地,30 分钟过期")。 */
const RULES_CACHE_TTL_MS: number = 30 * 60 * 1000;

/** 模拟首次拉规则的网络延时,体现 PageState.loading。 */
const FETCH_RULES_DELAY_MS: number = 150;

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
   * forceRefresh=true 强制走网络(调试/拉黑场景用)。
   */
  async fetchRules(forceRefresh: boolean = false): Promise<Array<WebInterceptRule>> {
    const now: number = Date.now();
    const cacheValid: boolean = !forceRefresh
      && this.cachedRules !== null
      && (now - this.cachedAt) < RULES_CACHE_TTL_MS;

    if (cacheValid) {
      // 这里的 ! 不可避免 — ArkTS 严格类型,前一行已守 null,但不会窄化字段
      return (this.cachedRules as Array<WebInterceptRule>).slice();
    }

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
