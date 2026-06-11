/**
 * @file SettingsPage.ets
 * @description 设置页主页面(P06 Settings)。4 组设置 + 2 个弹层。
 *
 * 设计要点:
 *
 * 1. NavDestination 包裹,与 FavoritesHistoryPage / WebContainerPage 同型。
 *    @Param navPathStack 接收路由栈。
 *
 * 2. Stack 分层:主体 Column(顶栏+Scrollable 设置列表) + ConfirmDialog overlay + UpdateDialog overlay。
 *    弹层永久渲染,由 VM boolean flag 控制显隐,与 LoginExpiredDialog 模式一致。
 *
 * 3. 4 个 SettingsGroup:
 *    通用(主题/语言/字体) → 纯占位,点 Toast
 *    隐私与数据(Switch + 清理) → Switch 接 Preferences,清理弹确认弹层
 *    Web 容器(Switch + 浏览器) → 占位
 *    关于(版本/更新/协议) → 检查更新弹 UpdateDialog,其余 Toast
 *
 * 4. Context 注入:
 *    aboutToAppear() 调 getContext(this) 传给 vm.init(),
 *    VM → SettingsRepository → PreferencesHelper 全链路。
 *
 * 5. @Builder 禁令:
 *    buildGroup1 / buildGroup2 等内不声明 const,
 *    数据在 build() 体算好通过参数传入 @Builder。
 */

import promptAction from "@ohos.promptAction";
import { RouteTable } from "@flowsearch/router";
import { ThemeManager, FontScaleManager } from "@flowsearch/theme";
import { SettingsViewModel } from "../viewmodel/SettingsViewModel";
import { SettingsRepository } from "../repo/SettingsRepository";
import { SettingsGroup } from "../components/SettingsGroup";
import { SettingsItem } from "../components/SettingsItem";
import { ConfirmDialog } from "../components/ConfirmDialog";
import { UpdateDialog } from "../components/UpdateDialog";

@ComponentV2
export struct SettingsPage {
  @Param navPathStack: NavPathStack = new NavPathStack();

  @Local vm: SettingsViewModel = new SettingsViewModel();

  /** 弹层描述文本(在 build() 外算好,避免 @Builder 内 const)。 */
  @Local clearDescription: string = "";

  /** S9:主题选择弹层。 */
  @Local showThemePicker: boolean = false;

  /** S10:字体大小选择弹层。 */
  @Local showFontSizePicker: boolean = false;

  aboutToAppear(): void {
    this.vm.init(getContext(this));
  }

  build() {
    NavDestination() {
      Stack() {
        // ===== 主体 =====
        Column() {
          // 1. 顶栏
          Row() {
            Text("←")
              .fontSize(20)
              .fontColor($r("app.color.fs_color_text_primary"))
              .onClick((): void => { this.navPathStack.pop(); })
            Text("设置")
              .fontSize($r("app.float.fs_text_title_2"))
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.fs_color_text_primary"))
              .margin({ left: $r("app.float.fs_space_md") })
          }
          .width("100%")
          .height(56)
          .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
          .alignItems(VerticalAlign.Center)
          .backgroundColor($r("app.color.fs_color_surface"))

          // 2. 设置列表(Scrollable)
          Scroll() {
            Column({ space: 24 }) {
              this.buildGroup1()
              this.buildGroup2()
              this.buildGroup3()
              this.buildGroup4()
            }
            .width("100%")
            .padding({
              left: $r("app.float.fs_space_lg"),
              right: $r("app.float.fs_space_lg"),
              top: $r("app.float.fs_space_lg"),
              bottom: $r("app.float.fs_space_3xl")
            })
          }
          .layoutWeight(1)
          .width("100%")
          .scrollBar(BarState.Off)
        }
        .width("100%")
        .height("100%")
        .backgroundColor($r("app.color.fs_color_background"))

        // ===== 清理确认弹层 =====
        ConfirmDialog({
          visible: this.vm.showClearDialog,
          title: this.getClearTitle(),
          description: this.getClearDescription(),
          confirmLabel: "清理",
          isDanger: true,
          onCancelTap: (): void => { this.vm.cancelClear(); },
          onConfirmTap: (): void => { this.vm.confirmClear(); }
        })

        // ===== 版本更新弹层 =====
        UpdateDialog({
          visible: this.vm.showUpdateDialog,
          onCancelTap: (): void => { this.vm.cancelUpdate(); },
          onUpdateTap: (): void => { this.vm.confirmUpdate(); }
        })

        // ===== S9:主题选择弹层 =====
        this.buildThemePicker()

        // ===== S10:字体大小选择弹层 =====
        this.buildFontSizePicker()
      }
      .width("100%")
      .height("100%")
    }
    .hideTitleBar(true)
  }

  /** 获取弹层标题(按 clearDialogTarget 分支)。 */
  private getClearTitle(): string {
    if (this.vm.clearDialogTarget === "cache") {
      return "清理缓存";
    }
    if (this.vm.clearDialogTarget === "history") {
      return "清理搜索历史";
    }
    return "清理收藏";
  }

