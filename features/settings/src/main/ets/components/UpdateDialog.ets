/**
 * @file UpdateDialog.ets
 * @description 版本更新弹层(mock)。参考 Stitch HTML 的确认弹层模式。
 *
 * 视觉:宽 320,圆角 fs_radius_lg,↑ 图标 + 标题 + 版本号 + 描述 + 两个按钮。
 */

@ComponentV2
export struct UpdateDialog {
  @Param visible: boolean = false;
  @Event onCancelTap: () => void = (): void => {};
  @Event onUpdateTap: () => void = (): void => {};

  build() {
    if (this.visible) {
      Stack() {
        // 半透明遮罩
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("rgba(0,0,0,0.4)")
          .onClick((): void => { this.onCancelTap(); })

        // 弹层卡片
        Column({ space: 12 }) {
          // ↑ 图标
          Text("↑")
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_primary"))
            .textAlign(TextAlign.Center)
            .width("100%")

          // 标题
          Text("发现新版本")
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))
            .textAlign(TextAlign.Center)
            .width("100%")

          // 版本号
          Text("FlowSearch v1.0.1")
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_text_secondary"))
            .textAlign(TextAlign.Center)
            .width("100%")

          // 更新内容
          Text("修复已知问题，提升使用体验")
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .textAlign(TextAlign.Center)
            .width("100%")

          // 按钮行
          Row({ space: 12 }) {
            Text("稍后")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .backgroundColor($r("app.color.fs_color_background"))
              .borderRadius($r("app.float.fs_radius_md"))
              .height($r("app.float.fs_height_button"))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .onClick((): void => { this.onCancelTap(); })

            Button("立即更新")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_inverse"))
              .backgroundColor($r("app.color.fs_color_primary"))
              .borderRadius($r("app.float.fs_radius_md"))
              .height($r("app.float.fs_height_button"))
              .layoutWeight(1)
              .onClick((): void => { this.onUpdateTap(); })
          }
          .width("100%")
          .margin({ top: 4 })
        }
        .width(320)
        .padding($r("app.float.fs_space_2xl"))
        .borderRadius($r("app.float.fs_radius_lg"))
        .backgroundColor($r("app.color.fs_color_surface"))
      }
      .width("100%")
      .height("100%")
    }
  }
}
