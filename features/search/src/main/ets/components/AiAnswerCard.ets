/**
 * @file AiAnswerCard.ets
 * @description SearchResult 顶部 AI 速答卡。Mock 占位,不接真实 LLM。
 *
 * 设计要点(PRD §04-03 §2):
 * 1. 背景 color.primary.tint(浅绿),圆角 16,padding 16。
 * 2. 顶部行:✦ icon + "AI 速答" 加粗 + 右侧 "Mock" chip(描边)。
 * 3. 中部:summary 多行(line-height 1.6,本期用 lineSpacing 近似)。
 * 4. 关联问题:横向流式胶囊(最多 3 个),点击发送新搜索。
 * 5. 底部:免责小字。
 * 6. data == null 时父组件不渲染本组件(本期 PRD 强约束)。
 */

import { AiQuickAnswer } from "@flowsearch/base";

@ComponentV2
export struct AiAnswerCard {
  @Param answer: AiQuickAnswer = new AiQuickAnswer("", "", new Array<string>(), "");

  /** 点击关联问题胶囊回调:新关键词触发 SearchResult 跳转。 */
  @Event onRelatedTap: (question: string) => void = (_q: string): void => {};

  /** 点击"复制"按钮回调:复制 summary 到剪贴板。 */
  @Event onCopyTap: () => void = (): void => {};

  build() {
    Column() {
      // 顶部行:icon + "AI 速答" + Mock chip
      Row() {
        Text("✦")
          .fontSize(14)
          .fontColor($r("app.color.fs_color_primary"))
          .fontWeight(FontWeight.Bold)
          .margin({ right: 6 })

        Text($r("app.string.fs_search_ai_answer"))
          .fontSize($r("app.float.fs_text_body"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_primary"))
          .layoutWeight(1)

        // "Mock" chip
        Text($r("app.string.fs_search_ai_mock"))
          .fontSize(10)
          .fontColor($r("app.color.fs_color_primary"))
          .fontWeight(FontWeight.Medium)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .border({ width: 1, color: $r("app.color.fs_color_primary") })
          .borderRadius($r("app.float.fs_radius_full"))
      }
      .width("100%")
      .alignItems(VerticalAlign.Center)

      // summary 正文
      Text(this.answer.summary)
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_primary"))
        .lineHeight(22)
        .width("100%")
        .margin({ top: $r("app.float.fs_space_md") })

      // 关联问题胶囊(最多 3 个,PRD §04-03 §6)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.relatedQuestionsCapped(), (q: string): void => {
          this.buildRelatedChip(q);
        }, (q: string): string => q)
      }
      .width("100%")
      .margin({ top: $r("app.float.fs_space_md") })

      // 底部分隔线 + 免责
      Divider()
        .strokeWidth(1)
        .color($r("app.color.fs_color_border"))
        .opacity(0.3)
        .margin({ top: $r("app.float.fs_space_md") })

      Row() {
        Text(this.answer.disclaimer)
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_text_tertiary"))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text($r("app.string.fs_search_copy"))
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_primary"))
          .margin({ left: $r("app.float.fs_space_sm") })
          .onClick((): void => { this.onCopyTap(); })
      }
      .width("100%")
      .margin({ top: $r("app.float.fs_space_sm") })
    }
    .width("100%")
    .padding($r("app.float.fs_space_lg"))
    .backgroundColor($r("app.color.fs_color_primary_tint"))
    .borderRadius($r("app.float.fs_radius_lg"))
  }

  @Builder
  buildRelatedChip(q: string) {
    Text(q)
      .fontSize($r("app.float.fs_text_body"))
      .fontColor($r("app.color.fs_color_text_primary"))
      .height(32)
      .padding({ left: $r("app.float.fs_space_md"), right: $r("app.float.fs_space_md") })
      .backgroundColor($r("app.color.fs_color_surface"))
      .border({ width: 1, color: $r("app.color.fs_color_border") })
      .borderRadius($r("app.float.fs_radius_lg"))
      .margin({ right: $r("app.float.fs_space_sm"), bottom: $r("app.float.fs_space_sm") })
      .onClick((): void => { this.onRelatedTap(q); })
  }

  /** PRD §04-03 §6:关联问题超过 3 条只显示前 3。 */
  private relatedQuestionsCapped(): Array<string> {
    if (this.answer.relatedQuestions.length <= 3) {
      return this.answer.relatedQuestions;
    }
    return this.answer.relatedQuestions.slice(0, 3);
  }
}
