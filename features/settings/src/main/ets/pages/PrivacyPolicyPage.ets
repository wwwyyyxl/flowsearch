/**
 * @file PrivacyPolicyPage.ets
 * @description 隐私政策页面(P06 Settings 子页)。NavDestination + 顶栏 + 滚动长文本。
 *
 * Mock 内容:占位隐私条款文本,真实版本替换为服务端下发或本地化文案。
 */

@ComponentV2
export struct PrivacyPolicyPage {
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
          Text("隐私政策")
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
            Text("FlowSearch 隐私政策")
              .fontSize($r("app.float.fs_text_title_2"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("更新日期：2026 年 6 月 1 日\n生效日期：2026 年 6 月 1 日")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("一、信息收集")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("我们可能收集的信息包括：搜索关键词、浏览历史、设备信息、应用使用数据等。这些信息用于提供和改进我们的服务，包括个性化搜索推荐和 AI 速答功能。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("二、信息使用")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("我们使用收集的信息用于：提供搜索服务、改善用户体验、生成匿名统计数据、防止滥用和欺诈。我们不会将您的个人信息出售给第三方。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("三、信息存储与安全")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("您的搜索历史和收藏内容存储在本地设备上（通过 HarmonyOS Preferences API），不会自动上传到服务器。我们采用行业标准的安全措施保护您的数据安全。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("四、Cookie 与本地存储")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("本应用使用 HarmonyOS 的 Web 组件加载第三方网页，这些网页可能使用 Cookie。本应用的登录态透传功能会在特定域名下注入认证信息，以提供无缝的登录体验。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("五、第三方服务")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("本应用的搜索结果来自第三方搜索引擎和内容提供商。这些第三方服务有其自己的隐私政策，我们建议您了解这些第三方的隐私实践。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("六、用户权利")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("您有权随时在设置中清除搜索历史、收藏内容和应用缓存。您也可以关闭个性化推荐和应用追踪功能。如需进一步的数据操作请求，请通过反馈功能联系我们。")
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_lg") })

            Text("七、隐私政策更新")
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ bottom: $r("app.float.fs_space_sm") })

            Text("我们可能会不时更新本隐私政策。更新后的隐私政策将在应用内公布，继续使用本应用即表示您同意更新后的隐私政策。")
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
