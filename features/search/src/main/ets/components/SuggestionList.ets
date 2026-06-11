/**
 * @file SuggestionList.ets
 * @description 输入态建议列表。每行 56 高,左放大镜 + 中关键词(高亮)+ 右回填箭头。
 *
 * 设计要点:
 * 1. 关键词高亮:把 suggestion.keyword 按 inputKeyword 前缀切分,
 *    前缀用 primary 绿色加粗,后缀用 text.primary 默认色。
 *    本期只做前缀匹配(对应 Mock 词典实际形态:全是 "arkts xxx"),
 *    严格意义的子串高亮留作扩展练习。
 *
 * 2. 行 56 高 + 1px 底分割线(PRD §04-02 §2)。
 *
 * 3. 两个回调分工(PRD §04-02 §3):
 *    - onItemTap(keyword)  整行点击 -> 跳 SearchResult
 *    - onFillTap(keyword)  右箭头点击 -> 仅回填输入框,不触发搜索
 *
 * 4. type === "HOT" 的建议项在关键词右侧显示 🔥(放在 Span 之后)。
 */

import { SearchSuggestion } from "@flowsearch/base";

@ComponentV2
export struct SuggestionList {
  /** 输入的关键词(用于前缀高亮)。 */
  @Param inputKeyword: string = "";

  @Param suggestions: Array<SearchSuggestion> = new Array();

  @Event onItemTap: (keyword: string) => void = (_k: string): void => {};
  @Event onFillTap: (keyword: string) => void = (_k: string): void => {};

  build() {
    Column() {
      ForEach(this.suggestions, (s: SearchSuggestion): void => {
        this.buildRow(s);
      }, (s: SearchSuggestion): string => s.suggestionId)
    }
    .width("100%")
  }

  @Builder
  buildRow(s: SearchSuggestion) {
    Column() {
      Row() {
        Text("⌕")
          .fontSize(16)
          .fontColor($r("app.color.fs_color_text_tertiary"))
          .width(20)
          .textAlign(TextAlign.Center)
          .margin({ right: $r("app.float.fs_space_md") })

        // 高亮文本:前缀绿色加粗 + 后缀普通
        Text() {
          Span(this.matchedPrefix(s.keyword))
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .fontWeight(FontWeight.Bold)
          Span(this.remainSuffix(s.keyword))
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_text_primary"))
          if (s.type === "HOT") {
            Span("  🔥").fontSize(14)
          }
        }
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 右侧回填箭头
        Text("↖")
          .fontSize(16)
          .fontColor($r("app.color.fs_color_text_tertiary"))
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .margin({ left: $r("app.float.fs_space_sm") })
          .onClick((): void => { this.onFillTap(s.keyword); })
      }
      .width("100%")
      .height(56)
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg")
      })
      .alignItems(VerticalAlign.Center)
      .onClick((): void => { this.onItemTap(s.keyword); })

      Divider()
        .strokeWidth(1)
        .color($r("app.color.fs_color_border"))
    }
  }

  /** 取 suggestion.keyword 的前缀(命中 inputKeyword 的部分)。 */
  private matchedPrefix(full: string): string {
    const kw: string = this.inputKeyword.trim().toLowerCase();
    if (kw.length === 0) {
      return "";
    }
    const lower: string = full.toLowerCase();
    if (lower.indexOf(kw) === 0) {
      // 前缀命中:返回原 full 的对应字符数(保留大小写 / 中文)
      return full.substring(0, kw.length);
    }
    return "";
  }

  /** 取 suggestion.keyword 去掉高亮前缀后剩下的部分。 */
  private remainSuffix(full: string): string {
    const kw: string = this.inputKeyword.trim().toLowerCase();
    if (kw.length === 0) {
      return full;
    }
    const lower: string = full.toLowerCase();
    if (lower.indexOf(kw) === 0) {
      return full.substring(kw.length);
    }
    return full;
  }
}
