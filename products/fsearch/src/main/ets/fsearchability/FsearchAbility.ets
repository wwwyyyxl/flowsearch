import { AbilityConstant, ConfigurationConstant, UIAbility, Want, errorManager } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { pushService, pushCommon } from '@kit.PushKit';
import { RouteTable } from "@flowsearch/router";
import { ThemeManager } from "@flowsearch/theme";
import { PreferencesHelper, NetworkMonitor } from "@flowsearch/base";

const DOMAIN: number = 0x0000;
const TAG: string = 'FsearchAbility';

export default class FsearchAbility extends UIAbility {
  /** 待处理的深链 URI(loadContent 完成后派发到 AppStorage)。 */
  private pendingDeepLinkUri: string = "";

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 先同步设置跟随系统(确保 loadContent 前已生效)
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (_e) {}

    // 异步读取用户保存的主题偏好,读到后覆盖
    try {
      const ctx: Context = this.context;
      PreferencesHelper.getJson(ctx, "fsearch_settings", "theme_mode").then((val: string | null): void => {
        const mode: string = val !== null ? val : "system";
        ThemeManager.apply(mode, ctx);
      }).catch((): void => {
        // 读取失败,保持 COLOR_MODE_NOT_SET(跟随系统)
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to restore theme. Cause: %{public}s', JSON.stringify(err));
    }

    // S12:全局异常捕获
    errorManager.on('globalErrorOccurred', (err: errorManager.GlobalError): void => {
      hilog.error(DOMAIN, TAG, 'Global error: %{public}s', err.message);
      hilog.error(DOMAIN, TAG, 'Stack: %{public}s', err.stack !== undefined ? err.stack : 'No stack');
    });

    // S18:启动网络状态监听
    NetworkMonitor.getInstance().start(this.context);

    // S23:PushKit 初始化(获取 Token + 注册前台消息监听)
    this.initPush();

    // S14:记录深链(loadContent 回调后派发)
    if (want.uri !== undefined && want.uri.length > 0) {
      this.pendingDeepLinkUri = want.uri;
    }

    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  /** S14:app 已在前台时收到新 Want(系统不重建 Ability)。 */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant uri=%{public}s', want.uri ?? 'null');
    if (want.uri !== undefined && want.uri.length > 0) {
      this.pendingDeepLinkUri = want.uri;
      // 窗口已就绪,直接派发
      this.dispatchDeepLink();
    }
  }

  onDestroy(): void {
    errorManager.off('globalErrorOccurred');
    NetworkMonitor.getInstance().stop();
    // S23:注销 PushKit Token 更新监听
    try {
      pushService.off('tokenUpdate');
    } catch (_e) {}
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
      // S14:loadContent 完成后派发待处理的深链
      this.dispatchDeepLink();
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  // ============================================================
  // S23: PushKit 初始化
  // ============================================================

  /**
   * PushKit 初始化:获取 Token + 注册前台消息监听 + 监听 Token 轮转。
   *
   * 鸿蒙文档依据:
   *   - pushService.getToken(): Promise<string> — 获取推送 Token(112 字符)
   *   - pushService.receiveMessage('DEFAULT', this, callback) — 前台通知消息
   *   - pushService.on('tokenUpdate', this, callback) — Token 轮转(跨区变更)
   *   - pushService.off('tokenUpdate') — onDestroy 注销
   *   - 需要 module.json5 中 action.ohos.push.listener skill
   *   - 不需要 ohos.permission.RECEIVE_MESSAGE(那是旧 HMS SDK)
   */
  private initPush(): void {
    // 1. 获取推送 Token
    pushService.getToken().then((token: string): void => {
      hilog.info(DOMAIN, TAG, 'Push token obtained, length=%{public}d', token.length);
    }).catch((err: object): void => {
      hilog.warn(DOMAIN, TAG, 'Push getToken failed: %{public}s', JSON.stringify(err));
    });

    // 2. 注册前台通知消息监听
    try {
      pushService.receiveMessage('DEFAULT', this, (payload: pushCommon.PushPayload): void => {
        hilog.info(DOMAIN, TAG, 'Push message received, type=%{public}s', payload.type);
        // payload.data 是 JSON 字符串，包含 notification.title / notification.body 等
        // 完整日志输出便于调试，生产环境按需解析
        hilog.info(DOMAIN, TAG, 'Push payload: %{public}s', payload.data);
      });
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'Push receiveMessage failed: %{public}s', JSON.stringify(err));
    }

    // 3. 监听 Token 轮转(设备跨区变更时 Token 更新)
    try {
      pushService.on('tokenUpdate', this, (newToken: string): void => {
        hilog.info(DOMAIN, TAG, 'Push token updated, length=%{public}d', newToken.length);
      });
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'Push on(tokenUpdate) failed: %{public}s', JSON.stringify(err));
    }
  }

