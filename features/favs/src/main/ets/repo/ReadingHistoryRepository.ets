/**
 * @file ReadingHistoryRepository.ets
 * @description 阅读历史持久化。PreferencesHelper 做 JSON 读写。
 *
 * 与 HistoryRepository(搜索历史)同层同模式,独立 store 名。
 * add() 做去重 URL + 插入队首 + 截断 100 条。
 */

import { PreferencesHelper, ReadingHistoryEntry } from "@flowsearch/base";

const STORE_NAME: string = "fsearch_reading_history";
const KEY_HISTORY: string = "reading_history_json";
const MAX_ENTRIES: number = 100;

/** 阅读历史 JSON 序列化条目。 */
interface ReadingEntry {
  url: string;
  title: string;
  readAt: number;
}

export class ReadingHistoryRepository {
  private context: Context | null = null;

  init(context: Context): void {
    this.context = context;
  }

  /** 加载全部阅读历史(按时间降序,最新在前)。 */
  async loadAll(): Promise<Array<ReadingHistoryEntry>> {
    if (this.context === null) {
      return new Array();
    }
    const json: string | null = await PreferencesHelper.getJson(this.context, STORE_NAME, KEY_HISTORY);
    if (json === null) {
      return new Array();
    }
    const parsed: object = JSON.parse(json) as object;
    const arr: Array<object> = parsed as Array<object>;
    const items: Array<ReadingHistoryEntry> = new Array();
    for (let i = 0; i < arr.length; i++) {
      const entry = arr[i] as ReadingEntry;
      items.push(new ReadingHistoryEntry(
        typeof entry.url === "string" ? entry.url : "",
        typeof entry.title === "string" ? entry.title : "",
        typeof entry.readAt === "number" ? entry.readAt : 0
      ));
    }
    return items;
  }

  /** 添加一条阅读记录(去重 URL + 插入队首 + 截断 100 条)。 */
  async add(url: string, title: string): Promise<void> {
    if (this.context === null || url.length === 0) {
      return;
    }
    const existing: Array<ReadingEntry> = await this.loadEntries();
    // 去重:移除已有的同 URL
    const filtered: Array<ReadingEntry> = new Array();
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].url !== url) {
        filtered.push(existing[i]);
      }
    }
    // 插入队首
    const next: Array<ReadingEntry> = new Array();
    next.push({
      url: url,
      title: title,
      readAt: new Date().getTime()
    });
    for (let i = 0; i < filtered.length; i++) {
      next.push(filtered[i]);
    }
    // 截断
    const truncated: Array<ReadingEntry> = next.slice(0, MAX_ENTRIES);
    await PreferencesHelper.putJson(this.context, STORE_NAME, KEY_HISTORY, JSON.stringify(truncated));
  }

  /** 清空全部阅读历史。 */
  async clearAll(): Promise<void> {
    if (this.context === null) {
      return;
    }
    await PreferencesHelper.putJson(this.context, STORE_NAME, KEY_HISTORY, "[]");
  }

  /** 内部:读取原始 ReadingEntry 列表。 */
  private async loadEntries(): Promise<Array<ReadingEntry>> {
    if (this.context === null) {
      return new Array();
    }
    const json: string | null = await PreferencesHelper.getJson(this.context, STORE_NAME, KEY_HISTORY);
    if (json === null) {
      return new Array();
    }
    const parsed: object = JSON.parse(json) as object;
    const arr: Array<object> = parsed as Array<object>;
    const entries: Array<ReadingEntry> = new Array();
    for (let i = 0; i < arr.length; i++) {
      const entry = arr[i] as ReadingEntry;
      entries.push({
        url: typeof entry.url === "string" ? entry.url : "",
        title: typeof entry.title === "string" ? entry.title : "",
        readAt: typeof entry.readAt === "number" ? entry.readAt : 0
      });
    }
    return entries;
  }
}
