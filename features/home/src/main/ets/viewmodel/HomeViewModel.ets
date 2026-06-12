/**
 * @file HomeViewModel.ets
 * @description 首页 ViewModel。把 PageState 状态机和 HomeRepository 串起来。
 *
 * 设计要点(简历主线 3 频道隔离 / 主线 4 空错加载分层):
 *
 * 1. 频道独立状态:
 *    用 Map<channelId, PageState> 而不是单一 state,
 *    切频道时不抹掉别的频道的数据(PRD §03 §4 "保留每个频道滚动位置和数据 30 分钟")。
 *    UI 层通过 currentChannelId 取当前展示的 state。
 *    -> 这是面试"切频道闪一下"问题的根答:状态隔离 + 缓存复用。
 *
 * 2. 装饰器只放在 VM 类上:
 *    @ObservedV2 标 class -> 类内 @Trace 字段变化时,绑定的 UI 重渲。
 *    Repository / Mock / Models 全部零装饰器(同源底线)。
 *
 * 3. 状态转换原子性:
 *    每次 loadFeed 全程: idle/content -> loading -> content/empty/error,
 *    赋新 PageState 实例,UI 拿到 .kind 变化即重渲。
 *    避免"先清空数据 -> 再 Loading"两次重渲的闪烁。
 *
 * 4. 不可变更新:
 *    切频道 / 收藏 toggle 都生成新 Map / 新 Article 实例,不直接 mutate;
 *    与 PRD §08 §4.1 .withFavorite() / Kotlin data class .copy() 同源。
 *
 * ArkTS ↔ Kotlin 对照:
 *   @ObservedV2 class XxxVM { @Trace state: PageState }
 *     ≈ class XxxVM : ViewModel() { val state: StateFlow<UiState<T>> }
 *   this.state = PageState.loading()
 *     ≈ _state.value = UiState.Loading
 */

import { PageState, Channel, HomeFeedData, Article, ToolEntry, PerfTracker } from "@flowsearch/base";
import { HomeRepository, HomeRepoError, FetchMoreResult } from "../repo/HomeRepository";
import { SimulationMode } from "../repo/SimulationMode";
import { ArticleDataSource } from "./ArticleDataSource";
import { FavoritesRepository } from "@flowsearch/favs";

/** 默认初始频道。 */
const DEFAULT_CHANNEL_ID: string = "hot";

@ObservedV2
export class HomeViewModel {
  /** 各频道独立的 PageState,key = channelId。 */
  @Trace channelStates: Map<string, PageState> = new Map();

  /** 当前展示的频道 id。切换时只更新这个值 + 触发对应频道的 loadFeed。 */
  @Trace currentChannelId: string = DEFAULT_CHANNEL_ID;

  /** 共享的频道列表(各频道复用,首次成功后填充)。 */
  @Trace channels: Array<Channel> = new Array();

  /** 共享的工具入口(各频道复用)。 */
  @Trace quickEntries: Array<ToolEntry> = new Array();

  /** 调试用:模拟网络模式。调试浮层可改;真实接口不存在这个概念。 */
  @Trace simulationMode: SimulationMode = "normal";

  /** 无限滚动:是否正在加载更多。 */
  @Trace isLoadingMore: boolean = false;

  /** 无限滚动:是否还有更多数据。 */
  @Trace hasMore: boolean = true;

  /** S11:收藏频道脏标记。其他频道 toggle 收藏后设 true,切到"fav"时强制重拉。 */
  @Trace favDirty: boolean = false;

  /** 每频道下一页页码(0-based)。切频道时重置。 */
  private nextPage: Map<string, number> = new Map();

  /**
   * LazyForEach 用的数据源。VM 持有,UI 直接消费。
   *
   * 为什么放 VM 而非 UI?
   * - dataSource 的数据来自 currentChannel 的 Content,VM 是数据权威源,UI 是消费方;
   * - 切频道 / 收藏 toggle 时 VM 改 state -> 同时刷 dataSource,UI 不操心同步时机;
   * - 类比 Compose: VM 暴露 StateFlow<List<Article>>,UI 用 collectAsState 消费。
   */
  readonly feedDataSource: ArticleDataSource = new ArticleDataSource();

