/**
 * @file SettingsGroup.ets
 * @description 设置页分组容器。圆角白色卡片 + 分组标题。
 *
 * 参考 Stitch HTML: <section> + <h2> + <div class="bg-white rounded-2xl border">
 *
 * 用法:
 *   SettingsGroup({ title: "通用" }) {
 *     SettingsItem({ ... })
 *     SettingsItem({ ... })
 *   }
 */

@ComponentV2
export struct SettingsGroup {
  @Param title: string = "";
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent(): void {
    // 空占位,当调用方不传 content 时使用
  }

  build() {
    Column() {
      // 分组标题
      Text(this.title)
        .fontSize($r("app.float.fs_text_caption"))
        .fontWeight(FontWeight.Medium)
        .fontColor($r("app.color.fs_color_text_secondary"))
        .padding({ left: $r("app.float.fs_space_lg"), bottom: $r("app.float.fs_space_sm") })

      // 卡片容器
      Column() {
        this.content()
      }
      .width("100%")
      .borderRadius($r("app.float.fs_radius_lg"))
      .backgroundColor($r("app.color.fs_color_surface"))
      .borderWidth(1)
      .borderColor($r("app.color.fs_color_border"))
      .clip(true)
    }
    .width("100%")
  }
}
