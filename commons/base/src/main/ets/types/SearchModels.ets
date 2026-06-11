/**
 * @file SearchModels.ets
 * @description 搜索域业务实体。字段严格对齐 PRD §04-02 / §04-03 / §08-数据模型。
 *
 * 设计要点(与 HomeModels 同源底线一致):
 *
 * 1. 放在 commons/base:mockdata 和 features/search 都要消费,放基础层让依赖方向干净。
 *    类比 Kotlin: 这相当于 :core:model 模块的扩展。
 *
 * 2. 零 ArkUI 装饰器,纯 readonly + 构造器,等价 Kotlin data class,可 1:1 平移。
 *
 * 3. type 用 string 字面量联合(ArkTS 支持),与服务端大写约定对齐。
 *
 * 4. 搜索结果卡片直接复用 Home 的 Article(PRD §04-03 §2 "同 Home 的 Article 卡片布局"),
 *    不另立类型;关键词高亮在 UI 层按 keyword 匹配,不污染数据模型。
 *
 * 5. 聚合类(SearchInputData / SearchSuggestionData / SearchResultData):
 *    这是为了 PageState.data 携带多字段数据准备的包装类,
 *    与 HomeFeedData 角色一致。UI 层 cast 到这些类型读字段。
 */

import { Article } from "./HomeModels";

/** 建议词类型。NORMAL=普通联想;HOT=热门(右侧带 🔥)。 */
export type SuggestionType = "NORMAL" | "HOT";

/**
 * SearchResult 顶部排序/筛选 Tab 类型(PRD §04-03 §2)。
 * RELEVANCE  = 综合(默认)
 * LATEST     = 最新
 * HOTTEST    = 最热
 * TOOL_ONLY  = 仅工具
 * ARTICLE_ONLY = 仅文章
 *
 * 服务端契约用大写,与 categoryTag / targetType 风格一致。
 */
export type SortType = "RELEVANCE" | "LATEST" | "HOTTEST" | "TOOL_ONLY" | "ARTICLE_ONLY";

/** 搜索建议词(PRD §04-02 §7 SearchSuggestion + §08 §4.4)。 */
export class SearchSuggestion {
  readonly suggestionId: string = "";
  readonly keyword: string = "";
  readonly type: SuggestionType = "NORMAL";
  readonly hot: boolean = false;

  constructor(suggestionId: string, keyword: string, type: SuggestionType, hot: boolean) {
    this.suggestionId = suggestionId;
    this.keyword = keyword;
    this.type = type;
    this.hot = hot;
  }
}

/** 热搜榜单项(PRD §04-02 §2 "大家在搜")。rank 从 1 起;前 3 红色 + 🔥。 */
export class HotSearchItem {
  readonly rank: number = 0;
  readonly keyword: string = "";
  readonly hot: boolean = false;

  constructor(rank: number, keyword: string, hot: boolean) {
    this.rank = rank;
    this.keyword = keyword;
    this.hot = hot;
  }
}

/**
 * 搜索历史项(PRD §04-02 §7 SearchHistory + §08 §4.5)。
 * 本期 searchAt 用预渲染字符串("12 分钟前"),不在端上计算。
 * Kotlin 阶段会切回 Long(ms 时间戳),由端上格式化 -- 这是叙事差异。
 */
export class SearchHistoryItem {
  readonly keyword: string = "";
  readonly searchAt: string = "";
  readonly createdAt: number = 0;

  constructor(keyword: string, searchAt: string, createdAt: number = 0) {
    this.keyword = keyword;
    this.searchAt = searchAt;
    this.createdAt = createdAt;
  }
}

/**
 * AI 速答卡数据(PRD §04-03 §7 AIQuickAnswer + §08 §4.6)。
 * 本期 Mock,不接真实 LLM(PRD §1 简历讲点:"未来 AI 接入"的视觉锚)。
 */
export class AiQuickAnswer {
  readonly answerId: string = "";
  readonly summary: string = "";
  readonly relatedQuestions: Array<string> = [];
  readonly disclaimer: string = "";

  constructor(answerId: string, summary: string, relatedQuestions: Array<string>, disclaimer: string) {
    this.answerId = answerId;
    this.summary = summary;
    this.relatedQuestions = relatedQuestions;
    this.disclaimer = disclaimer;
  }
}

/**
 * SearchInputPage 空输入态的内容聚合。
 * UI 通过 cast state.data 到这个类型,读 history / hotItems。
 */
export class SearchInputData {
  readonly history: Array<SearchHistoryItem> = [];
  readonly hotItems: Array<HotSearchItem> = [];

  constructor(history: Array<SearchHistoryItem>, hotItems: Array<HotSearchItem>) {
    this.history = history;
    this.hotItems = hotItems;
  }
}

/**
 * SearchInputPage 有输入时的建议聚合。
 * suggestions.length === 0 时 UI 显示"没有相关建议"(PRD §04-02 §6)。
 */
export class SearchSuggestionData {
  readonly keyword: string = "";
  readonly suggestions: Array<SearchSuggestion> = [];

  constructor(keyword: string, suggestions: Array<SearchSuggestion>) {
    this.keyword = keyword;
    this.suggestions = suggestions;
  }
}

/**
 * SearchResultPage 内容态聚合。
 * 三块组合:当前关键词 + AI 速答(可空) + 结果文章列表。
 * sortType 由 VM 单独维护(切排序不重抽 AI 卡,PRD §04-03 §3)。
 */
export class SearchResultData {
  readonly keyword: string = "";
  readonly aiAnswer: AiQuickAnswer | null = null;
  readonly articles: Array<Article> = [];

  constructor(keyword: string, aiAnswer: AiQuickAnswer | null, articles: Array<Article>) {
    this.keyword = keyword;
    this.aiAnswer = aiAnswer;
    this.articles = articles;
  }
}
