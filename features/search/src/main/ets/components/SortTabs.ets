/**
 * @file SortTabs.ets
 * @description SearchResult 顶部排序/筛选 Tab 条。
 *              横向滚动 + 5 个 Tab(综合/最新/最热/仅工具/仅文章)。
 *              选中态:文字 primary + 底部 2px 下划线;未选中:text.secondary。
 *
 * 设计要点:
 * 1. 与 home 的 ChannelTabs 形态接近,但选中态用"下划线"而非"胶囊填充"
 *    -- 对齐 PRD §04-03 §2 设计稿(更轻、二级页常见)。
 * 2. 数据驱动:接收 Array<SortOption>,父组件传 selectedKey,本组件不持状态。
 */

import { SortType } from "@flowsearch/base";

interface SortOption {
  key: SortType;
  label: ResourceStr;
}

const SORT_OPTIONS: Array<SortOption> = [
  { key: "RELEVANCE",    label: $r("app.string.fs_search_sort_relevance") },
  { key: "LATEST",       label: $r("app.string.fs_search_sort_newest") },
  { key: "HOTTEST",      label: $r("app.string.fs_search_sort_hottest") },
  { key: "TOOL_ONLY",    label: $r("app.string.fs_search_sort_tool_only") },
  { key: "ARTICLE_ONLY", label: $r("app.string.fs_search_sort_article_only") }
];

@ComponentV2
export struct SortTabs {
  @Param selectedKey: SortType = "RELEVANCE";

  @Event onSortChange: (sort: SortType) => void = (_s: SortType): void => {};

  build() {
    Scroll() {
      Row({ space: 24 }) {
        ForEach(SORT_OPTIONS, (opt: SortOption): void => {
          this.buildTab(opt);
        }, (opt: SortOption): string => opt.key)
      }
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg")
      })
      .height(40)
      .alignItems(VerticalAlign.Center)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width("100%")
    .height(40)
    .backgroundColor($r("app.color.fs_color_surface"))
    .border({
      width: { bottom: 1 },
      color: $r("app.color.fs_color_border")
    })
  }

  @Builder
  buildTab(opt: SortOption) {
    Column() {
      Text(opt.label)
        .fontSize($r("app.float.fs_text_body"))
        .fontWeight(this.isSelected(opt) ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.isSelected(opt)
          ? $r("app.color.fs_color_primary")
          : $r("app.color.fs_color_text_secondary"))
        .layoutWeight(1)

      // 选中下划线
      if (this.isSelected(opt)) {
        Column()
          .width("100%")
          .height(2)
          .backgroundColor($r("app.color.fs_color_primary"))
          .borderRadius(1)
      }
    }
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick((): void => { this.onSortChange(opt.key); })
  }

  private isSelected(opt: SortOption): boolean {
    return opt.key === this.selectedKey;
  }
}
