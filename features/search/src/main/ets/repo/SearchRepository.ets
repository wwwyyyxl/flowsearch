/**
 * @file SearchRepository.ets
 * @description 搜索数据源:从 SearchMock 取数据 + 模拟网络延时和错误。
 *
 * 设计要点(对齐 HomeRepository 同源底线):
 *
 * 1. 零装饰器(plain class):
 *    可以整段平移到 Kotlin:
 *      class SearchRepository {
 *        suspend fun fetchSuggestions(keyword: String): List<SearchSuggestion>
 *        suspend fun fetchResults(keyword: String, sort: SortType): List<Article>
 *        suspend fun fetchAiAnswer(keyword: String): AiQuickAnswer?
 *      }
 *
 * 2. 接口数对应 PRD §07-Mock-API:
 *    - fetchSuggestions  -> §2.5  GET /api/search/suggest
 *    - fetchResults      -> §2.6  GET /api/search/result
 *    - fetchAiAnswer     -> §2.7  GET /api/search/ai-quick-answer
 *
 * 3. AI 速答有独立 2s 超时(PRD §04-03 §6),
 *    本期用 Promise.race 模拟,真实接口在 commons/network 拦截器里做。
 *
 * 4. 错误码:
 *    - "500"        网络/服务异常
 *    - "TIMEOUT"    AI 速答 2s 超时(仅静默,不抛给 VM)
 *
 * 5. 历史 / 热搜不走 Repository:
 *    历史本期是 SearchMock 内存常量,S4 接 Preferences 后另起一个 HistoryRepository。
 *    热搜直接由 VM 通过 SearchMock 同步取(简单,不走 Promise),省一层异步。
 */

import { Article, SearchSuggestion, AiQuickAnswer, SortType, SearchInputData } from "@flowsearch/base";
import { SearchMock } from "@flowsearch/mockdata";
import { SimulationMode } from "./SimulationMode";

const DELAY_NORMAL_MS: number = 200;
const DELAY_ERROR_MS: number = 500;
const DELAY_SLOW_MS: number = 3000;

/** S17:Mock 分页:每页条数。 */
const SEARCH_PAGE_SIZE: number = 3;

/** AI 速答超时阈值(PRD §04-03 §6:"接口请求超时 2s")。 */
const AI_ANSWER_TIMEOUT_MS: number = 2000;

/** Repository 抛出的错误对象(沿用 HomeRepoError 风格,但本模块独立)。 */
export class SearchRepoError extends Error {
  readonly errorCode: string = "";

  constructor(errorCode: string, message: string) {
    super(message);
    this.errorCode = errorCode;
  }
}

/** S17:fetchMore 返回值。 */
export class SearchFetchMoreResult {
  readonly articles: Array<Article> = new Array();
  readonly hasMore: boolean = true;

  constructor(articles: Array<Article>, hasMore: boolean) {
    this.articles = articles;
    this.hasMore = hasMore;
  }
}

export class SearchRepository {
  /**
   * 取空输入态(历史 + 热搜)。本期同步返回,不模拟延时 -- 历史是本地数据。
   */
  getSearchInput(): SearchInputData {
    return SearchMock.getSearchInput();
  }

  /**
   * 拉取建议词(对应 GET /api/search/suggest)。
   * keyword 已经被 VM debounce 过,这里不再额外节流。
   */
  async fetchSuggestions(keyword: string, mode: SimulationMode): Promise<Array<SearchSuggestion>> {
    await SearchRepository.sleep(SearchRepository.pickDelay(mode));

    if (mode === "error") {
      // PRD §04-02 §6:Error(建议接口) 静默失败 -- VM 层 catch 后不抛 PageState.error,
      // 直接 fallback 空列表。但 Repository 接口语义保留 throw,VM 自己决定。
      throw new SearchRepoError("500", "建议接口异常");
    }

    if (mode === "empty") {
      return new Array();
    }

    return SearchMock.getSuggestions(keyword);
  }

