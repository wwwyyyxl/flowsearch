/**
 * @file HomeMock.ets
 * @description 首页假数据集。对应 PRD §07-Mock-API.md §2.1 GET /api/tool/home 返回结构。
 *
 * 设计要点:
 * 1. 零装饰器,纯静态导出 -> 可被任意层(repo / VM / 单测)安全 import,无副作用。
 * 2. 频道-文章映射用 Map<channelId, Article[]> 而非单一数组:
 *    Repository.fetchFeed(channelId) 时 O(1) 取列表,模拟"按频道查询"的接口语义。
 * 3. 字段值刻意覆盖 PRD §02 §1 角标矩阵的全部 4 类(WEB / TOOL / VIDEO / AI),
 *    让 UI 端 4 种角标颜色都能在演示中亮相。
 * 4. publishTimeDisplay 用中文相对时间字符串,与 PRD §08 §5 "服务端预渲染时间" 规范对齐。
 */

import { Article, Channel, ToolEntry, HomeFeedData } from "@flowsearch/base";

/** 5 个固定频道(PRD §08 §4.2)。 */
const CHANNELS: Array<Channel> = [
  new Channel("hot", "推荐", 0, true),
  new Channel("tech", "科技", 1, true),
  new Channel("study", "学习", 2, true),
  new Channel("tool", "工具", 3, true),
  new Channel("fav", "收藏", 4, true)
];

/** 4 个工具入口(PRD §08 §4.3,首版全部 SHELL 类型)。 */
const QUICK_ENTRIES: Array<ToolEntry> = [
  new ToolEntry("web", "网页", "icon_web", "SHELL", null, 0),
  new ToolEntry("scan", "扫码", "icon_scan", "SHELL", null, 1),
  new ToolEntry("translate", "翻译", "icon_translate", "SHELL", null, 2),
  new ToolEntry("file", "文件", "icon_file", "SHELL", null, 3)
];

/** "推荐"频道 6 条文章(覆盖 4 种 categoryTag)。 */
const HOT_ARTICLES: Array<Article> = [
  new Article({
    articleId: "a_10001",
    title: "HarmonyOS NEXT Web 容器适配实践",
    summary: "介绍 Web 页面加载、URL 拦截和弱网错误页处理。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "开发者社区",
    publishTime: "2026-06-10T09:48:00Z",
    publishTimeDisplay: "12 分钟前",
    targetUrl: "https://mock-web/article/a_10001",
    favorite: false,
    channelId: "hot"
  }),
  new Article({
    articleId: "a_10002",
    title: "ArkTS V2 状态管理:从 @State 到 @ObservedV2",
    summary: "对比 V1 / V2 装饰器、响应式触发链路差异、迁移成本评估。",
    coverUrl: null,
    coverPlaceholder: "工具",
    categoryTag: "TOOL",
    source: "鸿蒙官方",
    publishTime: "2026-06-10T08:30:00Z",
    publishTimeDisplay: "1 小时前",
    targetUrl: "https://mock-web/article/a_10002",
    favorite: true,
    channelId: "hot"
  }),
  new Article({
    articleId: "a_10003",
    title: "LazyForEach + cachedCount 性能实测",
    summary: "5000 条数据滚动 60fps 不掉帧的工程配置清单。",
    coverUrl: null,
    coverPlaceholder: "视频",
    categoryTag: "VIDEO",
    source: "性能小课",
    publishTime: "2026-06-10T07:10:00Z",
    publishTimeDisplay: "3 小时前",
    targetUrl: "https://mock-web/article/a_10003",
    favorite: false,
    channelId: "hot"
  }),
  new Article({
    articleId: "a_10004",
    title: "AI 速答卡:Mock 占位 + 静默降级策略",
    summary: "如何在不接 LLM 的前提下,把 AI 卡做得可演示、可解释。",
    coverUrl: null,
    coverPlaceholder: "AI",
    categoryTag: "AI",
    source: "FlowSearch Team",
    publishTime: "2026-06-09T18:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_10004",
    favorite: false,
    channelId: "hot"
  }),
  new Article({
    articleId: "a_10005",
    title: "Navigation 路由表设计:常量 vs Enum",
    summary: "鸿蒙 Navigation 命名规约与 Android Compose 路由对照。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "开发者社区",
    publishTime: "2026-06-09T15:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_10005",
    favorite: false,
    channelId: "hot"
  }),
  new Article({
    articleId: "a_10006",
    title: "同源契约:Article 字段 Android↔ArkTS 映射",
    summary: "12 个 Mock 接口的字段命名约定与双端语义一致性。",
    coverUrl: null,
    coverPlaceholder: "工具",
    categoryTag: "TOOL",
    source: "FlowSearch Team",
    publishTime: "2026-06-09T10:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_10006",
    favorite: false,
    channelId: "hot"
  })
];