  /** 数据源。VM 持有 Repository 实例,而非每次 new(便于将来注入 Mock Repo 做测试)。 */
  private readonly repository: HomeRepository = new HomeRepository();

  /** 收藏持久化(S4 新增)。init(context) 时初始化。 */
  private readonly favRepo: FavoritesRepository = new FavoritesRepository();

  /** 初始化:加载默认频道。从页面 aboutToAppear 里调一次。S4 改为传入 context。 */
  init(context: Context): void {
    this.favRepo.init(context);
    this.loadFeed(DEFAULT_CHANNEL_ID);
  }

  /** 取当前频道的 PageState;没有就返回 Idle。 */
  getCurrentState(): PageState {
    const state = this.channelStates.get(this.currentChannelId);
    return state !== undefined ? state : PageState.idle();
  }

  /**
   * 切换频道。
   * - 若目标频道已有 Content/Empty/Error 缓存,直接展示(不重拉)。
   * - 否则触发 loadFeed。
   * -> 体现 PRD §03 §4 "保留每个频道数据" 策略。
   */
  switchChannel(channelId: string): void {
    if (this.currentChannelId === channelId) {
      return;
    }
    this.currentChannelId = channelId;
    // 重置分页状态
    this.isLoadingMore = false;
    this.hasMore = true;

    // S11:收藏频道脏标记 -> 清除缓存强制重拉
    if (channelId === "fav" && this.favDirty) {
      this.favDirty = false;
      // 删除旧 fav 缓存,让 loadFeed("fav") 重新从 Preferences 读取
      const cleared: Map<string, PageState> = new Map(this.channelStates);
      cleared.delete("fav");
      this.channelStates = cleared;
      this.loadFeed("fav");
      return;
    }

    const cached = this.channelStates.get(channelId);
    // Idle 或不存在 -> 加载;Loading 中也允许重新触发(等同重试)
    if (cached === undefined || cached.isIdle()) {
      this.loadFeed(channelId);
    } else if (cached.isContent()) {
      // 已有缓存:同步 dataSource,UI 直接展示
      const data = cached.data as HomeFeedData;
      this.feedDataSource.setArticles(data.articles);
    } else {
      // Empty / Error 缓存:dataSource 给空,UI 走 StateHost 分发
      this.feedDataSource.setArticles(new Array());
    }
  }

  /** 手动重试当前频道(StateHost 错误页的"重试"按钮回调)。 */
  retryCurrent(): void {
    this.loadFeed(this.currentChannelId);
  }

  /**
   * 加载更多(上拉触底时调用)。
   * 防重复:isLoadingMore 或 !hasMore 时直接返回。
   * 拼接逻辑:取当前 Content 的 articles + 新 articles -> 更新 state + dataSource。
   */
  loadMore(): void {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }
    // 收藏频道不支持分页
    if (this.currentChannelId === "fav") {
      return;
    }
    this.isLoadingMore = true;
    const page: number = this.nextPage.get(this.currentChannelId) ?? 1;

