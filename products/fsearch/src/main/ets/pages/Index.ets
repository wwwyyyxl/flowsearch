/**
 * @file Index.ets
 * @description App 启动入口。Navigation 路由根 + 路由表分发。
 *
 * S2 阶段改造:
 *   1. pageMap 加 SEARCH_INPUT / SEARCH_RESULT 分发(对接 features/search);
 *   2. 通过 @Param navPathStack 把路由栈传给 HomePage / SearchInputPage / SearchResultPage,
 *      实现"VM 不依赖路由对象,UI 层用 navPathStack 跳转 + 返回"。
 *
 * ArkTS ↔ Compose 对照:
 *   Navigation + NavDestination ≈ NavHost + NavGraphBuilder.composable(...)
 *   pushPath({name, param}) ≈ navController.navigate(route, args)
 */

import { RouteTable, SearchResultArgs, WebContainerArgs, FavsHistoryArgs, ToolShellArgs } from "@flowsearch/router";
import { HomePage } from "@flowsearch/home";
import { SearchInputPage, SearchResultPage } from "@flowsearch/search";
import { WebContainerPage } from "@flowsearch/web";
import { FavoritesHistoryPage } from "@flowsearch/favs";
import { SettingsPage, UserAgreementPage, PrivacyPolicyPage } from "@flowsearch/settings";
import { ToolShellPage } from "@flowsearch/toolshell";

@Entry
@ComponentV2
struct Index {
  /**
   * 全局路由栈。@Local 让本组件持有引用并响应 push/pop 触发的重渲。
   * 通过 @Param 透传给各页面 -- 各 feature 的 VM 不依赖路由对象,
   * 只 UI 层用 navPathStack.pushPath / pop。
   */
  @Local navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    // S14:检查是否有待处理的深链(FsearchAbility 通过 AppStorage 桥接)
    const dlRoute: string | undefined = AppStorage.get<string>("__dl_route");
    if (dlRoute !== undefined && dlRoute.length > 0) {
      // 清除,防止重复触发
      AppStorage.setOrCreate<string>("__dl_route", "");

      // 延迟确保 navPathStack 已就绪
      if (dlRoute === RouteTable.WEB_CONTAINER) {
        const url: string = AppStorage.get<string>("__dl_url") ?? "";
        const title: string = AppStorage.get<string>("__dl_title") ?? "";
        AppStorage.setOrCreate<string>("__dl_url", "");
        AppStorage.setOrCreate<string>("__dl_title", "");
        if (url.length > 0) {
          setTimeout((): void => {
            this.navPathStack.pushPath({
              name: RouteTable.WEB_CONTAINER,
              param: new WebContainerArgs(url, title, false, true)
            });
          }, 100);
        }
      } else if (dlRoute === RouteTable.SEARCH_RESULT) {
        const keyword: string = AppStorage.get<string>("__dl_keyword") ?? "";
        AppStorage.setOrCreate<string>("__dl_keyword", "");
        if (keyword.length > 0) {
          setTimeout((): void => {
            this.navPathStack.pushPath({
              name: RouteTable.SEARCH_RESULT,
              param: new SearchResultArgs(keyword)
            });
          }, 100);
        }
      }
    }
  }

  build() {
    Navigation(this.navPathStack) {
      // 根页面:HomePage(首页)
      HomePage({ navPathStack: this.navPathStack })
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.pageMap)
  }

  /**
   * 路由分发。push 时 NavPathInfo.name 匹配到这里的 case 即创建对应页面。
   */
  @Builder
  pageMap(name: string, param: object) {
    if (name === RouteTable.HOME) {
      HomePage({ navPathStack: this.navPathStack })
    } else if (name === RouteTable.SEARCH_INPUT) {
      SearchInputPage({ navPathStack: this.navPathStack })
    } else if (name === RouteTable.SEARCH_RESULT) {
      // 从 NavPathInfo.param 取 keyword
      SearchResultPage({
        navPathStack: this.navPathStack,
        keyword: (param as SearchResultArgs).keyword
      })
    } else if (name === RouteTable.WEB_CONTAINER) {
      WebContainerPage({
        navPathStack: this.navPathStack,
        url: (param as WebContainerArgs).url,
        title: (param as WebContainerArgs).title,
        needTokenInject: (param as WebContainerArgs).needTokenInject,
        forceAllow: (param as WebContainerArgs).forceAllow,
        articleId: (param as WebContainerArgs).articleId
      })
    } else if (name === RouteTable.FAVORITES_HISTORY) {
      FavoritesHistoryPage({
        navPathStack: this.navPathStack,
        defaultTab: (param as FavsHistoryArgs).tab
      })
    } else if (name === RouteTable.SETTINGS) {
      SettingsPage({
        navPathStack: this.navPathStack
      })
    } else if (name === RouteTable.TOOL_SHELL) {
      ToolShellPage({
        navPathStack: this.navPathStack,
        toolId: (param as ToolShellArgs).toolId
      })
    } else if (name === RouteTable.USER_AGREEMENT) {
      UserAgreementPage({ navPathStack: this.navPathStack })
    } else if (name === RouteTable.PRIVACY_POLICY) {
      PrivacyPolicyPage({ navPathStack: this.navPathStack })
    }
  }
}
