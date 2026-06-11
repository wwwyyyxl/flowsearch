/**
 * @file ArticleDataSource.ets
 * @description LazyForEach 的数据源适配器。
 *
 * 为什么需要这一层?
 *   ArkUI 的 LazyForEach 要求数据源实现 IDataSource 接口(totalCount + getData),
 *   不像 ForEach 直接吃数组。我们用它包装 Article[] 给 LazyForEach 用,
 *   同时数据变化时调 notifyDataReload 触发 UI 增量更新。
 *
 * 设计要点:
 * 1. 单一职责:仅做数组 -> IDataSource 适配,业务逻辑全在 VM;
 * 2. 不持有装饰器(本类不是组件),被 HomePage 实例化并 register listener。
 * 3. 类比 Android: RecyclerView.Adapter,但更轻(只管 count + getItem)。
 */

import { Article } from "@flowsearch/base";

export class ArticleDataSource implements IDataSource {
  private articles: Array<Article> = new Array();
  private listeners: Array<DataChangeListener> = new Array();

  setArticles(next: Array<Article>): void {
    this.articles = next;
    // 全量刷新最简单。增量更新留作扩展练习(insert/delete/move 都有对应 notify 方法)。
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