  // ============================================================
  // S14: Deep Link 解析与派发
  // ============================================================

  /**
   * 派发深链到 AppStorage,由 Index.ets.aboutToAppear 消费。
   *
   * flowsearch://web?url=https%3A%2F%2Fexample.com&title=Article
   *   -> __dl_route = "web.container", __dl_url = decoded url
   *
   * flowsearch://search?keyword=arkts
   *   -> __dl_route = "search.result", __dl_keyword = "arkts"
   */
  private dispatchDeepLink(): void {
    const wantUri: string = this.pendingDeepLinkUri;
    if (wantUri.length === 0) {
      return;
    }
    // 清除,防止重复派发
    this.pendingDeepLinkUri = "";

    try {
      // 手动解析 URI: flowsearch://web?url=xxx 或 flowsearch://search?keyword=xxx
      // 格式: scheme://host?query
      const schemeEnd: number = wantUri.indexOf("://");
      if (schemeEnd < 0) {
        return;
      }
      const scheme: string = wantUri.substring(0, schemeEnd);
      if (scheme !== "flowsearch") {
        hilog.warn(DOMAIN, TAG, 'Deep link: unknown scheme %{public}s', scheme);
        return;
      }

      const afterScheme: string = wantUri.substring(schemeEnd + 3);
      const queryStart: number = afterScheme.indexOf("?");
      const host: string = queryStart >= 0 ? afterScheme.substring(0, queryStart) : afterScheme;
      const queryStr: string = queryStart >= 0 ? afterScheme.substring(queryStart + 1) : "";

      const params: Record<string, string> = parseQueryString(queryStr);

      if (host === "web") {
        const url: string = params["url"] ?? "";
        if (url.length > 0) {
          AppStorage.setOrCreate<string>("__dl_route", RouteTable.WEB_CONTAINER);
          AppStorage.setOrCreate<string>("__dl_url", url);
          AppStorage.setOrCreate<string>("__dl_title", params["title"] ?? "");
          hilog.info(DOMAIN, TAG, 'Deep link: web url=%{public}s', url);
        }
      } else if (host === "search") {
        const keyword: string = params["keyword"] ?? "";
        if (keyword.length > 0) {
          AppStorage.setOrCreate<string>("__dl_route", RouteTable.SEARCH_RESULT);
          AppStorage.setOrCreate<string>("__dl_keyword", keyword);
          hilog.info(DOMAIN, TAG, 'Deep link: search keyword=%{public}s', keyword);
        }
      } else {
        hilog.warn(DOMAIN, TAG, 'Deep link: unknown host %{public}s', host);
      }
    } catch (_e) {
      hilog.error(DOMAIN, TAG, 'Deep link parse failed: %{public}s', wantUri);
    }
  }
}

/**
 * 从 query string 解析 key=value 对。
 * ArkTS 无 new URL(),手动用 indexOf("=") + split("&") + decodeURIComponent。
 */
function parseQueryString(query: string): Record<string, string> {
  const result: Record<string, string> = {};
  if (query.length === 0) {
    return result;
  }
  const pairs: string[] = query.split("&");
  for (let i = 0; i < pairs.length; i++) {
    const eqIdx: number = pairs[i].indexOf("=");
    if (eqIdx > 0) {
      const key: string = decodeURIComponent(pairs[i].substring(0, eqIdx));
      const val: string = decodeURIComponent(pairs[i].substring(eqIdx + 1));
      result[key] = val;
    }
  }
  return result;
}
