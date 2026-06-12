/**
 * @file QuickEntries.ets
 * @description 工具入口 4 圆。对应 PRD §04-01-home.md §2 快捷工具卡。
 *
 * 设计要点:
 * 1. 数据驱动:接收 ToolEntry[],4 个一行均分(ArkUI 用 layoutWeight(1) 等分);
 * 2. 圆形内 icon 本期用 emoji 占位,iconKey 字典将来集中映射成 SVG(扩展练习);
 * 3. 点击回调外抛 toolId,父组件决定跳哪,本组件不耦合 router。
 */

import { ToolEntry } from "@flowsearch/base";

/** iconKey -> 占位 emoji 字典。后续接入 SVG 资源时改这里。 */
const ICON_EMOJI: Map<string, string> = new Map([
  ["icon_web", "🌐"],
  ["icon_scan", "⊞"],
  ["icon_translate", "文"],
  ["icon_file", "📄"]
]);

@ComponentV2
export struct QuickEntries {
  /** 入口列表(已按 order 排序,只取前 4)。父组件保证 length <= 4。 */
  @Param entries: Array<ToolEntry> = new Array();

  /** 点击某个入口的回调,外抛 toolId 让父组件决定跳转。 */
  @Event onEntryClick: (toolId: string) => void = (_toolId: string): void => {};

  build() {
    Column() {
      // 顶部行:标题 + "全部"链接
      Row() {
        Text($r("app.string.fs_home_quick_tools"))
          .fontSize($r("app.float.fs_text_title_2"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_text_primary"))
          .layoutWeight(1)

        Text($r("app.string.fs_home_all"))
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_primary"))
      }
      .width("100%")
      .margin({ bottom: $r("app.float.fs_space_md") })

      // 4 列均分入口
      Row() {
        ForEach(this.entries, (entry: ToolEntry): void => {
          this.buildEntry(entry);
        }, (entry: ToolEntry): string => entry.toolId)
      }
      .width("100%")
    }
    .width("100%")
    .padding($r("app.float.fs_space_lg"))
    .backgroundColor($r("app.color.fs_color_surface"))
    .borderRadius($r("app.float.fs_radius_lg"))
  }

  @Builder
  buildEntry(entry: ToolEntry) {
    Column() {
      // 圆形底色 + emoji 占位
      Stack() {
        Circle({ width: 56, height: 56 })
          .fill($r("app.color.fs_color_primary_tint"))

        Text(this.iconOf(entry.iconKey))
          .fontSize(24)
          .fontColor($r("app.color.fs_color_primary"))
      }
      .width($r("app.float.fs_height_tool_circle"))
      .height($r("app.float.fs_height_tool_circle"))

      Text(entry.name)
        .fontSize($r("app.float.fs_text_caption"))
        .fontColor($r("app.color.fs_color_text_primary"))
        .margin({ top: $r("app.float.fs_space_sm") })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .accessibilityText(entry.name)
    .onClick((): void => { this.onEntryClick(entry.toolId); })
  }

  /** 字典取 icon,未找到时给个默认占位避免空白。 */
  private iconOf(key: string): string {
    const v = ICON_EMOJI.get(key);
    return v !== undefined ? v : "?";
  }
}
