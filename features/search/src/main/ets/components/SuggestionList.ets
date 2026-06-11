/**
 * @file SuggestionList.ets
 * @description 输入态建议列表。每行 56 高,左放大镜 + 中关键词(高亮)+ 右回填箭头。
 *
 * 设计要点:
 * 1. 关键词高亮:把 suggestion.keyword 按 inputKeyword 子串切分,
 *    匹配部分用 primary 绿色加粗,前后用 text.primary 默认色。
 *    S8 升级:从仅前缀匹配改为任意子串匹配(如输入 "nav" 高亮
 *    "Compose **Nav**igation 教程" 中的 "Nav")。
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

        // 高亮文本:子串匹配(前 + 匹配绿粗体 + 后)
        Text() {
          Span(this.beforeMatch(s.keyword))
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_text_primary"))
          Span(this.matchText(s.keyword))
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .fontWeight(FontWeight.Bold)
          Span(this.afterMatch(s.keyword))
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

  /** 子串匹配起始位置(-1 = 未命中)。大小写不敏感。 */
  private matchStartIndex(full: string): number {
    const kw: string = this.inputKeyword.trim().toLowerCase();
    if (kw.length === 0) {
      return -1;
    }
    return full.toLowerCase().indexOf(kw);
  }

  /** 匹配子串之前的文本。 */
  private beforeMatch(full: string): string {
    const idx: number = this.matchStartIndex(full);
    if (idx <= 0) {
      return "";
    }
    return full.substring(0, idx);
  }

  /** 匹配的子串(保留原始大小写)。 */
  private matchText(full: string): string {
    const idx: number = this.matchStartIndex(full);
    if (idx < 0) {
      return "";
    }
    const kw: string = this.inputKeyword.trim();
    return full.substring(idx, idx + kw.length);
  }

  /** 匹配子串之后的文本。 */
  private afterMatch(full: string): string {
    const idx: number = this.matchStartIndex(full);
    if (idx < 0) {
      return full;
    }
    const kw: string = this.inputKeyword.trim();
    return full.substring(idx + kw.length);
  }
}
