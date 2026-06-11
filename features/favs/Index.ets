/**
 * @file Index.ets
 * @description features/favs HAR 公共出口。
 *
 * 只导出 FavoritesHistoryPage(供 entry 装配 NavDestination)和 ViewModel。
 * 内部组件(FavsTabs)、Repository、DataSource 不暴露。
 */

export { FavoritesHistoryPage } from "./src/main/ets/pages/FavoritesHistoryPage";
export { FavsViewModel } from "./src/main/ets/viewmodel/FavsViewModel";
export { FavoritesRepository } from "./src/main/ets/repo/FavoritesRepository";
export { HistoryRepository } from "./src/main/ets/repo/HistoryRepository";
