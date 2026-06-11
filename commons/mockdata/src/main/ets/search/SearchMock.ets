/**
 * @file SearchMock.ets
 * @description 搜索域假数据集。对应 PRD §07-Mock-API.md §2.5/2.6/2.7/2.9。
 *
 * 设计要点(对齐 HomeMock 同源策略):
 * 1. 零装饰器,纯静态导出。
 * 2. 接口分 4 块:
 *    - getSearchInput()              -> SearchInputData(历史 + 热搜),对齐 §2.9
 *    - getSuggestions(keyword)       -> Array<SearchSuggestion>,对齐 §2.5
 *    - getResults(keyword, sort)     -> Array<Article>,对齐 §2.6
 *    - getAiAnswer(keyword)          -> AiQuickAnswer | null,对齐 §2.7
 * 3. keyword 长度 < 2 时 AI 速答返回 null(PRD §04-03 §6 边界规则)。
 * 4. "empty result" 触发条件:VM 调 getResults 时显式传 "__empty__" 关键词。
 *    这是 mockdata 层暴露的演示开关 -- 真实接口没这个概念。
 */

import { Article, SearchSuggestion, HotSearchItem, SearchHistoryItem,
         AiQuickAnswer, SearchInputData, SortType } from "@flowsearch/base";

// ============================================================================
// 历史(本期为 mock 常量;S4 接 Preferences 存储后改为读真值)
// ============================================================================

// 生成 mock 时间戳:offsetHours 小时前
function mockTimestamp(offsetHours: number): number {
  return new Date().getTime() - offsetHours * 3600 * 1000;
}

const SEARCH_HISTORY: Array<SearchHistoryItem> = [
  new SearchHistoryItem("arkts 状态管理", "刚刚", mockTimestamp(0)),
  new SearchHistoryItem("web 容器 拦截", "5 分钟前", mockTimestamp(0.08)),
  new SearchHistoryItem("LazyForEach key", "30 分钟前", mockTimestamp(0.5)),
  new SearchHistoryItem("搜索建议", "1 小时前", mockTimestamp(1)),
  new SearchHistoryItem("Compose Navigation", "昨天", mockTimestamp(26)),
  new SearchHistoryItem("鸿蒙 Web 登录态", "昨天", mockTimestamp(30)),
  new SearchHistoryItem("OPPOSans", "2 天前", mockTimestamp(52))
];

// ============================================================================
// 热搜榜(PRD §04-02 §2 "大家在搜")
// ============================================================================

const HOT_ITEMS: Array<HotSearchItem> = [
  new HotSearchItem(1, "arkts vs ts", true),
  new HotSearchItem(2, "HarmonyOS NEXT Web", true),
  new HotSearchItem(3, "Kotlin Flow 实战", true),
  new HotSearchItem(4, "LazyForEach 性能", false),
  new HotSearchItem(5, "Compose 状态", false)
];

// ============================================================================
// 建议词词典:输入 "arkts" 触发 5 条;其他关键词触发 3 条通用建议
// ============================================================================

const SUGGESTIONS_FOR_ARKTS: Array<SearchSuggestion> = [
  new SearchSuggestion("s_001", "arkts 状态管理",        "NORMAL", false),
  new SearchSuggestion("s_002", "arkts vs ts",          "HOT",    true ),
  new SearchSuggestion("s_003", "arkts decorator @State","NORMAL", false),
  new SearchSuggestion("s_004", "arkts list lazy",      "NORMAL", false),
  new SearchSuggestion("s_005", "arkts ui navigation",  "NORMAL", false)
];

/** S8:非前缀建议词(用于验证子串高亮,如输入 "nav" 命中 "Compose Navigation 教程")。 */
const SUGGESTIONS_EXTRA: Array<SearchSuggestion> = [
  new SearchSuggestion("s_e01", "Compose Navigation 教程",       "NORMAL", false),
  new SearchSuggestion("s_e02", "Flutter vs ArkTS 状态管理对比",  "NORMAL", false),
  new SearchSuggestion("s_e03", "oh-my-posh 主题配置",           "NORMAL", false),
  new SearchSuggestion("s_e04", "HarmonyOS DataAbility 使用",    "NORMAL", false),
  new SearchSuggestion("s_e05", "ArkUI Web 组件性能优化",        "HOT",    true )
];

