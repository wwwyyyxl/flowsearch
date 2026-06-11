/**
 * @file SettingsViewModel.ets
 * @description 设置页 ViewModel。管理设置状态 + 弹层控制 + 清理操作。
 *
 * 设计要点:
 *
 * 1. @ObservedV2 + @Trace:与 FavsViewModel / HomeViewModel 同源。
 *    settings / cacheSizeText / showClearDialog 变化自动触发 UI 重渲。
 *
 * 2. 三合一持有:SettingsRepository + HistoryRepository + FavoritesRepository。
 *    前者读写设置,后两者执行"清理历史/收藏"。
 *
 * 3. 清理操作两步走:
 *    requestClear(target) → 弹确认弹层(设 showClearDialog + clearDialogTarget)
 *    confirmClear() → 根据 target 执行清理 + Toast 反馈。
 *
 * 4. 缓存大小:aboutToAppear 时异步计算并显示。
 *    清理缓存后重新计算(或直接显示 "0 B")。
 */

import promptAction from "@ohos.promptAction";
import { SettingsRepository, SettingsData } from "../repo/SettingsRepository";
import { CacheCalculator } from "../cache/CacheCalculator";
import { HistoryRepository, FavoritesRepository } from "@flowsearch/favs";
import { ThemeManager, FontScaleManager } from "@flowsearch/theme";

@ObservedV2
export class SettingsViewModel {
  /** 全部设置项(内存态,UI 直接绑定)。 */
  @Trace settings: SettingsData = new SettingsData();

  /** 缓存大小显示文本。 */
  @Trace cacheSizeText: string = "计算中...";

  /** 控制清理确认弹层。 */
  @Trace showClearDialog: boolean = false;

  /** 弹层目标:"cache" | "history" | "favorites"。 */
  @Trace clearDialogTarget: string = "cache";

  /** 控制版本更新弹层。 */
  @Trace showUpdateDialog: boolean = false;

  private settingsRepo: SettingsRepository = new SettingsRepository();
  private historyRepo: HistoryRepository = new HistoryRepository();
  private favRepo: FavoritesRepository = new FavoritesRepository();
  private context: Context | null = null;

  init(context: Context): void {
    this.context = context;
    this.settingsRepo.init(context);
    this.historyRepo.init(context);
    this.favRepo.init(context);
    this.loadSettings();
    this.loadCacheSize();
  }

  /** 加载设置。 */
  private loadSettings(): void {
    this.settingsRepo.loadAll().then((data: SettingsData): void => {
      this.settings = data;
      // S9:恢复上次保存的主题模式
      if (this.context !== null) {
        ThemeManager.apply(data.themeMode, this.context);
      }
      // S10 fix:恢复上次保存的字体大小
      if (this.context !== null) {
        FontScaleManager.apply(data.fontSize, this.context);
      }
    }).catch((_err: object): void => {
      // 加载失败用默认值(已经是 SettingsData 默认)
    });
  }

  /**
   * S9:切换主题模式。持久化 + 立即应用。
   * 与 updateSetting 分开,因为需要额外调 ThemeManager.apply。
   */
  changeThemeMode(mode: string): void {
    this.updateSetting(SettingsRepository.KEY_THEME, mode);
    if (this.context !== null) {
      ThemeManager.apply(mode, this.context);
    }
  }

  /** S10:切换字体大小。持久化 + 立即应用缩放。 */
  changeFontSize(size: string): void {
    this.updateSetting(SettingsRepository.KEY_FONT_SIZE, size);
    if (this.context !== null) {
      FontScaleManager.apply(size, this.context);
    }
  }

  /** 计算缓存大小。 */
  private loadCacheSize(): void {
    if (this.context === null) {
      return;
    }
    const cacheDir: string = this.context.cacheDir;
    CacheCalculator.getCacheSize(cacheDir).then((bytes: number): void => {
      this.cacheSizeText = CacheCalculator.formatSize(bytes);
    }).catch((_err: object): void => {
      this.cacheSizeText = "0 B";
    });
  }

  /** 更新单个设置项(即时写 Preferences)。 */
  updateSetting(key: string, value: string | boolean): void {
    // 内存先行(UI 即时反馈)
    if (key === SettingsRepository.KEY_RECOMMEND) {
      this.settings.personalizedRecommend = value as boolean;
    } else if (key === SettingsRepository.KEY_TRACKING) {
      this.settings.appTracking = value as boolean;
    } else if (key === SettingsRepository.KEY_HTTPS_ONLY) {
      this.settings.httpsOnlyToken = value as boolean;
    } else if (key === SettingsRepository.KEY_JS) {
      this.settings.jsEnabled = value as boolean;
    } else if (key === SettingsRepository.KEY_FONT_SIZE) {
      this.settings.fontSize = value as string;
    } else if (key === SettingsRepository.KEY_THEME) {
      this.settings.themeMode = value as string;
    } else if (key === SettingsRepository.KEY_LANGUAGE) {
      this.settings.language = value as string;
    } else if (key === SettingsRepository.KEY_BROWSER) {
      this.settings.defaultBrowser = value as string;
    }
    // 磁盘异步
    this.settingsRepo.update(key, value);
  }

  /** 弹确认弹层。 */
  requestClear(target: string): void {
    this.clearDialogTarget = target;
    this.showClearDialog = true;
  }

  /** 取消清理。 */
  cancelClear(): void {
    this.showClearDialog = false;
  }

  /** 执行清理(确认后)。 */
  confirmClear(): void {
    const target: string = this.clearDialogTarget;
    this.showClearDialog = false;

    if (target === "cache") {
      this.clearCache();
    } else if (target === "history") {
      this.clearHistory();
    } else if (target === "favorites") {
      this.clearFavorites();
    }
  }

  /** 清理缓存。 */
  private clearCache(): void {
    if (this.context === null) {
      return;
    }
    const cacheDir: string = this.context.cacheDir;
    CacheCalculator.clearCacheDir(cacheDir).then((): void => {
      this.cacheSizeText = "0 B";
      promptAction.showToast({ message: "缓存已清理" });
    }).catch((_err: object): void => {
      promptAction.showToast({ message: "清理失败" });
    });
  }

  /** 清理搜索历史。 */
  private clearHistory(): void {
    this.historyRepo.clearAll().then((): void => {
      promptAction.showToast({ message: "搜索历史已清理" });
    }).catch((_err: object): void => {
      promptAction.showToast({ message: "清理失败" });
    });
  }

  /** 清理收藏。 */
  private clearFavorites(): void {
    this.favRepo.clearAll().then((): void => {
      promptAction.showToast({ message: "收藏已清理" });
    }).catch((_err: object): void => {
      promptAction.showToast({ message: "清理失败" });
    });
  }

  /** 弹版本更新弹层(mock)。 */
  checkUpdate(): void {
    this.showUpdateDialog = true;
  }

  /** 取消版本更新。 */
  cancelUpdate(): void {
    this.showUpdateDialog = false;
  }

  /** 确认更新(mock)。 */
  confirmUpdate(): void {
    this.showUpdateDialog = false;
    promptAction.showToast({ message: "已是最新版本" });
  }
}
