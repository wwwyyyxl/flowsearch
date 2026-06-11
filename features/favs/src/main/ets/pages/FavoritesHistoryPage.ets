/**
 * @file FavoritesHistoryPage.ets
 * @description 收藏与历史页面(P05 FavoritesHistory)。双 Tab:收藏 / 历史。
 *
 * 设计要点:
 *
 * 1. NavDestination 包裹,与 SearchInputPage / SearchResultPage 同型。
 *    @Param navPathStack 接收路由栈,@Param defaultTab 由 FavsHistoryArgs.tab 传入。
 *
 * 2. 顶栏 + Tabs 永久渲染,主体按 tab 分支:
 *    收藏 Tab:PageState 四态分发(Loading/Empty/Content/Error),Content 用 LazyForEach
 *    历史 Tab:ForEach(历史不会上千条,不需要 LazyForEach)
 *
 * 3. FavsArticleCard 自包含在 features/favs 内(避免跨 HAR import ArticleCard):
 *    只展示标题+来源+摘要+取消收藏/删除按钮。
 *
 * 4. @Builder 禁令:
 *    buildFavoritesTab / buildHistoryTab 内不声明 const,
 *    数据在 build() 体算好通过参数传入 @Builder。
 *
 * 5. Context 注入:
 *    aboutToAppear() 调 getContext(this) 传给 vm.init(),
 *    VM -> Repository -> PreferencesHelper 全链路。
 */

import { PageState, Article, SearchHistoryItem } from "@flowsearch/base";
import { RouteTable, WebContainerArgs, FavsHistoryArgs } from "@flowsearch/router";
import { FavsViewModel } from "../viewmodel/FavsViewModel";
import { FavsTabs } from "../components/FavsTabs";
import { FavsArticleCard } from "../components/FavsArticleCard";

