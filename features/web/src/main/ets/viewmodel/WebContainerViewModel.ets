/**
 * @file WebContainerViewModel.ets
 * @description WebContainerPage 的 ViewModel。
 *              把 PageState 状态机 + URL 拦截结果 + 进度条 + 4 种叠加层标志串起来。
 *
 * 设计要点(简历主线 1 核心证据):
 *
 * 1. PageState 三态(复用 commons/base 同源):
 *    - Loading  首屏拉规则中 / Web 组件加载中(进度条 0-90%)
 *    - Content  WebView 可见,顶栏 + 进度条 + 主体三件套
 *    - Error    白屏错误页(整页替换主体,顶栏标题改"页面加载失败")
 *
 * 2. 叠加层标志位(不进 PageState,因为它们与 Content 共存):
 *    - showLoginExpired       INTERCEPT_LOGIN 命中后
 *    - showExternalConfirm    OPEN_EXTERNAL 命中后(待确认)
 *    - showSlowBar            加载 >5s 触发
 *    - pendingExternalUrl     外跳确认弹层展示用
 *
 * 3. 进度条策略(PRD §04-04 §5.1):
 *    - 0 -> 90% 平滑前进:外部用 onProgressChange 接 Web 组件真实进度,
 *      但真实进度可能跳跃 — 这里做了 max(prev, new) 防回退,Page 层另做平滑动画
 *    - 收到 onPageEnd 后到 100%(由 Page 层 animateTo 收尾)
 *
 * 4. 5s 慢加载定时器(PRD §04-04 §5.5):
 *    - aboutToLoadUrl 触发开计时,5s 后未 onPageEnd 自动 showSlowBar=true
 *    - 用户点"停止"或 onPageEnd 都清掉定时器
 *
 * 5. 拦截决策放在 Repository,VM 只调用:
 *    interceptUrl(url) -> 返回是否阻断加载,顺便触发对应叠加层 / Toast。
 *
 * 6. 不可变更新:state.data 每次都 new WebContainerData(...).withXxx,
 *    保持 PageState 不可变契约,@Trace 才稳触发。
 */

import promptAction from "@ohos.promptAction";
import pasteboard from "@ohos.pasteboard";
import { PageState, WebContainerData, WebInterceptRule, WebInterceptAction, Article } from "@flowsearch/base";
import { WebRepository } from "../repo/WebRepository";
import { FavoritesRepository } from "@flowsearch/favs";

/** 慢加载触发阈值(PRD §04-04 §5.5)。 */
const SLOW_THRESHOLD_MS: number = 5000;

@ObservedV2
export class WebContainerViewModel {
  /** 路由入参:初始 URL。 */
  @Trace initialUrl: string = "";

  /** 路由入参:初始标题。WebView 抽到的真实 title 会覆盖。 */
  @Trace initialTitle: string = "";

  /** 路由入参:是否强制 token 注入。命中规则未命中时用此默认。 */
  @Trace needTokenInjectDefault: boolean = false;

  /** 路由入参:深链 forceAllow,跳过所有拦截规则。 */
  @Trace forceAllow: boolean = false;

  /** 页面整体状态(Loading / Content / Error)。 */
  @Trace state: PageState = PageState.idle();

  /** 当前进度 0-100。 */
  @Trace progress: number = 0;

  /** 登录过期弹层是否显示。 */
  @Trace showLoginExpired: boolean = false;

  /** 外跳确认弹层是否显示。 */
  @Trace showExternalConfirm: boolean = false;

  /** 外跳目标 URL(弹层文案展示用)。 */
  @Trace pendingExternalUrl: string = "";

  /** 慢加载黄条是否显示。 */
  @Trace showSlowBar: boolean = false;

  /** 更多菜单 ActionSheet 是否显示。 */
  @Trace showMoreMenu: boolean = false;

  /** 路由入参:文章 id,用于详情页收藏。空串表示无关联文章。 */
  @Trace articleId: string = "";

