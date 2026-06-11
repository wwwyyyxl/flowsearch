/**
 * @file ChannelTabs.ets
 * @description 横向滚动的频道胶囊 Tab 条。对应 PRD §04-01-home.md §2 频道 Tab。
 *
 * 设计要点:
 * 1. 横向滚动用 Scroll + Row:ArkUI 没有原生 LazyRow,频道数量有限(本期 5 个),
 *    直接 Row 渲染。频道多到 30+ 才需要 List/水平 LazyForEach。
 * 2. 选中态变化时父组件传 selectedId 进来,组件内不持有状态(受控);
 * 3. 当前未做"选中项滚动居中"-- 留扩展练习 §1。
 */

import { Channel } from "@flowsearch/base";

@ComponentV2
export struct ChannelTabs {
  /** 频道列表。 */
  @Param channels: Array<Channel> = new Array();

  /** 当前选中频道 id。 */
  @Param selectedChannelId: string = "";

  /** 切换回调,外抛新 channelId。 */
  @Event onChannelChange: (channelId: string) => void = (_id: string): void => {};

  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.channels, (channel: Channel): void => {
          this.buildChip(channel);
        }, (channel: Channel): string => channel.channelId)
      }
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg")
      })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width("100%")
    .height(40)
  }

  @Builder
  buildChip(channel: Channel) {
    Text(channel.name)
      .fontSize($r("app.float.fs_text_body"))
      .fontWeight(this.isSelected(channel) ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.isSelected(channel)
        ? $r("app.color.fs_color_text_inverse")
        : $r("app.color.fs_color_text_secondary"))
      .backgroundColor(this.isSelected(channel)
        ? $r("app.color.fs_color_primary")
        : Color.Transparent)
      .borderRadius($r("app.float.fs_radius_full"))
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg"),
        top: $r("app.float.fs_space_sm"),
        bottom: $r("app.float.fs_space_sm")
      })
      .onClick((): void => { this.onChannelChange(channel.channelId); })
  }

  private isSelected(channel: Channel): boolean {
    return channel.channelId === this.selectedChannelId;
  }
}
