/**
 * @file ConfirmDialog.ets
 * @description 通用清理确认弹层。参考 LoginExpiredDialog 的 Stack overlay 模式。
 *
 * 视觉:宽 320,圆角 fs_radius_lg,半透明遮罩,标题+描述+取消/确认按钮。
 * isDanger=true 时确认按钮用 fs_color_danger(红色),否则用 fs_color_primary。
 */

@ComponentV2
export struct ConfirmDialog {
  @Param visible: boolean = false;
  @Param title: string = "";
  @Param description: string = "";
  @Param confirmLabel: string = "清理";
  @Param isDanger: boolean = true;
  @Event onCancelTap: () => void = (): void => {};
  @Event onConfirmTap: () => void = (): void => {};

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
        Column({ space: 16 }) {
          // 标题
          Text(this.title)
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))

          // 描述
          Text(this.description)
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_text_secondary"))

          // 按钮行
          Row({ space: 12 }) {
            // 取消按钮
            Text("取消")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .backgroundColor($r("app.color.fs_color_background"))
              .borderRadius($r("app.float.fs_radius_md"))
              .height($r("app.float.fs_height_button"))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .onClick((): void => { this.onCancelTap(); })

            // 确认按钮
            Button(this.confirmLabel)
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_inverse"))
              .backgroundColor(this.isDanger
                ? $r("app.color.fs_color_danger")
                : $r("app.color.fs_color_primary"))
              .borderRadius($r("app.float.fs_radius_md"))
              .height($r("app.float.fs_height_button"))
              .layoutWeight(1)
              .onClick((): void => { this.onConfirmTap(); })
          }
          .width("100%")
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
