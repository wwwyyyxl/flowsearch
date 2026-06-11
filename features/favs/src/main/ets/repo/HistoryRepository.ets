/**
 * @file HistoryRepository.ets
 * @description 搜索历史持久化。PreferencesHelper 做 JSON 读写。
 *
 * 设计要点:
 *
 * 1. 零装饰器(plain class):与 SearchRepository 同层。
 *    原 SearchRepository 的"历史"部分拆到这里(见 SearchRepository.ets 注释 S4 规划)。
 *
 * 2. add() 做去重+截断:
 *    已存在关键词 -> 移到队首;不存在 -> 直接插入队首。
 *    总量截断到 20 条(PRD §04-02 §5)。
 *
 * 3. SearchHistoryItem 已有 keyword + searchAt 字段。
 *    searchAt 本期用预渲染字符串("刚刚","3 分钟前"等),不在端上计算。
 *    Kotlin 阶段切回 Long 时间戳 + 端上格式化。
 */

import { PreferencesHelper, SearchHistoryItem } from "@flowsearch/base";

const STORE_NAME: string = "fsearch_history";
const KEY_HISTORY: string = "history_json";

/** 搜索历史 JSON 序列化条目(多一个 createdAt 时间戳用于排序)。 */
interface HistoryEntry {
  keyword: string;
  searchAt: string;
  createdAt: number;
}

export class HistoryRepository {
  private context: Context | null = null;

  /** 初始化:传入应用上下文。 */
  init(context: Context): void {
    this.context = context;
  }

  /** 加载全部历史(按时间降序,最新在前)。 */
  async loadAll(): Promise<Array<SearchHistoryItem>> {
    if (this.context === null) {
      return new Array();
    }
    const json: string | null = await PreferencesHelper.getJson(this.context, STORE_NAME, KEY_HISTORY);
    if (json === null) {
      return new Array();
    }
    const parsed: object = JSON.parse(json) as object;
    const arr: Array<object> = parsed as Array<object>;
    const items: Array<SearchHistoryItem> = new Array();
    for (let i = 0; i < arr.length; i++) {
      const entry = arr[i] as HistoryEntry;
      items.push(new SearchHistoryItem(
        typeof entry.keyword === "string" ? entry.keyword : "",
        typeof entry.searchAt === "string" ? entry.searchAt : "刚刚"
      ));
    }
    return items;
  }

  /** 添加一条历史(去重+插入队首+截断 20 条)。 */
  async add(keyword: string): Promise<void> {
    if (this.context === null) {
      return;
    }
    const trimmed: string = keyword.trim();
    if (trimmed.length === 0) {
      return;
    }
    const existing: Array<HistoryEntry> = await this.loadEntries();
    // 去重:移除已有的同关键词
    const filtered: Array<HistoryEntry> = new Array();
    for (let i = 0; i < existing.length; i++) {
      if (existing[i].keyword !== trimmed) {
        filtered.push(existing[i]);
      }
    }
    // 插入队首
    const next: Array<HistoryEntry> = new Array();
    next.push({
      keyword: trimmed,
      searchAt: "刚刚",
      createdAt: new Date().getTime()
    });
    for (let i = 0; i < filtered.length; i++) {
      next.push(filtered[i]);
    }
    // 截断 20 条
    const truncated: Array<HistoryEntry> = next.slice(0, 20);
    await PreferencesHelper.putJson(this.context, STORE_NAME, KEY_HISTORY, JSON.stringify(truncated));
  }

  /** 清空全部历史。 */
  async clearAll(): Promise<void> {
    if (this.context === null) {
      return;
    }
    await PreferencesHelper.putJson(this.context, STORE_NAME, KEY_HISTORY, "[]");
  }

  /** 内部:读取原始 HistoryEntry 列表。 */
  private async loadEntries(): Promise<Array<HistoryEntry>> {
    if (this.context === null) {
      return new Array();
    }
    const json: string | null = await PreferencesHelper.getJson(this.context, STORE_NAME, KEY_HISTORY);
    if (json === null) {
      return new Array();
    }
    const parsed: object = JSON.parse(json) as object;
    const arr: Array<object> = parsed as Array<object>;
    const entries: Array<HistoryEntry> = new Array();
    for (let i = 0; i < arr.length; i++) {
      const entry = arr[i] as HistoryEntry;
      entries.push({
        keyword: typeof entry.keyword === "string" ? entry.keyword : "",
        searchAt: typeof entry.searchAt === "string" ? entry.searchAt : "刚刚",
        createdAt: typeof entry.createdAt === "number" ? entry.createdAt as number : 0
      });
    }
    return entries;
  }
}
