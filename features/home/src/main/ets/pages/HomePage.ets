/**
 * @file HomePage.ets
 * @description 首页主页面。装配 Header / SearchBar / QuickEntries / ChannelTabs /
 *              StateHost(Feed/Skeleton/Empty/Error) + 调试浮层。
 *
 * 简历主线击中:
 *  - 主线 3:LazyForEach + key=`${channelId}_${articleId}` + cachedCount=5 + @Reusable;
 *  - 主线 4:StateHost 把 PageState 分发成 Loading 骨架 / Empty / Error / Content;
 *  - 主线 5:全程字段名严格对齐 PRD §08,Article.categoryTag 决定角标色。
 *
 * Cast helper 集中策略(本会话定下的模板):
 *   castToHomeFeedData(state) -> HomeFeedData | null
 *   所有 contentBuilder 内取 data 都走这个 helper,cast 一处,不散落。
 *   其他 feature 都照搬这个模板。
 *
 * 数据流(必看):
 *   VM.loadFeed -> Repository -> 成功 -> VM.updateState(PageState.content)
 *                                    -> VM.feedDataSource.setArticles
 *   UI 通过 vm.getCurrentState() 拿 PageState -> StateHost 分发 -> Content 走 buildFeed
 *   buildFeed 里 LazyForEach 消费 vm.feedDataSource(VM 持有的)
 *   切频道时 VM 同步 dataSource,UI 不需要 useEffect 之类的同步钩子。
 */

import promptAction from "@ohos.promptAction";
import { PageState, Article, HomeFeedData, UrlDebounceGuard } from "@flowsearch/base";
import { StateHost } from "@flowsearch/ui";
import { RouteTable, WebContainerArgs, ToolShellArgs } from "@flowsearch/router";
import { HomeViewModel } from "../viewmodel/HomeViewModel";
import { SimulationMode } from "../repo/SimulationMode";
import { HomeHeader } from "../components/HomeHeader";
import { HomeSearchBar } from "../components/HomeSearchBar";
import { QuickEntries } from "../components/QuickEntries";
import { ChannelTabs } from "../components/ChannelTabs";
import { ArticleCard } from "../components/ArticleCard";

/**
 * Cast helper:把 PageState.data(Object | null) 转成 HomeFeedData 或 null。
 * UI 层用 if (data !== null) 守护后访问字段,避免 force unwrap。
 * 后续每个 feature 都建一个同型 helper -- 这是本会话定下的模板。
 */
function castToHomeFeedData(state: PageState): HomeFeedData | null {
  if (state.data === null) {
    return null;
  }
  return state.data as HomeFeedData;
}

@ComponentV2
export struct HomePage {
  /**
   * 路由栈,由 entry 通过 @Param 传入。
   * VM 不持有路由对象,UI 层用 navPathStack.pushPath 跳转 -- 与 SearchInputPage 同型。
   */
  @Param navPathStack: NavPathStack = new NavPathStack();

  /** ViewModel,@Local 让本组件持有引用,VM 的 @Trace 字段变化自动触发本组件重渲。 */
  @Local vm: HomeViewModel = new HomeViewModel();

