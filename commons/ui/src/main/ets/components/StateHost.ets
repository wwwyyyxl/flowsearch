/**
 * @file StateHost.ets
 * @description 通用页面状态分发组件。
 *
 * 简历主线 4 的 UI 层落地:把 PageState<T> 翻译成对应的 UI(Loading 骨架 / Empty 空态 /
 * Error 错误页 / Offline 黄条 + 内容)。Content 状态把 T 数据交给 builder 渲染。
 *
 * 设计要点:
 * 1. 用 @ComponentV2 + @Param,V2 装饰器全程禁混 V1(@State / @Prop / @Link 禁用)。
 * 2. contentBuilder 用 @BuilderParam,这是 ArkUI 把"内容渲染方式"作为参数传入的标准模式。
 * 3. 不持有任何状态,完全是受控组件(stateless):状态由调用方 VM 提供,组件只渲染。
 * 4. data: T 通过 @Param 传入(因为 PageState 是不可变的,只比对 kind 不够,需把 data 单独拎)。
 *
 * ArkTS ↔ Kotlin 对照:
 *   @ComponentV2 struct StateHost<T> ↔ @Composable fun <T> StateHost(...)
 *   @BuilderParam content ↔ content: @Composable (T) -> Unit
 *   when(state.kind) { ... } ↔ if (state.isXxx()) { ... }
 *
 * 用法(伪代码):
 *   StateHost({
 *     state: this.vm.state,
 *     onRetry: () => this.vm.retry(),
 *     contentBuilder: () => { Text(this.vm.state.data.title) }
 *   })
 */

import { PageState } from "@flowsearch/base";

@ComponentV2
export struct StateHost {
  /**
   * VM 当前页面状态(非泛型,ArkTS 限制)。父组件持有 @ObservedV2 标注的 VM,
   * vm.state 是 @Trace 字段;当 VM 创建新的 PageState 实例赋给 state 时,
   * 父组件重渲触发本组件重建。
   * 业务数据通过 state.data 暴露(Object 类型),在 contentBuilder 里 cast 到具体类型。
   */
  @Param state: PageState = PageState.idle();

  /** 错误态/空态点击重试的回调。可空,空态可不传(此时不显示重试按钮)。 */
  @Param onRetry: () => void = () => {};

  /** Empty 态主标题。各页面文案不同,见 PRD §05-异常态规约。 */
  @Param emptyTitle: string = "暂无内容";

  /** Empty 态副标题。 */
  @Param emptySubtitle: string = "";

  /** 内容区构建器。仅在 Content / LoadingMore / Refreshing / Offline 状态下调用。 */
  @BuilderParam contentBuilder: () => void = this.defaultContentBuilder;

  @Builder
  defaultContentBuilder() {
    Text("(empty content builder)")
  }

  build() {
    Column() {
      // Offline 顶部黄条(数据来自缓存)
      if (this.state.isOffline()) {
        this.buildOfflineBar()
      }

      // 内容/状态分发
      if (this.state.isIdle() || this.state.isLoading()) {
        this.buildLoading()
      } else if (this.state.isEmpty()) {
        this.buildEmpty()
      } else if (this.state.isError()) {
        this.buildError()
      } else {
        // Content / LoadingMore / Refreshing / Offline 都渲染内容
        this.contentBuilder()
      }
    }
    .width("100%")
    .height("100%")
  }

  @Builder
  buildOfflineBar() {
    Row() {
      Text($r("app.string.fs_state_offline_hint"))
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_warning"))
        .margin({ left: $r("app.float.fs_space_lg") })
    }
    .width("100%")
    .height(56)
    .backgroundColor($r("app.color.fs_color_offline_bar_bg"))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildLoading() {
    // 简化版骨架:3 张灰矩形。后续可在各 features 里覆盖具体骨架样式。
    Column({ space: 12 }) {
      ForEach([1, 2, 3], (_: number, i: number) => {
        Column()
          .width("100%")
          .height(96)
          .borderRadius($r("app.float.fs_radius_lg"))
          .backgroundColor($r("app.color.fs_color_border"))
      })
    }
    .width("100%")
    .padding($r("app.float.fs_space_lg"))
  }

  @Builder
  buildEmpty() {
    Column() {
      // 线性 icon 占位(后续接入资源 SVG)
      Circle({ width: 80, height: 80 })
        .fill(Color.Transparent)
        .stroke($r("app.color.fs_color_text_tertiary"))
        .strokeWidth(1.5)

      Text(this.emptyTitle)
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .margin({ top: $r("app.float.fs_space_lg") })

      if (this.emptySubtitle.length > 0) {
        Text(this.emptySubtitle)
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_secondary"))
          .margin({ top: $r("app.float.fs_space_sm") })
      }
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildError() {
    Column() {
      // 红色圆 + ! 占位
      Stack() {
        Circle({ width: 64, height: 64 })
          .fill(Color.Transparent)
          .stroke($r("app.color.fs_color_danger"))
          .strokeWidth(2)
        Text("!")
          .fontSize(24)
          .fontColor($r("app.color.fs_color_danger"))
          .fontWeight(FontWeight.Bold)
      }

      Text($r("app.string.fs_state_load_error"))
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .margin({ top: $r("app.float.fs_space_lg") })

      Text($r("app.string.fs_state_error_code") + ": " + this.state.errorCode)
        .fontSize($r("app.float.fs_text_caption"))
        .fontColor($r("app.color.fs_color_text_tertiary"))
        .margin({ top: $r("app.float.fs_space_sm") })

      Button($r("app.string.fs_state_retry"))
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontColor($r("app.color.fs_color_text_inverse"))
        .backgroundColor($r("app.color.fs_color_primary"))
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(160)
        .margin({ top: $r("app.float.fs_space_2xl") })
        .onClick(() => {
          this.onRetry()
        })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
