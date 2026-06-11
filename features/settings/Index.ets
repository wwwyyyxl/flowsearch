/**
 * @file Index.ets
 * @description features/settings HAR 公共出口。
 *
 * 只导出页面组件(供 entry 装配 NavDestination)。
 * 内部组件(SettingsGroup / SettingsItem / ConfirmDialog / UpdateDialog)、
 * Repository、ViewModel、CacheCalculator 不暴露。
 */

export { SettingsPage } from "./src/main/ets/pages/SettingsPage";
export { UserAgreementPage } from "./src/main/ets/pages/UserAgreementPage";
export { PrivacyPolicyPage } from "./src/main/ets/pages/PrivacyPolicyPage";
