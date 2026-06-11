/**
 * @file Result.ets
 * @description 网络/异步调用的统一返回包装。
 *
 * 设计要点:
 * 1. 类似 Kotlin 的 Result<T> / Rust 的 Result<T, E>,但 ArkTS 不支持联合字面量,
 *    所以用 class + ok: boolean 区分。
 * 2. Repository 层方法签名统一返回 Result<T>,ViewModel 不再 try/catch 散落,
 *    错误处理收敛在 VM 一处。
 * 3. 不可变,每次都 new。
 *
 * 用法:
 * ```ts
 * const result: Result<HomeData> = await this.repo.fetchHome()
 * if (result.ok) {
 *   this.state = PageState.content(result.data!)
 * } else {
 *   this.state = PageState.error(result.errorCode, result.errorMessage)
 * }
 * ```
 *
 * Kotlin 对照:
 *   sealed class Result<out T> {
 *     data class Success<T>(val data: T): Result<T>()
 *     data class Failure(val code: String, val message: String): Result<Nothing>()
 *   }
 */

export class Result<T> {
  readonly ok: boolean = false;
  readonly data: T | null = null;
  readonly errorCode: string = "";
  readonly errorMessage: string = "";

  private constructor(ok: boolean, data: T | null, errorCode: string, errorMessage: string) {
    this.ok = ok;
    this.data = data;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
  }

  /** 成功。data 不能为 null(语义上成功就一定有数据,即使是空数组)。 */
  static success<T>(data: T): Result<T> {
    return new Result<T>(true, data, "", "");
  }

  /** 失败。code 对应 PRD §07 错误码表,如 "401" / "500" / "NETWORK_ERROR" / "TIMEOUT"。 */
  static failure<T>(code: string, message: string): Result<T> {
    return new Result<T>(false, null, code, message);
  }
}
