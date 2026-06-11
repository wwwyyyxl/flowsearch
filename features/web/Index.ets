/**
 * @file Index.ets
 * @description features/web HAR 公共出口。
 *
 * 只导出 WebContainerPage(供 entry 装配 NavDestination)和 ViewModel(便于注入测试 Repo)。
 * 内部组件(WebTopBar / WebErrorPage / LoginExpiredDialog ...)、Repository 不暴露。
 */

export { WebContainerPage } from "./src/main/ets/pages/WebContainerPage";
export { WebContainerViewModel } from "./src/main/ets/viewmodel/WebContainerViewModel";
