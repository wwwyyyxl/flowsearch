/**
 * @file RouteParams.ets
 * @description 各路由的强类型参数对象。
 *
 * 为什么不直接传 Record<string, string>?
 * - ArkTS 严格类型下 Record 的取值是 `V | undefined`,使用方需要到处判空;
 * - 强类型参数类有助于编译期捕获"漏传 url"之类错误;
 * - 等价 Kotlin: data class SearchResultArgs(val keyword: String)
 *
 * 用法:
 *   const args = new SearchResultArgs("arkts")
 *   navPathStack.pushPath({ name: RouteTable.SEARCH_RESULT, param: args })
 *
 * 页面里取:
 *   const args = stack.getParamByName(RouteTable.SEARCH_RESULT)[0] as SearchResultArgs
 */

export class SearchResultArgs {
  readonly keyword: string = "";

  constructor(keyword: string) {
    this.keyword = keyword;
  }
}

export class WebContainerArgs {
  readonly url: string = "";
  readonly title: string = "";
  readonly needTokenInject: boolean = false;
  /**
   * 深链场景绕过拦截规则。默认 false。
   * PRD §04-04 §7 入参 `forceAllow: Boolean?`。
   * 例如:从 `flowsearch://web?url=xxx&forceAllow=true` 进入时直接放行,
   * 跳过 INTERCEPT_LOGIN / INTERCEPT_PAY / OPEN_EXTERNAL 等策略 — 主要给
   * 调试 / 信任域名预览用。本期 mock 入口不触发,留位等真链。
   */
  readonly forceAllow: boolean = false;

  constructor(url: string, title: string, needTokenInject: boolean, forceAllow: boolean = false) {
    this.url = url;
    this.title = title;
    this.needTokenInject = needTokenInject;
    this.forceAllow = forceAllow;
  }
}

export class ToolShellArgs {
  readonly toolId: string = "";

  constructor(toolId: string) {
    this.toolId = toolId;
  }
}

export class FavsHistoryArgs {
  /** "favorites" | "history",决定进入页面后默认显示的内部 Tab */
  readonly tab: string = "favorites";

  constructor(tab: string) {
    this.tab = tab;
  }
}
