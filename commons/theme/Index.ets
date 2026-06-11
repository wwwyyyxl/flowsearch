/**
 * @file Index.ets
 * @description commons/theme HAR 公共出口。
 *
 * S9 新增 ThemeManager:封装 HarmonyOS setColorMode API,
 * 让 SettingsPage 可以在浅色 / 深色 / 跟随系统之间切换。
 *
 * 暗色资源已就绪(dark/element/color.json),切换 colorMode 后
 * ArkUI 框架自动从对应目录读取颜色,$r() 引用无需改动。
 */

import { common } from "@kit.AbilityKit";

/**
 * 主题模式管理器。
 *
 * HarmonyOS 的 setColorMode 影响整个 Ability 的资源加载方向:
 * - COLOR_MODE_LIGHT(1):强制浅色 -> 读 base/element/color.json
 * - COLOR_MODE_DARK(2):强制深色 -> 读 dark/element/color.json
 * - COLOR_MODE_AUTO(3):跟随系统 -> 由系统决定读哪个
 */
export class ThemeManager {
  /**
   * 应用主题模式。
   *
   * @param mode    "light" | "dark" | "system"
   * @param context 应用上下文(getContext(this))
   */
  static apply(mode: string, context: Context): void {
    const colorModeMap: Record<string, number> = {
      "light": 1,
      "dark": 2,
      "system": 3
    };
    const colorMode: number = colorModeMap[mode] !== undefined ? colorModeMap[mode] : 3;
    try {
      // common.UIAbilityContext.setColorMode 是 HarmonyOS API,
      // 改变整个应用的资源加载方向(base/ vs dark/)。
      // try/catch 降级:模拟器或低版本 API 可能不支持。
      const abilityContext: common.UIAbilityContext = context as common.UIAbilityContext;
      abilityContext.setColorMode(colorMode);
    } catch (_e) {
      // 静默降级
    }
  }

  /**
   * themeMode 值 -> 用户可见的中文标签。
   */
  static label(mode: string): string {
    if (mode === "light") {
      return "浅色";
    }
    if (mode === "dark") {
      return "深色";
    }
    return "跟随系统";
  }
}
