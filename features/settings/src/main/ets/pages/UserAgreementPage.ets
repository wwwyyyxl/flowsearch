/**
 * @file UserAgreementPage.ets
 * @description 用户协议页面(P06 Settings 子页)。NavDestination + 顶栏 + 滚动长文本。
 *
 * Mock 内容:占位法律文本段落,真实版本替换为服务端下发或本地化文案。
 */

@ComponentV2
export struct UserAgreementPage {
  @Param navPathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column() {
        // 顶栏
        Row() {
          Text("←")
            .fontSize(20)
            .fontColor($r("app.color.fs_color_text_primary"))
            .onClick((): void => { this.navPathStack.pop(); })
          Text("用户协议")
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))
            .margin({ left: $r("app.float.fs_space_md") })
        }
        .width("100%")
        .height(56)
        .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r("app.color.fs_color_surface"))

        // 内容
        Scroll() {
          Column() {
            Text("FlowSearch 用户服务协议")
              .fontSize($r("app.float.fs_text_title_2"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("更新日期：2026 年 6 月 1 日\n生效日期：2026 年 6 月 1 日")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("一、服务条款的确认与接纳")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("欢迎使用 FlowSearch（以下简称「本应用」）。本应用由 FlowSearch 团队开发和运营。请您在使用本应用之前仔细阅读本协议的全部内容。如果您对本协议的任何条款表示异议，您可以选择不使用本应用。当您注册、使用本应用时，即表示您已充分阅读、理解并同意接受本协议的全部内容的约束。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("二、服务内容")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("本应用为用户提供智能搜索聚合服务，包括但不限于网页搜索、工具搜索、AI 速答等功能。本应用保留随时修改或中断服务的权利，且无需事先通知用户。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("三、用户行为规范")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("用户在使用本应用时应遵守法律法规，不得利用本应用从事违法违规行为，包括但不限于：传播违法信息、侵犯他人知识产权、恶意攻击系统等。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("四、知识产权")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("本应用的所有内容，包括但不限于文字、图片、音频、视频、软件、程序代码、版面设计等，均受知识产权法律法规保护。未经本应用书面许可，任何人不得以任何方式复制、转载、摘编、修改本应用内容。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("五、免责声明")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("本应用提供的搜索结果来源于第三方，本应用不对搜索结果的准确性、完整性、合法性负责。用户应自行判断搜索结果的可靠性，并承担使用搜索结果所产生的风险。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("六、协议修改")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("本应用有权根据需要不时地修改本协议条款，修改后的协议一经公布即代替原来的协议条款。用户应定期查看本协议内容，如不同意修改后的条款，可停止使用本应用。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
          }
          .width("100%")
          .padding($r("app.float.fs_space_lg"))
        }
        .layoutWeight(1)
        .width("100%")
        .scrollBar(BarState.Off)
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.fs_color_background"))
    }
    .hideTitleBar(true)
  }
}
