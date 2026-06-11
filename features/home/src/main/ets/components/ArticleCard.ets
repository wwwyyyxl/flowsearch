/**
 * @file ArticleCard.ets
 * @description Feed 列表单条卡片。对应 PRD §04-01-home.md §2 内容流卡片。
 *
 * 设计要点(简历主线 3:LazyForEach):
 *
 * 1. ⚠️ ViewHolder 复用暂未启用:
 *    @Reusable 装饰器只支持 V1 @Component,与 @ComponentV2 不能混用;
 *    V2 对应的 @ReusableV2 SDK 6.1.1 支持度未验证,本期不上,留 S6 性能打磨阶段处理。
 *    本期数据量小(单频道 < 10 条),不复用对体验无影响。
 *    简历讲法:LazyForEach + cachedCount 即可覆盖核心性能场景,
 *    @ReusableV2 是数据量上量(500+ 条) 时的进一步优化。
 *
 * 2. categoryTag -> 角标色映射:
 *    走 commons/theme 的 fs_color_tag_*_bg/text token,switch 集中一处;
 *    避免散落在 if/else 里。
 *
 * 3. 文字裁剪:
 *    标题 maxLines: 2 + TextOverflow.Ellipsis;摘要同理。
 *    避免长文章撑爆卡片高度。
 */

import { Article, CategoryTag } from "@flowsearch/base";

interface CategoryStyle {
  bg: ResourceColor;
  text: ResourceColor;
  label: string;
}

@ComponentV2
export struct ArticleCard {
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

  /** 点击卡片回调,外抛 article,父组件决定跳哪。 */
  @Event onCardClick: (article: Article) => void = (_a: Article): void => {};

  /** 点击右下"收藏"按钮回调,外抛 articleId。 */
  @Event onFavoriteToggle: (articleId: string) => void = (_id: string): void => {};

  build() {
    Row() {
      this.buildCover()

      Column() {
        // 标题(最多 2 行)
        Text(this.article.title)
          .fontSize($r("app.float.fs_text_title_2"))
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.fs_color_text_primary"))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 摘要(最多 2 行)
        Text(this.article.summary)
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_secondary"))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        // 底部行:source · time + 右下角收藏按钮
        Row() {
          Text(`${this.article.source} · ${this.article.publishTimeDisplay}`)
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_secondary"))
            .layoutWeight(1)

          Text(this.article.favorite ? "已收藏" : "收藏")
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .onClick((): void => { this.onFavoriteToggle(this.article.articleId); })
        }
        .width("100%")
        .margin({ top: $r("app.float.fs_space_sm") })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r("app.float.fs_space_md") })
    }
    .width("100%")
    .padding($r("app.float.fs_space_lg"))
    .backgroundColor($r("app.color.fs_color_surface"))
    .borderRadius($r("app.float.fs_radius_lg"))
    .onClick((): void => { this.onCardClick(this.article); })
  }

  /** 左侧封面占位:56x56 圆角方块,按 categoryTag 取颜色。 */
  @Builder
  buildCover() {
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
  }

  /** categoryTag -> 角标样式映射(PRD §02 §1 卡片角标颜色)。 */
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
    // 默认 WEB
    return {
      bg: $r("app.color.fs_color_tag_web_bg"),
      text: $r("app.color.fs_color_tag_web_text"),
      label: "Web"
    };
  }
}
