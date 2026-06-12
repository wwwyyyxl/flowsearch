/**
 * @file FavsTabs.ets
 * @description 收藏与历史的双 Tab 切换组件。仿 SortTabs 模式。
 *
 * 设计要点:
 * - @Param selectedTab 控制当前选中
 * - @Event onTabChange 通知父组件切 Tab
 * - 选中态:primary 色 + 2px primary 底部下划线
 * - 未选中:tertiary 色
 */

@ComponentV2
export struct FavsTabs {
  @Param selectedTab: string = "favorites";
  @Event onTabChange: (tab: string) => void = (_tab: string): void => {};

  build() {
    Row() {
      this.buildTab("favorites", $r("app.string.fs_favs_tab_favorites"))
      this.buildTab("history", $r("app.string.fs_favs_tab_history"))
    }
    .width("100%")
    .height(44)
    .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
    .backgroundColor($r("app.color.fs_color_surface"))
  }

  @Builder
  buildTab(key: string, label: ResourceStr) {
    Column() {
      Text(label)
        .fontSize($r("app.float.fs_text_body"))
        .fontColor(this.selectedTab === key
          ? $r("app.color.fs_color_primary")
          : $r("app.color.fs_color_text_tertiary"))
        .fontWeight(this.selectedTab === key ? FontWeight.Bold : FontWeight.Normal)

      Column()
        .width(24)
        .height(2)
        .backgroundColor(this.selectedTab === key
          ? $r("app.color.fs_color_primary")
          : Color.Transparent)
        .borderRadius(1)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => { this.onTabChange(key); })
  }
}