  /** 当前文章是否已收藏。 */
  @Trace isFavorited: boolean = false;

  private readonly repository: WebRepository = new WebRepository();

  /** 收藏持久化(S8 新增)。init(context) 时初始化。 */
  private readonly favRepo: FavoritesRepository = new FavoritesRepository();

  /** 慢加载定时器句柄(setTimeout 返回值,ArkTS 是 number)。 */
  private slowTimerId: number = -1;

  /** 错误页"重新加载"按钮按下时,Page 用 LOAD_NO_CACHE 模式,这里只触发状态。 */
  private lastErrorCode: string = "";

  // ============================================================
  // 生命周期 — Page 在 aboutToAppear 调
  // ============================================================

  /**
   * 初始化:先把拦截规则拉起来(PageState.loading),再让 Page 加载首个 URL。
   * 规则拉取失败 -> PageState.error。
   */
  async init(initialUrl: string, initialTitle: string, needTokenInject: boolean, forceAllow: boolean, articleId: string, context: Context): Promise<void> {
    this.initialUrl = initialUrl;
    this.initialTitle = initialTitle;
    this.needTokenInjectDefault = needTokenInject;
    this.forceAllow = forceAllow;
    this.articleId = articleId;

    // S8:收藏持久化初始化
    this.favRepo.init(context);
    this.loadFavoriteStatus();

    this.state = PageState.loading();
    this.progress = 0;

    try {
      await this.repository.fetchRules();
    } catch (e) {
      // ArkTS 严格类型:catch 不带类型注解
      this.state = PageState.error("RULES_LOAD_FAIL", "拦截规则加载失败");
      return;
    }

    // 规则就绪,但 URL 实际加载由 Page 触发(Web 组件 controller.loadUrl)
    // 这里只构造 Content 初始数据,domain / title 待 Web 组件回调更新
    const domain: string = WebContainerViewModel.parseDomain(initialUrl);
    const isHttps: boolean = initialUrl.indexOf("https://") === 0;
    const displayTitle: string = initialTitle.length > 0 ? initialTitle : domain;
    const data: WebContainerData = new WebContainerData(initialUrl, displayTitle, domain, isHttps, true);
    this.state = PageState.content(data);

    // 启动慢加载计时
    this.startSlowTimer();
  }

  // ============================================================
  // Web 组件事件回调 — Page 把 Web 组件的事件转发到这里
  // ============================================================

  /** 进度变化:真实进度可能跳跃,用 max 防回退。 */
  onProgressChange(newProgress: number): void {
    if (newProgress > this.progress) {
      this.progress = newProgress;
    }
    if (newProgress >= 100) {
      this.clearSlowTimer();
    }
  }

  /** 文档标题回调:回填到 state.data,顶栏第一行更新。 */
  onTitleReceive(title: string): void {
    if (!this.state.isContent() || title.length === 0) {
      return;
    }
    const data: WebContainerData = this.state.data as WebContainerData;
    const next: WebContainerData = data.withTitle(title);
    this.state = PageState.content(next);
  }

  /** 单次 URL 加载完成。 */
  onPageEnd(_url: string): void {
    this.progress = 100;
    this.clearSlowTimer();
  }

  /** Web 组件报告加载错误(NETWORK / TIMEOUT / etc)。 */
  onPageError(code: string, message: string): void {
    this.lastErrorCode = code;
    this.clearSlowTimer();
    this.state = PageState.error(code, message);
  }

