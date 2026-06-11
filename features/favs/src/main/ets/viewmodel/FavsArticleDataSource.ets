/**
 * @file FavsArticleDataSource.ets
 * @description 收藏 Tab 的 LazyForEach 数据源适配器。
 *
 * 与 features/home 的 ArticleDataSource 完全同型(避免跨 HAR import 循环)。
 * 单一职责:数组 -> IDataSource 适配 + 数据变化时通知 UI。
 */

import { Article } from "@flowsearch/base";

export class FavsArticleDataSource implements IDataSource {
  private articles: Array<Article> = new Array();
  private listeners: Array<DataChangeListener> = new Array();

  /** 替换全部数据并通知 UI 重渲。 */
  setArticles(next: Array<Article>): void {
    this.articles = next;
    this.listeners.forEach((l: DataChangeListener): void => { l.onDataReloaded(); });
  }

  totalCount(): number {
    return this.articles.length;
  }

  getData(index: number): Article {
    return this.articles[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const i = this.listeners.indexOf(listener);
    if (i >= 0) {
      this.listeners.splice(i, 1);
    }
  }
}
