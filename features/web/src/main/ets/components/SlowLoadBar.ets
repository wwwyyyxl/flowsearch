/**
 * @file SlowLoadBar.ets
 * @description 慢加载提示黄条(PRD §04-04 §5.5)。
 *
 * 视觉:32px 高黄底 (#FEF3C7) 横条
 *  - 文字 "页面加载较慢,请检查网络" 14 warning 色
 *  - 右侧 "停止" 按钮(text 按钮,primary)
 *
 * 触发时机:WebContainerViewModel 内 5s 定时器到点未 onPageEnd 时 showSlowBar=true。
 * 用户点"停止"或加载完成都会清掉。
 */

@ComponentV2
export struct SlowLoadBar {
  @Param visible: boolean = false;

  @Event onStopTap: () => void = (): void => {};

  build() {
    if (this.visible) {
      Row() {
        Text("页面加载较慢,请检查网络")
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_warning"))
          .layoutWeight(1)

        Text("停止")
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_primary"))
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick((): void => { this.onStopTap(); })
      }
      .width("100%")
      .height(32)
      .backgroundColor("#FEF3C7")
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_sm")
      })
      .alignItems(VerticalAlign.Center)
    }
  }
}