/** "科技" 频道 4 条。 */
const TECH_ARTICLES: Array<Article> = [
  new Article({
    articleId: "a_20001",
    title: "鸿蒙 NEXT 6.1.1 SDK 新特性速览",
    summary: "compatibleSdkVersion 升级影响面、@ComponentV2 稳定性、新增组件清单。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "鸿蒙官方",
    publishTime: "2026-06-10T08:00:00Z",
    publishTimeDisplay: "1 小时前",
    targetUrl: "https://mock-web/article/a_20001",
    favorite: false,
    channelId: "tech"
  }),
  new Article({
    articleId: "a_20002",
    title: "Compose vs ArkUI:同一份 UI 双端实现成本对照",
    summary: "5 个典型组件(LazyColumn / Card / TabRow / TextField / Dialog)的代码量与差异点。",
    coverUrl: null,
    coverPlaceholder: "工具",
    categoryTag: "TOOL",
    source: "技术对比",
    publishTime: "2026-06-10T06:00:00Z",
    publishTimeDisplay: "4 小时前",
    targetUrl: "https://mock-web/article/a_20002",
    favorite: true,
    channelId: "tech"
  }),
  new Article({
    articleId: "a_20003",
    title: "ArkWeb Cookie 同步:与 WebView 的差异",
    summary: "登录态透传、Cookie domain 处理、Header 注入路径差异。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "开发者社区",
    publishTime: "2026-06-09T20:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_20003",
    favorite: false,
    channelId: "tech"
  }),
  new Article({
    articleId: "a_20004",
    title: "鸿蒙安全:Token 存储与生物认证",
    summary: "Preferences vs HUKS 选型、生物识别接入流程。",
    coverUrl: null,
    coverPlaceholder: "视频",
    categoryTag: "VIDEO",
    source: "安全研究",
    publishTime: "2026-06-09T09:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_20004",
    favorite: false,
    channelId: "tech"
  })
];

/** "学习" 频道 3 条。 */
const STUDY_ARTICLES: Array<Article> = [
  new Article({
    articleId: "a_30001",
    title: "ArkTS 严格类型 30 道避坑题",
    summary: "联合字面量、协变、struct 不支持泛型 -- 高频踩坑场景与解法。",
    coverUrl: null,
    coverPlaceholder: "学习",
    categoryTag: "TOOL",
    source: "学习路径",
    publishTime: "2026-06-10T07:00:00Z",
    publishTimeDisplay: "2 小时前",
    targetUrl: "https://mock-web/article/a_30001",
    favorite: false,
    channelId: "study"
  }),
  new Article({
    articleId: "a_30002",
    title: "从 Kotlin/Compose 视角学 ArkTS",
    summary: "VM / 状态机 / 长列表 / 路由 -- 一份心智模型对照表。",
    coverUrl: null,
    coverPlaceholder: "AI",
    categoryTag: "AI",
    source: "FlowSearch Team",
    publishTime: "2026-06-09T22:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_30002",
    favorite: false,
    channelId: "study"
  }),
  new Article({
    articleId: "a_30003",
    title: "PageState 状态机的 8 种状态详解",
    summary: "Idle / Loading / Content / Empty / Error / Refreshing / LoadingMore / Offline 一文讲透。",
    coverUrl: null,
    coverPlaceholder: "学习",
    categoryTag: "TOOL",
    source: "FlowSearch Team",
    publishTime: "2026-06-08T15:00:00Z",
    publishTimeDisplay: "2 天前",
    targetUrl: "https://mock-web/article/a_30003",
    favorite: false,
    channelId: "study"
  })
];

/** "工具" 频道 2 条(故意少,演示翻页 / 临界数据)。 */
const TOOL_ARTICLES: Array<Article> = [
  new Article({
    articleId: "a_40001",
    title: "FlowSearch 工具入口设计:4 个 ToolShell 复用模板",
    summary: "为什么不每个工具单独开页面,而是共享一套壳页 + toolId 参数。",
    coverUrl: null,
    coverPlaceholder: "工具",
    categoryTag: "TOOL",
    source: "FlowSearch Team",
    publishTime: "2026-06-10T05:00:00Z",
    publishTimeDisplay: "5 小时前",
    targetUrl: "https://mock-web/article/a_40001",
    favorite: false,
    channelId: "tool"
  }),
  new Article({
    articleId: "a_40002",
    title: "扫码、翻译、文件:三种工具的占位演示策略",
    summary: "不接真实能力时,如何把工具演示得像真实交互。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "FlowSearch Team",
    publishTime: "2026-06-09T12:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/a_40002",
    favorite: false,
    channelId: "tool"
  })
];

/**
 * 按 channelId 取文章列表。
 * "fav" 频道刻意返回空数组,用于演示 Empty 态。
 */
const ARTICLES_BY_CHANNEL: Map<string, Array<Article>> = new Map([
  ["hot", HOT_ARTICLES],
  ["tech", TECH_ARTICLES],
  ["study", STUDY_ARTICLES],
  ["tool", TOOL_ARTICLES],
  ["fav", new Array<Article>()] // 收藏频道初始空,演示 Empty 态
]);

/**
 * Mock 数据访问门面。Repository 通过它取数据,不直接 import 上面那些 const。
 * 这样以后切真接口或 IndexedDB 只改 Repository,不动 Mock。
 */
export class HomeMock {
  static getChannels(): Array<Channel> {
    return CHANNELS.slice();
  }

  static getQuickEntries(): Array<ToolEntry> {
    return QUICK_ENTRIES.slice();
  }

  /** 取某频道全部文章。频道不存在时返回空数组,语义对齐 PRD §05 "Empty(0 结果)" 态。 */
  static getArticles(channelId: string): Array<Article> {
    const list = ARTICLES_BY_CHANNEL.get(channelId);
    return list !== undefined ? list.slice() : new Array<Article>();
  }

  /** 取首页聚合(GET /api/tool/home 的整包响应)。 */
  static getHomeFeed(channelId: string): HomeFeedData {
    return new HomeFeedData(
      HomeMock.getChannels(),
      HomeMock.getQuickEntries(),
      HomeMock.getArticles(channelId)
    );
  }
}
