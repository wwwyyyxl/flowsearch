/**
 * @file FavsViewModel.ets
 * @description 收藏与历史页 ViewModel。管理双 Tab 状态 + 数据加载。
 *
 * 设计要点:
 *
 * 1. @ObservedV2 + @Trace:与 HomeViewModel / SearchInputViewModel 同源。
 *    currentTab / favArticles / historyItems 变化自动触发 UI 重渲。
 *
 * 2. 双 Repository 持有:FavoritesRepository + HistoryRepository。
 *    init(context, defaultTab) 时初始化两个 repo 的 context。
 *
 * 3. 两个独立的 PageState(favState / historyState):
 *    切 Tab 时各自独立 Loading/Content/Empty/Error,不互相影响。
 *
 * 4. removeFavorite / removeHistoryItem 是异步操作:
 *    先更新内存(即时 UI 反馈),再异步写盘。
 *    与 HomeViewModel.toggleFavorite() 的"内存先行,磁盘异步"同策略。
 */

import { PageState, Article, SearchHistoryItem } from "@flowsearch/base";
import { FavoritesRepository } from "../repo/FavoritesRepository";
import { HistoryRepository } from "../repo/HistoryRepository";
import { FavsArticleDataSource } from "./FavsArticleDataSource";

/** 历史时间分组。@ObservedV2 保证 items 变化时 UI 自动重渲。 */
@ObservedV2
export class HistoryGroup {
  @Trace label: string = "";
  @Trace items: Array<SearchHistoryItem> = new Array();

  constructor(label: string, items: Array<SearchHistoryItem>) {
    this.label = label;
    this.items = items;
  }
}

@ObservedV2
export class FavsViewModel {
  /** 当前 Tab:"favorites" | "history"。 */
  @Trace currentTab: string = "favorites";

  /** 收藏文章列表(内存态,从磁盘加载后缓存)。 */
  @Trace favArticles: Array<Article> = new Array();

  /** 搜索历史列表(内存态)。 */
  @Trace historyItems: Array<SearchHistoryItem> = new Array();

  /** 历史分组(按时间:今天/昨天/本周更早/更早)。 */
  @Trace historyGroups: Array<HistoryGroup> = new Array();

  /** 收藏 Tab 的加载状态。 */
  @Trace favState: PageState = PageState.idle();

  /** 历史 Tab 的加载状态。 */
  @Trace historyState: PageState = PageState.idle();

  // ========== 收藏管理模式(PRD §04-05) ==========
  /** 是否处于管理模式。 */
  @Trace isManaging: boolean = false;

  /** 管理模式下已选中的文章 id 列表。 */
  @Trace selectedIds: Array<string> = new Array();

  /** LazyForEach 数据源(收藏 Tab 用)。 */
  readonly favDataSource: FavsArticleDataSource = new FavsArticleDataSource();

  private favRepo: FavoritesRepository = new FavoritesRepository();
  private historyRepo: HistoryRepository = new HistoryRepository();

  /**
   * 初始化。从 Page.aboutToAppear() 调。
   * @param context    应用上下文(getContext(this))
   * @param defaultTab 进入时默认 Tab("favorites" | "history")
   */
  init(context: Context, defaultTab: string): void {
    this.favRepo.init(context);
    this.historyRepo.init(context);
    this.currentTab = defaultTab;
    if (defaultTab === "favorites") {
      this.loadFavorites();
    } else {
      this.loadHistory();
    }
  }

  /** 切换 Tab(已有数据则直接展示,否则加载)。 */
  switchTab(tab: string): void {
    if (this.currentTab === tab) {
      return;
    }
    this.currentTab = tab;
    if (tab === "favorites" && this.favState.isIdle()) {
      this.loadFavorites();
    } else if (tab === "history" && this.historyState.isIdle()) {
      this.loadHistory();
    }
  }

  /** 加载收藏列表。 */
  loadFavorites(): void {
    this.favState = PageState.loading();
    this.favRepo.loadAll().then((articles: Array<Article>): void => {
      this.favArticles = articles;
      this.favDataSource.setArticles(articles);
      this.favState = articles.length === 0
        ? PageState.empty()
        : PageState.content(articles);
    }).catch((_err: object): void => {
      this.favArticles = new Array();
      this.favDataSource.setArticles(new Array());
      this.favState = PageState.error("LOAD_ERR", "加载收藏失败");
    });
  }

  /** 加载搜索历史。 */
  loadHistory(): void {
    this.historyState = PageState.loading();
    this.historyRepo.loadAll().then((items: Array<SearchHistoryItem>): void => {
      this.historyItems = items;
      this.historyGroups = this.groupHistory(items);
      this.historyState = items.length === 0
        ? PageState.empty()
        : PageState.content(items);
    }).catch((_err: object): void => {
      this.historyItems = new Array();
      this.historyGroups = new Array();
      this.historyState = PageState.error("LOAD_ERR", "加载历史失败");
    });
  }