  /** 获取弹层描述(按 clearDialogTarget 分支)。 */
  private getClearDescription(): string {
    if (this.vm.clearDialogTarget === "cache") {
      return "将清除应用缓存数据，此操作不可撤销。";
    }
    if (this.vm.clearDialogTarget === "history") {
      return "将清除全部搜索历史记录，此操作不可撤销。";
    }
    return "将清除全部收藏内容，此操作不可撤销。";
  }

  // ============================================================
  // 分组 1: 通用
  // ============================================================
  @Builder
  buildGroup1() {
    SettingsGroup({ title: "通用" }) {
      SettingsItem({
        icon: "🎨",
        title: "主题模式",
        itemType: "text",
        value: ThemeManager.label(this.vm.settings.themeMode),
        showDivider: true,
        onTap: (): void => { this.showThemePicker = true; }
      })
      SettingsItem({
        icon: "🌐",
        title: "语言",
        itemType: "text",
        value: "简体中文",
        showDivider: true,
        onTap: (): void => { promptAction.showToast({ message: "语言设置(占位)" }); }
      })
      SettingsItem({
        icon: "🔤",
        title: "字体大小",
        itemType: "text",
        value: FontScaleManager.label(this.vm.settings.fontSize),
        showDivider: false,
        onTap: (): void => { this.showFontSizePicker = true; }
      })
    }
  }

  // ============================================================
  // 分组 2: 隐私与数据
  // ============================================================
  @Builder
  buildGroup2() {
    SettingsGroup({ title: "隐私与数据" }) {
      SettingsItem({
        icon: "🛡",
        title: "个性化推荐",
        itemType: "switch",
        switchOn: this.vm.settings.personalizedRecommend,
        showDivider: true,
        onSwitchChange: (on: boolean): void => {
          this.vm.updateSetting(SettingsRepository.KEY_RECOMMEND, on);
        }
      })
      SettingsItem({
        icon: "📋",
        title: "应用内追踪",
        itemType: "switch",
        switchOn: this.vm.settings.appTracking,
        showDivider: true,
        onSwitchChange: (on: boolean): void => {
          this.vm.updateSetting(SettingsRepository.KEY_TRACKING, on);
        }
      })
      SettingsItem({
        icon: "🧹",
        title: "清理缓存",
        itemType: "text",
        value: this.vm.cacheSizeText,
        showDivider: true,
        onTap: (): void => { this.vm.requestClear("cache"); }
      })
      SettingsItem({
        icon: "🕒",
        title: "清理搜索历史",
        itemType: "action",
        showDivider: true,
        onTap: (): void => { this.vm.requestClear("history"); }
      })
      SettingsItem({
        icon: "❤",
        title: "清理收藏",
        itemType: "action",
        showDivider: false,
        onTap: (): void => { this.vm.requestClear("favorites"); }
      })
    }
  }

  // ============================================================
  // 分组 3: Web 容器
  // ============================================================
  @Builder
  buildGroup3() {
    SettingsGroup({ title: "Web 容器" }) {
      SettingsItem({
        icon: "🔒",
        title: "仅在 HTTPS 注入登录态",
        itemType: "switch",
        switchOn: this.vm.settings.httpsOnlyToken,
        showDivider: true,
        onSwitchChange: (on: boolean): void => {
          this.vm.updateSetting(SettingsRepository.KEY_HTTPS_ONLY, on);
        }
      })
      SettingsItem({
        icon: "📥",
        title: "启用 JavaScript",
        itemType: "switch",
        switchOn: this.vm.settings.jsEnabled,
        showDivider: true,
        onSwitchChange: (on: boolean): void => {
          this.vm.updateSetting(SettingsRepository.KEY_JS, on);
        }
      })
      SettingsItem({
        icon: "🌍",
        title: "默认浏览器",
        itemType: "text",
        value: "系统",
        showDivider: false,
        onTap: (): void => { promptAction.showToast({ message: "默认浏览器(占位)" }); }
      })
    }
  }

  // ============================================================
  // 分组 4: 关于
  // ============================================================
  @Builder
  buildGroup4() {
    SettingsGroup({ title: "关于" }) {
      SettingsItem({
        icon: "ℹ",
        title: "版本",
        itemType: "info",
        value: "1.0.0",
        showDivider: true
      })
      SettingsItem({
        icon: "🔄",
        title: "检查更新",
        itemType: "action",
        showDivider: true,
        onTap: (): void => { this.vm.checkUpdate(); }
      })
      SettingsItem({
        icon: "📄",
        title: "用户协议",
        itemType: "action",
        showDivider: true,
        onTap: (): void => { this.navPathStack.pushPath({ name: RouteTable.USER_AGREEMENT }); }
      })
      SettingsItem({
        icon: "🔐",
        title: "隐私政策",
        itemType: "action",
        showDivider: true,
        onTap: (): void => { this.navPathStack.pushPath({ name: RouteTable.PRIVACY_POLICY }); }
      })
      SettingsItem({
        icon: "💡",
        title: "反馈",
        itemType: "action",
        showDivider: false,
        onTap: (): void => { promptAction.showToast({ message: "反馈(占位)" }); }
      })
    }
  }

