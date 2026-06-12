/**
 * @file HomeRepository.ets
 * @description 首页数据源。S21 升级:真实 API 优先,MockData 降级为 fallback。
 *
 * 设计要点(同源底线 / 简历主线 5):
 *
 * 1. 零装饰器(plain class):
 *    可以整段平移到 Kotlin:
 *      class HomeRepository {
 *        suspend fun fetchFeed(channelId: String, mode: SimulationMode): HomeFeedData
 *      }
 *
 * 2. S21 Fallback 策略:
 *    ① SimulationMode error/empty → 短路走 Mock(保留调试面板行为)
 *    ② HttpClient.baseUrl 非空 → 尝试真实 API → catch 降级到 ③
 *    ③ Mock fallback(sleep + MockData 调用)
 *
 * 3. 方法签名不变 — ViewModel 层零改动。
 *
 * 4. 响应映射用 Record<string, object> cast + typeof 守卫:
 *    与 FavoriteRecord.fromJson 同模式。
 */

import { HomeFeedData, Article, ArticleInit, Channel, ToolEntry, CategoryTag } from "@flowsearch/base";
import { HttpClient, HttpError, ApiResponse } from "@flowsearch/base";
import { HomeMock } from "@flowsearch/mockdata";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { SimulationMode } from "./SimulationMode";

/** Mock 分页:每页条数。 */
const PAGE_SIZE: number = 3;

/** Mock 网络延时(毫秒)。 */
const DELAY_NORMAL_MS: number = 200;
const DELAY_ERROR_MS: number = 500;
const DELAY_SLOW_MS: number = 3000;

const TAG: string = "HomeRepo";
const DOMAIN: number = 0x0000;

/** Repository 抛出的错误对象,带 errorCode 字段,便于 VM 翻译成 PageState.error。 */
export class HomeRepoError extends Error {
  readonly errorCode: string = "";

  constructor(errorCode: string, message: string) {
    super(message);
    this.errorCode = errorCode;
  }
}

/** fetchMore 返回值。 */
export class FetchMoreResult {
  readonly articles: Array<Article> = new Array();
  readonly hasMore: boolean = true;

  constructor(articles: Array<Article>, hasMore: boolean) {
    this.articles = articles;
    this.hasMore = hasMore;
  }
}

export class HomeRepository {
  /**
   * 拉取指定频道的首页数据。
   * S21:真实 API 优先 → Mock fallback。
   */
  async fetchFeed(channelId: string, mode: SimulationMode): Promise<HomeFeedData> {
    // ① SimulationMode 短路(保留调试面板行为)
    if (mode === "error") {
      throw new HomeRepoError("500", "服务器开小差了,请稍后重试");
    }

    if (mode === "empty") {
      return new HomeFeedData(
        HomeMock.getChannels(),
        HomeMock.getQuickEntries(),
        new Array()
      );
    }

    // ② 真实 API 尝试
    if (HttpClient.baseUrl.length > 0) {
      try {
        const params: Map<string, string> = new Map();
        params.set("channelId", channelId);
        const resp: ApiResponse = await HttpClient.get("/api/tool/home", params);
        if (resp.data !== null) {
          const feed: HomeFeedData = HomeRepository.mapHomeFeed(resp.data);
          hilog.info(DOMAIN, TAG, "fetchFeed API ok, articles=%{public}d", feed.articles.length);
          return feed;
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, "fetchFeed API fallback: %{public}s", JSON.stringify(err));
      }
    }

    // ③ Mock fallback
    const delayMs: number = HomeRepository.pickDelay(mode);
    await HomeRepository.sleep(delayMs);
    return HomeMock.getHomeFeed(channelId);
  }

