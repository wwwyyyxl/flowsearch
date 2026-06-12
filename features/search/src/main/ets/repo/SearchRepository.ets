/**
 * @file SearchRepository.ets
 * @description 搜索数据源:S21 升级:真实 API 优先,MockData 降级为 fallback。
 *
 * 设计要点(对齐 HomeRepository 同源底线):
 *
 * 1. 零装饰器(plain class),可整段平移 Kotlin。
 *
 * 2. S21 Fallback 策略:
 *    ① SimulationMode error/empty → 短路走 Mock
 *    ② HttpClient.baseUrl 非空 → 尝试真实 API → catch 降级到 ③
 *    ③ Mock fallback(sleep + MockData 调用)
 *
 * 3. AI 速答保留 Promise.race 2s 超时(PRD §04-03 §6)。
 *
 * 4. getSearchInput() 保持 Mock-only(同步方法,不走 HTTP)。
 */

import {
  Article, ArticleInit, CategoryTag, SearchSuggestion, AiQuickAnswer,
  SortType, SearchInputData, SuggestionType
} from "@flowsearch/base";
import { HttpClient, HttpError, ApiResponse } from "@flowsearch/base";
import { SearchMock } from "@flowsearch/mockdata";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { SimulationMode } from "./SimulationMode";

const DELAY_NORMAL_MS: number = 200;
const DELAY_ERROR_MS: number = 500;
const DELAY_SLOW_MS: number = 3000;

/** S17:Mock 分页:每页条数。 */
const SEARCH_PAGE_SIZE: number = 3;

/** AI 速答超时阈值(PRD §04-03 §6:"接口请求超时 2s")。 */
const AI_ANSWER_TIMEOUT_MS: number = 2000;

