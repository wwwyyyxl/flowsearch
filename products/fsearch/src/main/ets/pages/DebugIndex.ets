/**
 * @file DebugIndex.ets
 * @description S0 5 态状态机演示页(原 Index.ets)。
 *
 * 这是 S0 阶段验证 commons 4 个 HAR 联通的活证物,留作:
 *   1. 简历录屏可补素材;
 *   2. 后续调试 PageState 时切到这里独立验证,不污染主流程;
 *   3. 写文档讲 "S0 完工" 时可贴截图。
 *
 * S1 之后,Index.ets 改作 Navigation 路由根 + 默认装 HomePage,
 * 本文件移出 main_pages.json,不再作为 @Entry 启动入口。
 * 如果以后要单独跑这页,在 main_pages.json 临时加 "pages/DebugIndex" 即可。
 */

import { PageState } from "@flowsearch/base";
import { RouteTable } from "@flowsearch/router";
import { StateHost } from "@flowsearch/ui";

@ObservedV2
class DemoViewModel {
  @Trace state: PageState = PageState.idle();

  startLoading(): void {
    this.state = PageState.loading();
  }

  loadSuccess(): void {
    this.state = PageState.content("S0 路由 + 状态机 + 主题 token 全部跑通!");
  }

  loadEmpty(): void {
    this.state = PageState.empty();
  }

  loadFailed(): void {
    this.state = PageState.error("500", "服务器开小差了");
  }

  reset(): void {
    this.state = PageState.idle();
  }
}

@Entry
@ComponentV2
struct DebugIndex {
  @Local vm: DemoViewModel = new DemoViewModel();

  build() {
    Column() {
      Text("FlowSearch · S0 基础设施验证")
        .fontSize($r("app.float.fs_text_title_1"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .margin({ top: $r("app.float.fs_space_2xl"), bottom: $r("app.float.fs_space_lg") })

      Text(`首页路由名: ${RouteTable.HOME}`)
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .margin({ bottom: $r("app.float.fs_space_xl") })

      Column() {
        StateHost({
          state: this.vm.state,
          onRetry: (): void => { this.vm.startLoading(); },
          emptyTitle: "暂无数据",
          emptySubtitle: "点下面按钮试试别的状态",
          contentBuilder: (): void => { this.buildContent(); }
        })
      }
      .layoutWeight(1)
      .width("100%")

      Row({ space: 8 }) {
        this.buildStateButton("Loading", (): void => { this.vm.startLoading(); });
        this.buildStateButton("Content", (): void => { this.vm.loadSuccess(); });
        this.buildStateButton("Empty", (): void => { this.vm.loadEmpty(); });
      }
      .width("100%")
      .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })

      Row({ space: 8 }) {
        this.buildStateButton("Error", (): void => { this.vm.loadFailed(); });
        this.buildStateButton("Idle", (): void => { this.vm.reset(); });
      }
      .width("100%")
      .padding($r("app.float.fs_space_lg"))
    }
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.fs_color_background"))
  }

  @Builder
  buildContent() {
    Column() {
      Text((this.vm.state.data as string | null) ?? "")
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontColor($r("app.color.fs_color_primary"))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .padding($r("app.float.fs_space_2xl"))
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildStateButton(label: string, onTap: () => void) {
    Button(label)
      .fontSize($r("app.float.fs_text_body"))
      .fontColor($r("app.color.fs_color_text_inverse"))
      .backgroundColor($r("app.color.fs_color_primary"))
      .borderRadius($r("app.float.fs_radius_md"))
      .height($r("app.float.fs_height_button"))
      .layoutWeight(1)
      .onClick(onTap)
  }
}
