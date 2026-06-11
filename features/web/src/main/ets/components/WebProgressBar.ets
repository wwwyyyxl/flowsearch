/**
 * @file WebProgressBar.ets
 * @description WebContainer 顶栏下方的加载进度条(PRD §04-04 §2):
 *   - 高 2px
 *   - color.primary
 *   - 进度 0-100,宽度按比例
 *   - progress=100 时整条隐藏(由父组件控制 visibility)
 *
 * 用 Row 包左侧绿条 + 右侧空白实现,无需动画属性 — 父组件改 progress 触发重渲,
 * 配合 .width() 的隐式 animateTo 自动有过渡效果。
 */

@ComponentV2
export struct WebProgressBar {
  /** 0-100 */
  @Param progress: number = 0;

  build() {
    Row() {
      Row()
        .width(`${this.progress}%`)
        .height("100%")
        .backgroundColor($r("app.color.fs_color_primary"))
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })
    }
    .width("100%")
    .height(2)
    .backgroundColor(Color.Transparent)
    .visibility(this.progress > 0 && this.progress < 100 ? Visibility.Visible : Visibility.None)
  }
}
