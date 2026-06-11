/**
 * @file Index.ets
 * @description features/search HAR 公共出口。
 *
 * 只导出 SearchInputPage / SearchResultPage(供 entry 装配 NavDestination)
 * 和两个 ViewModel(便于将来注入测试 Repo)。
 * 内部组件(SearchTopBar / HistoryChips ...)、Repository、DataSource 不暴露。
 */

export { SearchInputPage } from "./src/main/ets/pages/SearchInputPage";
export { SearchResultPage } from "./src/main/ets/pages/SearchResultPage";
export { SearchInputViewModel } from "./src/main/ets/viewmodel/SearchInputViewModel";
export { SearchResultViewModel } from "./src/main/ets/viewmodel/SearchResultViewModel";
