/**
 * @file WebActionSheet.ets
 * @description WebContainer 底部 ActionSheet(更多菜单)。
 *
 * 视觉:从底部滑入,白色背景,顶部圆角 fs_radius_lg,
 * 4 个操作选项(刷新/浏览器打开/复制链接/分享) + 取消按钮。
 *
 * 参考 PRD §04-04 §2 右上角 ⋯ 更多菜单。
 *
 * 设计要点:
 * - Stack overlay 模式,与 LoginExpiredDialog 一致
 * - translate 动画:visible 时 y=0,否则 y='100%'
 * - 背景点击关闭
 * - 每个选项带 emoji icon + 文字
 */

@ComponentV2
export struct WebActionSheet {
  @Param visible: boolean = false;
  @Param isFavorited: boolean = false;
  @Event onCancelTap: () => void = (): void => {};
  @Event onRefreshTap: () => void = (): void => {};
  @Event onOpenInBrowserTap: () => void = (): void => {};
  @Event onCopyLinkTap: () => void = (): void => {};
  @Event onShareTap: () => void = (): void => {};
  @Event onFavoriteTap: () => void = (): void => {};

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 半透明遮罩
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("rgba(0,0,0,0.4)")
          .onClick((): void => { this.onCancelTap(); })

        // 底部面板
        Column() {
          // 4 个操作选项
          Column() {
            this.buildActionItem("🔄", "刷新", (): void => { this.onRefreshTap(); })
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildActionItem("🌐", "在浏览器中打开", (): void => { this.onOpenInBrowserTap(); })
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildActionItem("📋", "复制链接", (): void => { this.onCopyLinkTap(); })
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildActionItem("↗", "分享", (): void => { this.onShareTap(); })
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildActionItem(
              this.isFavorited ? "⭐" : "☆",
              this.isFavorited ? "取消收藏" : "收藏",
              (): void => { this.onFavoriteTap(); }
            )
          }
          .width("100%")
          .borderRadius($r("app.float.fs_radius_lg"))
          .backgroundColor($r("app.color.fs_color_surface"))
          .clip(true)

          // 取消按钮
          Text("取消")
            .fontSize($r("app.float.fs_text_body_lg"))
            .fontColor($r("app.color.fs_color_text_primary"))
            .textAlign(TextAlign.Center)
            .width("100%")
            .height($r("app.float.fs_height_button"))
            .backgroundColor($r("app.color.fs_color_surface"))
            .borderRadius($r("app.float.fs_radius_lg"))
            .margin({ top: 8 })
            .onClick((): void => { this.onCancelTap(); })
        }
        .width("100%")
        .padding({
          left: $r("app.float.fs_space_lg"),
          right: $r("app.float.fs_space_lg"),
          bottom: $r("app.float.fs_space_3xl")
        })
        .translate({ y: 0 })
        .animation({ duration: 250, curve: Curve.EaseOut })
      }
      .width("100%")
      .height("100%")
    }
  }

  @Builder
  buildActionItem(icon: string, label: string, handler: () => void) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(18)
      Text(label)
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontColor($r("app.color.fs_color_text_primary"))
    }
    .width("100%")
    .height($r("app.float.fs_height_list_single"))
    .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
    .alignItems(VerticalAlign.Center)
    .onClick(handler)
  }
}
