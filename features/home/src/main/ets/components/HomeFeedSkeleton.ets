/**
 * @file HomeFeedSkeleton.ets
 * @description 首页 Feed 区骨架屏。3 张卡片占位,匹配 ArticleCard 形状。
 *
 * 设计要点:
 * 1. 与 ArticleCard 的视觉骨架完全对应(左 56x56 方 + 右两行长条),
 *    数据到达时骨架替换成真实卡,UI 形状不跳动 -- PRD §05 §1.1 "骨架与正常内容形状一致"。
 * 2. 静态骨架不显示 spinner -- PRD §05 §1.1 明文规定。
 * 3. 通过 @BuilderParam 注入到 StateHost,覆盖默认 Loading 渲染。
 */

@ComponentV2
export struct HomeFeedSkeleton {
  build() {
    Column({ space: 12 }) {
      ForEach([1, 2, 3], (_v: number, _i: number): void => {
        this.buildOne();
      })
    }
    .width("100%")
    .padding({
      left: $r("app.float.fs_space_lg"),
      right: $r("app.float.fs_space_lg"),
      top: $r("app.float.fs_space_md"),
      bottom: $r("app.float.fs_space_md")
    })
  }

  @Builder
  buildOne() {
    Row() {
      // 左 56x56 灰方块
      Column()
        .width(56)
        .height(56)
        .borderRadius($r("app.float.fs_radius_md"))
        .backgroundColor($r("app.color.fs_color_border"))

      // 右 两行灰条
      Column() {
        Column()
          .width("80%")
          .height(18)
          .borderRadius($r("app.float.fs_radius_sm"))
          .backgroundColor($r("app.color.fs_color_border"))
        Column()
          .width("100%")
          .height(14)
          .borderRadius($r("app.float.fs_radius_sm"))
          .backgroundColor($r("app.color.fs_color_border"))
          .margin({ top: $r("app.float.fs_space_sm") })
        Column()
          .width("60%")
          .height(14)
          .borderRadius($r("app.float.fs_radius_sm"))
          .backgroundColor($r("app.color.fs_color_border"))
          .margin({ top: $r("app.float.fs_space_sm") })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r("app.float.fs_space_md") })
    }
    .width("100%")
    .padding($r("app.float.fs_space_lg"))
    .backgroundColor($r("app.color.fs_color_surface"))
    .borderRadius($r("app.float.fs_radius_lg"))
  }
}