  /**
   * 拉取搜索结果(对应 GET /api/search/result)。
   * sort 切换时 VM 重调此方法,但 AI 速答卡保留(PRD §04-03 §3)。
   */
  async fetchResults(keyword: string, sort: SortType, mode: SimulationMode): Promise<Array<Article>> {
    await SearchRepository.sleep(SearchRepository.pickDelay(mode));

    if (mode === "error") {
      throw new SearchRepoError("500", "服务器开小差了,请稍后重试");
    }

    if (mode === "empty") {
      return new Array();
    }

    return SearchMock.getResults(keyword, sort);
  }

  /**
   * 拉取 AI 速答(对应 GET /api/search/ai-quick-answer)。
   * 与 fetchResults 并行调用。本方法**永不抛**,失败/超时/null 都返回 null,
   * 让 UI 层简单一致:`aiAnswer === null` 就隐藏整张卡。
   */
  async fetchAiAnswer(keyword: string, mode: SimulationMode): Promise<AiQuickAnswer | null> {
    // 超时与延时竞速,先到先返回
    const delay: number = SearchRepository.pickDelay(mode);

    const dataPromise: Promise<AiQuickAnswer | null> = SearchRepository.sleep(delay).then((): AiQuickAnswer | null => {
      if (mode === "error" || mode === "empty") {
        return null;
      }
      return SearchMock.getAiAnswer(keyword);
    });

    // PRD §04-03 §6:2s 超时静默隐藏。slow 模式 3000ms > 2000ms 必然命中超时。
    const timeoutPromise: Promise<AiQuickAnswer | null> = SearchRepository.sleep(AI_ANSWER_TIMEOUT_MS).then((): AiQuickAnswer | null => null);

    return Promise.race([dataPromise, timeoutPromise]);
  }

  /**
   * S17:Mock 分页:取搜索结果的第 page 页(0-based)。
   * Mock 数据量小,用 cycle + suffix 模拟更多数据,最多返回 3 页。
   */
  async fetchMore(
    keyword: string,
    sort: SortType,
    page: number,
    mode: SimulationMode
  ): Promise<SearchFetchMoreResult> {
    const delayMs: number = SearchRepository.pickDelay(mode);
    await SearchRepository.sleep(delayMs);

    if (mode === "error") {
      throw new SearchRepoError("500", "加载更多失败");
    }

    // Mock:最多 3 页
    const maxPages: number = 3;
    if (page >= maxPages) {
      return new SearchFetchMoreResult(new Array(), false);
    }

    // 循环复用基础结果,加后缀区分 articleId
    const base: Array<Article> = SearchMock.getResults(keyword, sort);
    const start: number = page * SEARCH_PAGE_SIZE;
    const articles: Array<Article> = new Array();
    for (let i = 0; i < SEARCH_PAGE_SIZE; i++) {
      const src: Article = base[(start + i) % base.length];
      articles.push(new Article({
        articleId: src.articleId + "_p" + page + "_" + i,
        title: src.title,
        summary: src.summary,
        coverUrl: src.coverUrl,
        coverPlaceholder: src.coverPlaceholder,
        categoryTag: src.categoryTag,
        source: src.source,
        publishTime: src.publishTime,
        publishTimeDisplay: src.publishTimeDisplay,
        targetUrl: src.targetUrl,
        favorite: src.favorite,
        channelId: src.channelId
      }));
    }
    const hasMore: boolean = (page + 1) < maxPages;
    return new SearchFetchMoreResult(articles, hasMore);
  }

  private static pickDelay(mode: SimulationMode): number {
    if (mode === "slow") {
      return DELAY_SLOW_MS;
    }
    if (mode === "error") {
      return DELAY_ERROR_MS;
    }
    return DELAY_NORMAL_MS;
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => { resolve(); }, ms);
    });
  }
}