  /**
   * URL 内部跳转(用户在 WebView 里点了链接,即将加载新 URL)。
   * 返回 true = 阻断加载,false = 放行。
   *
   * 流程(PRD §04-04 §3):
   *   1. forceAllow=true -> 直接放行
   *   2. 命中规则:按 action 分发
   *      - ALLOW              更新 URL,继续加载(返回 false)
   *      - INTERCEPT_LOGIN    弹"登录过期"层,阻断
   *      - INTERCEPT_PAY      Toast,阻断
   *      - INTERCEPT_DOWNLOAD Toast,阻断
   *      - OPEN_EXTERNAL      弹"外跳确认"层,阻断
   *   3. 未命中 -> ALLOW(默认)
   */
  interceptUrl(url: string): boolean {
    if (this.forceAllow) {
      this.updateCurrentUrl(url);
      return false;
    }

    const action: WebInterceptAction = this.repository.resolveAction(url);

    if (action === "ALLOW") {
      this.updateCurrentUrl(url);
      this.startSlowTimer();
      return false;
    }

    if (action === "INTERCEPT_LOGIN") {
      this.showLoginExpired = true;
      return true;
    }

    if (action === "INTERCEPT_PAY") {
      promptAction.showToast({ message: "演示版不支持真实支付" });
      return true;
    }

    if (action === "INTERCEPT_DOWNLOAD") {
      promptAction.showToast({ message: "已识别下载链接(演示)" });
      return true;
    }

    if (action === "OPEN_EXTERNAL") {
      this.pendingExternalUrl = url;
      this.showExternalConfirm = true;
      return true;
    }

    // 兜底放行
    this.updateCurrentUrl(url);
    return false;
  }

  // ============================================================
  // 用户交互回调
  // ============================================================

  /** 登录过期弹层"重新登录":关闭弹层,VM 不直接 pop,由 Page 层调 navPathStack.clear。 */
  confirmLoginExpired(): void {
    this.showLoginExpired = false;
  }

  cancelLoginExpired(): void {
    this.showLoginExpired = false;
  }

  /** 外跳确认"打开":Page 层会调系统 want.startAbility。 */
  confirmExternalOpen(): void {
    this.showExternalConfirm = false;
    // 不清 pendingExternalUrl,Page 层用一次后自己置空
  }

  cancelExternalOpen(): void {
    this.showExternalConfirm = false;
    this.pendingExternalUrl = "";
  }

  /** 慢加载黄条"停止":Page 层会调 webController.stop(),这里只清状态。 */
  stopLoading(): void {
    this.showSlowBar = false;
    this.clearSlowTimer();
  }

  /** 打开更多菜单。 */
  openMoreMenu(): void {
    this.showMoreMenu = true;
  }

  /** 关闭更多菜单。 */
  closeMoreMenu(): void {
    this.showMoreMenu = false;
  }

  /**
   * S8:切换当前文章的收藏态。
   * 内存即时反馈 + 异步持久化,与 HomeViewModel.toggleFavorite 同策略。
   */
  toggleFavorite(): void {
    if (this.articleId.length === 0) {
      return;
    }
    this.isFavorited = !this.isFavorited;
    if (this.isFavorited) {
      // 构造最小 Article 存入收藏
      const article: Article = new Article({
        articleId: this.articleId,
        title: this.initialTitle,
        summary: "",
        coverUrl: null,
        coverPlaceholder: "",
        categoryTag: "WEB",
        source: "",
        publishTime: "",
        publishTimeDisplay: "",
        targetUrl: this.initialUrl,
        favorite: true,
        channelId: ""
      });
      this.favRepo.save(article);
    } else {
      this.favRepo.remove(this.articleId);
    }
  }

  /**
   * S8:从 Preferences 加载当前文章的收藏状态。
   * 在 init() 中同步调用(favRepo.loadAll 是异步,但状态检查不阻塞页面加载)。
   */
  private loadFavoriteStatus(): void {
    if (this.articleId.length === 0) {
      return;
    }
    this.favRepo.loadAll().then((articles: Array<Article>): void => {
      for (let i = 0; i < articles.length; i++) {
        if (articles[i].articleId === this.articleId) {
          this.isFavorited = true;
          return;
        }
      }
      this.isFavorited = false;
    }).catch((_err: object): void => {
      this.isFavorited = false;
    });
  }

