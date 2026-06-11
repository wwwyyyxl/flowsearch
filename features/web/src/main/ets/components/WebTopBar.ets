/**
 * @file WebTopBar.ets
 * @description WebContainer 顶栏(PRD §04-04 §2):
 *   - 左:← 返回(直接关闭 WebContainer,不消费 WebView 内部历史栈)
 *   - 中:两行 — 标题(18 加粗 单行省略) + 域名(12 带 🔒/⚠ 单行省略)
 *   - 右:⋯ 更多菜单(刷新 / 在浏览器中打开 / 复制链接 / 分享)— 本期 Toast 占位
 *
 * 设计要点:
 *  - 顶栏永久渲染,不进 PageState 分发(Loading/Error 时也保留)
 *  - 高度 56,与 PRD §02 视觉规范对齐
 */

@ComponentV2
export struct WebTopBar {
  @Param title: string = "";
  @Param domain: string = "";
  @Param isHttps: boolean = true;

  @Event onBackTap: () => void = (): void => {};
  @Event onMoreTap: () => void = (): void => {};

  build() {
    Row() {
      // 左:返回
      Text("←")
        .fontSize(22)
        .fontColor($r("app.color.fs_color_text_primary"))
        .width(40)
        .height("100%")
        .textAlign(TextAlign.Center)
        .onClick((): void => { this.onBackTap(); })

      // 中:两行标题 + 域名
      Column() {
        Text(this.title)
          .fontSize($r("app.float.fs_text_title_2"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_text_primary"))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width("100%")

        Row({ space: 4 }) {
          Text(this.isHttps ? "🔒" : "⚠")
            .fontSize(12)
            .fontColor(this.isHttps
              ? $r("app.color.fs_color_text_secondary")
              : $r("app.color.fs_color_warning"))
          Text(this.domain)
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_secondary"))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width("100%")
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: $r("app.float.fs_space_sm") })

      // 右:更多菜单
      Text("⋯")
        .fontSize(22)
        .fontColor($r("app.color.fs_color_text_primary"))
        .width(40)
        .height("100%")
        .textAlign(TextAlign.Center)
        .onClick((): void => { this.onMoreTap(); })
    }
    .width("100%")
    .height($r("app.float.fs_height_nav_bar"))
    .backgroundColor($r("app.color.fs_color_background"))
    .padding({
      left: $r("app.float.fs_space_sm"),
      right: $r("app.float.fs_space_sm")
    })
    .alignItems(VerticalAlign.Center)
  }
}
