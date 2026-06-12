/**
 * @file SearchResultViewModel.ets
 * @description SearchResultPage 的 ViewModel。
 *              把 PageState 状态机 + AI 速答卡 + 排序 Tab + LazyForEach 数据源串起来。
 *
 * 设计要点(简历主线 3/4 二次落地):
 *
 * 1. PageState 复用:
 *    Loading / Empty / Error 三态走 StateHost 分发。
 *    Content 状态下 state.data 是 SearchResultData(keyword + aiAnswer + articles)。
 *
 * 2. 并行请求(PRD §04-03 §3):
 *    fetchResults 和 fetchAiAnswer 同时发,AI 失败 / null / 超时 -> 整卡不展示,
 *    但**不阻塞**主结果。所以 VM 先 await 结果列表生成 PageState,
 *    AI 拉到再单独 setAiAnswer。
 *
 * 3. AI 卡边界规则(PRD §04-03 §6):
 *    - keyword.trim().length < 2 -> 不请求接口(VM 提前 return null)
 *    - relatedQuestions 超过 3 条 -> 只取前 3(UI 截断,但 VM 不修剪 -- 数据契约保真)
 *    - 2s 超时由 Repository.fetchAiAnswer 内部 race 处理,VM 拿到的就是 null
 *
 * 4. 排序 Tab 切换:
 *    重调 fetchResults,但 AI 速答保留(PRD §04-03 §3)。
 *    所以切换时:VM 只刷 articles,不动 aiAnswer。
 *
 * 5. 不可变更新:
 *    收藏 toggle / 排序切换都 new 新 SearchResultData,@Trace 才稳触发。
 */

import { PageState, Article, SearchResultData, AiQuickAnswer, SortType, PerfTracker } from "@flowsearch/base";
import { FavoritesRepository } from "@flowsearch/favs";
import { SearchRepository, SearchRepoError, SearchFetchMoreResult } from "../repo/SearchRepository";
import { SimulationMode } from "../repo/SimulationMode";
import { SearchResultDataSource } from "./SearchResultDataSource";

@ObservedV2
export class SearchResultViewModel {
  /** 当前关键词(从 SearchInput 跳转时传入)。 */
  @Trace keyword: string = "";

  /** 当前排序方式。默认 RELEVANCE(综合)。 */
  @Trace sortType: SortType = "RELEVANCE";

  /** 页面整体状态(Loading/Empty/Error/Content)。 */
  @Trace state: PageState = PageState.idle();

  /** 调试用模拟模式。 */
  @Trace simulationMode: SimulationMode = "normal";

  /** S17:无限滚动:是否正在加载更多。 */
  @Trace isLoadingMore: boolean = false;

  /** S17:无限滚动:是否还有更多数据。 */
  @Trace hasMore: boolean = true;

  /** S17:下一页页码(0-based)。 */
  private nextPage: number = 0;

  /** LazyForEach 数据源,VM 持有。 */
  readonly dataSource: SearchResultDataSource = new SearchResultDataSource();

  private readonly repository: SearchRepository = new SearchRepository();
  private readonly favRepo: FavoritesRepository = new FavoritesRepository();

  /** 初始化:接收 keyword + context + 立即并行加载结果与 AI 速答。 */
  init(keyword: string, context: Context): void {
    this.keyword = keyword.trim();
    this.favRepo.init(context);
    if (this.keyword.length === 0) {
      this.state = PageState.empty();
      return;
    }
    this.loadResults();
  }

  /** 切换排序 Tab(综合 / 最新 / 最热 / 仅工具 / 仅文章)。 */
  changeSort(sort: SortType): void {
    if (this.sortType === sort) {
      return;
    }
    this.sortType = sort;
    // 切排序:只重拉结果,AI 卡保持(PRD §04-03 §3)。
    this.loadResultsOnly();
  }

  /** 错误页"重试"按钮回调。 */
  retryCurrent(): void {
    this.loadResults();
  }

  /** 切模拟模式 + 立刻重拉(调试浮层用)。 */
  changeSimulationMode(mode: SimulationMode): void {
    this.simulationMode = mode;
    this.loadResults();
  }

  /**
   * S17:下拉刷新。保留 AI 卡,只重拉结果列表。
   * 返回 Promise,Page 层在完成后置 isRefreshing=false。
   */
  async refreshResults(): Promise<void> {
    const prevAi: AiQuickAnswer | null = this.state.isContent()
      ? (this.state.data as SearchResultData).aiAnswer
      : null;
    try {
      const articles: Array<Article> = await this.repository.fetchResults(
        this.keyword, this.sortType, this.simulationMode
      );
      if (articles.length === 0) {
        this.state = PageState.empty();
        this.dataSource.setArticles(new Array());
      } else {
        const data = new SearchResultData(this.keyword, prevAi, articles);
        this.state = PageState.content(data);
        this.dataSource.setArticles(articles);
      }
      // 重置分页
      this.hasMore = true;
      this.isLoadingMore = false;
      this.nextPage = 1;
    } catch (_err) {
      // 静默失败,保留当前数据
    }
  }

