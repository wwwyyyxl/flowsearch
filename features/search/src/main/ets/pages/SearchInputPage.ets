/**
 * @file SearchInputPage.ets
 * @description 搜索输入页(P02 SearchInput)。装配:
 *   - SearchTopBar(可编辑输入框 + "取消")
 *   - 空输入态:HistoryChips + HotSearchList
 *   - 有输入态:SuggestionList(关键词高亮 + 回填箭头)
 *
 * 设计要点:
 *
 * 1. NavPathStack 通过 @Param 传入:
 *    路由跳转 / 返回都通过它,VM 不持有路由对象 -- 避免 VM 反向耦合 UI 框架。
 *    类比 Compose: NavController 作为 CompositionLocal 注入。
 *
 * 2. 状态分支:
 *    keyword.trim().length === 0 -> 渲染 history + hotItems
 *    keyword.trim().length  >  0 -> 渲染 suggestions
 *    不用 StateHost -- 这两组都是 Content 态,只是渲染哪组取决于输入。
 *
 * 3. 跳 SearchResult 的三个触发点(PRD §04-02 §3):
 *    - 输入框回车
 *    - 点击建议项主区
 *    - 点击历史 / 热搜 chip
 *    都走同一个 commitAndNavigate(keyword) 函数:写历史 + 路由跳转。
 *
 * 4. NavDestination 包裹:
 *    本页通过 NavPathStack.pushPath 进入 -- 必须用 NavDestination 包裹,
 *    否则路由分发拿到的是普通 @ComponentV2 而非 NavDestination,
 *    返回栈管理会失效。这是 ArkUI Navigation 的硬约束。
 */

import { SearchInputViewModel } from "../viewmodel/SearchInputViewModel";
import { SearchTopBar } from "../components/SearchTopBar";
import { HistoryChips } from "../components/HistoryChips";
import { HotSearchList } from "../components/HotSearchList";
import { SuggestionList } from "../components/SuggestionList";
import { RouteTable, SearchResultArgs } from "@flowsearch/router";

@ComponentV2
export struct SearchInputPage {
  /** 路由栈,由 entry 通过 NavDestination param 传入。 */
  @Param navPathStack: NavPathStack = new NavPathStack();

  @Local vm: SearchInputViewModel = new SearchInputViewModel();

  aboutToAppear(): void {
    this.vm.init(getContext(this));
  }

  build() {
    NavDestination() {
      Column() {
        // 顶栏
        SearchTopBar({
          keyword: this.vm.keyword,
          autoFocus: true,
          readOnly: false,
          placeholder: "搜索网页、工具、历史记录",
          showCancel: true,
          showBack: false,
          onKeywordChange: (next: string): void => { this.vm.updateKeyword(next); },
          onSubmit: (kw: string): void => { this.commitAndNavigate(kw); },
          onClearTap: (): void => { this.vm.clearKeyword(); },
          onCancelTap: (): void => { this.navPathStack.pop(); }
        })

        // 主体:空输入态 vs 有输入态
        if (this.vm.keyword.trim().length === 0) {
          this.buildEmptyInputBody()
        } else {
          this.buildSuggestionBody()
        }
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.fs_color_surface"))
    }
    .hideTitleBar(true)
  }

  // ============================================================
  // 主体:空输入态(历史 + 热搜)
  // ============================================================
  @Builder
  buildEmptyInputBody() {
    Scroll() {
      Column() {
        // 历史只有非空时渲染,空历史整段隐藏(PRD §04-02 §6)
        if (this.vm.history.length > 0) {
          HistoryChips({
            history: this.vm.history,
            onChipTap: (kw: string): void => { this.commitAndNavigate(kw); },
            onClearAllTap: (): void => { this.vm.clearAllHistory(); }
          })
        }

        HotSearchList({
          items: this.vm.hotItems,
          onItemTap: (kw: string): void => { this.commitAndNavigate(kw); }
        })
      }
      .width("100%")
    }
    .layoutWeight(1)
    .width("100%")
    .scrollBar(BarState.Off)
  }

  // ============================================================
  // 主体:有输入态(建议列表)
  // ============================================================
  @Builder
  buildSuggestionBody() {
    Scroll() {
      Column() {
        SuggestionList({
          inputKeyword: this.vm.keyword,
          suggestions: this.vm.suggestions,
          onItemTap: (kw: string): void => { this.commitAndNavigate(kw); },
          onFillTap: (kw: string): void => { this.vm.fillKeywordFromSuggestion(kw); }
        })
      }
      .width("100%")
    }
    .layoutWeight(1)
    .width("100%")
    .scrollBar(BarState.Off)
  }

  /**
   * 写历史 + 跳 SearchResult。
   * 关键词为空时直接 no-op(不跳转,不写历史)。
   */
  private commitAndNavigate(keyword: string): void {
    const trimmed: string = this.vm.commitHistory(keyword);
    if (trimmed.length === 0) {
      return;
    }
    this.navPathStack.pushPath({
      name: RouteTable.SEARCH_RESULT,
      param: new SearchResultArgs(trimmed)
    });
  }
}