/** 通用 fallback:把当前关键词回显 + 3 条相邻关键词。 */
function defaultSuggestions(keyword: string): Array<SearchSuggestion> {
  return [
    new SearchSuggestion("s_g1", `${keyword} 实战`,  "NORMAL", false),
    new SearchSuggestion("s_g2", `${keyword} 教程`,  "NORMAL", false),
    new SearchSuggestion("s_g3", `${keyword} 性能`,  "HOT",    true )
  ];
}

// ============================================================================
// 搜索结果文章(关键词 "arkts 状态管理" 4 条;通用 3 条)
//
// 字段刻意覆盖 Web/AI/TOOL 三类 categoryTag,与 Home Feed 卡片样式同源。
// ============================================================================

const RESULTS_ARKTS_STATE: Array<Article> = [
  new Article({
    articleId: "r_50001",
    title: "ArkTS @State 装饰器深度解析",
    summary: "覆盖单层组件、子组件、对象类型和数组的响应式行为。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "客户端笔记",
    publishTime: "2026-06-10T07:00:00Z",
    publishTimeDisplay: "3 小时前",
    targetUrl: "https://mock-web/article/r_50001",
    favorite: false,
    channelId: "search"   // 搜索结果统一标 channelId=search,LazyForEach key 不与 home 重
  }),
  new Article({
    articleId: "r_50002",
    title: "@Provide @Consume 跨层级通信",
    summary: "层级传递、命名空间冲突和性能边界。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "移动体验",
    publishTime: "2026-06-09T20:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/r_50002",
    favorite: false,
    channelId: "search"
  }),
  new Article({
    articleId: "r_50003",
    title: "ArkTS V2 状态体系演进",
    summary: "@ObservedV2 / @Trace 出现的原因和迁移策略。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "鸿蒙月刊",
    publishTime: "2026-06-08T15:00:00Z",
    publishTimeDisplay: "2 天前",
    targetUrl: "https://mock-web/article/r_50003",
    favorite: false,
    channelId: "search"
  }),
  new Article({
    articleId: "r_50004",
    title: "Kotlin StateFlow vs ArkTS State",
    summary: "两端状态管理对照与迁移要点。",
    coverUrl: null,
    coverPlaceholder: "工具",
    categoryTag: "TOOL",
    source: "客户端工程",
    publishTime: "2026-06-07T10:00:00Z",
    publishTimeDisplay: "3 天前",
    targetUrl: "https://mock-web/article/r_50004",
    favorite: true,
    channelId: "search"
  })
];

/** 通用兜底文章列表:任意非 "arkts 状态管理" 关键词都用这一组,演示用。 */
const RESULTS_GENERIC: Array<Article> = [
  new Article({
    articleId: "r_60001",
    title: "鸿蒙搜索接入指南:Mock 与真实 API 切换",
    summary: "Repository 层切换策略,VM/UI 完全无感知。",
    coverUrl: null,
    coverPlaceholder: "Web",
    categoryTag: "WEB",
    source: "工程师之路",
    publishTime: "2026-06-10T08:00:00Z",
    publishTimeDisplay: "1 小时前",
    targetUrl: "https://mock-web/article/r_60001",
    favorite: false,
    channelId: "search"
  }),
  new Article({
    articleId: "r_60002",
    title: "AI 速答 UI 兜底:LLM 没接上前怎么演示",
    summary: "占位卡 + Mock chip + disclaimer 三件套。",
    coverUrl: null,
    coverPlaceholder: "AI",
    categoryTag: "AI",
    source: "FlowSearch Team",
    publishTime: "2026-06-09T14:00:00Z",
    publishTimeDisplay: "昨天",
    targetUrl: "https://mock-web/article/r_60002",
    favorite: false,
    channelId: "search"
  }),
  new Article({
    articleId: "r_60003",
    title: "搜索历史本地化:Preferences vs DataStore",
    summary: "为什么不直接放内存 -- 数据持久化的工程边界。",
    coverUrl: null,
    coverPlaceholder: "工具",
    categoryTag: "TOOL",
    source: "FlowSearch Team",
    publishTime: "2026-06-08T10:00:00Z",
    publishTimeDisplay: "2 天前",
    targetUrl: "https://mock-web/article/r_60003",
    favorite: false,
    channelId: "search"
  })
];

