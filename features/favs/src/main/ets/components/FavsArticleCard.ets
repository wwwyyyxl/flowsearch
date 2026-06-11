/**
 * @file FavsArticleCard.ets
 * @description 收藏/历史列表中的文章卡片(简化版)。
 *
 * 为什么不复用 features/home 的 ArticleCard?
 *   避免循环依赖:favs 不 import home。
 *   本卡片只展示标题 + 来源 + 摘要 + 取消收藏按钮,够用。
 *   与 ArticleCard 的视觉差异:无角标分类、无关键词高亮。
 *
 * 设计要点:
 * - @Param article 接收数据
 * - @Event onCardTap 点击整卡(跳 WebContainer)
 * - @Event onRemoveTap 取消收藏/删除历史
 */

import { Article } from "@flowsearch/base";

@ComponentV2
export struct FavsArticleCard {
  @Param article: Article = new Article({
    articleId: "", title: "", summary: "", coverUrl: null, coverPlaceholder: "",
    categoryTag: "WEB", source: "", publishTime: "", publishTimeDisplay: "",
    targetUrl: "", favorite: false, channelId: ""
  });
  @Param showRemoveButton: boolean = true;
  @Param removeLabel: string = "取消收藏";
  @Event onCardTap: (article: Article) => void = (_a: Article): void => {};
  @Event onRemoveTap: (articleId: string) => void = (_id: string): void => {};

  build() {
    Row() {
      Column() {
        Text(this.article.title)
          .fontSize($r("app.float.fs_text_body"))
          .fontWeight(FontWeight.Medium)
          .fontColor($r("app.color.fs_color_text_primary"))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.article.summary)
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_text_secondary"))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        Row() {
          Text(this.article.source)
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .layoutWeight(1)

          if (this.showRemoveButton) {
            Text(this.removeLabel)
              .fontSize($r("app.float.fs_text_caption"))
              .fontColor($r("app.color.fs_color_danger"))
              .onClick((): void => { this.onRemoveTap(this.article.articleId); })
          }
        }
        .width("100%")
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width("100%")
    .padding({
      left: $r("app.float.fs_space_lg"),
      right: $r("app.float.fs_space_lg"),
      top: $r("app.float.fs_space_md"),
      bottom: $r("app.float.fs_space_md")
    })
    .onClick((): void => { this.onCardTap(this.article); })
  }
}
