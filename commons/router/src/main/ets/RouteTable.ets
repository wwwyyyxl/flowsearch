/**
 * @file RouteTable.ets
 * @description FlowSearch 路由表常量。对应 PRD §03-信息架构与路由.md §7 命名约定。
 *
 * 设计要点(简历主线 5:双端字段语义一致):
 *
 * 1. 用 string 常量而不是 enum:
 *    HarmonyOS 的 NavPathStack.pushPath({name: string}) 直接吃字符串,
 *    用常量类聚集起来既保留编辑器自动完成,又方便日志打印路由名。
 *
 * 2. PageName 命名严格对齐 PRD:
 *    每个常量名 = PRD 里 `const PageName = {...}` 列出的字段名,
 *    保证简历"路由命名一致"的根证据可被追溯。
 *
 * 3. 不耦合具体页面实现:
 *    本文件不 import 任何 features/* 文件,只是字符串字典;
 *    实际页面构建器(WrappedBuilder)注册在 products/fsearch 启动时,
 *    避免 commons 反向依赖 features 造成的循环依赖。
 *
 * Kotlin 对照:
 *   object Routes {
 *     const val HOME = "home"
 *     const val SEARCH_INPUT = "search/input"
 *     ...
 *   }
 */

export class RouteTable {
  static readonly HOME: string = "home";
  static readonly SEARCH_INPUT: string = "search.input";
  static readonly SEARCH_RESULT: string = "search.result";
  static readonly WEB_CONTAINER: string = "web.container";
  static readonly FAVORITES_HISTORY: string = "favs";
  static readonly SETTINGS: string = "settings";
  static readonly TOOL_SHELL: string = "tool.shell";

  // 路由参数 key(各页面通过 NavPathStack.getParamByName 取)
  static readonly PARAM_KEYWORD: string = "keyword";
  static readonly PARAM_URL: string = "url";
  static readonly PARAM_TITLE: string = "title";
  static readonly PARAM_TOOL_ID: string = "toolId";
  static readonly PARAM_FAVS_TAB: string = "tab"; // favorites | history
}
