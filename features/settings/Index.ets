/**
 * @file Index.ets
 * @description features/settings HAR 公共出口。
 *
 * 只导出 SettingsPage(供 entry 装配 NavDestination)。
 * 内部组件(SettingsGroup / SettingsItem / ConfirmDialog / UpdateDialog)、
 * Repository、ViewModel、CacheCalculator 不暴露。
 */

export { SettingsPage } from "./src/main/ets/pages/SettingsPage";
