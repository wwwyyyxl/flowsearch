/**
 * @file FavoritesHistoryPage.ets
 * @description 收藏与历史页面(P05 FavoritesHistory)。双 Tab:收藏 / 历史。
 *
 * S7 补全:
 * - 历史 Tab:按时间分组(今天/昨天/本周更早/更早) + HH:mm 时间
 * - 收藏 Tab:管理模式(多选 + 底部操作栏:全选/批量取消收藏)
 *
 * 设计要点:
 * 1. NavDestination 包裹,@Param navPathStack 接收路由栈。
 * 2. 收藏 Tab:PageState 四态分发,Content 用 LazyForEach。
 * 3. 历史 Tab:分组 ForEach(按 HistoryGroup 渲染)。
 * 4. 管理模式:isManaging 控制多选圈 + 底部操作栏。
 * 5. Context 注入:aboutToAppear() -> vm.init(context, defaultTab)。
 */

import { PageState, Article, SearchHistoryItem } from "@flowsearch/base";
import { RouteTable, WebContainerArgs, FavsHistoryArgs } from "@flowsearch/router";
import { FavsViewModel, HistoryGroup } from "../viewmodel/FavsViewModel";
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
  // 收藏 Tab(PageState 四态分发 + 管理模式)
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
    Column() {
      // 标题行: "全部 (N)" + "管理"/"完成"
      Row() {
        Text(`全部 (${this.vm.favArticles.length})`)
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_text_secondary"))
          .layoutWeight(1)
        Text(this.vm.isManaging ? "完成" : "管理")
          .fontSize($r("app.float.fs_text_body"))
          .fontColor($r("app.color.fs_color_primary"))
          .onClick((): void => {
            if (this.vm.isManaging) {
              this.vm.exitManageMode();
            } else {
              this.vm.enterManageMode();
            }
          })
      }
      .width("100%")
      .height(40)
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg")
      })
      .alignItems(VerticalAlign.Center)

      // 收藏列表
      List() {
        LazyForEach(
          this.vm.favDataSource,
          (article: Article): void => {
            ListItem() {
              Row() {
                // 管理模式:左侧多选圈
                if (this.vm.isManaging) {
                  Column() {
                    Circle({ width: 24, height: 24 })
                      .stroke(
                        this.vm.isItemSelected(article.articleId)
                          ? $r("app.color.fs_color_primary")
                          : $r("app.color.fs_color_border")
                      )
                      .fill(
                        this.vm.isItemSelected(article.articleId)
                          ? $r("app.color.fs_color_primary")
                          : Color.Transparent
                      )
                      .strokeWidth(2)
                  }
                  .width(32)
                  .height("100%")
                  .justifyContent(FlexAlign.Center)
                  .onClick((): void => { this.vm.toggleSelect(article.articleId); })
                }

                // 卡片主体
                Column() {
                  FavsArticleCard({
                    article: article,
                    showRemoveButton: !this.vm.isManaging,
                    removeLabel: "取消收藏",
                    onCardTap: (a: Article): void => {
                      if (this.vm.isManaging) {
                        this.vm.toggleSelect(a.articleId);
                      } else {
                        this.navPathStack.pushPath({
                          name: RouteTable.WEB_CONTAINER,
                          param: new WebContainerArgs(a.targetUrl, a.title, false, false, a.articleId)
                        });
                      }
                    },
                    onRemoveTap: (id: string): void => { this.vm.removeFavorite(id); }
                  })
                  Divider()
                    .strokeWidth(1)
                    .color($r("app.color.fs_color_border"))
                    .opacity(0.5)
                    .margin({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
                }
                .layoutWeight(1)
              }
            }
          },
          (article: Article): string => `fav_${article.articleId}`
        )
      }
      .cachedCount(5)
      .width("100%")
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 管理模式底部操作栏
      if (this.vm.isManaging) {
        Row() {
          Text("全选")
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_primary"))
            .onClick((): void => { this.vm.selectAll(); })
          Blank()
          Text(`取消收藏 (${this.vm.selectedIds.length})`)
            .fontSize($r("app.float.fs_text_body"))
            .fontColor($r("app.color.fs_color_danger"))
            .onClick((): void => { this.vm.batchRemove(); })
        }
        .width("100%")
        .height(56)
        .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
        .alignItems(VerticalAlign.Center)
        .backgroundColor($r("app.color.fs_color_surface"))
        .border({
          width: { top: 1 },
          color: $r("app.color.fs_color_border")
        })
      }
    }
    .width("100%")
    .height("100%")
  }

  // ============================================================
  // 历史 Tab(分组渲染)
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

      // 分组历史列表
      List() {
        ForEach(this.vm.historyGroups, (group: HistoryGroup): void => {
          // 分组头
          ListItem() {
            Text(group.label)
              .fontSize($r("app.float.fs_text_caption"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_secondary"))
              .width("100%")
              .height(32)
              .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
          }

          // 组内历史项
          ForEach(group.items,
            (item: SearchHistoryItem): void => {
              ListItem() {
                Row() {
                  Text("🕐")
                    .fontSize(16)
                    .fontColor($r("app.color.fs_color_text_tertiary"))
                    .width(24)
                  Text(item.keyword)
                    .fontSize($r("app.float.fs_text_body"))
                    .fontColor($r("app.color.fs_color_text_primary"))
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(this.formatTime(item.createdAt))
                    .fontSize($r("app.float.fs_text_caption"))
                    .fontColor($r("app.color.fs_color_text_tertiary"))
                    .margin({ left: $r("app.float.fs_space_md") })
                  Text("✕")
                    .fontSize(14)
                    .fontColor($r("app.color.fs_color_text_tertiary"))
                    .margin({ left: $r("app.float.fs_space_md") })
                    .onClick((): void => { this.vm.removeHistoryItem(item.keyword); })
                }
                .width("100%")
                .height(56)
                .padding({
                  left: $r("app.float.fs_space_lg"),
                  right: $r("app.float.fs_space_lg")
                })
                .alignItems(VerticalAlign.Center)
              }
            })
        })
      }
      .width("100%")
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width("100%")
    .height("100%")
  }

  /** 格式化时间戳为 HH:mm。ts=0 时返回空串(向后兼容无时间戳数据)。 */
  private formatTime(ts: number): string {
    if (ts <= 0) {
      return "";
    }
    const d: Date = new Date(ts);
    const h: number = d.getHours();
    const m: number = d.getMinutes();
    const hh: string = h < 10 ? `0${h}` : `${h}`;
    const mm: string = m < 10 ? `0${m}` : `${m}`;
    return `${hh}:${mm}`;
  }
}
