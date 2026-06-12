/**
 * @file WebContainerPage.ets
 * @description WebContainer 主页面(P04)。装配 VM + 7 个子组件 + ArkUI Web 组件。
 *
 * 简历主线 1 核心证据页:
 *  - URL 拦截(onLoadIntercept 调 VM.interceptUrl,策略模式分 5 种 action)
 *  - 登录态透传(VM.shouldInjectToken 判断,Page 在 Content 后调 runJavaScript 注入 cookie)
 *  - 白屏错误页(WebErrorPage 双按钮次左主右, LOAD_NO_CACHE 重载)
 *  - 返回栈(PR 转述:← 直接 pop,系统返回键 canGoBack/goBack 由 Web 组件内处理)
 *  - 慢加载检测(VM 内 5s 定时器 -> SlowLoadBar)
 *
 * 架构要点:
 *  - 不用整页 StateHost:顶栏+进度条在所有状态下保留,同 SearchResultPage 思路
 *  - 顶栏+弹层永久渲染,主体按 vm.state.kind 三态自渲染
 *  - @Builder buildBodyContent(data) 传参,不放 const(ArkTS @Builder 禁令)
 *  - WebviewController 持有,离页 controller.stop() 防内存泄漏
 */

import promptAction from "@ohos.promptAction";
import webview from "@ohos.web.webview";
import { common } from "@kit.AbilityKit";
import { systemShare } from "@kit.ShareKit";
import { uniformTypeDescriptor as utd } from "@kit.ArkData";
import { BusinessError } from "@kit.BasicServicesKit";
import { PageState, WebContainerData } from "@flowsearch/base";
import { WebContainerViewModel } from "../viewmodel/WebContainerViewModel";
import { WebTopBar } from "../components/WebTopBar";
import { WebProgressBar } from "../components/WebProgressBar";
import { WebErrorPage } from "../components/WebErrorPage";
import { LoginExpiredDialog } from "../components/LoginExpiredDialog";
import { ExternalConfirmDialog } from "../components/ExternalConfirmDialog";
import { SlowLoadBar } from "../components/SlowLoadBar";
import { WebActionSheet } from "../components/WebActionSheet";

@ComponentV2
export struct WebContainerPage {
  @Param navPathStack: NavPathStack = new NavPathStack();
  @Param url: string = "";
  @Param title: string = "";
  @Param needTokenInject: boolean = false;
  @Param forceAllow: boolean = false;
  @Param articleId: string = "";

  @Local vm: WebContainerViewModel = new WebContainerViewModel();

  /** Web 组件控制器。@Local 让 struct 持有,生命周期与组件绑定。 */
  @Local controller: webview.WebviewController = new webview.WebviewController();

  /** 安全域(跳过首次拦截:首屏 loadUrl 是 VM 选中的,已在拦截之外)。 */
  @Local isFirstLoad: boolean = true;

  aboutToAppear(): void {
    this.vm.init(this.url, this.title, this.needTokenInject, this.forceAllow, this.articleId, getContext(this));
  }