  /** 取消收藏(内存即时移除 + 异步写盘)。 */
  removeFavorite(articleId: string): void {
    // 内存即时移除
    const next: Array<Article> = new Array();
    for (let i = 0; i < this.favArticles.length; i++) {
      if (this.favArticles[i].articleId !== articleId) {
        next.push(this.favArticles[i]);
      }
    }
    this.favArticles = next;
    this.favDataSource.setArticles(next);
    if (next.length === 0) {
      this.favState = PageState.empty();
    }
    // 异步写盘
    this.favRepo.remove(articleId);
  }

  /** 删除一条历史记录(内存即时移除 + 异步写盘)。 */
  removeHistoryItem(keyword: string): void {
    const next: Array<SearchHistoryItem> = new Array();
    for (let i = 0; i < this.historyItems.length; i++) {
      if (this.historyItems[i].keyword !== keyword) {
        next.push(this.historyItems[i]);
      }
    }
    this.historyItems = next;
    this.historyGroups = this.groupHistory(next);
    if (next.length === 0) {
      this.historyState = PageState.empty();
    }
    // 异步:重写全部(简化实现,不需要按条删)
    this.historyRepo.clearAll().then((): void => {
      // 逐条回写
      for (let i = 0; i < next.length; i++) {
        this.historyRepo.add(next[i].keyword);
      }
    });
  }

  /** 清空全部历史。 */
  clearAllHistory(): void {
    this.historyItems = new Array();
    this.historyGroups = new Array();
    this.historyState = PageState.empty();
    this.historyRepo.clearAll();
  }

  // ========== 收藏管理模式 ==========

  /** 进入管理模式。 */
  enterManageMode(): void {
    this.isManaging = true;
    this.selectedIds = new Array();
  }

  /** 退出管理模式。 */
  exitManageMode(): void {
    this.isManaging = false;
    this.selectedIds = new Array();
  }

  /** 切换某文章的选中态。 */
  toggleSelect(articleId: string): void {
    const idx: number = this.selectedIds.indexOf(articleId);
    const next: Array<string> = new Array();
    for (let i = 0; i < this.selectedIds.length; i++) {
      if (i !== idx) {
        next.push(this.selectedIds[i]);
      }
    }
    if (idx < 0) {
      next.push(articleId);
    }
    this.selectedIds = next;
  }

  /** 判断某文章是否已选中。 */
  isItemSelected(articleId: string): boolean {
    return this.selectedIds.indexOf(articleId) >= 0;
  }

  /** 全选。 */
  selectAll(): void {
    const all: Array<string> = new Array();
    for (let i = 0; i < this.favArticles.length; i++) {
      all.push(this.favArticles[i].articleId);
    }
    this.selectedIds = all;
  }

  /** 批量取消收藏。 */
  batchRemove(): void {
    for (let i = 0; i < this.selectedIds.length; i++) {
      this.removeFavorite(this.selectedIds[i]);
    }
    this.exitManageMode();
  }

  // ========== 历史时间分组 ==========

  /**
   * 将历史项按时间分组:今天 / 昨天 / 本周更早 / 更早。
   * createdAt 为 0 的项归入"更早"(向后兼容无时间戳数据)。
   */
  private groupHistory(items: Array<SearchHistoryItem>): Array<HistoryGroup> {
    const now: number = new Date().getTime();
    // 今天 00:00
    const todayStart: number = FavsViewModel.startOfDay(now);
    // 昨天 00:00
    const yesterdayStart: number = todayStart - 24 * 3600 * 1000;
    // 本周一 00:00
    const weekStart: number = FavsViewModel.startOfWeek(now);

    const todayItems: Array<SearchHistoryItem> = new Array();
    const yesterdayItems: Array<SearchHistoryItem> = new Array();
    const weekItems: Array<SearchHistoryItem> = new Array();
    const olderItems: Array<SearchHistoryItem> = new Array();

    for (let i = 0; i < items.length; i++) {
      const ts: number = items[i].createdAt;
      if (ts >= todayStart) {
        todayItems.push(items[i]);
      } else if (ts >= yesterdayStart) {
        yesterdayItems.push(items[i]);
      } else if (ts >= weekStart) {
        weekItems.push(items[i]);
      } else {
        olderItems.push(items[i]);
      }
    }

    const groups: Array<HistoryGroup> = new Array();
    if (todayItems.length > 0) {
      groups.push(new HistoryGroup("今天", todayItems));
    }
    if (yesterdayItems.length > 0) {
      groups.push(new HistoryGroup("昨天", yesterdayItems));
    }
    if (weekItems.length > 0) {
      groups.push(new HistoryGroup("本周更早", weekItems));
    }
    if (olderItems.length > 0) {
      groups.push(new HistoryGroup("更早", olderItems));
    }
    return groups;
  }

  /** 取某时间戳当天 00:00 的毫秒数。 */
  private static startOfDay(ts: number): number {
    const d: Date = new Date(ts);
    d.setHours(0, 0, 0, 0);
    return d.getTime();
  }

  /** 取某时间戳所在周一 00:00 的毫秒数。 */
  private static startOfWeek(ts: number): number {
    const d: Date = new Date(ts);
    d.setHours(0, 0, 0, 0);
    const day: number = d.getDay(); // 0=Sun,1=Mon,...
    const diff: number = day === 0 ? 6 : day - 1; // 距周一的天数
    return d.getTime() - diff * 24 * 3600 * 1000;
  }
}
