/**
 * @file PageState.ets
 * @description 通用页面状态机。对应 PRD §08-数据模型.md §4.8 的 UiState<T>。
 *
 * 设计要点(简历主线 4:空错加载分层 / 强类型 UiState):
 *
 * 1. 为什么用 class + kind discriminator,不用 TS 联合字面量?
 *    ArkTS 严格类型不支持 'idle' | 'loading' | 'success' 这种字面量联合,
 *    必须用 class + 一个区分字段(kind)。
 *    等价 Kotlin: `sealed interface UiState<out T>` 用 when 解构。
 *
 * 2. 为什么这里不带泛型 <T>?
 *    ArkUI 的 @ComponentV2 struct 不支持泛型类型参数(语法层面阻断),
 *    且 ArkTS 严格类型禁止协变(PageState<string> 不能赋给 PageState<object>)。
 *    所以 data 字段统一用 Object | null,UI 层 cast 到具体类型使用。
 *    Kotlin 阶段恢复泛型:`sealed interface UiState<out T>`(out 关键字声明协变)。
 *    -> 这是 ArkTS 语言能力的真实约束,不是设计缺陷,可作为面试讲点。
 *
 * 3. 为什么 8 种状态而不是 4 种?
 *    Idle / Loading / Empty / Error 是基础四态;
 *    Refreshing / LoadingMore / Offline 是带"上次数据"的复合态(下拉刷新时仍展示旧数据),
 *    Content 是成功态。这套 8 态覆盖 PRD §05-异常态规约.md 全部矩阵。
 *
 * 4. 不可变:每次状态变更都 new 一个新实例,UI 比对 kind + data 判定是否需要重渲。
 *    这与 Compose StateFlow.value = newState 同源。
 */

/**
 * 页面状态的 kind 枚举。string 字面量便于日志和调试。
 */
export type PageStateKind =
  "Idle" | "Loading" | "Empty" | "Content" | "Error" | "Refreshing" | "LoadingMore" | "Offline";

/**
 * 通用页面状态(非泛型 - ArkTS 限制,见文件头注释 §2)。
 *
 * 用法:
 * ```ts
 * // VM 暴露:
 * @ObservedV2 class HomeVM {
 *   @Trace state: PageState = PageState.idle()
 * }
 *
 * // UI 消费(cast 到具体业务类型):
 * if (this.vm.state.isContent()) {
 *   const data = this.vm.state.data as HomeData
 *   Text(data.title)
 * }
 * ```
 */
export class PageState {
  readonly kind: PageStateKind = "Idle";
  readonly data: Object | null = null;
  readonly errorCode: string = "";
  readonly errorMessage: string = "";
  readonly cachedAt: number = 0;

  /**
   * 构造器私有化:强制走静态工厂方法,语义更清晰。
   * 类比 Kotlin sealed class 的私有 constructor + companion object 工厂。
   */
  private constructor(
    kind: PageStateKind,
    data: Object | null,
    errorCode: string,
    errorMessage: string,
    cachedAt: number
  ) {
    this.kind = kind;
    this.data = data;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
    this.cachedAt = cachedAt;
  }

  /** 初始静默态(页面刚挂载,还没拉数据)。 */
  static idle(): PageState {
    return new PageState("Idle", null, "", "", 0);
  }

  /** 首次加载态(显示骨架屏)。 */
  static loading(): PageState {
    return new PageState("Loading", null, "", "", 0);
  }

  /** 成功态(渲染数据)。data 推荐传业务对象;使用方 cast 回具体类型。 */
  static content(data: Object): PageState {
    return new PageState("Content", data, "", "", 0);
  }

  /** 空态(请求成功但 list 长度为 0)。 */
  static empty(): PageState {
    return new PageState("Empty", null, "", "", 0);
  }

  /** 错误态(网络异常 / 业务错误 / 超时)。errorCode 对应 PRD §07 错误码表。 */
  static error(code: string, message: string): PageState {
    return new PageState("Error", null, code, message, 0);
  }

  /** 下拉刷新态(保留旧数据,顶部显示 spinner)。 */
  static refreshing(staleData: Object | null): PageState {
    return new PageState("Refreshing", staleData, "", "", 0);
  }

  /** 上拉加载更多态(列表渲染中,底部 spinner)。 */
  static loadingMore(data: Object): PageState {
    return new PageState("LoadingMore", data, "", "", 0);
  }

  /** 离线态(展示缓存数据 + 顶部黄条)。cachedAt 用于判 30 分钟过期。 */
  static offline(cachedData: Object, cachedAt: number): PageState {
    return new PageState("Offline", cachedData, "", "", cachedAt);
  }

  // ========== 类型守卫 ==========
  // 这些 isXxx() 让 UI 层判断变得直观,避免到处写 this.state.kind === "Loading"。

  isIdle(): boolean {
    return this.kind === "Idle";
  }

  isLoading(): boolean {
    return this.kind === "Loading";
  }

  isContent(): boolean {
    return this.kind === "Content";
  }

  isEmpty(): boolean {
    return this.kind === "Empty";
  }

  isError(): boolean {
    return this.kind === "Error";
  }

  isRefreshing(): boolean {
    return this.kind === "Refreshing";
  }

  isLoadingMore(): boolean {
    return this.kind === "LoadingMore";
  }

  isOffline(): boolean {
    return this.kind === "Offline";
  }

  /**
   * 是否有可渲染的数据。
   * Content / LoadingMore / Refreshing(有旧数据时) / Offline 都返回 true。
   */
  hasData(): boolean {
    return this.data !== null;
  }
}
