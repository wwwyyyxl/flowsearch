/**
 * @file Index.ets
 * @description 主题管理器 + 字体缩放管理器。
 *
 * S15 bugfix 修复项:
 * 1. setColorMode 只存在于 ApplicationContext,不在 UIAbilityContext 上
 * 2. 枚举值修正: COLOR_MODE_LIGHT=1, COLOR_MODE_DARK=0, COLOR_MODE_NOT_SET=-1(跟随系统)
 * 3. 必须通过 getApplicationContext() 调用
 */

import { ConfigurationConstant } from "@kit.AbilityKit";

/**
 * 主题模式管理器。
 *
 * setColorMode 枚举值(官方 SDK):
 *   COLOR_MODE_NOT_SET = -1  → 跟随系统
 *   COLOR_MODE_DARK    = 0   → 强制深色
 *   COLOR_MODE_LIGHT   = 1   → 强制浅色
 *
 * 必须通过 context.getApplicationContext().setColorMode() 调用,
 * setColorMode 方法只定义在 ApplicationContext 上,不在 UIAbilityContext 上。
 */
export class ThemeManager {
  static apply(mode: string, context: Context): void {
    let colorMode: ConfigurationConstant.ColorMode;
    if (mode === "light") {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === "dark") {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } else {
      // "system" 或未知值 → 跟随系统
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    }
    try {
      context.getApplicationContext().setColorMode(colorMode);
    } catch (_e) {
      // setColorMode 需要在主线程且窗口已创建后调用
    }
  }

  static label(mode: string): Resource {
    if (mode === "light") {
      return $r("app.string.fs_theme_light");
    }
    if (mode === "dark") {
      return $r("app.string.fs_theme_dark");
    }
    return $r("app.string.fs_theme_system");
  }
}

/**
 * 字体缩放管理器。
 *
 * setFontSizeScale 影响所有 fp 单位:
 *   0.85 → 小号, 1.0 → 标准, 1.15 → 大号
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
      context.getApplicationContext().setFontSizeScale(scale);
    } catch (_e) {
      // 静默降级
    }
  }

  static label(size: string): Resource {
    if (size === "small") {
      return $r("app.string.fs_font_small");
    }
    if (size === "large") {
      return $r("app.string.fs_font_large");
    }
    return $r("app.string.fs_font_standard");
  }
}