const TAG: string = "SearchRepo";
const DOMAIN: number = 0x0000;

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
   * 取空输入态(历史 + 热搜)。同步返回,不走 HTTP。
   */
  getSearchInput(): SearchInputData {
    return SearchMock.getSearchInput();
  }

  /**
   * 拉取建议词(对应 GET /api/search/suggest)。
   * S21:真实 API 优先 → Mock fallback。
   */
  async fetchSuggestions(keyword: string, mode: SimulationMode): Promise<Array<SearchSuggestion>> {
    if (mode === "error") {
      throw new SearchRepoError("500", "建议接口异常");
    }

    if (mode === "empty") {
      return new Array();
    }

    // 真实 API 尝试
    if (HttpClient.baseUrl.length > 0) {
      try {
        const params: Map<string, string> = new Map();
        params.set("keyword", keyword);
        const resp: ApiResponse = await HttpClient.get("/api/search/suggest", params);
        if (resp.data !== null) {
          const d = resp.data as Record<string, object>;
          const rawList = d.list as Array<object>;
          const result: Array<SearchSuggestion> = new Array();
          for (let i: number = 0; i < rawList.length; i++) {
            result.push(SearchRepository.mapSuggestion(rawList[i]));
          }
          hilog.info(DOMAIN, TAG, "fetchSuggestions API ok, count=%{public}d", result.length);
          return result;
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, "fetchSuggestions API fallback: %{public}s", JSON.stringify(err));
      }
    }

    // Mock fallback
    await SearchRepository.sleep(SearchRepository.pickDelay(mode));
    return SearchMock.getSuggestions(keyword);
  }

  /**
   * 拉取搜索结果(对应 GET /api/search/result)。
   * S21:真实 API 优先 → Mock fallback。
   */
  async fetchResults(keyword: string, sort: SortType, mode: SimulationMode): Promise<Array<Article>> {
    if (mode === "error") {
      throw new SearchRepoError("500", "服务器开小差了,请稍后重试");
    }

    if (mode === "empty") {
      return new Array();
    }

    // 真实 API 尝试
    if (HttpClient.baseUrl.length > 0) {
      try {
        const params: Map<string, string> = new Map();
        params.set("keyword", keyword);
        params.set("sort", sort);
        const resp: ApiResponse = await HttpClient.get("/api/search/result", params);
        if (resp.data !== null) {
          const d = resp.data as Record<string, object>;
          const rawList = d.list as Array<object>;
          const result: Array<Article> = new Array();
          for (let i: number = 0; i < rawList.length; i++) {
            result.push(SearchRepository.mapArticle(rawList[i]));
          }
          hilog.info(DOMAIN, TAG, "fetchResults API ok, count=%{public}d", result.length);
          return result;
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, "fetchResults API fallback: %{public}s", JSON.stringify(err));
      }
    }

    // Mock fallback
    await SearchRepository.sleep(SearchRepository.pickDelay(mode));
    return SearchMock.getResults(keyword, sort);
  }

  /**
   * 拉取 AI 速答(对应 GET /api/search/ai-quick-answer)。
   * 永不抛错,失败/超时/null 都返回 null。
   * S21:保留 Promise.race 2s 超时结构。
   */
  async fetchAiAnswer(keyword: string, mode: SimulationMode): Promise<AiQuickAnswer | null> {
    // 真实 API 调用(包装在 dataPromise 中,与 2s 超时竞速)
    const dataPromise: Promise<AiQuickAnswer | null> = (async (): Promise<AiQuickAnswer | null> => {
      if (mode === "error" || mode === "empty") {
        return null;
      }

      // 真实 API 尝试
      if (HttpClient.baseUrl.length > 0) {
        try {
          const params: Map<string, string> = new Map();
          params.set("keyword", keyword);
          const resp: ApiResponse = await HttpClient.get("/api/search/ai-quick-answer", params);
          if (resp.data !== null) {
            const answer: AiQuickAnswer = SearchRepository.mapAiAnswer(resp.data);
            hilog.info(DOMAIN, TAG, "fetchAiAnswer API ok");
            return answer;
          }
          return null;
        } catch (err) {
          hilog.warn(DOMAIN, TAG, "fetchAiAnswer API fallback: %{public}s", JSON.stringify(err));
        }
      }

      // Mock fallback
      const delay: number = SearchRepository.pickDelay(mode);
      await SearchRepository.sleep(delay);
      return SearchMock.getAiAnswer(keyword);
    })();

    // PRD §04-03 §6: 2s 超时静默隐藏。slow 模式 3000ms > 2000ms 必然命中超时。
    const timeoutPromise: Promise<AiQuickAnswer | null> = SearchRepository.sleep(AI_ANSWER_TIMEOUT_MS).then(
      (): AiQuickAnswer | null => null
    );

    return Promise.race([dataPromise, timeoutPromise]);
  }

  /**
   * S17:Mock 分页:取搜索结果的第 page 页(0-based)。
   * S21:真实 API 优先 → Mock fallback。
   */
  async fetchMore(
    keyword: string,
    sort: SortType,
    page: number,
    mode: SimulationMode
  ): Promise<SearchFetchMoreResult> {
    if (mode === "error") {
      throw new SearchRepoError("500", "加载更多失败");
    }

    // 真实 API 尝试
    if (HttpClient.baseUrl.length > 0) {
      try {
        const params: Map<string, string> = new Map();
        params.set("keyword", keyword);
        params.set("sort", sort);
        params.set("page", String(page));
        const resp: ApiResponse = await HttpClient.get("/api/search/result", params);
        if (resp.data !== null) {
          const d = resp.data as Record<string, object>;
          const rawList = d.list as Array<object>;
          const articles: Array<Article> = new Array();
          for (let i: number = 0; i < rawList.length; i++) {
            articles.push(SearchRepository.mapArticle(rawList[i]));
          }
          const hasMore: boolean = typeof d.hasMore === "boolean" ? d.hasMore as boolean : false;
          hilog.info(DOMAIN, TAG, "fetchMore API ok, count=%{public}d", articles.length);
          return new SearchFetchMoreResult(articles, hasMore);
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, "fetchMore API fallback: %{public}s", JSON.stringify(err));
      }
    }

    // Mock fallback
    const delayMs: number = SearchRepository.pickDelay(mode);
    await SearchRepository.sleep(delayMs);

    // Mock:最多 3 页
    const maxPages: number = 3;
    if (page >= maxPages) {
      return new SearchFetchMoreResult(new Array(), false);
    }

    // 循环复用基础结果,加后缀区分 articleId
    const base: Array<Article> = SearchMock.getResults(keyword, sort);
    const start: number = page * SEARCH_PAGE_SIZE;
    const articles: Array<Article> = new Array();
    for (let i: number = 0; i < SEARCH_PAGE_SIZE; i++) {
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

  // ============================================================
  // 内部:API 响应映射
  // ============================================================

  private static mapSuggestion(obj: object): SearchSuggestion {
    const o = obj as Record<string, object>;
    const typeStr: string = typeof o.type === "string" ? o.type : "NORMAL";
    return new SearchSuggestion(
      typeof o.suggestionId === "string" ? o.suggestionId : "",
      typeof o.keyword === "string" ? o.keyword : "",
      typeStr as SuggestionType,
      typeof o.hot === "boolean" ? o.hot as boolean : false
    );
  }

  private static mapAiAnswer(obj: object): AiQuickAnswer {
    const o = obj as Record<string, object>;
    const related: Array<string> = new Array();
    if (typeof o.relatedQuestions === "object" && o.relatedQuestions !== null) {
      const rawArr = o.relatedQuestions as Array<object>;
      for (let i: number = 0; i < rawArr.length; i++) {
        related.push(String(rawArr[i]));
      }
    }
    return new AiQuickAnswer(
      typeof o.answerId === "string" ? o.answerId : "",
      typeof o.summary === "string" ? o.summary : "",
      related,
      typeof o.disclaimer === "string" ? o.disclaimer : ""
    );
  }

  private static mapArticle(obj: object): Article {
    const o = obj as Record<string, object>;
    const tag: string = typeof o.categoryTag === "string" ? o.categoryTag : "WEB";
    const init: ArticleInit = {
      articleId: typeof o.articleId === "string" ? o.articleId : "",
      title: typeof o.title === "string" ? o.title : "",
      summary: typeof o.summary === "string" ? o.summary : "",
      coverUrl: typeof o.coverUrl === "string" ? o.coverUrl : null,
      coverPlaceholder: typeof o.coverPlaceholder === "string" ? o.coverPlaceholder : "",
      categoryTag: tag as CategoryTag,
      source: typeof o.source === "string" ? o.source : "",
      publishTime: typeof o.publishTime === "string" ? o.publishTime : "",
      publishTimeDisplay: typeof o.publishTimeDisplay === "string" ? o.publishTimeDisplay : "",
      targetUrl: typeof o.targetUrl === "string" ? o.targetUrl : "",
      favorite: typeof o.favorite === "boolean" ? o.favorite as boolean : false,
      channelId: typeof o.channelId === "string" ? o.channelId : ""
    };
    return new Article(init);
  }

  // ============================================================
  // 内部:Mock 辅助
  // ============================================================

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
