/**
 * @file SearchTopBar.ets
 * @description SearchInput 页顶栏:真实可输入的搜索框 + "取消"按钮。
 *
 * 设计要点:
 * 1. 用原生 TextInput 而非自绘 -- 软键盘 / 光标 / 选区都由系统接管。
 * 2. TextInput 不接 @Trace,改用 onChange 回调把值同步给 VM(单向数据流)。
 * 3. 右侧清空 ⊗ 仅在 value.length > 0 时显示。
 * 4. 顶栏外加 1px 底分割线(对齐 PRD §04-02 §2 顶栏样式)。
 *
 * 命名避坑:
 *   @Event 全部使用 onXxxTap / onXxxChange,避开 ArkUI 内置 onClick / onFocus。
 */

@ComponentV2
export struct SearchTopBar {
  /** 当前关键词(由父组件 VM 持有,本组件只是受控展示)。 */
  @Param keyword: string = "";

  /** 是否自动聚焦(SearchInput 进入时 true,SearchResult 顶栏静态时 false)。 */
  @Param autoFocus: boolean = true;

  /** 输入框是否只读(SearchResult 顶栏点击回 SearchInput 时,只读 + 全条可点)。 */
  @Param readOnly: boolean = false;

  /** placeholder 文案。 */
  @Param placeholder: string = "搜索网页、工具、历史记录";

  /** 输入变化回调(VM 接住做 debounce)。 */
  @Event onKeywordChange: (next: string) => void = (_n: string): void => {};

  /** 提交搜索(回车键)。 */
  @Event onSubmit: (keyword: string) => void = (_k: string): void => {};

  /** 清空按钮回调。 */
  @Event onClearTap: () => void = (): void => {};

  /** "取消"按钮回调(SearchInput)/ 整框点击回调(SearchResult 只读时)。 */
  @Event onCancelTap: () => void = (): void => {};

  /** 整框点击回调(SearchResult 只读时用,SearchInput 留空)。 */
  @Event onBarTap: () => void = (): void => {};

  /** 是否显示右侧"取消"按钮(SearchResult 顶栏不显示,只显示左侧返回箭头)。 */
  @Param showCancel: boolean = true;

  /** 是否显示左侧返回箭头(SearchResult 用)。 */
  @Param showBack: boolean = false;

  /** 返回箭头点击回调。 */
  @Event onBackTap: () => void = (): void => {};

  build() {
    Row() {
      // 左侧返回箭头(SearchResult 用)
      if (this.showBack) {
        Text("←")
          .fontSize(22)
          .fontColor($r("app.color.fs_color_text_primary"))
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .margin({ right: $r("app.float.fs_space_sm") })
          .onClick((): void => { this.onBackTap(); })
      }

      // 搜索框:left 放大镜 + 中 TextInput + right 清空
      Stack({ alignContent: Alignment.Center }) {
        // 整框背景(只读态可点)
        Row()
          .width("100%")
          .height(36)
          .backgroundColor($r("app.color.fs_color_surface"))
          .borderRadius(this.readOnly ? $r("app.float.fs_radius_full") : $r("app.float.fs_radius_md"))
          .border({
            width: this.readOnly ? 1 : 1.5,
            color: this.readOnly
              ? $r("app.color.fs_color_border")
              : $r("app.color.fs_color_primary")
          })

        // 内容层
        Row() {
          // 左放大镜
          Text("⌕")
            .fontSize(18)
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .margin({ left: $r("app.float.fs_space_md"), right: $r("app.float.fs_space_sm") })

          // 输入框 / 只读文本
          if (this.readOnly) {
            // SearchResult 顶栏:只读展示关键词
            Text(this.keyword)
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          } else {
            // SearchInput 顶栏:真实输入框
            TextInput({ text: this.keyword, placeholder: this.placeholder })
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .placeholderColor($r("app.color.fs_color_text_tertiary"))
              .backgroundColor(Color.Transparent)
              .borderRadius(0)
              .padding(0)
              .layoutWeight(1)
              .height(36)
              .defaultFocus(this.autoFocus)
              .enterKeyType(EnterKeyType.Search)
              .onChange((value: string): void => { this.onKeywordChange(value); })
              .onSubmit((_type: EnterKeyType): void => { this.onSubmit(this.keyword); })
          }

          // 右侧清空(关键词非空时显示)
          if (this.keyword.length > 0) {
            Text("⊗")
              .fontSize(18)
              .fontColor($r("app.color.fs_color_text_tertiary"))
              .margin({ right: $r("app.float.fs_space_md") })
              .onClick((): void => { this.onClearTap(); })
          }
        }
        .width("100%")
        .height(36)
        .alignItems(VerticalAlign.Center)
      }
      .layoutWeight(1)
      .height(36)
      // 只读态下,点整框走 onBarTap(回 SearchInput)
      .onClick((): void => {
        if (this.readOnly) {
          this.onBarTap();
        }
      })

      // 右侧"取消"
      if (this.showCancel) {
        Text($r("app.string.fs_search_cancel"))
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_primary"))
          .margin({ left: $r("app.float.fs_space_md") })
          .onClick((): void => { this.onCancelTap(); })
      }
    }
    .width("100%")
    .height(56)
    .padding({
      left: $r("app.float.fs_space_lg"),
      right: $r("app.float.fs_space_lg")
    })
    .backgroundColor($r("app.color.fs_color_surface"))
    .border({
      width: { bottom: 1 },
      color: $r("app.color.fs_color_border")
    })
    .alignItems(VerticalAlign.Center)
  }
}