  // ============================================================
  // S9:主题选择弹层
  // ============================================================
  @Builder
  buildThemePicker() {
    if (this.showThemePicker) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("rgba(0,0,0,0.4)")
          .onClick((): void => { this.showThemePicker = false; })

        Column() {
          Text("选择主题")
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))
            .width("100%")
            .textAlign(TextAlign.Center)
            .padding({ top: $r("app.float.fs_space_lg"), bottom: $r("app.float.fs_space_md") })

          Column() {
            this.buildThemeOption("浅色", "light")
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildThemeOption("深色", "dark")
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildThemeOption("跟随系统", "system")
          }
          .width("100%")
          .borderRadius($r("app.float.fs_radius_lg"))
          .backgroundColor($r("app.color.fs_color_surface"))
          .clip(true)

          Text("取消")
            .fontSize($r("app.float.fs_text_body_lg"))
            .fontColor($r("app.color.fs_color_text_primary"))
            .textAlign(TextAlign.Center)
            .width("100%")
            .height($r("app.float.fs_height_button"))
            .backgroundColor($r("app.color.fs_color_surface"))
            .borderRadius($r("app.float.fs_radius_lg"))
            .margin({ top: 8 })
            .onClick((): void => { this.showThemePicker = false; })
        }
        .width("100%")
        .padding({
          left: $r("app.float.fs_space_lg"),
          right: $r("app.float.fs_space_lg"),
          bottom: $r("app.float.fs_space_3xl")
        })
      }
      .width("100%")
      .height("100%")
    }
  }

  @Builder
  buildThemeOption(label: string, mode: string) {
    Row() {
      Text(label)
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontColor($r("app.color.fs_color_text_primary"))
        .layoutWeight(1)
      if (this.vm.settings.themeMode === mode) {
        Text("✓")
          .fontSize(18)
          .fontColor($r("app.color.fs_color_primary"))
      }
    }
    .width("100%")
    .height($r("app.float.fs_height_list_single"))
    .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.vm.changeThemeMode(mode);
      this.showThemePicker = false;
    })
  }

  // ============================================================
  // S10:字体大小选择弹层
  // ============================================================
  @Builder
  buildFontSizePicker() {
    if (this.showFontSizePicker) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width("100%")
          .height("100%")
          .backgroundColor("rgba(0,0,0,0.4)")
          .onClick((): void => { this.showFontSizePicker = false; })

        Column() {
          Text("字体大小")
            .fontSize($r("app.float.fs_text_title_2"))
            .fontWeight(FontWeight.Bold)
            .fontColor($r("app.color.fs_color_text_primary"))
            .width("100%")
            .textAlign(TextAlign.Center)
            .padding({ top: $r("app.float.fs_space_lg"), bottom: $r("app.float.fs_space_md") })

          Column() {
            this.buildFontSizeOption("小号", "small")
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildFontSizeOption("标准", "standard")
            Divider().strokeWidth(0.5).color($r("app.color.fs_color_border")).opacity(0.5)
            this.buildFontSizeOption("大号", "large")
          }
          .width("100%")
          .borderRadius($r("app.float.fs_radius_lg"))
          .backgroundColor($r("app.color.fs_color_surface"))
          .clip(true)

          Text("取消")
            .fontSize($r("app.float.fs_text_body_lg"))
            .fontColor($r("app.color.fs_color_text_primary"))
            .textAlign(TextAlign.Center)
            .width("100%")
            .height($r("app.float.fs_height_button"))
            .backgroundColor($r("app.color.fs_color_surface"))
            .borderRadius($r("app.float.fs_radius_lg"))
            .margin({ top: 8 })
            .onClick((): void => { this.showFontSizePicker = false; })
        }
        .width("100%")
        .padding({
          left: $r("app.float.fs_space_lg"),
          right: $r("app.float.fs_space_lg"),
          bottom: $r("app.float.fs_space_3xl")
        })
      }
      .width("100%")
      .height("100%")
    }
  }

  @Builder
  buildFontSizeOption(label: string, size: string) {
    Row() {
      Text(label)
        .fontSize($r("app.float.fs_text_body_lg"))
        .fontColor($r("app.color.fs_color_text_primary"))
        .layoutWeight(1)
      if (this.vm.settings.fontSize === size) {
        Text("✓")
          .fontSize(18)
          .fontColor($r("app.color.fs_color_primary"))
      }
    }
    .width("100%")
    .height($r("app.float.fs_height_list_single"))
    .padding({ left: $r("app.float.fs_space_lg"), right: $r("app.float.fs_space_lg") })
    .alignItems(VerticalAlign.Center)
    .onClick((): void => {
      this.vm.changeFontSize(size);
      this.showFontSizePicker = false;
    })
  }
}