  /** 复制当前 URL 到剪贴板。 */
  copyLink(): void {
    const data: WebContainerData | null = this.getCurrentData();
    if (data === null) {
      return;
    }
    const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, data.currentUrl);
    const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData).then((): void => {
      promptAction.showToast({ message: "链接已复制" });
    }).catch((_err: object): void => {
      promptAction.showToast({ message: "复制失败" });
    });
    this.showMoreMenu = false;
  }

  /** 错误页"重新加载":重置状态,Page 层调 webController.loadUrl(LOAD_NO_CACHE)。 */
  retryLoad(): void {
    this.state = PageState.loading();
    this.progress = 0;
    this.showSlowBar = false;
    this.lastErrorCode = "";
    this.startSlowTimer();

    // Content 数据保持(currentUrl 不变),重拉时 Page 会用 currentUrl 重新加载
    const url: string = this.initialUrl;
    const domain: string = WebContainerViewModel.parseDomain(url);
    const isHttps: boolean = url.indexOf("https://") === 0;
    const title: string = this.initialTitle.length > 0 ? this.initialTitle : domain;
    const data: WebContainerData = new WebContainerData(url, title, domain, isHttps, true);
    this.state = PageState.content(data);
  }

  /** 取当前 state.data,Page 层用。 */
  getCurrentData(): WebContainerData | null {
    if (!this.state.isContent()) {
      return null;
    }
    return this.state.data as WebContainerData;
  }

  /** 错误页展示用,traceId 后 6 位 — 本期 mock,取 errorCode 尾部当占位。 */
  getTraceTail(): string {
    const code: string = this.lastErrorCode.length > 0 ? this.lastErrorCode : "UNKNOWN";
    return code.length >= 6 ? code.substring(code.length - 6) : code;
  }

  /** 当前 URL 是否需要注入登录 token(Page 在 onPageEnd 时调)。 */
  shouldInjectToken(url: string): boolean {
    return this.repository.shouldInjectToken(url);
  }

  /** 取 mock token 鉴权头(Page 注入 cookie 用,简历主线 2"登录态透传"证据)。 */
  getAuthHeader(): string {
    return this.repository.authHeader();
  }

  // ============================================================
  // 内部
  // ============================================================

  private updateCurrentUrl(url: string): void {
    if (!this.state.isContent()) {
      return;
    }
    const data: WebContainerData = this.state.data as WebContainerData;
    const domain: string = WebContainerViewModel.parseDomain(url);
    const isHttps: boolean = url.indexOf("https://") === 0;
    const title: string = data.displayTitle.length > 0 ? data.displayTitle : domain;
    const next: WebContainerData = data.withUrl(url, title, domain, isHttps);
    this.state = PageState.content(next);
    this.progress = 0;
  }

  private startSlowTimer(): void {
    this.clearSlowTimer();
    this.showSlowBar = false;
    this.slowTimerId = setTimeout((): void => {
      // 5s 没到 100% 就显示黄条
      if (this.progress < 100) {
        this.showSlowBar = true;
      }
    }, SLOW_THRESHOLD_MS);
  }

  private clearSlowTimer(): void {
    if (this.slowTimerId !== -1) {
      clearTimeout(this.slowTimerId);
      this.slowTimerId = -1;
    }
  }

  /**
   * 从 URL 中抽 domain(host 部分)。
   * ArkTS 严格类型,不能用 new URL(),手撸简单 parser:
   *   "https://mock-cdn/article/123" -> "mock-cdn"
   *   "tel:10086" -> "tel"
   */
  private static parseDomain(url: string): string {
    const schemeEnd: number = url.indexOf("://");
    if (schemeEnd < 0) {
      // tel: / mailto: 等无 host
      const colonIdx: number = url.indexOf(":");
      return colonIdx > 0 ? url.substring(0, colonIdx) : url;
    }
    const hostStart: number = schemeEnd + 3;
    const pathStart: number = url.indexOf("/", hostStart);
    if (pathStart < 0) {
      return url.substring(hostStart);
    }
    return url.substring(hostStart, pathStart);
  }
}