    this.repository.fetchMore(this.currentChannelId, page, this.simulationMode)
      .then((result: FetchMoreResult): void => {
        const state = this.channelStates.get(this.currentChannelId);
        if (state !== undefined && state.isContent()) {
          const oldData = state.data as HomeFeedData;
          // 拼接:旧 articles + 新 articles
          const merged: Array<Article> = new Array();
          for (let i = 0; i < oldData.articles.length; i++) {
            merged.push(oldData.articles[i]);
          }
          for (let i = 0; i < result.articles.length; i++) {
            merged.push(result.articles[i]);
          }
          const newData = new HomeFeedData(oldData.channels, oldData.quickEntries, merged);
          this.updateState(this.currentChannelId, PageState.content(newData));
          this.feedDataSource.setArticles(merged);
        }
        this.hasMore = result.hasMore;
        // 更新 nextPage
        const nextMap: Map<string, number> = new Map(this.nextPage);
        nextMap.set(this.currentChannelId, page + 1);
        this.nextPage = nextMap;
        this.isLoadingMore = false;
      })
      .catch((_err: object): void => {
        this.isLoadingMore = false;
      });
  }

  /** 切换模拟模式 + 立刻重拉。调试浮层用。 */
  changeSimulationMode(mode: SimulationMode): void {
    this.simulationMode = mode;
    this.loadFeed(this.currentChannelId);
  }

  /**
   * S17:下拉刷新。重新拉取当前频道数据。
   * 不走 Loading 态(保留当前内容),成功后直接替换 Content。
   * 失败静默(保留当前数据,不弹 Error 页)。
   * 返回 Promise,Page 层在 .then/.catch 后置 isRefreshing=false。
   */
  async refreshFeed(): Promise<void> {
    if (this.currentChannelId === "fav") {
      await this.refreshFavorites();
      return;
    }
    try {
      const data: HomeFeedData = await this.repository.fetchFeed(
        this.currentChannelId, this.simulationMode
      );
      if (this.channels.length === 0 && data.channels.length > 0) {
        this.channels = data.channels;
      }
      if (this.quickEntries.length === 0 && data.quickEntries.length > 0) {
        this.quickEntries = data.quickEntries;
      }
      if (data.articles.length === 0) {
        this.updateState(this.currentChannelId, PageState.empty());
        this.feedDataSource.setArticles(new Array());
      } else {
        this.updateState(this.currentChannelId, PageState.content(data));
        this.feedDataSource.setArticles(data.articles);
      }
      // 重置分页
      this.hasMore = true;
      this.isLoadingMore = false;
      const resetNext: Map<string, number> = new Map(this.nextPage);
      resetNext.set(this.currentChannelId, 0);
      this.nextPage = resetNext;
    } catch (_err) {
      // 静默失败,保留当前数据
    }
  }

  /** S17:刷新收藏频道(从 Preferences 重新读取)。 */
  private async refreshFavorites(): Promise<void> {
    try {
      const articles: Array<Article> = await this.favRepo.loadAll();
      const data: HomeFeedData = new HomeFeedData(this.channels, this.quickEntries, articles);
      if (articles.length === 0) {
        this.updateState("fav", PageState.empty());
        this.feedDataSource.setArticles(new Array());
      } else {
        this.updateState("fav", PageState.content(data));
        this.feedDataSource.setArticles(articles);
      }
    } catch (_err) {
      // 静默失败
    }
  }

  /**
   * 切换某文章的收藏态。
   * S4 改进:不再纯内存 toggle,同时异步持久化到 Preferences。
   * 不可变更新:用 Article.withFavorite + 重建文章列表。
   */
  toggleFavorite(articleId: string): void {
    const state = this.channelStates.get(this.currentChannelId);
    if (state === undefined || !state.isContent()) {
      return;
    }
    const data = state.data as HomeFeedData;
    let toggledArticle: Article | null = null;
    const nextArticles: Array<Article> = data.articles.map((a: Article): Article => {
      if (a.articleId === articleId) {
        toggledArticle = a.withFavorite(!a.favorite);
        return toggledArticle;
      }
      return a;
    });
    const nextData = new HomeFeedData(data.channels, data.quickEntries, nextArticles);
    this.updateState(this.currentChannelId, PageState.content(nextData));
    // 同步 dataSource 让 LazyForEach 重渲对应卡片
    this.feedDataSource.setArticles(nextArticles);

    // S4:异步持久化(不管在哪个频道都同步收藏状态到磁盘)
    if (toggledArticle !== null) {
      const article: Article = toggledArticle as Article;
      if (article.favorite) {
        this.favRepo.save(article);
      } else {
        this.favRepo.remove(articleId);
      }
      // S11:非"fav"频道的收藏变更标记脏,切回"fav"时重拉
      if (this.currentChannelId !== "fav") {
        this.favDirty = true;
      }
    }
  }

  /**
   * 拉某频道的 Feed。
   *
   * 转换链:
   *   当前频道 state -> Loading
   *   -> 异步等 Repository
   *   -> 成功:articles 长度 = 0 时 Empty;否则 Content
   *   -> 异常:Error(error_code, message)
   *
   * 不返回 Promise,因为 UI 层不关心结果;状态变化通过 @Trace 自动推送 UI。
   */
  private loadFeed(channelId: string): void {
    // S4:收藏频道走 FavoritesRepository,不走 HomeMock
    if (channelId === "fav") {
      this.loadFavorites();
      return;
    }

    this.updateState(channelId, PageState.loading());

    // S24:性能追踪
    const traceId: number = PerfTracker.markStart("home_feed_load");

    this.repository.fetchFeed(channelId, this.simulationMode).then((data: HomeFeedData): void => {
      // 频道列表 + 工具入口只在首次成功时缓存(避免轮播)
      if (this.channels.length === 0 && data.channels.length > 0) {
        this.channels = data.channels;
      }
      if (this.quickEntries.length === 0 && data.quickEntries.length > 0) {
        this.quickEntries = data.quickEntries;
      }
      const nextState: PageState = data.articles.length === 0
        ? PageState.empty()
        : PageState.content(data);
      this.updateState(channelId, nextState);

      // 重置分页状态(首次加载后从第 1 页开始加载更多)
      this.hasMore = true;
      this.isLoadingMore = false;
      const resetNext: Map<string, number> = new Map(this.nextPage);
      resetNext.set(channelId, 1);
      this.nextPage = resetNext;

      // 同步当前频道数据到 LazyForEach 数据源
      if (channelId === this.currentChannelId) {
        this.feedDataSource.setArticles(data.articles);
      }
      // S24:性能追踪完成
      PerfTracker.markEnd("home_feed_load", traceId);
      PerfTracker.reportEvent("home_feed_loaded", { "channel": channelId, "count": data.articles.length });
    }).catch((err: object): void => {
      const repoErr = err as HomeRepoError;
      const code: string = repoErr.errorCode !== undefined && repoErr.errorCode.length > 0
        ? repoErr.errorCode
        : "UNKNOWN";
      const msg: string = repoErr.message !== undefined && repoErr.message.length > 0
        ? repoErr.message
        : "未知错误";
      this.updateState(channelId, PageState.error(code, msg));
      // 错误态下清空 dataSource(显示 Error UI,不让旧数据残留在背后)
      if (channelId === this.currentChannelId) {
        this.feedDataSource.setArticles(new Array());
      }
    });
  }

  /**
   * S4:从 Preferences 加载收藏文章("fav" 频道专用)。
   * 成功:articles 长度 = 0 时 Empty;否则 Content。
   * 失败:Error("LOAD_ERR", message)。
   */
  private loadFavorites(): void {
    this.updateState("fav", PageState.loading());
    this.favRepo.loadAll().then((articles: Array<Article>): void => {
      const nextState: PageState = articles.length === 0
        ? PageState.empty()
        : PageState.content(new HomeFeedData(this.channels, this.quickEntries, articles));
      this.updateState("fav", nextState);
      if (this.currentChannelId === "fav") {
        this.feedDataSource.setArticles(articles);
      }
    }).catch((_err: object): void => {
      this.updateState("fav", PageState.error("LOAD_ERR", "加载收藏失败"));
      if (this.currentChannelId === "fav") {
        this.feedDataSource.setArticles(new Array());
      }
    });
  }

  /**
   * 不可变更新某频道的 state。
   * Map 的 set 是原地修改,但 @Trace 需要新引用才稳触发 UI,所以 new 一个 Map。
   * 这是 ArkTS V2 响应式的一个常见坑:基础类型 / 引用替换才稳触发,内部 mutate 可能漏触发。
   */
  private updateState(channelId: string, state: PageState): void {
    const nextMap: Map<string, PageState> = new Map(this.channelStates);
    nextMap.set(channelId, state);
    this.channelStates = nextMap;
  }
}
