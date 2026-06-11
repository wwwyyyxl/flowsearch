/**
 * @file Index.ets
 * @description commons/theme HAR 公共出口。
 *
 * S9:ThemeManager — 封装 setColorMode API(浅色/深色/跟随系统)。
 * S10 fix:FontScaleManager — 封装 setFontSizeScale API(小号/标准/大号)。
 *
 * 暗色资源已就绪(dark/element/color.json),切换 colorMode 后
 * ArkUI 框架自动从对应目录读取颜色,$r() 引用无需改动。
 *
 * 字体缩放:项目所有文字用 fp 单位,$r("app.float.fs_text_body") 等,
 * setFontSizeScale() 自动缩放全部 fp 值,零组件改动。
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
  static apply(mode: string, context: Context): void {
    const colorModeMap: Record<string, number> = {
      "light": 1,
      "dark": 2,
      "system": 3
    };
    const colorMode: number = colorModeMap[mode] !== undefined ? colorModeMap[mode] : 3;
    try {
      const abilityContext: common.UIAbilityContext = context as common.UIAbilityContext;
      abilityContext.setColorMode(colorMode);
    } catch (_e) {
      // 静默降级
    }
  }

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

/**
 * 字体缩放管理器。
 *
 * HarmonyOS 的 ApplicationContext.setFontSizeScale(scale) 影响所有 fp 单位:
 * - 0.85:小号
 * - 1.0:标准(默认)
 * - 1.15:大号
 *
 * 项目里 36+ 个文件用 $r("app.float.fs_text_body") 等 fp 资源,
 * 调用 setFontSizeScale 后全部自动缩放,无需逐组件改动。
 *
 * API 要求(API 12+):
 * - 必须在主线程调用
 * - scale 为非负数
 * - 超过 fontSizeMaxScale 时会被钳位
 */
export class FontScaleManager {
  static apply(size: string, context: Context): void {
    const scaleMap: Record<string, number> = {
      "small": 0.85,
      "standard": 1.0,
      "large": 1.15
    };
    const scale: number = scaleMap[size] !== undefined ? scaleMap[size] : 1.0;
    try {
      const abilityContext: common.UIAbilityContext = context as common.UIAbilityContext;
      abilityContext.getApplicationContext().setFontSizeScale(scale);
    } catch (_e) {
      // 静默降级
    }
  }

  static label(size: string): string {
    if (size === "small") {
      return "小号";
    }
    if (size === "large") {
      return "大号";
    }
    return "标准";
  }
}
