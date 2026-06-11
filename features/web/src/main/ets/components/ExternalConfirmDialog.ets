/**
 * @file ExternalConfirmDialog.ets
 * @description 外跳确认弹层(PRD §04-04 §5.4)。
 *
 * 视觉:半透明遮罩 + 中央弹层(同 LoginExpiredDialog 结构)
 *  - 标题 "即将打开外部应用"
 *  - 描述 "目标: {url}\n确认要离开 FlowSearch 吗?"
 *  - 按钮 取消 / 打开
 *
 * 由父组件通过 visible 控制显隐,targetUrl 决定描述文案。
 */

@ComponentV2
export struct ExternalConfirmDialog {
  @Param visible: boolean = false;
  @Param targetUrl: string = "";

  @Event onCancelTap: () => void = (): void => {};
  @Event onConfirmTap: () => void = (): void => {};

  build() {
    if (this.visible) {
      Stack() {
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("rgba(0,0,0,0.4)")
          .onClick((): void => { this.onCancelTap(); })

        Column() {
          Text("即将打开外部应用")
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))
            .alignSelf(ItemAlign.Start)

          Text(`目标: ${this.targetUrl}\n确认要离开 FlowSearch 吗?`)
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_text_secondary"))
            .alignSelf(ItemAlign.Start)
            .margin({ top: $r("app.float.fs_space_md") })

          Row({ space: 16 }) {
            Text("取消")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .onClick((): void => { this.onCancelTap(); })

            Button("打开")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_inverse"))
              .backgroundColor($r("app.color.fs_color_primary"))
              .borderRadius($r("app.float.fs_radius_md"))
              .height(44)
              .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
              .onClick((): void => { this.onConfirmTap(); })
          }
          .width("100%")
          .justifyContent(FlexAlign.End)
          .margin({ top: $r("app.float.fs_space_2xl") })
        }
        .width(320)
        .backgroundColor($r("app.color.fs_color_surface"))
        .borderRadius($r("app.float.fs_radius_xl"))
        .padding($r("app.float.fs_space_xl"))
      }
      .width("100%")
      .height("100%")
      .alignContent(Alignment.Center)
    }
  }
}
