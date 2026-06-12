/**
 * @file SearchResultCard.ets
 * @description 搜索结果卡片,样式与 home/ArticleCard 同源。
 *
 * 设计要点(PRD §04-03 §2):
 * 1. 紧凑形态(对照设计稿):无白卡圆角,直接横向排布;
 *    与 home ArticleCard 的"白底圆角卡"略有差异 -- 是 PRD 留的视觉差异点。
 * 2. 左侧 56×56 圆角分类色块(按 categoryTag 上色);
 * 3. 右侧:标题(2 行 + Ellipsis)/ 摘要(2 行)/ source · time。
 * 4. 关键词高亮:在标题里把 keyword 出现的字符串用 primary 绿色加粗;
 *    本期实现"首次匹配"高亮(简单且足够演示),
 *    全部匹配 + 区分 highlightTitle/highlightSummary 留作扩展练习。
 * 5. 收藏按钮放在右下,文案"已收藏 / 收藏"。
 */

import { Article, CategoryTag } from "@flowsearch/base";
import { LazyImage } from "@flowsearch/ui";

interface CategoryStyle {
  bg: ResourceColor;
  text: ResourceColor;
  label: string;
}

@ReusableV2
@ComponentV2
export struct SearchResultCard {
  @Param article: Article = new Article({
    articleId: "",
    title: "",
    summary: "",
    coverUrl: null,
    coverPlaceholder: "",
    categoryTag: "WEB",
    source: "",
    publishTime: "",
    publishTimeDisplay: "",
    targetUrl: "",
    favorite: false,
    channelId: ""
  });

  /** 当前搜索关键词,用于标题高亮。 */
  @Param keyword: string = "";

  @Event onCardTap: (article: Article) => void = (_a: Article): void => {};
  @Event onFavoriteTap: (articleId: string) => void = (_id: string): void => {};

  build() {
    Row() {
      // 左侧分类色块
      this.buildBadge()

      // 右侧内容
      Column() {
        // 标题(关键词高亮)
        Text() {
          this.buildHighlightedSpans(this.article.title)
        }
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 摘要
        Text(this.article.summary)
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_secondary"))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        // 底部:source · time + 收藏
        Row() {
          Text(`${this.article.source} · ${this.article.publishTimeDisplay}`)
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.article.favorite ? "已收藏" : "收藏")
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .accessibilityText(this.article.favorite
              ? `取消收藏 ${this.article.title}`
              : `收藏 ${this.article.title}`)
            .onClick((): void => { this.onFavoriteTap(this.article.articleId); })
        }
        .width("100%")
        .margin({ top: $r("app.float.fs_space_sm") })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r("app.float.fs_space_md") })
    }
    .width("100%")
    .padding({ top: $r("app.float.fs_space_md"), bottom: $r("app.float.fs_space_md") })
    .alignItems(VerticalAlign.Top)
    .onClick((): void => { this.onCardTap(this.article); })
  }

  @Builder
  buildBadge() {
    if (this.article.coverUrl !== null && this.article.coverUrl.length > 0) {
      // S19:有封面 URL → LazyImage 加载
      LazyImage({
        src: this.article.coverUrl,
        placeholderText: this.article.coverPlaceholder,
        imgWidth: "56vp",
        imgHeight: "56vp",
        imgBorderRadius: "8vp"
      })
      .flexShrink(0)
    } else {
      // 无封面:分类色块
      Stack() {
        Column()
          .width(56)
          .height(56)
          .borderRadius($r("app.float.fs_radius_md"))
          .backgroundColor(this.styleOf(this.article.categoryTag).bg)

        Text(this.styleOf(this.article.categoryTag).label)
          .fontSize($r("app.float.fs_text_caption"))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.styleOf(this.article.categoryTag).text)
      }
      .width(56)
      .height(56)
      .flexShrink(0)
    }
  }

  /**
   * 把 title 按 keyword 首次出现位置切成 3 段:[before][match][after],
   * 中间段用 primary 绿色加粗。keyword 为空或未命中则整段普通色。
   */
  @Builder
  buildHighlightedSpans(title: string) {
    if (this.keyword.trim().length === 0) {
      Span(title)
        .fontColor($r("app.color.fs_color_text_primary"))
    } else {
      // ArkTS 不支持把判断结果拆成多个 Span 还要返回值,
      // 直接在 buildHighlightedSpans 里用 if 分支输出 Span 组合。
      this.renderSplit(title)
    }
  }

  @Builder
  renderSplit(title: string) {
    if (this.findMatchStart(title) < 0) {
      Span(title)
        .fontColor($r("app.color.fs_color_text_primary"))
    } else {
      Span(title.substring(0, this.findMatchStart(title)))
        .fontColor($r("app.color.fs_color_text_primary"))
      Span(title.substring(this.findMatchStart(title), this.findMatchStart(title) + this.keyword.length))
        .fontColor($r("app.color.fs_color_primary"))
        .fontWeight(FontWeight.Bold)
      Span(title.substring(this.findMatchStart(title) + this.keyword.length))
        .fontColor($r("app.color.fs_color_text_primary"))
    }
  }

  /** 查找 keyword 在 title 中首次匹配位置(大小写不敏感)。 */
  private findMatchStart(title: string): number {
    if (this.keyword.trim().length === 0) {
      return -1;
    }
    return title.toLowerCase().indexOf(this.keyword.toLowerCase());
  }

  private styleOf(tag: CategoryTag): CategoryStyle {
    if (tag === "TOOL") {
      return {
        bg: $r("app.color.fs_color_tag_tool_bg"),
        text: $r("app.color.fs_color_tag_tool_text"),
        label: "工具"
      };
    }
    if (tag === "VIDEO") {
      return {
        bg: $r("app.color.fs_color_tag_video_bg"),
        text: $r("app.color.fs_color_tag_video_text"),
        label: "视频"
      };
    }
    if (tag === "AI") {
      return {
        bg: $r("app.color.fs_color_tag_ai_bg"),
        text: $r("app.color.fs_color_tag_ai_text"),
        label: "AI"
      };
    }
    return {
      bg: $r("app.color.fs_color_tag_web_bg"),
      text: $r("app.color.fs_color_tag_web_text"),
      label: "Web"
    };
  }
}
