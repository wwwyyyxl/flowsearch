/**
 * @file ToolShellPage.ets
 * @description 工具壳页(P07 ToolShell)。4 个工具入口(web/scan/translate/file)共用模板。
 *
 * 设计稿参考:
 *   stitch_flowsearch_06_07_08/flowsearch_tool_shell_variants/code.html
 *   PRD: FlowSearch-PRD/04-页面规约/07-tool-shell.md
 */

import { RouteTable, WebContainerArgs } from "@flowsearch/router";

@ComponentV2
export struct ToolShellPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param toolId: string = "web";

  build() {
    NavDestination() {
      Column() {
        // 1. 顶栏
        Row() {
          Text("←")
            .fontSize(20)
            .fontColor($r("app.color.fs_color_text_primary"))
            .onClick((): void => { this.navPathStack.pop(); })
          Text(this.getTitleResource())
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

        // 2-6. 主体(居中布局)
        Column({ space: 16 }) {
          // 2. 头部区:圆形容器 + icon
          Stack() {
            Circle({ width: 96, height: 96 })
              .fill($r("app.color.fs_color_primary_tint"))
            Text(this.getIcon())
              .fontSize(48)
              .fontColor($r("app.color.fs_color_primary"))
          }
          .width(96)
          .height(96)

          // 3. 工具名
          Text(this.getTitleResource())
            .fontSize($r("app.float.fs_text_title_1"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))

          // 4. 说明区
          Column({ space: 8 }) {
            Text($r("app.string.fs_tool_demo_status"))
              .fontSize($r("app.float.fs_text_body_lg"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .textAlign(TextAlign.Center)

            Text(this.getDescription())
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .textAlign(TextAlign.Center)
              .lineHeight(22)
          }
          .padding({ left: 32, right: 32 })

          // 5. 操作区
          Column({ space: 12 }) {
            Button($r("app.string.fs_tool_open_demo"))
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_inverse"))
              .backgroundColor($r("app.color.fs_color_primary"))
              .borderRadius($r("app.float.fs_radius_md"))
              .height($r("app.float.fs_height_button"))
              .width(200)
              .onClick((): void => {
                this.navPathStack.pushPath({
                  name: RouteTable.WEB_CONTAINER,
                  param: new WebContainerArgs(this.getDemoUrl(), this.getTitle(), false)
                });
              })

            Text($r("app.string.fs_tool_back_home"))
              .fontSize($r("app.float.fs_text_body"))
              .fontColor($r("app.color.fs_color_text_secondary"))
              .onClick((): void => { this.navPathStack.pop(); })
          }
          .margin({ top: 16 })
        }
        .layoutWeight(1)
        .width("100%")
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 6. 底部小字
        Text($r("app.string.fs_tool_demo_note"))
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_text_tertiary"))
          .margin({ bottom: 32 })
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.fs_color_background"))
    }
    .hideTitleBar(true)
  }

  private getTitle(): string {
    if (this.toolId === "scan") {
      return "扫码";
    }
    if (this.toolId === "translate") {
      return "翻译";
    }
    if (this.toolId === "file") {
      return "文件";
    }
    return "网页";
  }

  private getTitleResource(): Resource {
    if (this.toolId === "scan") {
      return $r("app.string.fs_tool_title_scan");
    }
    if (this.toolId === "translate") {
      return $r("app.string.fs_tool_title_translate");
    }
    if (this.toolId === "file") {
      return $r("app.string.fs_tool_title_file");
    }
    return $r("app.string.fs_tool_title_web");
  }

  private getIcon(): string {
    if (this.toolId === "scan") {
      return "⊞";
    }
    if (this.toolId === "translate") {
      return "A↔文";
    }
    if (this.toolId === "file") {
      return "📄";
    }
    return "🌐";
  }

  private getDescription(): Resource {
    if (this.toolId === "scan") {
      return $r("app.string.fs_tool_desc_scan");
    }
    if (this.toolId === "translate") {
      return $r("app.string.fs_tool_desc_translate");
    }
    if (this.toolId === "file") {
      return $r("app.string.fs_tool_desc_file");
    }
    return $r("app.string.fs_tool_desc_web");
  }

  private getDemoUrl(): string {
    return "https://mock-web/tool/" + this.toolId;
  }
}
