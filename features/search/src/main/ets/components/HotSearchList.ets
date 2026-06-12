/**
 * @file HotSearchList.ets
 * @description "大家在搜"榜单列表。
 *
 * 设计要点:
 * 1. 每行 48 高(PRD §04-02 §2)。
 * 2. 序号颜色规则:rank 1/2/3 用 danger 红 + 加粗;rank 4+ 用 text-tertiary 灰。
 * 3. hot=true 才显示 🔥(本期 mock 数据前 3 全 hot,4/5 false)。
 * 4. 每行底部 1px 分隔线,左缩进 48 对齐文字(不顶到序号)。
 */

import { HotSearchItem } from "@flowsearch/base";

@ComponentV2
export struct HotSearchList {
  @Param items: Array<HotSearchItem> = new Array();

  @Event onItemTap: (keyword: string) => void = (_k: string): void => {};

  build() {
    Column() {
      // 标题行
      Text($r("app.string.fs_search_hot_title"))
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .width("100%")
        .padding({
          left: $r("app.float.fs_space_lg"),
          right: $r("app.float.fs_space_lg"),
          bottom: $r("app.float.fs_space_sm")
        })

      // 列表
      ForEach(this.items, (item: HotSearchItem, idx: number): void => {
        this.buildRow(item, idx === this.items.length - 1);
      }, (item: HotSearchItem): string => `hot_${item.rank}`)
    }
    .width("100%")
    .margin({ top: $r("app.float.fs_space_2xl") })
  }

  @Builder
  buildRow(item: HotSearchItem, isLast: boolean) {
    Column() {
      Row() {
        // 序号
        Text(`${item.rank}`)
          .fontSize($r("app.float.fs_text_body_lg"))
          .fontWeight(item.rank <= 3 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(item.rank <= 3
            ? $r("app.color.fs_color_danger")
            : $r("app.color.fs_color_text_tertiary"))
          .width(20)
          .textAlign(TextAlign.Center)
          .margin({ right: $r("app.float.fs_space_md") })

        // 关键词
        Text(item.keyword)
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_primary"))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 🔥
        if (item.hot) {
          Text("🔥")
            .fontSize(14)
            .margin({ left: $r("app.float.fs_space_sm") })
        }
      }
      .width("100%")
      .height(48)
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg")
      })
      .alignItems(VerticalAlign.Center)
      .onClick((): void => { this.onItemTap(item.keyword); })

      // 分隔线(最后一行不画)
      if (!isLast) {
        Divider()
          .strokeWidth(1)
          .color($r("app.color.fs_color_border"))
          .margin({ left: 48, right: $r("app.float.fs_space_lg") })
      }
    }
  }
}
