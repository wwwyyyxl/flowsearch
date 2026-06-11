/**
 * @file Index.ets
 * @description features/home HAR 公共出口。
 *
 * 只导出 HomePage(供 entry 装配)和 HomeViewModel(便于将来注入测试 Repo)。
 * 内部组件(ArticleCard / ChannelTabs ...)和 Repository / DataSource 不暴露。
 */

export { HomePage } from "./src/main/ets/pages/HomePage";
export { HomeViewModel } from "./src/main/ets/viewmodel/HomeViewModel";
