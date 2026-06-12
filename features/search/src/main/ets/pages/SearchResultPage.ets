/**
 * @file SearchResultPage.ets
 * @description 搜索结果页(P03 SearchResult)。装配:
 *   - SearchTopBar(只读,点击整框回 SearchInput)
 *   - SortTabs(综合 / 最新 / 最热 / 仅工具 / 仅文章)
 *   - 内容区:Loading 骨架 / Empty 提示 / Error 重试 / Content(AI 卡 + LazyForEach 结果)
 *
 * 设计要点:
 *
 * 1. 不用整页 StateHost:
 *    PRD §04-03 §5 强约束 -- Empty / Error 时顶栏 + Tab 保持。
 *    所以页面布局是:[顶栏][Tab][主体],主体根据 vm.state 分四种渲染。
 *
 * 2. 复用 home 的 PageState 状态机:
 *    虽然没用 StateHost 组件,但 PageState class 完全复用 -- 这是简历主线 4
 *    "状态机契约同源"的二次落地证据。
 *
 * 3. LazyForEach + cachedCount(5)再次出现(简历主线 3):
 *    搜索结果列表用 LazyForEach + SearchResultDataSource,
 *    key = `${keyword}_${articleId}`,与 home 的 `${channelId}_${articleId}` 同型。
 *
 * 4. AI 卡渲染条件:
 *    state.isContent() && data.aiAnswer !== null
 *    PRD §04-03 §3 + §6:keyword<2 / 接口返回 null / 2s 超时 -> aiAnswer 都是 null,
 *    UI 层判一次就够,VM 不暴露"AI 卡 loading"独立态(简化交互模型)。
 *
 * 5. Empty 态文案:
 *    "未找到「{keyword}」相关内容" + "建议换个关键词" + 「返回首页」按钮(PRD §04-03 §5)。
 *
 * 6. Error 态文案:
 *    "搜索失败" + "错误码: {code}" + 重试按钮(PRD §04-03 §5,设计稿用 trace,
 *    本期没真实 trace,只展示 errorCode)。
 *
 * Cast helper 集中:
 *   castToSearchResultData(state) -> SearchResultData | null
 *   与 HomePage 的 castToHomeFeedData 同型 -- 这是本会话定下的模板。
 */

import promptAction from "@ohos.promptAction";
import { pasteboard } from "@kit.BasicServicesKit";
import { PageState, Article, SearchResultData, SortType, UrlDebounceGuard } from "@flowsearch/base";
import { RouteTable, SearchResultArgs, WebContainerArgs } from "@flowsearch/router";
import { SearchResultViewModel } from "../viewmodel/SearchResultViewModel";
import { SearchTopBar } from "../components/SearchTopBar";
import { SortTabs } from "../components/SortTabs";
import { AiAnswerCard } from "../components/AiAnswerCard";
import { SearchResultCard } from "../components/SearchResultCard";

/** PageState.data -> SearchResultData | null 的集中 cast helper(沿用 HomePage 模板)。 */
function castToSearchResultData(state: PageState): SearchResultData | null {
  if (state.data === null) {
    return null;
  }
  return state.data as SearchResultData;
}

@ComponentV2
export struct SearchResultPage {
  /** 路由栈。 */
  @Param navPathStack: NavPathStack = new NavPathStack();

  /** 路由参数(keyword)。父组件从 NavPathStack.getParamByName 取后传入。 */
  @Param keyword: string = "";

  @Local vm: SearchResultViewModel = new SearchResultViewModel();

  /** S17:下拉刷新状态。Refresh 组件通过 $$ 双向绑定。 */
  @Local isRefreshing: boolean = false;

  aboutToAppear(): void {
    this.vm.init(this.keyword, getContext(this));
  }

