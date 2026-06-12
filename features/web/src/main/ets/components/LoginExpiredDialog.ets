/**
 * @file LoginExpiredDialog.ets
 * @description 登录过期弹层(PRD §04-04 §5.3)。
 *
 * 视觉:半透明遮罩 + 中央弹层(320 宽 圆角 16 padding 24)
 *  - 标题 "登录已过期" 18 加粗 居左
 *  - 描述 "请重新登录后继续访问该页面" 14 灰
 *  - 按钮组 右对齐:取消(text)/ 重新登录(主色)
 *
 * 由父组件通过 visible 控制显隐,自身不持状态。
 */

@ComponentV2
export struct LoginExpiredDialog {
  @Param visible: boolean = false;

  @Event onCancelTap: () => void = (): void => {};
  @Event onConfirmTap: () => void = (): void => {};

  build() {
    if (this.visible) {
      // 半透明遮罩 + 弹层
      Stack() {
        // 全屏遮罩
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("rgba(0,0,0,0.4)")
          .onClick((): void => { this.onCancelTap(); })

        // 弹层
        Column() {
          Text("登录已过期")
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))
            .alignSelf(ItemAlign.Start)

          Text($r("app.string.fs_web_login_expired_desc"))
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_text_secondary"))
            .alignSelf(ItemAlign.Start)
            .margin({ top: $r("app.float.fs_space_md") })

          Row({ space: 16 }) {
            Text($r("app.string.fs_web_cancel"))
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .onClick((): void => { this.onCancelTap(); })

            Button($r("app.string.fs_web_relogin"))
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
