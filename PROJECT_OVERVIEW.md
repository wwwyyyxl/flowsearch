# FlowSearch 项目全景文档

> **Bundle:** `com.xleo.flowsearch` | **SDK:** 6.1.1(24) | **Sprint:** S0-S16 完成  
> **最后更新:** 2026-06-12

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术栈与架构决策](#2-技术栈与架构决策)
3. [模块依赖关系](#3-模块依赖关系)
4. [路由系统](#4-路由系统)
5. [状态管理模式](#5-状态管理模式)
6. [持久化策略](#6-持久化策略)
7. [深色模式完整方案](#7-深色模式完整方案)
8. [国际化方案](#8-国际化方案)
9. [各模块详细拆解](#9-各模块详细拆解)
   - 9.1 [Product: fsearch (入口)](#91-product-fsearch-入口)
   - 9.2 [Commons: base (基础类型)](#92-commons-base-基础类型)
   - 9.3 [Commons: theme (主题)](#93-commons-theme-主题)
   - 9.4 [Commons: router (路由)](#94-commons-router-路由)
   - 9.5 [Commons: ui (共享组件)](#95-commons-ui-共享组件)
   - 9.6 [Commons: mockdata (模拟数据)](#96-commons-mockdata-模拟数据)
   - 9.7 [Feature: home (首页)](#97-feature-home-首页)
   - 9.8 [Feature: search (搜索)](#98-feature-search-搜索)
   - 9.9 [Feature: web (网页容器)](#99-feature-web-网页容器)
   - 9.10 [Feature: favs (收藏/历史)](#910-feature-favs-收藏历史)
   - 9.11 [Feature: settings (设置)](#911-feature-settings-设置)
   - 9.12 [Feature: toolshell (工具外壳)](#912-feature-toolshell-工具外壳)
10. [页面功能流转图](#10-页面功能流转图)
11. [Sprint 完成记录](#11-sprint-完成记录)
12. [已知限制与待办](#12-已知限制与待办)
13. [构建与运行](#13-构建与运行)

---

## 1. 项目概述

FlowSearch 是一个 **HarmonyOS 新闻搜索聚合 App**，采用 ArkTS + V2 状态管理开发。核心功能包括：

- 首页信息流（频道切换 + 文章卡片 + 快捷工具入口）
- 搜索系统（输入建议 + 热搜 + 搜索结果 + AI 快答）
- WebView 容器（URL 拦截 + 登录态注入 + 进度条 + 慢加载检测）
- 收藏与历史（收藏管理 + 搜索历史 + 阅读历史）
- 设置中心（主题/字体/隐私/Web 容器开关）
- Deep Link 支持（`flowsearch://web` / `flowsearch://search`）
- 多语言（zh-CN + en-US）
- 深色模式（跟随系统 / 手动切换）

---

## 2. 技术栈与架构决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 状态管理 | **V2 only** (@ComponentV2, @ObservedV2, @Trace) | 细粒度响应式，无 V1 混合 |
| 导航 | **Navigation + NavPathStack** | 鸿蒙推荐，支持 NavDestination 生命周期 |
| 路由表 | **RouteTable 常量类** | 单一来源，string ID + 类型安全 params |
| 数据层 | **Repository 模式** | 零装饰器纯函数，未来换 API 只改 Repo |
| 持久化 | **PreferencesHelper (JSON)** | 轻量级，够用，无数据库依赖 |
| 列表虚拟化 | **LazyForEach + IDataSource** | 三处复用同模式 |
| 资源系统 | **$r() + base/dark 双目录** | 系统自动切色，跨模块同名 token |

### V2 装饰器速查

| 装饰器 | 位置 | 作用 |
|--------|------|------|
| `@ComponentV2` | struct | V2 组件声明 |
| `@Entry` | struct | 页面入口（main_pages.json 注册） |
| `@Local` | struct 属性 | 本地可变状态（Page 层） |
| `@Param` | struct 属性 | 父传子的只读输入 |
| `@Event` | struct 方法 | 子传父的回调 |
| `@Builder` | struct 方法 | 声明式 UI 片段 |
| `@BuilderParam` | struct 属性 | 接受外部传入的 @Builder |
| `@ObservedV2` | class | 可观察类（ViewModel/Repository） |
| `@Trace` | class 属性 | 细粒度追踪（自动触发 UI 刷新） |
| `@Monitor` | struct 方法 | 监听 @Trace 属性变化 |
| `@ReusableV2` | struct | 组件复用池（LazyForEach 优化） |

---

## 3. 模块依赖关系

```
fsearch (entry HAP) ← 唯一可安装产物
  ├── @flowsearch/base          ← 叶子节点，零依赖
  ├── @flowsearch/theme         ← 叶子节点，零依赖
  ├── @flowsearch/router        ← 叶子节点，零依赖
  ├── @flowsearch/ui            → base, theme
  ├── @flowsearch/mockdata      → base
  ├── @flowsearch/favs          → base, theme, router, ui
  ├── @flowsearch/home          → base, theme, router, ui, mockdata, favs
  ├── @flowsearch/search        → base, theme, router, ui, mockdata, favs
  ├── @flowsearch/web           → base, theme, router, ui, mockdata, favs
  ├── @flowsearch/settings      → base, theme, router, ui, favs
  └── @flowsearch/toolshell     → base, theme, router, ui
```

**依赖规则：**
- Feature 之间不允许直接依赖（home 不能 import search）
- 共享数据（收藏状态）通过 `@flowsearch/favs` 的 Repository 注入
- `favs` 被 home、search、web、settings 四个模块依赖（收藏读写）

---

## 4. 路由系统

### 路由表 (`@flowsearch/router`)

| 路由 ID | 常量 | 目标页面 | 入参类型 |
|---------|------|---------|---------|
| `home` | `RouteTable.HOME` | HomePage | 无 |
| `search.input` | `RouteTable.SEARCH_INPUT` | SearchInputPage | 无 |
| `search.result` | `RouteTable.SEARCH_RESULT` | SearchResultPage | `SearchResultArgs(keyword)` |
| `web.container` | `RouteTable.WEB_CONTAINER` | WebContainerPage | `WebContainerArgs(url, title, needTokenInject, forceAllow, articleId)` |
| `favs` | `RouteTable.FAVORITES_HISTORY` | FavoritesHistoryPage | `FavsHistoryArgs(tab: "fav"\|"history")` |
| `settings` | `RouteTable.SETTINGS` | SettingsPage | 无 |
| `tool.shell` | `RouteTable.TOOL_SHELL` | ToolShellPage | `ToolShellArgs(toolId)` |
| `settings.agreement` | `RouteTable.USER_AGREEMENT` | UserAgreementPage | 无 |
| `settings.privacy` | `RouteTable.PRIVACY_POLICY` | PrivacyPolicyPage | 无 |

### 路由分发 (Index.ets)

```
NavPathStack → pageMap(routeName, param) → switch → 9 个 NavDestination
```

- 所有页面都是 `NavDestination`，不在 `main_pages.json` 注册
- `main_pages.json` 只注册一个 `pages/Index`
- Navigation 组件包裹所有内容，`hideTitleBar(true)` 全局生效

### Deep Link

```
flowsearch://web?url=https%3A%2F%2Fexample.com&title=Article
  → FsearchAbility.onCreate/onNewWant → AppStorage("__dl_route", "__dl_url")
  → Index.aboutToAppear() → navPathStack.pushPathByName

flowsearch://search?keyword=arkts
  → AppStorage("__dl_route", "__dl_keyword")
  → Index.aboutToAppear() → navPathStack.pushPathByName
```

---

## 5. 状态管理模式

### 标准三件套

```
View (@ComponentV2)
  ├── @Local vm: XxxViewModel = new XxxViewModel()
  ├── 绑定: vm.someState / vm.someMethod()
  └── @Monitor('vm.toastMessage') → showToast()

ViewModel (@ObservedV2)
  ├── @Trace state: PageState = PageState.idle()
  ├── @Trace progress / showOverlay / toastMessage ...
  ├── private repo: XxxRepository = new XxxRepository()
  └── async init(context) → repo.fetch() → state 更新

Repository (零装饰器)
  ├── async fetchXxx() → Promise<数据>
  ├── 纯函数，无 UI 依赖
  └── 未来只改此处接入真 API
```

### PageState 状态机 (8 态)

| Kind | 含义 | UI 表现 |
|------|------|---------|
| `idle` | 初始化未开始 | 由页面自行处理（通常显示 Loading） |
| `loading` | 加载中 | 骨架屏 |
| `content` | 有数据 | 内容列表 |
| `empty` | 无数据 | 空状态插画 |
| `error` | 加载失败 | 错误页 + 重试 |
| `refreshing` | 下拉刷新 | 保留当前内容 + Loading 指示器 |
| `loadingMore` | 加载更多 | 底部 Loading |
| `offline` | 离线模式 | 顶部黄条 |

### Toast 消息模式 (ViewModel → Page)

```
ViewModel:  @Trace toastMessage = ""  // 不引用 promptAction
            this.toastMessage = "link_copied"  // 设标记

Page:       @Monitor('vm.toastMessage')
            onToastChange(): void {
              if (key === "link_copied") { message = $r("app.string.fs_web_link_copied") }
              promptAction.showToast({ message })
              this.vm.toastMessage = ""
            }
```

**原因:** ViewModel 没有 UIContext，无法调 promptAction。Page 层有完整上下文。

---

## 6. 持久化策略

全部基于 `PreferencesHelper`（HarmonyOS Preferences 的 JSON 封装）：

| 数据 | Store Name | Key | 最大条目 | 模块 |
|------|-----------|-----|---------|------|
| 收藏文章 | `fsearch_favorites` | `favorites_json` | 无硬限 | favs/FavoritesRepository |
| 搜索历史 | `fsearch_history` | `history_json` | 20 条 | favs/HistoryRepository |
| 阅读历史 | `fsearch_reading_history` | `reading_history_json` | 100 条 | favs/ReadingHistoryRepository |
| 设置项 | `fsearch_settings` | 各字段独立 key | N/A | settings/SettingsRepository |
| 主题偏好 | `fsearch_settings` | `theme_mode` | N/A | FsearchAbility 读取 |

### PreferencesHelper 核心 API

```typescript
static async getJson(context: Context, store: string, key: string): Promise<string | null>
static async putJson(context: Context, store: string, key: string, value: string): Promise<void>
```

- 内部使用 `dataPreferences.getPreferences()` + `put()` + `flush()`
- 所有复杂对象 JSON.stringify/parse 序列化

---

## 7. 深色模式完整方案

### 工作原理

```
系统设置 / 用户切换
  → ApplicationContext.setColorMode(COLOR_MODE_DARK / LIGHT / NOT_SET)
  → 系统扫描每个模块的 resources/base/ 和 resources/dark/ 目录
  → 深色模式下优先使用 dark/element/color.json 的值
  → $r("app.color.fs_color_xxx") 自动返回对应值
```

### 关键代码路径

```
FsearchAbility.onCreate()
  → 同步: setColorMode(COLOR_MODE_NOT_SET)  // 先跟随系统
  → 异步: PreferencesHelper.getJson("theme_mode")
      → ThemeManager.apply("system"|"light"|"dark", context)
          → context.getApplicationContext().setColorMode(...)
```

### 模块暗色资源覆盖

| 模块 | base/color.json | dark/color.json | 颜色 Token 数 |
|------|:---:|:---:|---:|
| fsearch (entry) | ✅ | ✅ | 25 |
| theme | ✅ | ✅ | 25 |
| ui | ❌ (无 color) | ✅ | 24 |
| home | ❌ (无 color) | ✅ | 24 |
| search | ❌ (无 color) | ✅ | 24 |
| web | ❌ (无 color) | ✅ | 24 |
| favs | ❌ (无 color) | ✅ | 24 |
| settings | ❌ (无 color) | ✅ | 24 |
| toolshell | ❌ (无 color) | ✅ | 24 |
| base/router/mockdata | ❌ | ❌ | 0 (只有 string) |

> **坑点:** HarmonyOS 资源解析是**按模块隔离**的。feature HAR 如果没有自己的 `dark/element/color.json`，即使用了 $r() 引用，深色模式下也不会切换颜色。必须每个 HAR 模块单独放一套 dark 资源。

### 25 个设计 Token

| Token 名 | 浅色值 | 用途 |
|-----------|--------|------|
| `fs_color_primary` | #0C7A53 | 主色调（绿） |
| `fs_color_primary_variant` | #0A6645 | 主色深变体 |
| `fs_color_background` | #F5F5F5 | 页面背景 |
| `fs_color_surface` | #FFFFFF | 卡片/容器背景 |
| `fs_color_text_primary` | #1A1A1A | 主文本 |
| `fs_color_text_secondary` | #666666 | 副文本 |
| `fs_color_text_tertiary` | #999999 | 辅助文本 |
| `fs_color_text_inverse` | #FFFFFF | 反色文本 |
| `fs_color_border` | #E5E5E5 | 边框/分割线 |
| `fs_color_danger` | #E74C3C | 危险/错误 |
| `fs_color_warning` | #F39C12 | 警告 |
| `fs_color_info` | #3498DB | 信息 |
| `fs_color_tag_web_bg` | #EBF5FB | Web 标签背景 |
| `fs_color_tag_web_text` | #2980B9 | Web 标签文字 |
| `fs_color_tag_tool_bg` | #E8F8F5 | Tool 标签背景 |
| `fs_color_tag_tool_text` | #1ABC9C | Tool 标签文字 |
| `fs_color_tag_video_bg` | #FDEDEC | Video 标签背景 |
| `fs_color_tag_video_text` | #E74C3C | Video 标签文字 |
| `fs_color_tag_ai_bg` | #F4ECF7 | AI 标签背景 |
| `fs_color_tag_ai_text` | #8E44AD | AI 标签文字 |
| `fs_color_offline_bar` | #FFF3CD | 离线提示条 |
| `fs_color_skeleton` | #E0E0E0 | 骨架屏底色 |
| `fs_color_skeleton_shine` | #F0F0F0 | 骨架屏闪光 |
| `fs_color_surface_dim` | #F8F8F8 | 次级容器背景 |
| `fs_color_scrim` | #66000000 | 遮罩层 |

---

## 8. 国际化方案

### 资源结构

```
每个模块的 resources/
  ├── base/element/string.json    ← 默认语言 (zh-CN)
  └── en_US/element/string.json   ← 英文翻译
```

### 字符串统计

| 模块 | 字符串条数 | 说明 |
|------|----------:|------|
| AppScope | 1 | app_name |
| fsearch (entry) | 29 | 通用组件 + 页面标题 |
| base | 1 | module_desc |
| theme | 7 | 主题/字体标签 |
| router | 1 | module_desc |
| ui | 4 | 状态组件文案 |
| mockdata | 1 | module_desc |
| home | 15 | 首页 UI + 工具描述 |
| search | 32 | 搜索页全链路 |
| web | 27 | WebView 容器全部 UI |
| favs | 11 | 收藏/历史页 |
| settings | 36 | 设置项 + 协议页标题 |
| toolshell | 14 | 4 个工具壳页 |
| **合计** | **~179** | |

### ViewModel Toast 迁移清单

ViewModel 中的 `promptAction.showToast("中文")` 已全部迁移为 `toastMessage` 标记模式：

| ViewModel | Toast 消息数 | 对应 Page |
|-----------|----------:|-----------|
| SettingsViewModel | 7 | SettingsPage |
| WebContainerViewModel | 4 | WebContainerPage |
| SearchResultPage (直写) | 1 | SearchResultPage |

---

## 9. 各模块详细拆解

### 9.1 Product: fsearch (入口)

**类型:** entry (HAP) | **包名:** fsearch

#### 文件清单

| 文件 | 行数 | 职责 |
|------|-----:|------|
| `ets/pages/Index.ets` | ~120 | 应用根组件。Navigation + NavPathStack + 9 路由分发 + Deep Link 消费 |
| `ets/fsearchability/FsearchAbility.ets` | ~173 | UIAbility。主题初始化 + Deep Link 解析 + 全局异常捕获 |
| `ets/fsearchbackupability/FsearchBackupAbility.ets` | ~15 | 备份恢复桩 |
| `ets/pages/DebugIndex.ets` | ~60 | S0 调试页（不在 main_pages.json，不参与生产构建） |

#### Index.ets 路由分发逻辑

```typescript
@Builder pageMap(name: string, param: object) {
  if (name === RouteTable.HOME) { HomePage({ navPathStack }) }
  else if (name === RouteTable.SEARCH_INPUT) { SearchInputPage({ navPathStack }) }
  else if (name === RouteTable.SEARCH_RESULT) { SearchResultPage({ navPathStack, keyword }) }
  else if (name === RouteTable.WEB_CONTAINER) { WebContainerPage({ navPathStack, url, title, ... }) }
  else if (name === RouteTable.FAVORITES_HISTORY) { FavoritesHistoryPage({ navPathStack, tab }) }
  else if (name === RouteTable.SETTINGS) { SettingsPage({ navPathStack }) }
  else if (name === RouteTable.TOOL_SHELL) { ToolShellPage({ navPathStack, toolId }) }
  else if (name === RouteTable.USER_AGREEMENT) { UserAgreementPage({ navPathStack }) }
  else if (name === RouteTable.PRIVACY_POLICY) { PrivacyPolicyPage({ navPathStack }) }
}
```

#### FsearchAbility 生命周期

```
onCreate(want)
  1. setColorMode(COLOR_MODE_NOT_SET)          // 同步，先跟随系统
  2. PreferencesHelper.getJson("theme_mode")   // 异步读用户偏好
     → ThemeManager.apply(mode)                // 覆盖
  3. errorManager.on('globalErrorOccurred')    // 全局异常监听
  4. want.uri → pendingDeepLinkUri             // 记录深链

onWindowStageCreate(windowStage)
  → loadContent('pages/Index')
  → dispatchDeepLink()                         // 把 URI 写入 AppStorage

onNewWant(want)                                // app 在前台收到新 Want
  → dispatchDeepLink()
```

---

### 9.2 Commons: base (基础类型)

**类型:** HAR | **依赖:** 无 | **导出数:** 25

#### 核心类型

| 类型文件 | 导出 | 设计要点 |
|----------|------|---------|
| `types/PageState.ets` | `PageState`, `PageStateKind` | 8 态不可变状态机。工厂方法: `idle()`, `loading()`, `content(data)`, `empty(msg)`, `error(code, msg)` 等。`kind` 字符串判别，`data` 任意类型 |
| `types/Result.ets` | `Result<T>` | 成功/错误包装。`Result.ok(value)` / `Result.error(msg)` |
| `types/HomeModels.ets` | `Article`, `Channel`, `ToolEntry`, `HomeFeedData`, `CategoryTag` | 零装饰器纯数据类。Article 有 `withFavorite(bool)` 不可变更新方法 |
| `types/SearchModels.ets` | `SearchSuggestion`, `HotSearchItem`, `SearchHistoryItem`, `AiQuickAnswer`, `SearchInputData`, `SearchResultData`, `SortType` | 搜索全链路模型。SortType = "RELEVANCE" \| "LATEST" \| "HOTTEST" \| "TOOLS" \| "ARTICLES" |
| `types/WebModels.ets` | `WebContainerData`, `WebInterceptRule`, `WebInterceptAction` | 拦截动作: ALLOW / INTERCEPT_LOGIN / INTERCEPT_PAY / INTERCEPT_DOWNLOAD / OPEN_EXTERNAL |
| `types/FavoriteRecord.ets` | `FavoriteRecord` | 与 Article 双向转换，用于 JSON 序列化存储 |
| `types/ReadingHistoryEntry.ets` | `ReadingHistoryEntry` | url + title + readAt 时间戳 |
| `persistence/PreferencesHelper.ets` | `PreferencesHelper` | `getJson(ctx, store, key)` / `putJson(ctx, store, key, value)` + auto-flush |
| `utils/UrlDebounceGuard.ets` | `UrlDebounceGuard` | 静态类。`shouldOpen(url)` 返回 boolean，同 URL 5 秒内只放行一次 |

#### Article 模型关键字段

```typescript
class Article {
  articleId: string          // 唯一标识
  title: string
  summary: string
  coverUrl: string | null
  coverPlaceholder: string   // 无图时的灰色占位文字
  categoryTag: CategoryTag   // "WEB" | "TOOL" | "VIDEO" | "AI"
  source: string
  publishTime: string
  publishTimeDisplay: string // 相对时间如 "3小时前"
  targetUrl: string
  favorite: boolean
  channelId: string
  withFavorite(bool): Article // 不可变更新
}
```

---

### 9.3 Commons: theme (主题)

**类型:** HAR | **依赖:** 无 | **导出数:** 2

#### ThemeManager

```typescript
class ThemeManager {
  static apply(mode: "light"|"dark"|"system", context: Context): void
  // → context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode)

  static label(mode: string): Resource
  // → $r("app.string.fs_theme_light|dark|system")
}
```

**关键 API:** `ConfigurationConstant.ColorMode`
- `COLOR_MODE_LIGHT = 1`
- `COLOR_MODE_DARK = 0`
- `COLOR_MODE_NOT_SET = -1`（跟随系统）

#### FontScaleManager

```typescript
class FontScaleManager {
  static apply(size: "small"|"standard"|"large", context: Context): void
  // → context.getApplicationContext().setFontSizeScale(0.85 / 1.0 / 1.15)

  static label(size: string): Resource
}
```

---

### 9.4 Commons: router (路由)

**类型:** HAR | **依赖:** 无 | **导出数:** 5

#### RouteTable 常量

```typescript
class RouteTable {
  static readonly HOME = "home"
  static readonly SEARCH_INPUT = "search.input"
  static readonly SEARCH_RESULT = "search.result"
  static readonly WEB_CONTAINER = "web.container"
  static readonly FAVORITES_HISTORY = "favs"
  static readonly SETTINGS = "settings"
  static readonly TOOL_SHELL = "tool.shell"
  static readonly USER_AGREEMENT = "settings.agreement"
  static readonly PRIVACY_POLICY = "settings.privacy"
}
```

#### 路由参数类

| 类 | 字段 | 用途 |
|----|------|------|
| `SearchResultArgs` | keyword: string | 搜索结果页入参 |
| `WebContainerArgs` | url, title, needTokenInject, forceAllow, articleId | WebView 页入参 |
| `ToolShellArgs` | toolId: string | 工具壳页入参 (web/scan/translate/file) |
| `FavsHistoryArgs` | tab: "fav" \| "history" | 收藏/历史页初始 Tab |

---

### 9.5 Commons: ui (共享组件)

**类型:** HAR | **依赖:** base, theme | **导出数:** 1

#### StateHost 组件

```typescript
@ComponentV2
struct StateHost {
  @Param pageState: PageState              // 当前状态
  @Param data: object | null = null        // content 态的数据
  @BuilderParam contentBuilder: (data: object) => void  // content 态渲染

  // 内部按 state.kind 分支:
  // loading → 骨架屏 (3 条灰块)
  // empty → 空状态插画 + 文案
  // error → 错误图标 + 错误码 + 重试按钮
  // offline → 顶部黄条
  // content → contentBuilder(data)
  // idle → 骨架屏 (同 loading)
}
```

**使用方式:**

```typescript
StateHost({
  pageState: this.vm.state,
  data: this.vm.state.data,
  contentBuilder: (data: Article[]) => {
    List() { ForEach(data, (item: Article) => { ... }) }
  }
})
```

> HomePage 使用 StateHost；SearchResultPage 和 WebContainerPage 因需要在 Empty/Error 状态下仍显示顶栏/Tab，采用自定义 body 渲染。

---

### 9.6 Commons: mockdata (模拟数据)

**类型:** HAR | **依赖:** base | **导出数:** 3

| Mock 文件 | 模拟的 API | 数据内容 |
|-----------|-----------|---------|
| `home/HomeMock.ets` | `GET /api/tool/home` | 5 频道 (hot/tech/study/tool/fav) + 4 工具入口 + 每频道 8 篇文章 |
| `search/SearchMock.ets` | `GET /api/search/suggest\|result\|ai` | 搜索历史 5 条 + 热搜 10 条 + 建议 5 条 + 结果 10 条 + AI 快答 |
| `web/WebMock.ets` | `GET /api/web/rules` | 5 条拦截规则 (login/pay/download/cdn/external) + mock token |

**SimulationMode 类型（每个 feature 模块独立定义）：**

```typescript
type SimulationMode = "normal" | "empty" | "error" | "slow"
```

- `normal`: 正常返回数据（300ms 延迟模拟网络）
- `empty`: 返回空数据集
- `error`: 抛出异常
- `slow`: 2 秒延迟（测试慢加载 UI）

---

### 9.7 Feature: home (首页)

**类型:** HAR | **依赖:** base, theme, router, ui, mockdata, favs

#### 文件清单 (11 个)

| 文件 | 职责 |
|------|------|
| `pages/HomePage.ets` | 首页主组件。Header + SearchBar + QuickEntries + ChannelTabs + StateHost(Feed) |
| `viewmodel/HomeViewModel.ets` | 首页 VM。按频道独立 PageState map。loadFeed(channelId) |
| `repo/HomeRepository.ets` | 数据层。fetchFeed(channelId, mode) → Promise\<HomeFeedData\> |
| `repo/SimulationMode.ets` | SimulationMode 类型定义 |
| `viewmodel/ArticleDataSource.ets` | LazyForEach IDataSource 适配器 |
| `components/HomeHeader.ets` | 顶栏：logo + 头像圆 |
| `components/HomeSearchBar.ets` | 假搜索栏（点击跳转 SearchInputPage） |
| `components/QuickEntries.ets` | 4 个工具圆圈入口（网页/扫描/翻译/文件） |
| `components/ChannelTabs.ets` | 横向滚动频道 Tab |
| `components/ArticleCard.ets` | 文章卡片。@ReusableV2 + 分类色块 |
| `components/HomeFeedSkeleton.ets` | 骨架屏（3 个占位卡片） |

#### 功能流转

```
HomePage 加载
  → HomeViewModel.init()
  → HomeRepository.fetchFeed("hot", "normal")
  → HomeMock 返回数据
  → PageState.content(HomeFeedData)
  → StateHost 渲染文章列表 (LazyForEach)

用户切换频道
  → ChannelTabs @Event → vm.switchChannel(channelId)
  → 已缓存则直接切 state，未缓存则 fetchFeed

点击文章卡片
  → ArticleCard @Event → navPathStack.pushPathByName("web.container", WebContainerArgs)

点击搜索栏
  → HomeSearchBar @Event → navPathStack.pushPathByName("search.input")

点击工具入口
  → QuickEntries @Event → navPathStack.pushPathByName("tool.shell", ToolShellArgs)
```

---

### 9.8 Feature: search (搜索)

**类型:** HAR | **依赖:** base, theme, router, ui, mockdata, favs

#### 文件清单 (14 个)

| 文件 | 职责 |
|------|------|
| `pages/SearchInputPage.ets` | 搜索输入页。TopBar + HistoryChips + HotSearchList / SuggestionList |
| `pages/SearchResultPage.ets` | 搜索结果页。TopBar(readonly) + SortTabs + AI 卡 + 结果列表 |
| `viewmodel/SearchInputViewModel.ets` | 输入页 VM。keyword @Trace + 历史/热搜(同步) + 建议(300ms 防抖) |
| `viewmodel/SearchResultViewModel.ets` | 结果页 VM。并行 fetch(results + AI)。AI 独立 2s 超时 |
| `viewmodel/SearchResultDataSource.ets` | LazyForEach 适配器 |
| `repo/SearchRepository.ets` | 数据层。三个异步方法 + SimulationMode |
| `repo/SimulationMode.ets` | SimulationMode 类型 |
| `components/SearchTopBar.ets` | 真 TextInput + 取消按钮 |
| `components/HistoryChips.ets` | 搜索历史：标题 + 删除 + Flex 芯片标签 |
| `components/HotSearchList.ets` | 热搜排行：1-3 红色粗体，4+ 灰色 |
| `components/SuggestionList.ets` | 建议列表：关键词高亮 + 填充箭头 |
| `components/AiAnswerCard.ets` | AI 快答卡片：绿色背景 + 摘要 + 关联问题胶囊 |
| `components/SortTabs.ets` | 排序 Tab：相关/最新/最热/仅工具/仅文章 |
| `components/SearchResultCard.ets` | 结果卡片：分类色块 + 关键词高亮 + 收藏按钮 |

#### 搜索流程

```
SearchInputPage
  ├── 空输入 → 显示 HistoryChips + HotSearchList
  │   ├── 点击历史/热搜 → navPathStack.push(SearchResultArgs)
  │   └── 点击输入 → 键盘输入
  │
  └── 有输入 → 显示 SuggestionList (300ms 防抖)
      ├── 点击建议 → navPathStack.push(SearchResultArgs)
      ├── 按回车 → navPathStack.push(SearchResultArgs)
      └── 清空 → 回到 HistoryChips + HotSearchList

SearchResultPage
  → vm.init(keyword)
  → 并行: repo.fetchResults(keyword, sort) + repo.fetchAiAnswer(keyword)
  → results → PageState.content(SearchResultData)
  → aiAnswer → 独立 @Trace，2s 超时后静默降级
  → SortTabs 切换 → vm.changeSort(sortType) → 重新 fetch
  → 点击收藏 → vm.toggleFavorite(article) → FavoritesRepository 持久化
  → 点击卡片 → navPathStack.push(WebContainerArgs)
```

---

### 9.9 Feature: web (网页容器)

**类型:** HAR | **依赖:** base, theme, router, ui, mockdata, favs

#### 文件清单 (10 个)

| 文件 | 职责 |
|------|------|
| `pages/WebContainerPage.ets` | Web 容器主页面。TopBar + ProgressBar + Web 组件 + 5 个 Overlay |
| `viewmodel/WebContainerViewModel.ets` | 容器 VM。3 态 PageState + 4 个叠加层标志 + 慢加载计时 |
| `repo/WebRepository.ets` | 数据层。fetchRules(30min 缓存) + matchRule(url) + authHeader() |
| `components/WebTopBar.ets` | 顶栏：← + 标题/域名 + 更多菜单 |
| `components/WebProgressBar.ets` | 2px 进度条 |
| `components/WebErrorPage.ets` | 白屏错误页：警告图标 + 错误码 + 双按钮 |
| `components/LoginExpiredDialog.ets` | 登录过期弹窗 |
| `components/ExternalConfirmDialog.ets` | 外跳确认弹窗 |
| `components/SlowLoadBar.ets` | 慢加载黄条 (5s 触发) |
| `components/WebActionSheet.ets` | 底部菜单：刷新/浏览器打开/复制链接/分享 |

#### URL 拦截流程 (简历主线 1 核心证据)

```
Web 组件 onLoadIntercept(event)
  → isFirstLoad? → 放行 (首屏由 VM.init 选中)
  → vm.interceptUrl(url)
    → forceAllow=true? → 放行
    → repository.resolveAction(url)
      → "ALLOW"              → 放行 + 更新 URL + 启动慢加载计时
      → "INTERCEPT_LOGIN"    → 阻断 + showLoginExpired=true
      → "INTERCEPT_PAY"      → 阻断 + toastMessage="payment_not_supported"
      → "INTERCEPT_DOWNLOAD" → 阻断 + toastMessage="download_detected"
      → "OPEN_EXTERNAL"      → 阻断 + showExternalConfirm=true
      → 未命中               → 放行 (默认 ALLOW)
```

#### 登录态透传 (简历主线 2 证据)

```
Web 组件 onPageEnd(url)
  → vm.shouldInjectToken(url)?
    → repository.shouldInjectToken(url)  // 域名白名单匹配
    → controller.runJavaScript(`document.cookie = "Authorization=${token}"`)
```

#### 进度条策略

```
0% → onPageBegin 触发
0-90% → onProgressChange 真实进度 (max 防回退)
90-100% → onPageEnd 后跳 100%
慢加载 → 5s 未到 100% → SlowLoadBar 出现
```

#### WebView 生命周期管理

```
onPageShow() → controller.onActive()    // 恢复播放
onPageHide() → controller.onInactive()  // 暂停释放
aboutToDisappear() → controller.pauseAllMedia() + controller.stop()  // 防泄漏
```

---

### 9.10 Feature: favs (收藏/历史)

**类型:** HAR | **依赖:** base, theme, router, ui | **导出数:** 5

#### 文件清单 (8 个)

| 文件 | 职责 |
|------|------|
| `pages/FavoritesHistoryPage.ets` | 双 Tab 页。收藏(管理模式 + 多选批量取消) / 历史(时间分组) |
| `viewmodel/FavsViewModel.ets` | VM。双 PageState (favState/historyState) + 双 Repository |
| `repo/FavoritesRepository.ets` | 收藏持久化。Article ↔ FavoriteRecord 双向转换 |
| `repo/HistoryRepository.ets` | 搜索历史持久化。去重 + 截断 20 条 |
| `repo/ReadingHistoryRepository.ets` | 阅读历史持久化。去重 URL + 截断 100 条 |
| `viewmodel/FavsArticleDataSource.ets` | LazyForEach 适配器 |
| `components/FavsTabs.ets` | Tab 切换器：选中 = primary + 2px 下划线 |
| `components/FavsArticleCard.ets` | 简化文章卡片：无分类色块，无关键词高亮 |

#### 三种历史的区别

| 类型 | 写入时机 | 存储 | 最大条数 | 用途 |
|------|---------|------|---------|------|
| 搜索历史 | SearchResultPage 搜索时 | HistoryRepository | 20 | 搜索输入页回显 |
| 阅读历史 | WebContainerPage onPageEnd | ReadingHistoryRepository | 100 | 历史 Tab 展示 |
| 收藏 | 手动点击收藏按钮 | FavoritesRepository | 无硬限 | 收藏 Tab 展示 |

---

### 9.11 Feature: settings (设置)

**类型:** HAR | **依赖:** base, theme, router, ui, favs

#### 文件清单 (9 个)

| 文件 | 职责 |
|------|------|
| `pages/SettingsPage.ets` | 设置主页。4 组：通用/隐私数据/Web 容器/关于 |
| `pages/UserAgreementPage.ets` | 用户协议页 |
| `pages/PrivacyPolicyPage.ets` | 隐私政策页 |
| `repo/SettingsRepository.ets` | 设置持久化。SettingsData @ObservedV2 + 每字段独立 key |
| `cache/CacheCalculator.ets` | 缓存大小计算 + 清理（递归 fs.listFile） |
| `components/SettingsGroup.ets` | 设置分组容器：圆角白卡 + 标题 |
| `components/SettingsItem.ets` | 设置行：4 变体 (text/switch/info/action) |
| `components/ConfirmDialog.ets` | 通用确认弹窗（Stack overlay 模式） |
| `components/UpdateDialog.ets` | 版本更新弹窗 (mock) |

#### SettingsRepository 持久化字段

| Key | 类型 | 默认值 | 对应 UI |
|-----|------|--------|--------|
| `theme_mode` | string | `"system"` | 主题选择器 |
| `language` | string | `"zh"` | 语言选择器 |
| `font_size` | string | `"standard"` | 字体大小选择器 |
| `personalized_recommend` | boolean | `true` | 个性化推荐开关 |
| `app_tracking` | boolean | `true` | 应用跟踪开关 |
| `https_only_token` | boolean | `false` | HTTPS-only Token 开关 |
| `js_enabled` | boolean | `true` | JavaScript 启用开关 |
| `default_browser` | string | `"in_app"` | 默认浏览器选择 |

#### 设置项操作流程

```
主题选择 → ThemeManager.apply(mode) + PreferencesHelper.putJson
字体大小 → FontScaleManager.apply(size) + PreferencesHelper.putJson
清缓存 → CacheCalculator.calculateSize() → 显示大小 → 确认弹窗 → CacheCalculator.clear()
版本更新 → UpdateDialog (mock)
反馈建议 → 复制邮箱到剪贴板
用户协议 → navPathStack.push("settings.agreement")
隐私政策 → navPathStack.push("settings.privacy")
```

---

### 9.12 Feature: toolshell (工具外壳)

**类型:** HAR | **依赖:** base, theme, router, ui

#### 文件清单 (1 个页面 + 1 个 Index)

| 文件 | 职责 |
|------|------|
| `pages/ToolShellPage.ets` | 4 个工具的共享壳模板。根据 toolId 显示不同标题和占位内容 |

#### 支持的工具

| toolId | 标题 | 当前状态 |
|--------|------|---------|
| `web` | 网页浏览 | 占位，点击跳转 WebContainer |
| `scan` | 扫一扫 | 占位 |
| `translate` | 翻译 | 占位 |
| `file` | 文件管理 | 占位 |

---

## 10. 页面功能流转图

```
┌─────────────────────────────────────────────────────────┐
│                    Index.ets (根)                         │
│  Navigation + NavPathStack + Deep Link 消费              │
└────────┬────────────────────────────────────────────────┘
         │
    ┌────┴────┐
    │ HomePage │ ← 默认首页
    └────┬────┘
         │
    ┌────┼────────────────┬──────────────┐
    │    │                │              │
    ▼    ▼                ▼              ▼
 SearchInput  ToolShellPage     FavoritesHistory    Settings
    │        (4 工具壳)         (收藏/历史双 Tab)    (设置中心)
    │                                                    │
    ▼                                              ┌─────┼─────┐
 SearchResult                                      │     │     │
    │                                          UserAgreement  PrivacyPolicy
    ▼
 WebContainer
    ├── LoginExpiredDialog    → 清登录态 → pop 到根
    ├── ExternalConfirmDialog → 打开外部 app
    ├── SlowLoadBar           → 5s 黄条
    ├── WebErrorPage          → 重试/返回
    └── WebActionSheet        → 刷新/浏览器/复制/分享
```

### 用户操作 → 数据流映射

| 用户操作 | 触发组件 | 目标页面 | 携带参数 |
|---------|---------|---------|---------|
| 点击假搜索栏 | HomeSearchBar | SearchInputPage | 无 |
| 点击文章卡片 | ArticleCard / SearchResultCard / FavsArticleCard | WebContainerPage | WebContainerArgs |
| 输入关键词回车 | SearchTopBar | SearchResultPage | SearchResultArgs(keyword) |
| 点击热搜/历史/建议 | HotSearchList / HistoryChips / SuggestionList | SearchResultPage | SearchResultArgs(keyword) |
| 点击工具入口 | QuickEntries | ToolShellPage | ToolShellArgs(toolId) |
| 点击"设置" | HomePage 顶栏 | SettingsPage | 无 |
| 点击"收藏/历史" | 底部导航 | FavoritesHistoryPage | FavsHistoryArgs(tab) |
| 点击协议链接 | SettingsPage | UserAgreementPage / PrivacyPolicyPage | 无 |
| 收到 Deep Link | 系统 → FsearchAbility | WebContainerPage 或 SearchResultPage | url 或 keyword |

---

## 11. Sprint 完成记录

| Sprint | 内容 | 状态 |
|--------|------|:----:|
| S0 | 项目脚手架 + 12 模块搭建 + PageState 状态机验证 | ✅ |
| S1 | HomePage 完整实现（Header + SearchBar + QuickEntries + ChannelTabs + Feed） | ✅ |
| S2 | SearchInputPage（输入建议 + 搜索历史 + 热搜排行） | ✅ |
| S3 | SearchResultPage（结果列表 + 排序 + AI 快答卡片） | ✅ |
| S4 | WebContainerPage（WebView + URL 拦截 + 进度条 + 5 种拦截动作） | ✅ |
| S5 | WebContainer 叠加层（登录过期 + 外跳确认 + 慢加载 + 错误页 + ActionSheet） | ✅ |
| S6 | FavoritesHistoryPage（收藏/历史双 Tab + 管理模式 + 批量操作） | ✅ |
| S7 | SettingsPage（设置 4 组 + 缓存管理 + 版本更新 + 协议页） | ✅ |
| S8 | 收藏持久化（FavoritesRepository + 偏好读写 + 跨页面同步） | ✅ |
| S9 | 搜索历史持久化 + ToolShell 4 工具壳 + 返回栈处理 | ✅ |
| S10 | 首页收藏态同步 + Setting 项联动（主题/字体即时生效） | ✅ |
| S11 | 全局异常捕获 + URL 防重复打开 + WebView 生命周期 | ✅ |
| S12 | Deep Link 支持（flowsearch://web + flowsearch://search） | ✅ |
| S13 | 阅读历史记录 + WebView onPageShow/onPageHide | ✅ |
| S14 | 搜索结果收藏按钮 + WebContainer 收藏按钮 + 分享功能 | ✅ |
| S15 | i18n 字符串资源化 + 深色模式全模块修复 | ✅ |
| S16 | i18n 收尾 + en_US 英文包 + ViewModel Toast 迁移 | ✅ |

---

## 12. 已知限制与待办

### P3 待办（低优先级）

| # | 内容 | 工作量 | 说明 |
|---|------|--------|------|
| 1 | 无障碍 contentDescription | 中 | 逐页逐组件添加 |
| 2 | 协议页法律文本 i18n | 低 | 14 条长段落，法律文本通常保留原文 |
| 3 | Mock 数据 i18n | 低 | 3 个 Mock 文件的中文内容，演示用 |
| 4 | ToolShell 4 工具实际功能 | 高 | 扫描/翻译/文件管理需要系统 API 接入 |
| 5 | 真实 API 替换 Mock | 高 | Repository 层只改此处 |
| 6 | 图片懒加载 + 缓存策略 | 中 | ArticleCard coverUrl 目前直接加载 |
| 7 | 下拉刷新 + 上拉加载更多 | 中 | PageState 已支持 refreshing/loadingMore，UI 未接入 |
| 8 | 网络状态检测 | 低 | PageState.offline 已定义，未接入系统网络监听 |

### 架构预留

| 预留点 | 当前状态 | 接入方式 |
|--------|---------|---------|
| 真实 API | MockData 硬编码 | 替换 Repository 中的 Mock 调用为 http 请求 |
| 数据库 | Preferences JSON 字符串 | 替换 PreferencesHelper 为 RDB |
| 图片加载 | 直接 `Image(src)` | 接入 `@ohos.image` 图片缓存 |
| 推送通知 | 无 | 接入 `@kit.PushKit` |
| 性能监控 | 无 | 接入 `@kit.PerformanceAnalysisKit` |

---

## 13. 构建与运行

### 环境要求

- DevEco Studio 5.0+
- HarmonyOS SDK 6.1.1(24)
- JDK (DevEco 内置 JBR)

### 构建命令

```powershell
# 设置 Java 环境（必须，否则 PackageHap 报 ENOENT）
$env:JAVA_HOME = "C:\Program Files\Huawei\DevEco Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:DEVECO_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk"

# 构建
hvigorw assembleHap -p product=default
```

### 输出

```
products/fsearch/build/default/outputs/default/fsearch-default-signed.hap
```

### 安装到设备

```powershell
hdc install fsearch-default-signed.hap
```

---

## 附录 A: 文件统计

| 类别 | 数量 |
|------|-----:|
| .ets 源文件 | ~65 |
| module.json5 | 12 |
| oh-package.json5 | 12 |
| build-profile.json5 | 12 |
| hvigorfile.ts | 12 |
| string.json (base + en_US) | 24 |
| color.json (base + dark) | 18 |
| float.json | 2 |
| **总计配置/资源文件** | **~150** |

## 附录 B: 完整导航路径

所有页面均为 NavDestination，通过 `navPathStack.pushPathByName(routeName, param)` 导航：

```
Index (根 Navigation)
├── HomePage                          ← home
│   ├── → SearchInputPage            ← search.input
│   │   └── → SearchResultPage       ← search.result (param: keyword)
│   │       └── → WebContainerPage   ← web.container (param: url, title, ...)
│   ├── → ToolShellPage              ← tool.shell (param: toolId)
│   │   └── → WebContainerPage       ← web.container (从"网页浏览"工具)
│   └── → FavoritesHistoryPage       ← favs (param: tab)
│       └── → WebContainerPage       ← web.container
├── SettingsPage                      ← settings
│   ├── → UserAgreementPage          ← settings.agreement
│   └── → PrivacyPolicyPage          ← settings.privacy
└── (Deep Link 直达)
    ├── → WebContainerPage            ← flowsearch://web?url=...
    └── → SearchResultPage            ← flowsearch://search?keyword=...
```