  build() {
    NavDestination() {
      Column() {
        // 1. 顶栏(只读,点整框回 SearchInput)
        SearchTopBar({
          keyword: this.vm.keyword,
          autoFocus: false,
          readOnly: true,
          showCancel: false,
          showBack: true,
          onBackTap: (): void => { this.navPathStack.pop(); },
          onClearTap: (): void => { this.navPathStack.pop(); },
          onBarTap: (): void => { this.navPathStack.pop(); }
        })

        // 2. 排序 Tab
        SortTabs({
          selectedKey: this.vm.sortType,
          onSortChange: (sort: SortType): void => { this.vm.changeSort(sort); }
        })

        // 3. 主体内容(Refresh 包裹,支持下拉刷新)
        Refresh({ refreshing: $$this.isRefreshing }) {
          Column() {
            if (this.vm.state.isLoading() || this.vm.state.isIdle()) {
              this.buildLoading()
            } else if (this.vm.state.isEmpty()) {
              this.buildEmpty()
            } else if (this.vm.state.isError()) {
              this.buildError()
            } else {
              this.buildContent(castToSearchResultData(this.vm.state))
            }
          }
          .layoutWeight(1)
          .width("100%")
        }
        .onRefreshing((): void => {
          this.vm.refreshResults().then((): void => {
            this.isRefreshing = false;
          }).catch((_e: object): void => {
            this.isRefreshing = false;
          });
        })
        .layoutWeight(1)
        .width("100%")
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.fs_color_surface"))
    }
    .hideTitleBar(true)
  }

  // ============================================================
  // 主体:Loading(AI 卡骨架 + 3 张结果骨架)
  // ============================================================
  @Builder
  buildLoading() {
    Scroll() {
      Column() {
        // AI 卡骨架(同 AI 卡尺寸的灰底)
        Column()
          .width("100%")
          .height(180)
          .backgroundColor($r("app.color.fs_color_border"))
          .borderRadius($r("app.float.fs_radius_lg"))
          .opacity(0.4)

        // 3 张结果骨架
        Column({ space: 12 }) {
          ForEach([1, 2, 3], (_v: number): void => {
            this.buildSkeletonCard()
          })
        }
        .width("100%")
        .margin({ top: $r("app.float.fs_space_md") })
      }
      .width("100%")
      .padding($r("app.float.fs_space_lg"))
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  buildSkeletonCard() {
    Row() {
      Column()
        .width(56)
        .height(56)
        .borderRadius($r("app.float.fs_radius_md"))
        .backgroundColor($r("app.color.fs_color_border"))
        .opacity(0.4)

      Column() {
        Column()
          .width("80%")
          .height(18)
          .borderRadius($r("app.float.fs_radius_sm"))
          .backgroundColor($r("app.color.fs_color_border"))
          .opacity(0.4)
        Column()
          .width("100%")
          .height(14)
          .borderRadius($r("app.float.fs_radius_sm"))
          .backgroundColor($r("app.color.fs_color_border"))
          .opacity(0.4)
          .margin({ top: $r("app.float.fs_space_sm") })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r("app.float.fs_space_md") })
    }
    .width("100%")
    .alignItems(VerticalAlign.Top)
  }

  // ============================================================
  // 主体:Empty(未找到 + 返回首页)
  // ============================================================
  @Builder
  buildEmpty() {
    Column() {
      // 空态插画占位(虚线圆环 + 内圈圆 + 放大镜叉号)
      Stack() {
        Circle({ width: 100, height: 100 })
          .fill(Color.Transparent)
          .stroke($r("app.color.fs_color_border"))
          .strokeDashArray([4, 4])
        Circle({ width: 80, height: 80 })
          .fill($r("app.color.fs_color_primary_tint"))
          .opacity(0.4)
        Text("⊘")
          .fontSize(36)
          .fontColor($r("app.color.fs_color_text_tertiary"))
      }
      .width(100)
      .height(100)
      .margin({ bottom: $r("app.float.fs_space_2xl") })

      Text(`未找到「${this.vm.keyword}」相关内容`)
        .fontSize($r("app.float.fs_text_title_2"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text($r("app.string.fs_search_try_other_keywords"))
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_secondary"))
        .margin({ top: $r("app.float.fs_space_sm") })

      Button($r("app.string.fs_search_back_home"))
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_primary"))
        .backgroundColor($r("app.color.fs_color_surface"))
        .border({ width: 1, color: $r("app.color.fs_color_border") })
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(200)
        .margin({ top: $r("app.float.fs_space_3xl") })
        .onClick((): void => { this.navPathStack.clear(); })
    }
    .width("100%")
    .height("100%")
    .padding($r("app.float.fs_space_lg"))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // 主体:Error(感叹号 + 错误码 + 重试)
  // ============================================================
  @Builder
  buildError() {
    Column() {
      Stack() {
        Circle({ width: 80, height: 80 })
          .fill(Color.Transparent)
          .stroke($r("app.color.fs_color_danger"))
          .strokeWidth(2)
        Text("!")
          .fontSize(36)
          .fontColor($r("app.color.fs_color_danger"))
          .fontWeight(FontWeight.Bold)
      }
      .width(80)
      .height(80)

      Text($r("app.string.fs_search_error"))
        .fontSize($r("app.float.fs_text_title_2"))
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.fs_color_text_primary"))
        .margin({ top: $r("app.float.fs_space_lg") })

      Text($r("app.string.fs_search_error_code") + ": " + this.vm.state.errorCode)
        .fontSize($r("app.float.fs_text_body"))
        .fontColor($r("app.color.fs_color_text_tertiary"))
        .margin({ top: $r("app.float.fs_space_sm") })

      Button($r("app.string.fs_search_retry"))
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontColor($r("app.color.fs_color_text_inverse"))
        .backgroundColor($r("app.color.fs_color_primary"))
        .borderRadius($r("app.float.fs_radius_md"))
        .height($r("app.float.fs_height_button"))
        .width(200)
        .margin({ top: $r("app.float.fs_space_3xl") })
        .onClick((): void => { this.vm.retryCurrent(); })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ============================================================
  // 主体:Content(AI 卡 + LazyForEach 结果)
  // ============================================================
  /**
   * data 由外层 if 分支算好后传入 ——
   * ArkTS @Builder 体内只允许 UI 组件语法 + if/ForEach,不能有 const/let 等
   * 语句。原本写在 Builder 第一行的 `const data = castToSearchResultData(...)`
   * 会触发编译错 10905209 "Only UI component syntax can be written here"。
   * 解法:把 data 提到外层 build() 里算,Builder 只接参数渲染。
   */
  @Builder
  buildContent(data: SearchResultData | null) {
    List() {
      // 第一项:AI 速答卡(可空,null 时直接不展示这一项)
      if (data !== null && data.aiAnswer !== null) {
        ListItem() {
          AiAnswerCard({
            answer: data.aiAnswer,
            onRelatedTap: (q: string): void => {
              // 关联问题胶囊:跳新的 SearchResult(PRD §04-03 §3)
              this.navPathStack.pushPath({
                name: RouteTable.SEARCH_RESULT,
                param: new SearchResultArgs(q)
              });
            },
            onCopyTap: (): void => {
              const pasteData = pasteboard.createData("text/plain", data.aiAnswer!.summary);
              pasteboard.getSystemPasteboard().setData(pasteData);
              promptAction.showToast({ message: $r("app.string.fs_search_copied") });
            }
          })
        }
        .margin({
          left: $r("app.float.fs_space_lg"),
          right: $r("app.float.fs_space_lg"),
          top: $r("app.float.fs_space_md"),
          bottom: $r("app.float.fs_space_md")
        })
      }

      // 之后:LazyForEach 结果卡片
      LazyForEach(
        this.vm.dataSource,
        (article: Article): void => {
          ListItem() {
            Column() {
              SearchResultCard({
                article: article,
                keyword: this.vm.keyword,
                onCardTap: (a: Article): void => {
                  if (UrlDebounceGuard.shouldOpen(a.targetUrl)) {
                    this.navPathStack.pushPath({
                      name: RouteTable.WEB_CONTAINER,
                      param: new WebContainerArgs(a.targetUrl, a.title, false, false, a.articleId)
                    });
                  }
                },
                onFavoriteTap: (id: string): void => { this.vm.toggleFavorite(id); }
              })
              Divider()
                .strokeWidth(1)
                .color($r("app.color.fs_color_border"))
                .opacity(0.5)
                .margin({ left: 68 })
            }
            .padding({
              left: $r("app.float.fs_space_lg"),
              right: $r("app.float.fs_space_lg")
            })
          }
        },
        (article: Article): string => `${this.vm.keyword}_${article.articleId}`
      )

      // S17:底部:LoadingMore / 没有更多
      ListItem() {
        if (this.vm.isLoadingMore) {
          Row({ space: 8 }) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color($r("app.color.fs_color_primary"))
            Text($r("app.string.fs_search_loading"))
              .fontSize($r("app.float.fs_text_caption"))
              .fontColor($r("app.color.fs_color_text_tertiary"))
          }
          .width("100%")
          .height(56)
          .justifyContent(FlexAlign.Center)
        } else if (!this.vm.hasMore) {
          Text($r("app.string.fs_search_no_more"))
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
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .onScrollIndex((_start: number, end: number): void => {
      // S17:触底检测:当最后一条可见时触发加载更多
      const totalCount: number = this.vm.dataSource.totalCount();
      if (end >= totalCount - 1 && totalCount > 0) {
        this.vm.loadMore();
      }
    })
  }
}
