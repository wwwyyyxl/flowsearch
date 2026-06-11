/**
 * @file WebMock.ets
 * @description Web 容器域假数据集。对应 PRD §07-Mock-API.md §2.13。
 *
 * 设计要点(对齐 HomeMock / SearchMock 同源策略):
 * 1. 零装饰器,静态导出。Kotlin 阶段可整段平移。
 * 2. 接口:
 *    - getInterceptRules() -> Array<WebInterceptRule>,对齐 §2.13
 * 3. 5 条规则字段与 PRD §07-2.13 100% 同型(ruleId/pattern/action/needTokenInject)。
 * 4. mock token 也放在这里(简化版),features/web 自包含的拦截器会从这里取。
 *    真实接口阶段 token 会移到 commons/network 的 AuthInterceptor + Preferences。
 */

import { WebInterceptRule } from "@flowsearch/base";

// ============================================================================
// 拦截规则(PRD §07 §2.13)
// ============================================================================

const INTERCEPT_RULES: Array<WebInterceptRule> = [
  new WebInterceptRule("r_001", "https://mock-login/*",    "INTERCEPT_LOGIN",    false),
  new WebInterceptRule("r_002", "https://mock-pay/*",      "INTERCEPT_PAY",      true ),
  new WebInterceptRule("r_003", "https://*.download/*",    "INTERCEPT_DOWNLOAD", false),
  new WebInterceptRule("r_004", "https://mock-cdn/*",      "ALLOW",              true ),
  new WebInterceptRule("r_005", "tel:*",                   "OPEN_EXTERNAL",      false)
];

// ============================================================================
// Mock token(简化版,真接口阶段切 commons/network/Preferences)
// ============================================================================

const MOCK_TOKEN: string = "mock_token_fsearch_demo_v1";

// ============================================================================
// Mock 门面
// ============================================================================

export class WebMock {
  /**
   * 取拦截规则。PRD §07 §2.13 + §04-04 §3。
   * 真实接口缓存 30 分钟由 WebRepository 自己管理,Mock 层不关心。
   */
  static getInterceptRules(): Array<WebInterceptRule> {
    return INTERCEPT_RULES.slice();
  }

  /**
   * 取 mock token。当 `needTokenInject=true` 时由 WebRepository 注入到 cookie/header。
   * 这是 commons/network/AuthInterceptor 的功能预演 — 简历主线 2"登录态透传"的占位证据。
   */
  static getMockToken(): string {
    return MOCK_TOKEN;
  }
}