  /** S17:下拉刷新状态。Refresh 组件通过 $$ 双向绑定。 */
  @Local isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.vm.init(getContext(this));
  }

  build() {
    Column() {
      // ===== 1. 顶栏 =====
      HomeHeader({ avatarLetter: "王" })

      // ===== 2. 搜索框(点击跳 SearchInput,S2 接入) =====
      Row() {
        HomeSearchBar({
          onSearchBarTap: (): void => {
            this.navPathStack.pushPath({ name: RouteTable.SEARCH_INPUT });
          }
        })
      }
      .width("100%")
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg")
      })

      // ===== 3. 调试浮层(切 mock 模式) -- S6 收口前可改成右上角小齿轮 =====
      Row({ space: 6 }) {
        Text(`mock: ${this.vm.simulationMode}`)
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_text_tertiary"))
          .layoutWeight(1)
        this.buildModeBtn("正常", "normal")
        this.buildModeBtn("空", "empty")
        this.buildModeBtn("错", "error")
        this.buildModeBtn("慢", "slow")
        Text("⚙设置")
          .fontSize($r("app.float.fs_text_caption"))
          .fontColor($r("app.color.fs_color_primary"))
          .backgroundColor($r("app.color.fs_color_primary_tint"))
          .borderRadius($r("app.float.fs_radius_sm"))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .onClick((): void => {
            this.navPathStack.pushPath({ name: RouteTable.SETTINGS });
          })
      }
      .width("100%")
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg"),
        top: $r("app.float.fs_space_sm")
      })

      // ===== 4. 工具入口 4 圆 =====
      Column() {
        QuickEntries({
          entries: this.vm.quickEntries,
          onEntryClick: (toolId: string): void => {
            this.navPathStack.pushPath({
              name: RouteTable.TOOL_SHELL,
              param: new ToolShellArgs(toolId)
            });
          }
        })
      }
      .padding({
        left: $r("app.float.fs_space_lg"),
        right: $r("app.float.fs_space_lg"),
        top: $r("app.float.fs_space_lg")
      })

      // ===== 5. 频道 Tab =====
      Column() {
        ChannelTabs({
          channels: this.vm.channels,
          selectedChannelId: this.vm.currentChannelId,
          onChannelChange: (id: string): void => { this.vm.switchChannel(id); }
        })
      }
      .margin({ top: $r("app.float.fs_space_lg") })

      // ===== 6. Feed 状态分发区(Refresh 包裹,支持下拉刷新) =====
      Refresh({ refreshing: $$this.isRefreshing }) {
        Column() {
          StateHost({
            state: this.vm.getCurrentState(),
            onRetry: (): void => { this.vm.retryCurrent(); },
            emptyTitle: "这个频道暂无内容",
            emptySubtitle: "试试其他频道",
            contentBuilder: (): void => {
              this.buildFeed();
            }
          })
        }
        .width("100%")
        .height("100%")
      }
      .onRefreshing((): void => {
        this.vm.refreshFeed();
      })
      .layoutWeight(1)
      .width("100%")
    }
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.fs_color_background"))
  }

  /**
   * Content 状态下的 Feed 渲染。
   *
   * 关键点(简历主线 3):
   * 1. LazyForEach 而非 ForEach -- 长列表延迟创建 ViewHolder;
   * 2. cachedCount(5) -- 预创建可视区上下各 5 个,提升滚动流畅度;
   * 3. key generator 用 `${channelId}_${articleId}` -- 频道切换不复用脏 ViewHolder;
   * 4. @ReusableV2 已启用(reuseId 按 categoryTag 分 4 个复用池)。
   */
  @Builder
  buildFeed() {
    List({ space: 12 }) {
      LazyForEach(
        this.vm.feedDataSource,
        (article: Article): void => {
          ListItem() {
            ArticleCard({
              article: article,
              onCardClick: (a: Article): void => {
                if (UrlDebounceGuard.shouldOpen(a.targetUrl)) {
                  this.navPathStack.pushPath({
                    name: RouteTable.WEB_CONTAINER,
                    param: new WebContainerArgs(a.targetUrl, a.title, false, false, a.articleId)
                  });
                }
              },
              onFavoriteToggle: (id: string): void => { this.vm.toggleFavorite(id); }
            })
            .reuse({ reuseId: (): string => article.categoryTag })
          }
        },
        (article: Article): string => `${article.channelId}_${article.articleId}`
      )

      // 底部:LoadingMore / End
      ListItem() {
        if (this.vm.isLoadingMore) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color($r("app.color.fs_color_primary"))
            Text($r("app.string.fs_home_loading"))
              .fontSize($r("app.float.fs_text_caption"))
              .fontColor($r("app.color.fs_color_text_tertiary"))
          }
          .width("100%")
          .height(56)
          .justifyContent(FlexAlign.Center)
        } else if (!this.vm.hasMore) {
          Text($r("app.string.fs_home_no_more"))
            .fontSize($r("app.float.fs_text_caption"))
            .fontColor($r("app.color.fs_color_text_tertiary"))
            .width("100%")
            .height(56)
            .textAlign(TextAlign.Center)
        }
      }
    }
    .cachedCount(5)
    .width("100%")
    .height("100%")
    .padding({
      left: $r("app.float.fs_space_lg"),
      right: $r("app.float.fs_space_lg"),
      top: $r("app.float.fs_space_md"),
      bottom: $r("app.float.fs_space_md")
    })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .onReachEnd((): void => { this.vm.loadMore(); })
  }

  /** 调试浮层按钮工厂。 */
  @Builder
  buildModeBtn(label: string, mode: SimulationMode) {
    Text(label)
      .fontSize($r("app.float.fs_text_caption"))
      .fontColor(this.vm.simulationMode === mode
        ? $r("app.color.fs_color_text_inverse")
        : $r("app.color.fs_color_primary"))
      .backgroundColor(this.vm.simulationMode === mode
        ? $r("app.color.fs_color_primary")
        : $r("app.color.fs_color_primary_tint"))
      .borderRadius($r("app.float.fs_radius_sm"))
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .onClick((): void => { this.vm.changeSimulationMode(mode); })
  }
}
