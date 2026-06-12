/**
 * @file HistoryChips.ets
 * @description 搜索历史区块:标题 + 删除图标 + 流式标签云。
 *
 * 设计要点:
 * 1. 流式标签布局:用 Flex 容器 + wrap,ArkUI 原生支持;
 *    每个 chip 高 36 圆角 18,padding 8/16(PRD §04-02 §2)。
 * 2. 点击标签 -> 调 onChipTap(keyword) 跳 SearchResult;
 *    长按 -> onChipLongPress 留作扩展练习(本期不接弹窗)。
 * 3. 空历史时整段不展示 -- 由父组件判 history.length === 0 后不渲染本组件,
 *    本组件假定收到的列表非空。
 */

import { SearchHistoryItem } from "@flowsearch/base";

@ComponentV2
export struct HistoryChips {
  @Param history: Array<SearchHistoryItem> = new Array();

  @Event onChipTap: (keyword: string) => void = (_k: string): void => {};

  /** 清空所有历史按钮回调(垃圾桶图标)。 */
  @Event onClearAllTap: () => void = (): void => {};

  build() {
    Column() {
      // 标题行
      Row() {
        Text($r("app.string.fs_search_history_title"))
          .fontSize($r("app.float.fs_text_body_lg"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_text_primary"))
          .layoutWeight(1)

        Text("🗑")
          .fontSize(18)
          .fontColor($r("app.color.fs_color_danger"))
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .onClick((): void => { this.onClearAllTap(); })
      }
      .width("100%")
      .margin({ bottom: $r("app.float.fs_space_md") })

      // 流式标签云
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.history, (h: SearchHistoryItem): void => {
          this.buildChip(h);
        }, (h: SearchHistoryItem): string => h.keyword)
      }
      .width("100%")
    }
    .width("100%")
    .padding({
      left: $r("app.float.fs_space_lg"),
      right: $r("app.float.fs_space_lg"),
      top: $r("app.float.fs_space_lg")
    })
  }

  @Builder
  buildChip(h: SearchHistoryItem) {
    Text(h.keyword)
      .fontSize($r("app.float.fs_text_body"))
      .fontColor($r("app.color.fs_color_text_primary"))
      .height(36)
      .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
      .backgroundColor($r("app.color.fs_color_surface"))
      .border({ width: 1, color: $r("app.color.fs_color_border") })
      .borderRadius($r("app.float.fs_radius_full"))
      .margin({ right: $r("app.float.fs_space_sm"), bottom: $r("app.float.fs_space_sm") })
      .onClick((): void => { this.onChipTap(h.keyword); })
  }
}
