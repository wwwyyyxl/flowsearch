/**
 * @file HomeHeader.ets
 * @description 首页顶栏:Logo 文字 + 副标题 + 右上角头像圆。对应 PRD §04-01-home.md §2 顶栏。
 *
 * 简单展示组件,无状态(@ComponentV2 + @Param)。所有尺寸走 fs_* token,不写魔法数。
 */

@ComponentV2
export struct HomeHeader {
  /** 头像里展示的姓氏单字。@Param 让父组件可注入(便于换皮)。 */
  @Param avatarLetter: string = "王";

  build() {
    Row() {
      // 左侧 Logo + 副标题
      Column() {
        Text("FlowSearch")
          .fontSize($r("app.float.fs_text_title_1"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_text_primary"))

        Text("搜索、工具与内容聚合")
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_text_secondary"))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右上角头像圆
      Stack() {
        Circle({ width: 36, height: 36 })
          .fill($r("app.color.fs_color_primary_tint"))

        Text(this.avatarLetter)
          .fontSize($r("app.float.fs_text_body"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_primary"))
      }
      .width(36)
      .height(36)
    }
    .width("100%")
    .padding({
      left: $r("app.float.fs_space_lg"),
      right: $r("app.float.fs_space_lg"),
      top: $r("app.float.fs_space_lg"),
      bottom: $r("app.float.fs_space_md")
    })
    .alignItems(VerticalAlign.Center)
  }
}
