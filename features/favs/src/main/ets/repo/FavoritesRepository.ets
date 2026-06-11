/**
 * @file FavoritesRepository.ets
 * @description 收藏数据持久化。PreferencesHelper 做 JSON 读写,FavoriteRecord 做序列化。
 *
 * 设计要点:
 *
 * 1. 零装饰器(plain class):与 HomeRepository / SearchRepository 同层。
 *    Kotlin 阶段直接平移成 class FavoritesRepository(PreferencesHelper).
 *
 * 2. 读-改-写单向链:
 *    save()/remove() 都是:loadAll(内存) -> 修改 -> stringify -> putJson(落盘)。
 *    不需要锁:ArkTS 单线程 + await 让出执行期间不会并发修改 Preferences。
 *
 * 3. Context 由 VM.init() 透传:Page.aboutToAppear() -> vm.init(getContext(this)) -> repo.init(context)。
 *    Repository 不持有 Context 引用以外的状态。
 *
 * 4. Article <-> FavoriteRecord 双向转换:
 *    收藏时:Article -> FavoriteRecord.fromArticle -> JSON
 *    读取时:JSON -> FavoriteRecord.fromJson -> toArticle()
 */

import { PreferencesHelper, FavoriteRecord, Article } from "@flowsearch/base";

const STORE_NAME: string = "fsearch_favorites";
const KEY_FAVORITES: string = "favorites_json";

export class FavoritesRepository {
  private context: Context | null = null;

  /** 初始化:传入应用上下文(Page.getContext(this))。 */
  init(context: Context): void {
    this.context = context;
  }

  /** 加载全部收藏文章(按收藏时间降序)。 */
  async loadAll(): Promise<Array<Article>> {
    if (this.context === null) {
      return new Array();
    }
    const json: string | null = await PreferencesHelper.getJson(this.context, STORE_NAME, KEY_FAVORITES);
    if (json === null) {
      return new Array();
    }
    const parsed: object = JSON.parse(json) as object;
    const arr: Array<object> = parsed as Array<object>;
    const records: Array<FavoriteRecord> = new Array();
    for (let i = 0; i < arr.length; i++) {
      records.push(FavoriteRecord.fromJson(arr[i]));
    }
    // 按 savedAt 降序(最新收藏在前)
    records.sort((a: FavoriteRecord, b: FavoriteRecord): number => {
      return b.savedAt - a.savedAt;
    });
    const articles: Array<Article> = new Array();
    for (let i = 0; i < records.length; i++) {
      articles.push(records[i].toArticle());
    }
    return articles;
  }

  /** 收藏一篇文章(追加到列表,去重后写回)。 */
  async save(article: Article): Promise<void> {
    if (this.context === null) {
      return;
    }
    const existing: Array<FavoriteRecord> = await this.loadRecords();
    // 去重:已存在则不重复添加
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].articleId === article.articleId) {
        return;
      }
    }
    existing.push(FavoriteRecord.fromArticle(article));
    await PreferencesHelper.putJson(this.context, STORE_NAME, KEY_FAVORITES, JSON.stringify(existing));
  }

  /** 取消收藏(移除指定文章)。 */
  async remove(articleId: string): Promise<void> {
    if (this.context === null) {
      return;
    }
    const existing: Array<FavoriteRecord> = await this.loadRecords();
    const filtered: Array<FavoriteRecord> = new Array();
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].articleId !== articleId) {
        filtered.push(existing[i]);
      }
    }
    await PreferencesHelper.putJson(this.context, STORE_NAME, KEY_FAVORITES, JSON.stringify(filtered));
  }

  /** 内部:读取原始 Record 列表。 */
  private async loadRecords(): Promise<Array<FavoriteRecord>> {
    if (this.context === null) {
      return new Array();
    }
    const json: string | null = await PreferencesHelper.getJson(this.context, STORE_NAME, KEY_FAVORITES);
    if (json === null) {
      return new Array();
    }
    const parsed: object = JSON.parse(json) as object;
    const arr: Array<object> = parsed as Array<object>;
    const records: Array<FavoriteRecord> = new Array();
    for (let i = 0; i < arr.length; i++) {
      records.push(FavoriteRecord.fromJson(arr[i]));
    }
    return records;
  }
}
