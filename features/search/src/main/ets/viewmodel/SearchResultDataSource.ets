/**
 * @file SearchResultDataSource.ets
 * @description SearchResult 的 LazyForEach 数据源适配器。
 *
 * 与 home/ArticleDataSource 同型,但属于 search HAR 内部。
 * 没有把 ArticleDataSource 提到 commons/ui:它是数据源适配器而非 UI 组件,
 * 类型边界放 commons 反而模糊;每个 feature 自己持有适配器更干净。
 */

import { Article } from "@flowsearch/base";

export class SearchResultDataSource implements IDataSource {
  private articles: Array<Article> = new Array();
  private listeners: Array<DataChangeListener> = new Array();

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
