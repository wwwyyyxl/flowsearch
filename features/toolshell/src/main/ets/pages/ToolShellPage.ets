/**
 * @file ToolShellPage.ets
 * @description 工具壳页(P07 ToolShell)。S22 升级:扫码/文件/翻译接入真实系统能力。
 *
 * 设计稿参考:
 *   stitch_flowsearch_06_07_08/flowsearch_tool_shell_variants/code.html
 *   PRD: FlowSearch-PRD/04-页面规约/07-tool-shell.md
 *
 * S22 变更:
 *   - scan → 渲染 ScanTool(ScanKit 系统扫码),结果为 URL 时跳转 WebContainer
 *   - file → 渲染 FileTool(DocumentViewPicker 系统文件选择器)
 *   - translate → 跳转 WebContainer 打开在线翻译
 *   - web  → 保持演示布局(mock URL)
 */

import { RouteTable, WebContainerArgs } from "@flowsearch/router";
import { ScanTool } from "../components/ScanTool";
import { FileTool } from "../components/FileTool";

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

        // 2. 主体(按 toolId 条件渲染)
        if (this.toolId === "scan") {
          // 扫码:渲染 ScanTool 组件
          ScanTool({
            onScanResult: (value: string): void => { this.handleScanResult(value); }
          })
          .layoutWeight(1)
        } else if (this.toolId === "file") {
          // 文件:渲染 FileTool 组件
          FileTool()
            .layoutWeight(1)
        } else if (this.toolId === "translate") {
          // 翻译:跳转在线翻译页面
          this.TranslateBody()
        } else {
          // 网页 / 默认:保持演示布局
          this.DemoBody()
        }

        // 3. 底部小字
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

  /**
   * 翻译工具:展示说明 + 按钮跳转在线翻译。
   */
  @Builder
  TranslateBody() {
    Column({ space: 16 }) {
      Stack() {
        Circle({ width: 96, height: 96 })
          .fill($r("app.color.fs_color_primary_tint"))
        Text("A↔文")
          .fontSize(32)
          .fontColor($r("app.color.fs_color_primary"))
      }
      .width(96)
      .height(96)

      Text(this.getTitleResource())
        .fontSize($r("app.float.fs_text_title_1"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))

      Text("在线翻译服务，支持多语言互译")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      Button("打开在线翻译")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_inverse"))
        .backgroundColor($r("app.color.fs_color_primary"))
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(200)
        .onClick((): void => {
          this.navPathStack.pushPath({
            name: RouteTable.WEB_CONTAINER,
            param: new WebContainerArgs("https://translate.google.com", "在线翻译", false)
          });
        })

      Text($r("app.string.fs_tool_back_home"))
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .onClick((): void => { this.navPathStack.pop(); })
    }
    .layoutWeight(1)
    .width("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 默认演示布局(web 工具 / 兜底)。
   */
  @Builder
  DemoBody() {
    Column({ space: 16 }) {
      Stack() {
        Circle({ width: 96, height: 96 })
          .fill($r("app.color.fs_color_primary_tint"))
        Text(this.getIcon())
          .fontSize(48)
          .fontColor($r("app.color.fs_color_primary"))
      }
      .width(96)
      .height(96)

      Text(this.getTitleResource())
        .fontSize($r("app.float.fs_text_title_1"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))

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
  }

  /**
   * 扫码结果处理。URL → 跳转 WebContainer,其他 → 保留在结果页。
   */
  private handleScanResult(value: string): void {
    if (value.startsWith("http://") || value.startsWith("https://")) {
      this.navPathStack.pushPath({
        name: RouteTable.WEB_CONTAINER,
        param: new WebContainerArgs(value, "扫码结果", false)
      });
    }
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
