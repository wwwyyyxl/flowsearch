/**
 * @file ReadingHistoryEntry.ets
 * @description 阅读历史条目数据模型。url + title + readAt 三元组。
 *
 * 与 SearchHistoryItem 平级,放在 commons/base/types 层。
 * ReadingHistoryRepository 用它做 JSON 序列化。
 */

export class ReadingHistoryEntry {
  readonly url: string = "";
  readonly title: string = "";
  readonly readAt: number = 0;

  constructor(url: string, title: string, readAt: number = 0) {
    this.url = url;
    this.title = title;
    this.readAt = readAt;
  }
}
