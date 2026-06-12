/**
 * @file WebErrorPage.ets
 * @description WebContainer 白屏错误页(PRD §04-04 §5.2)。
 *
 * 关键视觉规约(面试工程复盘题视觉证据):
 *   - 居中,距顶 33%(垂直 justify center 也行,本期居中)
 *   - ⚠ 圆形图标 64×64,边框 2px color.danger,内"!"红色
 *   - 主标题 18 加粗 "页面加载失败"
 *   - 副标题 14 灰 "可能是网络异常或目标页面暂时不可用"
 *   - 错误码小字 12 三级灰 "错误码: {code} · trace: {tail}"
 *   - 按钮组**次左主右**(iOS / Material 标准):
 *      左 "返回上一页"(次按钮,border,140 宽 44 高)
 *      右 "重新加载"(主按钮 primary 底,140 宽 44 高)
 *
 * 这个组件不接 PageState,只接 errorCode / traceTail / 两个 callback。
 */

@ComponentV2
export struct WebErrorPage {
  @Param errorCode: string = "UNKNOWN";
  @Param traceTail: string = "";

  @Event onBackTap: () => void = (): void => {};
  @Event onRetryTap: () => void = (): void => {};

  build() {
    Column() {
      // ⚠ 图标
      Stack() {
        Circle({ width: 64, height: 64 })
          .fill(Color.Transparent)
          .stroke($r("app.color.fs_color_danger"))
          .strokeWidth(2)
        Text("!")
          .fontSize(32)
          .fontColor($r("app.color.fs_color_danger"))
          .fontWeight(FontWeight.Bold)
      }
      .width(64)
      .height(64)

      // 主标题
      Text("页面加载失败")
        .fontSize($r("app.float.fs_text_title_2"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .margin({ top: $r("app.float.fs_space_lg") })

      // 副标题
      Text($r("app.string.fs_web_error_subtitle"))
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .textAlign(TextAlign.Center)
        .margin({ top: $r("app.float.fs_space_sm") })

      // 错误码
      Text($r("app.string.fs_web_error_code") + ": " + this.errorCode + " . trace: " + this.traceTail)
        .fontSize($r("app.float.fs_text_caption"))
        .fontColor($r("app.color.fs_color_text_tertiary"))
        .margin({ top: $r("app.float.fs_space_sm") })

      // 按钮组(次左主右)
      Row({ space: 12 }) {
        // 次按钮:返回上一页
        Button($r("app.string.fs_web_back"))
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_primary"))
          .backgroundColor($r("app.color.fs_color_surface"))
          .border({ width: 1, color: $r("app.color.fs_color_border") })
          .borderRadius($r("app.float.fs_radius_md"))
          .height(44)
          .width(140)
          .onClick((): void => { this.onBackTap(); })

        // 主按钮:重新加载
        Button($r("app.string.fs_web_reload"))
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_inverse"))
          .backgroundColor($r("app.color.fs_color_primary"))
          .borderRadius($r("app.float.fs_radius_md"))
          .height(44)
          .width(140)
          .onClick((): void => { this.onRetryTap(); })
      }
      .margin({ top: $r("app.float.fs_space_2xl") })
    }
    .width("100%")
    .height("100%")
    .padding($r("app.float.fs_space_lg"))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r("app.color.fs_color_background"))
  }
}
