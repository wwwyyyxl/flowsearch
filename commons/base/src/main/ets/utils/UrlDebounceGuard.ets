/**
 * @file UrlDebounceGuard.ets
 * @description URL 防抖守卫。同一 URL 5 秒内不重复打开 WebContainer。
 *
 * PRD §04-04 §6: "同一 URL 5 秒防抖"。
 * 静态类,全 app 共享一个实例状态。
 */

export class UrlDebounceGuard {
  private static lastUrl: string = "";
  private static lastTime: number = 0;
  private static readonly DEBOUNCE_MS: number = 5000;

  /** 判断该 URL 是否允许打开。允许则记录并返回 true,否则返回 false。 */
  static shouldOpen(url: string): boolean {
    const now: number = new Date().getTime();
    if (url === UrlDebounceGuard.lastUrl &&
      (now - UrlDebounceGuard.lastTime) < UrlDebounceGuard.DEBOUNCE_MS) {
      return false;
    }
    UrlDebounceGuard.lastUrl = url;
    UrlDebounceGuard.lastTime = now;
    return true;
  }
}