  /**
   * Mock 分页:取指定频道的第 page 页文章(0-based)。
   * S21:真实 API 优先 → Mock fallback。
   */
  async fetchMore(
    channelId: string,
    page: number,
    mode: SimulationMode
  ): Promise<FetchMoreResult> {
    if (mode === "error") {
      throw new HomeRepoError("500", "加载更多失败");
    }

    // ② 真实 API 尝试
    if (HttpClient.baseUrl.length > 0) {
      try {
        const params: Map<string, string> = new Map();
        params.set("channelId", channelId);
        params.set("page", String(page));
        const resp: ApiResponse = await HttpClient.get("/api/tool/feed", params);
        if (resp.data !== null) {
          const d = resp.data as Record<string, object>;
          const rawList = d.list as Array<object>;
          const articles: Array<Article> = new Array();
          for (let i: number = 0; i < rawList.length; i++) {
            articles.push(HomeRepository.mapArticle(rawList[i]));
          }
          const hasMore: boolean = typeof d.hasMore === "boolean" ? d.hasMore as boolean : false;
          hilog.info(DOMAIN, TAG, "fetchMore API ok, count=%{public}d", articles.length);
          return new FetchMoreResult(articles, hasMore);
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, "fetchMore API fallback: %{public}s", JSON.stringify(err));
      }
    }

    // ③ Mock fallback
    const delayMs: number = HomeRepository.pickDelay(mode);
    await HomeRepository.sleep(delayMs);

    const all: Array<Article> = HomeMock.getArticles(channelId);
    const start: number = page * PAGE_SIZE;
    const end: number = Math.min(start + PAGE_SIZE, all.length);
    const articles: Array<Article> = all.slice(start, end);
    const hasMore: boolean = end < all.length;

    return new FetchMoreResult(articles, hasMore);
  }

  // ============================================================
  // 内部:API 响应映射
  // ============================================================

  /**
   * 映射 /api/tool/home 响应 data → HomeFeedData。
   * 期望 data 结构: { channels: [...], quickEntries: [...], firstFeed: { list: [...] } }
   */
  private static mapHomeFeed(data: object): HomeFeedData {
    const d = data as Record<string, object>;

    const channels: Array<Channel> = new Array();
    const rawChannels = d.channels as Array<object>;
    for (let i: number = 0; i < rawChannels.length; i++) {
      channels.push(HomeRepository.mapChannel(rawChannels[i]));
    }

    const entries: Array<ToolEntry> = new Array();
    const rawEntries = d.quickEntries as Array<object>;
    for (let i: number = 0; i < rawEntries.length; i++) {
      entries.push(HomeRepository.mapToolEntry(rawEntries[i]));
    }

    const articles: Array<Article> = new Array();
    const firstFeed = d.firstFeed as Record<string, object>;
    if (firstFeed !== null && firstFeed !== undefined) {
      const rawList = firstFeed.list as Array<object>;
      for (let i: number = 0; i < rawList.length; i++) {
        articles.push(HomeRepository.mapArticle(rawList[i]));
      }
    }

    return new HomeFeedData(channels, entries, articles);
  }

  private static mapChannel(obj: object): Channel {
    const o = obj as Record<string, object>;
    return new Channel(
      typeof o.channelId === "string" ? o.channelId : "",
      typeof o.name === "string" ? o.name : "",
      typeof o.order === "number" ? o.order as number : 0,
      typeof o.fixed === "boolean" ? o.fixed as boolean : true
    );
  }

  private static mapToolEntry(obj: object): ToolEntry {
    const o = obj as Record<string, object>;
    return new ToolEntry(
      typeof o.toolId === "string" ? o.toolId : "",
      typeof o.name === "string" ? o.name : "",
      typeof o.iconKey === "string" ? o.iconKey : "",
      typeof o.targetType === "string" ? o.targetType as "SHELL" | "WEB" : "SHELL",
      typeof o.targetUrl === "string" ? o.targetUrl : null,
      typeof o.order === "number" ? o.order as number : 0
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

  /** 按模式映射延时。集中一处,方便调参。 */
  private static pickDelay(mode: SimulationMode): number {
    if (mode === "slow") {
      return DELAY_SLOW_MS;
    }
    if (mode === "error") {
      return DELAY_ERROR_MS;
    }
    return DELAY_NORMAL_MS;
  }

  /**
   * Promise 化的 setTimeout。等价 Kotlin delay(ms)。
   * 用箭头函数 + 显式 void 返回,避开 arkts-no-implicit-return-types。
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => { resolve(); }, ms);
    });
  }
}
