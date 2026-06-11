/**
 * @file HomeModels.ets
 * @description Home 屏业务实体。字段严格对齐 PRD §08-数据模型.md。
 *
 * 设计要点(简历主线 5:双端字段语义一致):
 *
 * 1. 放在 commons/base 而不是 features/home:
 *    "数据契约"是基础设施层的关注点,所有 feature 共享同一个 Article/Channel 定义;
 *    mockdata 模块也要靠这些类型组装数据 -> 放 base 让依赖方向干净。
 *    类比 Kotlin: 这相当于 :core:model 模块,而非 :feature:home 内部 model。
 *
 * 2. 零装饰器(同源底线):
 *    本文件不引入 @ObservedV2 / @Trace 等任何 ArkUI 装饰器,
 *    用 readonly + 构造器赋值,等价 Kotlin data class。
 *    Kotlin 阶段直接 1:1 平移成 data class。
 *
 * 3. categoryTag / targetType 用 string 字面量类型:
 *    ArkTS 支持 string literal union(只要值域全是字符串),
 *    比 enum 更轻、序列化友好,与服务端约定(大写蛇形)对齐。
 *    Kotlin 阶段映射成 sealed class 或 enum class。
 *
 * 4. 时间双发:
 *    publishTime(ISO 8601) + publishTimeDisplay(已渲染的相对时间字符串),
 *    避免客户端各自实现"12 分钟前"的格式化,见 PRD §08 §5。
 */

/** 内容卡片分类标签。决定 ArticleCard 角标颜色(见 PRD §02 §1)。 */
export type CategoryTag = "WEB" | "TOOL" | "VIDEO" | "AI";

/** 工具入口跳转类型。SHELL = 占位壳页;WEB = 进 Web 容器。 */
export type ToolTargetType = "SHELL" | "WEB";

/**
 * Article 内容卡片(PRD §08 §4.1)。
 * LazyForEach key 规则: `${channelId}_${articleId}` -> 跨频道切换不复用 ViewHolder。
 */
export class Article {
  readonly articleId: string = "";
  readonly title: string = "";
  readonly summary: string = "";
  readonly coverUrl: string | null = null;
  readonly coverPlaceholder: string = "";
  readonly categoryTag: CategoryTag = "WEB";
  readonly source: string = "";
  readonly publishTime: string = "";
  readonly publishTimeDisplay: string = "";
  readonly targetUrl: string = "";
  readonly favorite: boolean = false;
  readonly channelId: string = "";

  constructor(init: ArticleInit) {
    this.articleId = init.articleId;
    this.title = init.title;
    this.summary = init.summary;
    this.coverUrl = init.coverUrl;
    this.coverPlaceholder = init.coverPlaceholder;
    this.categoryTag = init.categoryTag;
    this.source = init.source;
    this.publishTime = init.publishTime;
    this.publishTimeDisplay = init.publishTimeDisplay;
    this.targetUrl = init.targetUrl;
    this.favorite = init.favorite;
    this.channelId = init.channelId;
  }

  /** 不可变更新收藏态:返回新实例,不修改原对象。等价 Kotlin data class .copy()。 */
  withFavorite(favorite: boolean): Article {
    return new Article({
      articleId: this.articleId,
      title: this.title,
      summary: this.summary,
      coverUrl: this.coverUrl,
      coverPlaceholder: this.coverPlaceholder,
      categoryTag: this.categoryTag,
      source: this.source,
      publishTime: this.publishTime,
      publishTimeDisplay: this.publishTimeDisplay,
      targetUrl: this.targetUrl,
      favorite: favorite,
      channelId: this.channelId
    });
  }
}

/** Article 构造器入参。ArkTS 不支持具名参数,用 init 对象模拟,字段顺序无关。 */
export interface ArticleInit {
  articleId: string;
  title: string;
  summary: string;
  coverUrl: string | null;
  coverPlaceholder: string;
  categoryTag: CategoryTag;
  source: string;
  publishTime: string;
  publishTimeDisplay: string;
  targetUrl: string;
  favorite: boolean;
  channelId: string;
}

/** Channel 频道(PRD §08 §4.2)。 */
export class Channel {
  readonly channelId: string = "";
  readonly name: string = "";
  readonly order: number = 0;
  readonly fixed: boolean = true;

  constructor(channelId: string, name: string, order: number, fixed: boolean) {
    this.channelId = channelId;
    this.name = name;
    this.order = order;
    this.fixed = fixed;
  }
}

/** ToolEntry 工具入口(PRD §08 §4.3)。首页只展示 order 最小的前 4 个。 */
export class ToolEntry {
  readonly toolId: string = "";
  readonly name: string = "";
  readonly iconKey: string = "";
  readonly targetType: ToolTargetType = "SHELL";
  readonly targetUrl: string | null = null;
  readonly order: number = 0;

  constructor(
    toolId: string,
    name: string,
    iconKey: string,
    targetType: ToolTargetType,
    targetUrl: string | null,
    order: number
  ) {
    this.toolId = toolId;
    this.name = name;
    this.iconKey = iconKey;
    this.targetType = targetType;
    this.targetUrl = targetUrl;
    this.order = order;
  }
}

/**
 * 首页聚合数据(PRD §07 §2.1 GET /api/tool/home 的 data 部分)。
 *
 * 三块组合:频道列表 + 工具入口 + 首屏 Feed 文章列表。
 * 当前 channelId 不放在这个对象里,由 ViewModel 维护(频道切换是 UI 状态)。
 */
export class HomeFeedData {
  readonly channels: Array<Channel> = [];
  readonly quickEntries: Array<ToolEntry> = [];
  readonly articles: Array<Article> = [];

  constructor(channels: Array<Channel>, quickEntries: Array<ToolEntry>, articles: Array<Article>) {
    this.channels = channels;
    this.quickEntries = quickEntries;
    this.articles = articles;
  }
}