  aboutToDisappear(): void {
    // 防内存泄漏:停止加载,释放 Web 组件(PRD §04-04 §6 性能护栏)
    try {
      this.controller.stop();
    } catch (_e) {
      // 页面未加载时 stop 可能抛,吞掉
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 1. 顶栏(永久渲染)
          WebTopBar({
            title: this.currentTitle(),
            domain: this.currentDomain(),
            isHttps: this.currentIsHttps(),
            onBackTap: (): void => {
              // 顶部 ← 按钮直接关闭,不消费 WebView 内部历史栈(PRD §04-04 §4)
              this.navPathStack.pop();
            },
            onMoreTap: (): void => {
              // 本期 Toast 占位(S5 设置接入后改菜单)
              this.showMoreMenu();
            }
          })

          // 2. 进度条
          WebProgressBar({ progress: this.vm.progress })

          // 3. 慢加载黄条
          SlowLoadBar({
            visible: this.vm.showSlowBar,
            onStopTap: (): void => {
              this.controller.stop();
              this.vm.stopLoading();
            }
          })

          // 4. 主体内容(三态)
          Column() {
            if (this.vm.state.isLoading() || this.vm.state.isIdle()) {
              this.buildLoading()
            } else if (this.vm.state.isError()) {
              WebErrorPage({
                errorCode: this.vm.state.errorCode,
                traceTail: this.vm.getTraceTail(),
                onBackTap: (): void => { this.navPathStack.pop(); },
                onRetryTap: (): void => { this.handleRetry(); }
              })
            } else {
              this.buildBodyContent(this.vm.getCurrentData())
            }
          }
          .layoutWeight(1)
          .width("100%")
        }
        .width("100%")
        .height("100%")
        .backgroundColor($r("app.color.fs_color_background"))

        // 5. 登录过期弹层(Overlay,不进 PageState)
        LoginExpiredDialog({
          visible: this.vm.showLoginExpired,
          onCancelTap: (): void => { this.vm.cancelLoginExpired(); },
          onConfirmTap: (): void => {
            this.vm.confirmLoginExpired();
            // 清登录态后跳回首页(模拟:pop + clear 到根)
            this.navPathStack.clear();
          }
        })

        // 6. 外跳确认弹层
        ExternalConfirmDialog({
          visible: this.vm.showExternalConfirm,
          targetUrl: this.vm.pendingExternalUrl,
          onCancelTap: (): void => { this.vm.cancelExternalOpen(); },
          onConfirmTap: (): void => {
            this.vm.confirmExternalOpen();
            // 本期 Toast 占位(真实系统应用跳转用 @ohos.ability.startAbility)
          }
        })

        // 7. 更多菜单 ActionSheet
        WebActionSheet({
          visible: this.vm.showMoreMenu,
          isFavorited: this.vm.isFavorited,
          onCancelTap: (): void => { this.vm.closeMoreMenu(); },
          onRefreshTap: (): void => {
            this.vm.closeMoreMenu();
            try {
              const currentData: WebContainerData | null = this.vm.getCurrentData();
              if (currentData !== null) {
                this.controller.loadUrl(currentData.currentUrl);
              }
            } catch (_e) {
              // controller 可能未初始化
            }
          },
          onOpenInBrowserTap: (): void => {
            this.vm.closeMoreMenu();
            const data: WebContainerData | null = this.vm.getCurrentData();
            if (data !== null) {
              const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
              ctx.openLink(data.currentUrl);
            }
          },
          onCopyLinkTap: (): void => {
            this.vm.copyLink();
          },
          onShareTap: (): void => {
            this.vm.closeMoreMenu();
            const data: WebContainerData | null = this.vm.getCurrentData();
            if (data !== null) {
              const shareData: systemShare.SharedData = new systemShare.SharedData({
                utd: utd.UniformDataType.TEXT,
                content: data.currentUrl
              });
              const controller: systemShare.ShareController = new systemShare.ShareController(shareData);
              const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
              controller.show(ctx, {
                selectionMode: systemShare.SelectionMode.SINGLE
              });
            }
          },
          onFavoriteTap: (): void => {
            this.vm.toggleFavorite();
            this.vm.closeMoreMenu();
          }
        })
      }
      .width("100%")
      .height("100%")
    }
    .hideTitleBar(true)
  }

  // ============================================================
  // Loading 骨架(PRD §04-04 §5.1:顶部灰条 + 三段灰条)
  // ============================================================
  @Builder
  buildLoading() {
    Column() {
      Column()
        .width("60%")
        .height(20)
        .borderRadius(4)
        .backgroundColor($r("app.color.fs_color_border"))
        .opacity(0.4)
        .margin({ top: $r("app.float.fs_space_lg") })

      Column({ space: 12 }) {
        Column()
          .width("100%")
          .height(16)
          .borderRadius(4)
          .backgroundColor($r("app.color.fs_color_border"))
          .opacity(0.4)
        Column()
          .width("100%")
          .height(16)
          .borderRadius(4)
          .backgroundColor($r("app.color.fs_color_border"))
          .opacity(0.4)
        Column()
          .width("80%")
          .height(16)
          .borderRadius(4)
          .backgroundColor($r("app.color.fs_color_border"))
          .opacity(0.4)
      }
      .width("100%")
      .margin({ top: $r("app.float.fs_space_lg") })
    }
    .width("100%")
    .height("100%")
    .padding($r("app.float.fs_space_xl"))
    .backgroundColor($r("app.color.fs_color_surface"))
  }

  // ============================================================
  // Content 主体:Web 组件(data 从 build() 体算好传入,遵守 @Builder 禁令)
  // ============================================================
  @Builder
  buildBodyContent(data: WebContainerData | null) {
    if (data !== null) {
      Web({
        src: data.currentUrl,
        controller: this.controller
      })
        .domStorageAccess(true)
        .javaScriptAccess(true)  // Mock 场景全开;白名单域名阶段再限
        .mixedMode(MixedMode.Compatible)
        .cacheMode(CacheMode.Default)
        .onPageBegin((_event?: OnPageBeginEvent): void => {
          // 新 URL 开始加载:重置 progress,触发慢加载计时
          // 首屏已在 VM.init 内触发,这里处理后续内部跳转
          if (!this.isFirstLoad) {
            this.vm.progress = 0;
          }
        })
        .onPageEnd((event: OnPageEndEvent): void => {
          this.vm.onPageEnd(event.url);
          // 首屏加载完,后续拦截由 onLoadIntercept 处理
          this.isFirstLoad = false;
          // 登录态注入(needTokenInject=true 时,Content 加载完注入 cookie)
          if (this.vm.getCurrentData() !== null) {
            const currentData: WebContainerData = this.vm.getCurrentData() as WebContainerData;
            if (this.vm.shouldInjectToken(currentData.currentUrl)) {
              this.controller.runJavaScript(`document.cookie = "Authorization=${this.vm.getAuthHeader()}";`);
            }
          }
        })
        .onProgressChange((event: OnProgressChangeEvent): void => {
          this.vm.onProgressChange(event.newProgress);
        })
        .onTitleReceive((event: OnTitleReceiveEvent): void => {
          this.vm.onTitleReceive(event.title);
        })
        .onErrorReceive((event?: OnErrorReceiveEvent): void => {
          const code: string = event !== undefined ? event.error.getErrorCode().toString() : "UNKNOWN";
          const msg: string = event !== undefined ? event.error.getErrorInfo() : "未知网络错误";
          this.vm.onPageError(code, msg);
        })
        .onLoadIntercept((event: OnLoadInterceptEvent): boolean => {
          // ★ 核心拦截入口(简历主线 1 证据点)
          // 首屏 loadUrl 放行(已在 VM.init 前处理过拦截)
          if (this.isFirstLoad) {
            return false;
          }
          const interceptedUrl: string = event.data.getRequestUrl();
          return this.vm.interceptUrl(interceptedUrl);
        })
        .layoutWeight(1)
        .width("100%")
        .backgroundColor($r("app.color.fs_color_surface"))
    }
  }

  // ============================================================
  // 辅助:getCurrentData 的安全访问
  // ============================================================
  private currentTitle(): string {
    const data: WebContainerData | null = this.vm.getCurrentData();
    if (data !== null) {
      return data.displayTitle;
    }
    return this.title;
  }

  private currentDomain(): string {
    const data: WebContainerData | null = this.vm.getCurrentData();
    if (data !== null) {
      return data.domain;
    }
    return this.url;
  }

  private currentIsHttps(): boolean {
    const data: WebContainerData | null = this.vm.getCurrentData();
    if (data !== null) {
      return data.isHttps;
    }
    return this.url.indexOf("https://") === 0;
  }

  /**
   * 错误页重试:LOAD_NO_CACHE 模式重载(PRD §04-04 §5.2)。
   */
  private handleRetry(): void {
    this.vm.retryLoad();
    try {
      // URL 加时间戳绕缓存(loadUrl 签名不支持 CacheMode)
      const bustUrl: string = this.vm.initialUrl + (this.vm.initialUrl.indexOf("?") >= 0 ? "&" : "?") + "_t=" + new Date().getTime().toString();
      this.controller.loadUrl(bustUrl);
    } catch (_e) {
      // controller 可能未初始化(规则加载阶段就失败),吞掉
    }
  }

  /**
   * 更多菜单(S5 接入 WebActionSheet)。
   */
  private showMoreMenu(): void {
    this.vm.openMoreMenu();
  }
}