@ComponentV2
export struct FavoritesHistoryPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param defaultTab: string = "favorites";

  @Local vm: FavsViewModel = new FavsViewModel();

  aboutToAppear(): void {
    this.vm.init(getContext(this), this.defaultTab);
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶栏
        Row() {
          Text("←")
            .fontSize(20)
            .fontColor($r("app.color.fs_color_text_primary"))
            .onClick((): void => { this.navPathStack.pop(); })
          Text("收藏与历史")
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

        // 2. 双 Tab
        FavsTabs({
          selectedTab: this.vm.currentTab,
          onTabChange: (tab: string): void => { this.vm.switchTab(tab); }
        })

        // 3. 主体内容(按 tab 分支)
        Column() {
          if (this.vm.currentTab === "favorites") {
            this.buildFavoritesTab()
          } else {
            this.buildHistoryTab()
          }
        }
        .layoutWeight(1)
        .width("100%")
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.fs_color_background"))
    }
    .hideTitleBar(true)
  }

  // ============================================================
  // 收藏 Tab(PageState 四态分发)
  // ============================================================
  @Builder
  buildFavoritesTab() {
    if (this.vm.favState.isLoading() || this.vm.favState.isIdle()) {
      this.buildFavLoading()
    } else if (this.vm.favState.isEmpty()) {
      this.buildFavEmpty()
    } else if (this.vm.favState.isError()) {
      this.buildFavError()
    } else {
      this.buildFavContent()
    }
  }

  @Builder
  buildFavLoading() {
    Column() {
      Column({ space: 12 }) {
        ForEach([1, 2, 3], (_v: number): void => {
          Column() {
            Column()
              .width("80%")
              .height(18)
              .borderRadius(4)
              .backgroundColor($r("app.color.fs_color_border"))
              .opacity(0.4)
            Column()
              .width("100%")
              .height(14)
              .borderRadius(4)
              .backgroundColor($r("app.color.fs_color_border"))
              .opacity(0.4)
              .margin({ top: 8 })
          }
          .width("100%")
          .padding({
            left: $r("app.float.fs_space_lg"),
            right: $r("app.float.fs_space_lg"),
            top: $r("app.float.fs_space_md"),
            bottom: $r("app.float.fs_space_md")
          })
        })
      }
      .width("100%")
      .margin({ top: $r("app.float.fs_space_lg") })
    }
    .width("100%")
    .height("100%")
  }

  @Builder
  buildFavEmpty() {
    Column() {
      Text("⭐")
        .fontSize(48)
        .margin({ bottom: $r("app.float.fs_space_lg") })
      Text("还没有收藏内容")
        .fontSize($r("app.float.fs_text_title_2"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
      Text("浏览文章时点击收藏按钮即可")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .margin({ top: $r("app.float.fs_space_sm") })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding($r("app.float.fs_space_lg"))
  }

  @Builder
  buildFavError() {
    Column() {
      Text("加载收藏失败")
        .fontSize($r("app.float.fs_text_title_2"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
      Button("重试")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_inverse"))
        .backgroundColor($r("app.color.fs_color_primary"))
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(160)
        .margin({ top: $r("app.float.fs_space_lg") })
        .onClick((): void => { this.vm.loadFavorites(); })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildFavContent() {
    List() {
      LazyForEach(
        this.vm.favDataSource,
        (article: Article): void => {
          ListItem() {
            Column() {
              FavsArticleCard({
                article: article,
                showRemoveButton: true,
                removeLabel: "取消收藏",
                onCardTap: (a: Article): void => {
                  this.navPathStack.pushPath({
                    name: RouteTable.WEB_CONTAINER,
                    param: new WebContainerArgs(a.targetUrl, a.title, false)
                  });
                },
                onRemoveTap: (id: string): void => { this.vm.removeFavorite(id); }
              })
              Divider()
                .strokeWidth(1)
                .color($r("app.color.fs_color_border"))
                .opacity(0.5)
                .margin({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
            }
          }
        },
        (article: Article): string => `fav_${article.articleId}`
      )
    }
    .cachedCount(5)
    .width("100%")
    .height("100%")
    .scrollBar(BarState.Off)
  }

  // ============================================================
  // 历史 Tab(ForEach,不需要 LazyForEach)
  // ============================================================
  @Builder
  buildHistoryTab() {
    if (this.vm.historyState.isLoading() || this.vm.historyState.isIdle()) {
      this.buildFavLoading()
    } else if (this.vm.historyState.isEmpty()) {
      this.buildHistoryEmpty()
    } else {
      this.buildHistoryContent()
    }
  }

  @Builder
  buildHistoryEmpty() {
    Column() {
      Text("🕐")
        .fontSize(48)
        .margin({ bottom: $r("app.float.fs_space_lg") })
      Text("还没有搜索历史")
        .fontSize($r("app.float.fs_text_title_2"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
      Text("搜索内容后会自动记录")
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .margin({ top: $r("app.float.fs_space_sm") })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding($r("app.float.fs_space_lg"))
  }

  @Builder
  buildHistoryContent() {
    Column() {
      // 清除全部按钮
      Row() {
        Text(`共 ${this.vm.historyItems.length} 条历史`)
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_text_tertiary"))
          .layoutWeight(1)
        Text("清除全部")
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_danger"))
          .onClick((): void => { this.vm.clearAllHistory(); })
      }
      .width("100%")
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg"),
        top: $r("app.float.fs_space_md"),
        bottom: $r("app.float.fs_space_md")
      })

      // 历史列表
      List() {
        ForEach(this.vm.historyItems, (item: SearchHistoryItem): void => {
          ListItem() {
            Row() {
              Text(item.keyword)
                .fontSize($r("app.float.fs_text_body"))
                .fontColor($r("app.color.fs_color_text_primary"))
                .layoutWeight(1)
              Text(item.searchAt)
                .fontSize($r("app.float.fs_text_caption"))
                .fontColor($r("app.color.fs_color_text_tertiary"))
              Text("✕")
                .fontSize(14)
                .fontColor($r("app.color.fs_color_text_tertiary"))
                .margin({ left: $r("app.float.fs_space_md") })
                .onClick((): void => { this.vm.removeHistoryItem(item.keyword); })
            }
            .width("100%")
            .height(48)
            .padding({
              left: $r("app.float.fs_space_lg"),
              right: $r("app.float.fs_space_lg")
            })
            .alignItems(VerticalAlign.Center)
          }
        })
      }
      .width("100%")
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width("100%")
    .height("100%")
  }
}
