/**
 * @file LazyImage.ets
 * @description 通用懒加载图片组件。加载中显示占位色块，加载成功显示图片，失败显示兜底。
 *
 * 鸿蒙文档依据:
 *   - Image.onError(callback: ImageError) → 加载失败回调
 *   - Image.onComplete(callback: ImageLoadResult) → 加载成功回调
 *   - Image.objectFit(ImageFit.Cover) → 图片填充模式
 *
 * 设计决策:
 *   - alt() 只接受 ResourceStr，不能传 @Builder，所以用 @Local loadState 状态管理
 *   - src 为 null 时直接显示占位色块，不创建 Image 组件
 *   - 占位色块复用 fs_color_skeleton token（深色模式自动适配）
 */

@ComponentV2
export struct LazyImage {
  /** 图片地址。null 或空串时显示占位色块。 */
  @Param src: string | null = null;

  /** 占位文字（无图时显示在色块中央）。 */
  @Param placeholderText: string = "";

  /** 宽度。 */
  @Param imgWidth: string = "56vp";

  /** 高度。 */
  @Param imgHeight: string = "56vp";

  /** 圆角。 */
  @Param imgBorderRadius: string = "8vp";

  /** 图片填充模式。 */
  @Param fit: ImageFit = ImageFit.Cover;

  /** 加载状态:'idle' | 'loading' | 'success' | 'error'。 */
  @Local loadState: string = "idle";

  aboutToAppear(): void {
    if (this.src !== null && this.src.length > 0) {
      this.loadState = "loading";
    }
  }

  build() {
    Stack() {
      // 底层:占位色块(始终渲染,作为 Image 加载中的底层)
      Column() {
        if (this.placeholderText.length > 0) {
          Text(this.placeholderText)
            .fontSize(12)
            .fontColor($r("app.color.fs_color_text_tertiary"))
        }
      }
      .width(this.imgWidth)
      .height(this.imgHeight)
      .borderRadius(this.imgBorderRadius)
      .backgroundColor($r("app.color.fs_color_border"))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 中层:真实图片(src 非空时渲染)
      if (this.src !== null && this.src.length > 0 && this.loadState !== "error") {
        Image(this.src)
          .width(this.imgWidth)
          .height(this.imgHeight)
          .objectFit(this.fit)
          .borderRadius(this.imgBorderRadius)
          .opacity(this.loadState === "success" ? 1 : 0)
          .onComplete((): void => {
            this.loadState = "success";
          })
          .onError((_err: ImageError): void => {
            this.loadState = "error";
          })
      }

      // 上层:错误兜底(loadState === "error" 时显示)
      if (this.loadState === "error") {
        Column() {
          Text("!")
            .fontSize(16)
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .fontWeight(FontWeight.Bold)
        }
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .backgroundColor($r("app.color.fs_color_border"))
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width(this.imgWidth)
    .height(this.imgHeight)
    .clip(true)
  }
}