// ============================================================================
// AI 速答词典:keyword 命中预设词条返回真数据,其他返回 null(演示降级)
// ============================================================================

const AI_ANSWERS: Map<string, AiQuickAnswer> = new Map<string, AiQuickAnswer>([
  ["arkts 状态管理", new AiQuickAnswer(
    "ai_mock_001",
    "ArkTS 提供 @State / @Prop / @Link / @Provide 等装饰器管理组件状态,V2 引入 @ObservedV2 / @Trace 等更精细控制。建议从单组件 @State 起步,父子通信用 @Prop/@Link,跨层级用 @Provide/@Consume。",
    [
      "@State 和 @Prop 的区别",
      "@Link 和 @Provide 何时用",
      "ArkTS V1 vs V2 状态体系"
    ],
    "本卡片为演示占位,不接真实 LLM"
  )]
]);

// ============================================================================
// Mock 门面
// ============================================================================

export class SearchMock {
  /** 空输入态:历史 + 热搜。 */
  static getSearchInput(): SearchInputData {
    return new SearchInputData(SEARCH_HISTORY.slice(), HOT_ITEMS.slice());
  }

  /**
   * 实时建议词。
   * keyword 去空白后 < 1 字符直接返回空数组(VM 层不该调到这里,但兜底)。
   */
  static getSuggestions(keyword: string): Array<SearchSuggestion> {
    const kw = keyword.trim().toLowerCase();
    if (kw.length === 0) {
      return new Array();
    }
    if (kw.indexOf("arkts") === 0) {
      // 前缀命中 "arkts" 用预设列表
      return SUGGESTIONS_FOR_ARKTS.slice();
    }
    // S8:子串匹配 -- 从 SUGGESTIONS_EXTRA 中筛选包含关键词的建议
    const matched: Array<SearchSuggestion> = new Array();
    for (let i = 0; i < SUGGESTIONS_EXTRA.length; i++) {
      if (SUGGESTIONS_EXTRA[i].keyword.toLowerCase().indexOf(kw) >= 0) {
        matched.push(SUGGESTIONS_EXTRA[i]);
      }
    }
    if (matched.length > 0) {
      return matched;
    }
    return defaultSuggestions(keyword.trim());
  }

  /**
   * 搜索结果列表。
   * - keyword === "__empty__" 强制返回空(演示 Empty 态)
   * - 其他 keyword 走预设词典 / 兜底列表
   * - sort 在 Mock 层不真做排序,只是签名占位(真实接口会用)
   */
  static getResults(keyword: string, _sort: SortType): Array<Article> {
    const kw = keyword.trim();
    if (kw === "__empty__") {
      return new Array();
    }
    if (kw === "arkts 状态管理") {
      return RESULTS_ARKTS_STATE.slice();
    }
    return RESULTS_GENERIC.slice();
  }

  /**
   * AI 速答。
   * keyword 长度 < 2 字符返回 null(PRD §04-03 §6)。
   * 字典命中返回真数据,否则返回 null(整张卡 UI 层隐藏)。
   */
  static getAiAnswer(keyword: string): AiQuickAnswer | null {
    const kw = keyword.trim();
    if (kw.length < 2) {
      return null;
    }
    const hit = AI_ANSWERS.get(kw);
    return hit !== undefined ? hit : null;
  }
}
