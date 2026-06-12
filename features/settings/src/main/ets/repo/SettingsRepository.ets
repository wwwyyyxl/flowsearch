/**
 * @file SettingsRepository.ets
 * @description 设置项 Preferences 持久化。复用 PreferencesHelper + JSON 模式。
 *
 * 设计要点:
 *
 * 1. SettingsData 用 @ObservedV2 + @Trace,UI 可直接绑定。
 *    与 FavsViewModel 内的 @Trace 字段同源。
 *
 * 2. storeName = "fsearch_settings",一个 store 存所有设置项。
 *    每个 key 独立读写(不存整个 JSON 对象),避免单项更新时互相覆盖。
 *
 * 3. 默认值硬编码在 DEFAULTS 常量中:
 *    loadAll() 先读 Preferences,未命中则用默认值。
 *    update() 立即写入单个 key。
 */

import { PreferencesHelper, HttpClient } from "@flowsearch/base";

const STORE_NAME: string = "fsearch_settings";

const KEY_THEME: string = "theme_mode";
const KEY_LANGUAGE: string = "language";
const KEY_FONT_SIZE: string = "font_size";
const KEY_RECOMMEND: string = "personalized_recommend";
const KEY_TRACKING: string = "app_tracking";
const KEY_HTTPS_ONLY: string = "https_only_token";
const KEY_JS: string = "js_enabled";
const KEY_BROWSER: string = "default_browser";
const KEY_API_BASE_URL: string = "api_base_url";

/** @ObservedV2 设置数据模型,UI 可直接绑定 @Trace 字段。 */
@ObservedV2
export class SettingsData {
  @Trace themeMode: string = "system";
  @Trace language: string = "zh-CN";
  @Trace fontSize: string = "standard";
  @Trace personalizedRecommend: boolean = true;
  @Trace appTracking: boolean = false;
  @Trace httpsOnlyToken: boolean = true;
  @Trace jsEnabled: boolean = true;
  @Trace defaultBrowser: string = "system";
  @Trace apiBaseUrl: string = "";
}

export class SettingsRepository {
  private context: Context | null = null;

  init(context: Context): void {
    this.context = context;
  }

  /** 加载全部设置项,未命中用默认值。 */
  async loadAll(): Promise<SettingsData> {
    const data: SettingsData = new SettingsData();
    if (this.context === null) {
      return data;
    }
    const ctx: Context = this.context;

    const themeVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_THEME);
    if (themeVal !== null) {
      data.themeMode = themeVal;
    }

    const langVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_LANGUAGE);
    if (langVal !== null) {
      data.language = langVal;
    }

    const fontVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_FONT_SIZE);
    if (fontVal !== null) {
      data.fontSize = fontVal;
    }

    const recVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_RECOMMEND);
    if (recVal !== null) {
      data.personalizedRecommend = recVal === "true";
    }

    const trackVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_TRACKING);
    if (trackVal !== null) {
      data.appTracking = trackVal === "true";
    }

    const httpsVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_HTTPS_ONLY);
    if (httpsVal !== null) {
      data.httpsOnlyToken = httpsVal === "true";
    }

    const jsVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_JS);
    if (jsVal !== null) {
      data.jsEnabled = jsVal === "true";
    }

    const browserVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_BROWSER);
    if (browserVal !== null) {
      data.defaultBrowser = browserVal;
    }

    const apiVal: string | null = await PreferencesHelper.getJson(ctx, STORE_NAME, KEY_API_BASE_URL);
    if (apiVal !== null) {
      data.apiBaseUrl = apiVal;
    }

    // 同步到 HttpClient(非空时才设置)
    if (data.apiBaseUrl.length > 0) {
      HttpClient.baseUrl = data.apiBaseUrl;
    }

    return data;
  }

  /** 更新单个设置项并立即落盘。 */
  async update(key: string, value: string | boolean): Promise<void> {
    if (this.context === null) {
      return;
    }
    await PreferencesHelper.putJson(this.context, STORE_NAME, key, String(value));
  }

  // ---- Key 常量暴露给 ViewModel ----
  static readonly KEY_THEME: string = KEY_THEME;
  static readonly KEY_LANGUAGE: string = KEY_LANGUAGE;
  static readonly KEY_FONT_SIZE: string = KEY_FONT_SIZE;
  static readonly KEY_RECOMMEND: string = KEY_RECOMMEND;
  static readonly KEY_TRACKING: string = KEY_TRACKING;
  static readonly KEY_HTTPS_ONLY: string = KEY_HTTPS_ONLY;
  static readonly KEY_JS: string = KEY_JS;
  static readonly KEY_BROWSER: string = KEY_BROWSER;
  static readonly KEY_API_BASE_URL: string = KEY_API_BASE_URL;
}
