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

@ObservedV2
export class FavsViewModel {
  /** 当前 Tab:"favorites" | "history"。 */
  @Trace currentTab: string = "favorites";

  /** 收藏文章列表(内存态,从磁盘加载后缓存)。 */
  @Trace favArticles: Array<Article> = new Array();

  /** 搜索历史列表(内存态)。 */
  @Trace historyItems: Array<SearchHistoryItem> = new Array();

  /** 收藏 Tab 的加载状态。 */
  @Trace favState: PageState = PageState.idle();

  /** 历史 Tab 的加载状态。 */
  @Trace historyState: PageState = PageState.idle();

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
      this.historyState = items.length === 0
        ? PageState.empty()
        : PageState.content(items);
    }).catch((_err: object): void => {
      this.historyItems = new Array();
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
    this.historyState = PageState.empty();
    this.historyRepo.clearAll();
  }
}
