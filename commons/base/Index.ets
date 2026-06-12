/**
 * @file Index.ets
 * @description commons/base HAR 模块的公共 API 出口。
 *
 * 只导出供 features 使用的稳定类型。内部辅助类不导出。
 * 类比 Kotlin: 模块 internal vs public 修饰符的边界。
 */

export { PageState } from "./src/main/ets/types/PageState";
export type { PageStateKind } from "./src/main/ets/types/PageState";
export { Result } from "./src/main/ets/types/Result";
export {
  Article, Channel, ToolEntry, HomeFeedData
} from "./src/main/ets/types/HomeModels";
export type {
  ArticleInit, CategoryTag, ToolTargetType
} from "./src/main/ets/types/HomeModels";

// ===== Search 域类型(S2 新增) =====
export {
  SearchSuggestion, HotSearchItem, SearchHistoryItem,
  AiQuickAnswer, SearchInputData, SearchSuggestionData, SearchResultData
} from "./src/main/ets/types/SearchModels";
export type {
  SuggestionType, SortType
} from "./src/main/ets/types/SearchModels";

// ===== Web 域类型(S3 新增) =====
export {
  WebInterceptRule, WebContainerData
} from "./src/main/ets/types/WebModels";
export type {
  WebInterceptAction
} from "./src/main/ets/types/WebModels";

// ===== Persistence 域(S4 新增) =====
export { PreferencesHelper } from "./src/main/ets/persistence/PreferencesHelper";
export { FavoriteRecord } from "./src/main/ets/types/FavoriteRecord";

// ===== Utils 域(S12 新增) =====
export { UrlDebounceGuard } from "./src/main/ets/utils/UrlDebounceGuard";

// ===== Reading History 域(S13 新增) =====
export { ReadingHistoryEntry } from "./src/main/ets/types/ReadingHistoryEntry";