  /**
   * S17:上拉加载更多。
   * 防重复:isLoadingMore 或 !hasMore 时直接返回。
   */
  loadMore(): void {
    if (this.isLoadingMore || !this.hasMore) {
      return;
    }
    this.isLoadingMore = true;

    this.repository.fetchMore(this.keyword, this.sortType, this.nextPage, this.simulationMode)
      .then((result: SearchFetchMoreResult): void => {
        if (this.state.isContent()) {
          const oldData = this.state.data as SearchResultData;
          const merged: Array<Article> = new Array();
          for (let i = 0; i < oldData.articles.length; i++) {
            merged.push(oldData.articles[i]);
          }
          for (let i = 0; i < result.articles.length; i++) {
            merged.push(result.articles[i]);
          }
          const nextData = new SearchResultData(oldData.keyword, oldData.aiAnswer, merged);
          this.state = PageState.content(nextData);
          this.dataSource.setArticles(merged);
        }
        this.hasMore = result.hasMore;
        this.nextPage = this.nextPage + 1;
        this.isLoadingMore = false;
      })
      .catch((_err: object): void => {
        this.isLoadingMore = false;
      });
  }

  /** 收藏 toggle:不可变更新当前 SearchResultData 里的对应 Article + 持久化。 */
  toggleFavorite(articleId: string): void {
    if (!this.state.isContent()) {
      return;
    }
    const data = this.state.data as SearchResultData;
    let toggledArticle: Article | null = null;
    const nextArticles: Array<Article> = data.articles.map((a: Article): Article => {
      if (a.articleId === articleId) {
        toggledArticle = a.withFavorite(!a.favorite);
        return toggledArticle;
      }
      return a;
    });
    const nextData = new SearchResultData(data.keyword, data.aiAnswer, nextArticles);
    this.state = PageState.content(nextData);
    this.dataSource.setArticles(nextArticles);

    // S11:异步持久化到 FavoritesRepository
    if (toggledArticle !== null) {
      const article: Article = toggledArticle as Article;
      if (article.favorite) {
        this.favRepo.save(article);
      } else {
        this.favRepo.remove(articleId);
      }
    }
  }

  // ============================================================
  // 内部:数据加载链
  // ============================================================

  /**
   * 全量加载:Loading -> 并行(results + aiAnswer) -> Content/Empty/Error。
   */
  private loadResults(): void {
    this.state = PageState.loading();
    this.dataSource.setArticles(new Array());

    // S24:性能追踪
    const traceId: number = PerfTracker.markStart("search_query");

    const aiPromise: Promise<AiQuickAnswer | null> = this.keyword.length < 2
      ? Promise.resolve<AiQuickAnswer | null>(null)
      : this.repository.fetchAiAnswer(this.keyword, this.simulationMode);

    this.repository.fetchResults(this.keyword, this.sortType, this.simulationMode)
      .then((articles: Array<Article>): void => {
        // 主结果先就位
        if (articles.length === 0) {
          this.state = PageState.empty();
          this.dataSource.setArticles(new Array());
        } else {
          const data = new SearchResultData(this.keyword, null, articles);
          this.state = PageState.content(data);
          this.dataSource.setArticles(articles);
        }
        // S17:重置分页
        this.hasMore = true;
        this.isLoadingMore = false;
        this.nextPage = 1;
        // 等 AI 速答(可能更晚到)
        aiPromise.then((ai: AiQuickAnswer | null): void => {
          this.applyAiAnswerIfStillCurrent(ai);
        });
        // S24:性能追踪完成
        PerfTracker.markEnd("search_query", traceId);
        PerfTracker.reportEvent("search_completed", { "keyword": this.keyword, "count": articles.length });
      })
      .catch((err: object): void => {
        const repoErr = err as SearchRepoError;
        const code: string = repoErr.errorCode !== undefined && repoErr.errorCode.length > 0
          ? repoErr.errorCode
          : "UNKNOWN";
        const msg: string = repoErr.message !== undefined && repoErr.message.length > 0
          ? repoErr.message
          : "未知错误";
        this.state = PageState.error(code, msg);
        this.dataSource.setArticles(new Array());
      });
  }

  /**
   * 仅刷结果列表(切排序场景)。
   * 保留 aiAnswer,不重拉 AI 接口(PRD §04-03 §3)。
   */
  private loadResultsOnly(): void {
    const prevAi: AiQuickAnswer | null = this.state.isContent()
      ? (this.state.data as SearchResultData).aiAnswer
      : null;

    this.state = PageState.loading();
    this.dataSource.setArticles(new Array());

    this.repository.fetchResults(this.keyword, this.sortType, this.simulationMode)
      .then((articles: Array<Article>): void => {
        if (articles.length === 0) {
          this.state = PageState.empty();
          this.dataSource.setArticles(new Array());
        } else {
          const data = new SearchResultData(this.keyword, prevAi, articles);
          this.state = PageState.content(data);
          this.dataSource.setArticles(articles);
        }
      })
      .catch((err: object): void => {
        const repoErr = err as SearchRepoError;
        const code: string = repoErr.errorCode !== undefined && repoErr.errorCode.length > 0
          ? repoErr.errorCode
          : "UNKNOWN";
        this.state = PageState.error(code, repoErr.message ?? "未知错误");
        this.dataSource.setArticles(new Array());
      });
  }

  /**
   * AI 速答迟到回填。
   * 仅在 state 仍是 Content 且 keyword 没换的前提下生效(防止 race condition)。
   */
  private applyAiAnswerIfStillCurrent(ai: AiQuickAnswer | null): void {
    if (ai === null) {
      return;
    }
    if (!this.state.isContent()) {
      return;
    }
    const data = this.state.data as SearchResultData;
    if (data.keyword !== this.keyword) {
      return;
    }
    const next = new SearchResultData(data.keyword, ai, data.articles);
    this.state = PageState.content(next);
  }
}
