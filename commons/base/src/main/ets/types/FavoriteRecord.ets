/**
 * @file FavoriteRecord.ets
 * @description 收藏记录(序列化模型)。用于 Preferences JSON 存储。
 *
 * 设计要点:
 *
 * 1. 零装饰器(plain class):
 *    与 Article / SearchHistoryItem 同层,放 commons/base。
 *    Kotlin 阶段平移成 data class: @Serializable data class FavoriteRecord(...)
 *
 * 2. 为什么不用 Article 直接序列化?
 *    Article 有 channelId 字段(来自 HomeMock),但收藏场景下
 *    channelId 可能不准(文章可能来自搜索结果,channelId 为空)。
 *    FavoriteRecord 用 savedAt(收藏时间戳)做排序依据,语义更清晰。
 *    另外 Article 构造器需要 ArticleInit 接口,JSON.parse 无法直接构造。
 *
 * 3. savedAt 用 new Date().getTime():
 *    ArkTS 禁止 Date.now(),但 new Date().getTime() 合法。
 *    用于按收藏时间降序排列(最新收藏在前)。
 *
 * 4. fromArticle / toArticle 双向转换:
 *    fromArticle:收藏时 Article -> FavoriteRecord 存入 Preferences
 *    toArticle:   读取时 FavoriteRecord -> Article 渲染到 UI(favorite=true)
 */

import { Article, ArticleInit } from "./HomeModels";

export class FavoriteRecord {
  readonly articleId: string = "";
  readonly title: string = "";
  readonly summary: string = "";
  readonly coverUrl: string | null = null;
  readonly coverPlaceholder: string = "";
  readonly categoryTag: string = "WEB";
  readonly source: string = "";
  readonly publishTime: string = "";
  readonly publishTimeDisplay: string = "";
  readonly targetUrl: string = "";
  readonly channelId: string = "";
  readonly savedAt: number = 0;

  constructor(
    articleId: string,
    title: string,
    summary: string,
    coverUrl: string | null,
    coverPlaceholder: string,
    categoryTag: string,
    source: string,
    publishTime: string,
    publishTimeDisplay: string,
    targetUrl: string,
    channelId: string,
    savedAt: number
  ) {
    this.articleId = articleId;
    this.title = title;
    this.summary = summary;
    this.coverUrl = coverUrl;
    this.coverPlaceholder = coverPlaceholder;
    this.categoryTag = categoryTag;
    this.source = source;
    this.publishTime = publishTime;
    this.publishTimeDisplay = publishTimeDisplay;
    this.targetUrl = targetUrl;
    this.channelId = channelId;
    this.savedAt = savedAt;
  }

  /** 从 Article 构造收藏记录。收藏时刻取当前时间戳。 */
  static fromArticle(article: Article): FavoriteRecord {
    return new FavoriteRecord(
      article.articleId,
      article.title,
      article.summary,
      article.coverUrl,
      article.coverPlaceholder,
      article.categoryTag,
      article.source,
      article.publishTime,
      article.publishTimeDisplay,
      article.targetUrl,
      article.channelId,
      new Date().getTime()
    );
  }

  /** 转回 Article(favorite 固定为 true)。 */
  toArticle(): Article {
    const init: ArticleInit = {
      articleId: this.articleId,
      title: this.title,
      summary: this.summary,
      coverUrl: this.coverUrl,
      coverPlaceholder: this.coverPlaceholder,
      categoryTag: this.categoryTag as "WEB" | "TOOL" | "VIDEO" | "AI",
      source: this.source,
      publishTime: this.publishTime,
      publishTimeDisplay: this.publishTimeDisplay,
      targetUrl: this.targetUrl,
      favorite: true,
      channelId: this.channelId
    };
    return new Article(init);
  }

  /** 从 JSON 对象还原(Preferences 读出来后 parse 再构造)。 */
  static fromJson(obj: object): FavoriteRecord {
    const o = obj as Record<string, object>;
    return new FavoriteRecord(
      typeof o.articleId === "string" ? o.articleId : "",
      typeof o.title === "string" ? o.title : "",
      typeof o.summary === "string" ? o.summary : "",
      typeof o.coverUrl === "string" ? o.coverUrl : null,
      typeof o.coverPlaceholder === "string" ? o.coverPlaceholder : "",
      typeof o.categoryTag === "string" ? o.categoryTag : "WEB",
      typeof o.source === "string" ? o.source : "",
      typeof o.publishTime === "string" ? o.publishTime : "",
      typeof o.publishTimeDisplay === "string" ? o.publishTimeDisplay : "",
      typeof o.targetUrl === "string" ? o.targetUrl : "",
      typeof o.channelId === "string" ? o.channelId : "",
      typeof o.savedAt === "number" ? o.savedAt as number : 0
    );
  }
}
