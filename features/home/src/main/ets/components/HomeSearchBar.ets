/**
 * @file HomeSearchBar.ets
 * @description 首页假搜索栏。点击整个区域跳 SearchInput(S2 接 router,本期仅 Toast)。
 *
 * PRD §04-01-home.md §2 / §3:点击命中区不限于输入框内字段,整个 44 高条都可点。
 */

import promptAction from "@ohos.promptAction";

@ComponentV2
export struct HomeSearchBar {
  /**
   * 点击回调。父组件传 router 跳转或 Toast。
   *
   * 注意:属性名不能叫 onClick -- 会和 CustomComponentV2 基类内置的
   * .onClick() 通用方法签名冲突(基类返回 CommonAttribute,自定义返回 void)。
   * 命名规则:自定义事件 prop 一律避开 onClick/onTouch/onAppear 等
   * ArkUI 通用方法名,改用 onXxxTap/onXxxChange 之类的语义名。
   */
  @Event onSearchBarTap: () => void = (): void => {
    promptAction.showToast({ message: "SearchInput 待 S2 接入" });
  };

  build() {
    Row() {
      // 左 icon: 搜索(占位用 Text 字符,后续接 SVG)
      Text("⌕")
        .fontSize(20)
        .fontColor($r("app.color.fs_color_text_tertiary"))
        .margin({ left: $r("app.float.fs_space_md"), right: $r("app.float.fs_space_sm") })

      // placeholder 文案
      Text("搜索网页、工具、历史记录")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_tertiary"))
        .layoutWeight(1)

      // 右 icon: 扫码(占位)
      Text("⌖")
        .fontSize(20)
        .fontColor($r("app.color.fs_color_text_tertiary"))
        .margin({ right: $r("app.float.fs_space_md") })
    }
    .width("100%")
    .height($r("app.float.fs_height_search_bar"))
    .backgroundColor($r("app.color.fs_color_surface"))
    .borderRadius($r("app.float.fs_radius_md"))
    .border({ width: 1, color: $r("app.color.fs_color_border") })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => { this.onSearchBarTap(); })
  }
}
