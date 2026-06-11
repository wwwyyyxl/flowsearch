/**
 * @file SearchInputViewModel.ets
 * @description SearchInputPage 的 ViewModel。管理三件事:
 *   1. 输入框关键词(@Trace keyword)
 *   2. 空输入态数据(history + hotItems,启动时同步加载)
 *   3. 有输入态数据(suggestions,debounce 300ms 后异步加载)
 *
 * 设计要点:
 *
 * 1. 不用 PageState 包裹整体状态:
 *    与 HomePage 不同 -- SearchInput 的"内容"分两组(空态/输入态),
 *    它们都是 Content,只是渲染哪组取决于 keyword 是否非空。
 *    所以 VM 暴露明确的 @Trace 字段,UI 层用 if/else 分支渲染,
 *    简单直观,不用 cast PageState.data。
 *
 * 2. debounce 用 setTimeout token 模式:
 *    每次 input 变化重置 token,等 300ms 后真正发请求。
 *    类比 Compose: snapshotFlow + debounce(300.ms)。
 *
 * 3. 建议接口失败"静默":
 *    PRD §04-02 §6 -- Error(建议接口) 时不展示建议区,历史/热搜照常。
 *    所以 catch 后 suggestions 设空,不抛 PageState.error。
 *
 * 4. simulationMode 也给搜索调试浮层使用,与 Home 同步联调。
 *
 * Kotlin 对照:
 *   @ObservedV2 class SearchInputVM { @Trace keyword: String }
 *     ≈ class SearchInputViewModel : ViewModel() {
 *         val keyword: MutableStateFlow<String>
 *       }
 */

import { SearchInputData, SearchSuggestion, SearchHistoryItem, HotSearchItem } from "@flowsearch/base";
import { SearchRepository } from "../repo/SearchRepository";
import { SimulationMode } from "../repo/SimulationMode";
import { HistoryRepository } from "@flowsearch/favs";

/** 建议词请求节流(PRD §04-02 §3 "输入变化 debounce 300ms")。 */
const SUGGEST_DEBOUNCE_MS: number = 300;

@ObservedV2
export class SearchInputViewModel {
  /** 输入框关键词。空字符串 -> 显示历史 + 热搜,非空 -> 显示建议列表。 */
  @Trace keyword: string = "";

  /** 历史记录(S4 改为从 Preferences 加载)。 */
  @Trace history: Array<SearchHistoryItem> = new Array();

  /** 热搜榜(本期 Mock 静态,启动时一次加载)。 */
  @Trace hotItems: Array<HotSearchItem> = new Array();

  /** 当前输入对应的建议词列表(keyword=="" 时为空)。 */
  @Trace suggestions: Array<SearchSuggestion> = new Array();

  /** 建议接口加载中标志(本期只用于面试讲点,UI 还没接进度条)。 */
  @Trace loadingSuggestions: boolean = false;

  /** 调试用模拟模式。 */
  @Trace simulationMode: SimulationMode = "normal";

  private readonly repository: SearchRepository = new SearchRepository();

  /** S4:搜索历史持久化。 */
  private readonly historyRepo: HistoryRepository = new HistoryRepository();

  /** debounce token。每次输入变化自增,fetch 回来时 token 不匹配则丢弃。 */
  private suggestSeq: number = 0;

  /** 初始化:从 Preferences 异步加载历史 + Mock 热搜。S4 改为传入 context。 */
  init(context: Context): void {
    this.historyRepo.init(context);
    // Mock 热搜仍然同步加载
    const data: SearchInputData = this.repository.getSearchInput();
    this.hotItems = data.hotItems;
    // 历史从 Preferences 异步加载
    this.historyRepo.loadAll().then((items: Array<SearchHistoryItem>): void => {
      this.history = items;
    }).catch((_err: object): void => {
      // 加载失败用 Mock 历史兜底
      this.history = data.history;
    });
  }

  /** UI 层调:输入变化。空字符串 -> 清建议;否则 300ms 后请求。 */
  updateKeyword(next: string): void {
    this.keyword = next;
    if (next.trim().length === 0) {
      this.suggestions = new Array();
      this.loadingSuggestions = false;
      return;
    }
    this.scheduleSuggestFetch(next);
  }

  /** 清空输入框(输入框右侧 ⊗ 点击)。 */
  clearKeyword(): void {
    this.updateKeyword("");
  }

  /**
   * 把建议词回填到输入框(点击建议右侧 ↖ 箭头,PRD §04-02 §3)。
   * 不触发搜索 -- 由用户决定是否回车。
   */
  fillKeywordFromSuggestion(suggestionKeyword: string): void {
    this.updateKeyword(suggestionKeyword);
  }

  /** 清空所有历史(点击垃圾桶图标 -> 弹窗确认 -> 调本方法)。S4:同时清磁盘。 */
  clearAllHistory(): void {
    this.history = new Array();
    this.historyRepo.clearAll();
  }

  /** 切换调试模拟模式(预留,本页暂无 UI 触发点)。 */
  changeSimulationMode(mode: SimulationMode): void {
    this.simulationMode = mode;
  }

  /**
   * 写历史 + 返回当前关键词(用于 SearchResult 跳转前的最后一步)。
   * S4:同时异步写入 Preferences 持久化。
   */
  commitHistory(keyword: string): string {
    const trimmed: string = keyword.trim();
    if (trimmed.length === 0) {
      return "";
    }
    // 1) 去重:已存在则移除
    const filtered: Array<SearchHistoryItem> = this.history.filter(
      (h: SearchHistoryItem): boolean => h.keyword !== trimmed
    );
    // 2) 插入队首
    const next: Array<SearchHistoryItem> = new Array();
    next.push(new SearchHistoryItem(trimmed, "刚刚"));
    filtered.forEach((h: SearchHistoryItem): void => { next.push(h); });
    // 3) 截断到 20 条
    this.history = next.slice(0, 20);
    // S4:异步写磁盘
    this.historyRepo.add(trimmed);
    return trimmed;
  }

  // ============================================================
  // 内部:debounce + 异步建议请求
  // ============================================================

  private scheduleSuggestFetch(keyword: string): void {
    this.suggestSeq += 1;
    const mySeq: number = this.suggestSeq;
    this.loadingSuggestions = true;

    setTimeout((): void => {
      // 用户已经又输入了新内容 -> 丢弃本次请求
      if (mySeq !== this.suggestSeq) {
        return;
      }
      this.repository.fetchSuggestions(keyword, this.simulationMode)
        .then((list: Array<SearchSuggestion>): void => {
          if (mySeq !== this.suggestSeq) {
            return;
          }
          this.suggestions = list;
          this.loadingSuggestions = false;
        })
        .catch((_err: object): void => {
          if (mySeq !== this.suggestSeq) {
            return;
          }
          // PRD §04-02 §6:Error 静默,suggestions 给空数组,
          // UI 渲染"没有相关建议"或直接不展示(本期取后者)。
          this.suggestions = new Array();
          this.loadingSuggestions = false;
        });
    }, SUGGEST_DEBOUNCE_MS);
  }
}
