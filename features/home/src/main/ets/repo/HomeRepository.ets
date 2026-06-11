/**
 * @file HomeRepository.ets
 * @description 首页数据源。从 HomeMock 取数据 + 模拟网络延时和错误。
 *
 * 设计要点(同源底线 / 简历主线 5):
 *
 * 1. 零装饰器(plain class):
 *    本类不引入任何 @ObservedV2 / @Trace / @ComponentV2 等 ArkUI 装饰器,
 *    全部走 async / Promise / setTimeout,可以整段平移到 Kotlin:
 *      class HomeRepository {
 *        suspend fun fetchFeed(channelId: String, mode: SimulationMode): HomeFeedData
 *      }
 *    -> 这是简历"双端数据层 1:1 平移"的根证据。
 *
 * 2. 不持有状态:
 *    所有方法都是纯函数(给定输入 -> 给定输出 / 异常),
 *    缓存策略放在 VM 或更上层,Repository 只管"怎么取"。
 *
 * 3. 接口契约用 throw + 自定义错误对象:
 *    ArkTS 没有 Kotlin 的 Result<T>,但 commons/base 里已有 Result 类,
 *    本期为了让 VM 用 try/catch 风格(与 Kotlin runCatching 心智一致),
 *    Repository 直接 throw 错误,VM 用 try/catch 包装。
 *
 * 4. 函数签名:
 *    fetchFeed(channelId, mode) -> Promise<HomeFeedData>
 *    -- 不用 PRD §07 §2.1 那种聚合响应包,因为响应包封装该在 commons/network 做,
 *    本期没建 network 模块,Repository 直接返回 data 部分,VM 直接消费。
 *    S2 接 commons/network 后,Repository 升级为调 MockApiClient,签名不变。
 */

import { HomeFeedData } from "@flowsearch/base";
import { HomeMock } from "@flowsearch/mockdata";
import { SimulationMode } from "./SimulationMode";

/** Mock 网络延时(毫秒)。 */
const DELAY_NORMAL_MS: number = 200;
const DELAY_ERROR_MS: number = 500;
const DELAY_SLOW_MS: number = 3000;

/** Repository 抛出的错误对象,带 errorCode 字段,便于 VM 翻译成 PageState.error。 */
export class HomeRepoError extends Error {
  readonly errorCode: string = "";

  constructor(errorCode: string, message: string) {
    super(message);
    this.errorCode = errorCode;
  }
}

export class HomeRepository {
  /**
   * 拉取指定频道的首页数据。
   *
   * @param channelId 频道 id(如 "hot" / "tech")
   * @param mode      模拟模式(本期默认 normal,调试浮层可切换)
   * @returns         HomeFeedData(频道 + 工具入口 + 文章列表)
   * @throws          HomeRepoError(mode === "error" 时,500 服务异常)
   */
  async fetchFeed(channelId: string, mode: SimulationMode): Promise<HomeFeedData> {
    const delayMs: number = HomeRepository.pickDelay(mode);
    await HomeRepository.sleep(delayMs);

    if (mode === "error") {
      throw new HomeRepoError("500", "服务器开小差了,请稍后重试");
    }

    if (mode === "empty") {
      // 频道列表和工具入口仍然要给(顶部 UI 需要渲染),但文章列表强制空
      return new HomeFeedData(
        HomeMock.getChannels(),
        HomeMock.getQuickEntries(),
        new Array()
      );
    }

    // normal / slow 都走正常数据(slow 只是延时长一点)
    return HomeMock.getHomeFeed(channelId);
  }

  /** 按模式映射延时。集中一处,方便调参。 */
  private static pickDelay(mode: SimulationMode): number {
    if (mode === "slow") {
      return DELAY_SLOW_MS;
    }
    if (mode === "error") {
      return DELAY_ERROR_MS;
    }
    return DELAY_NORMAL_MS;
  }

  /**
   * Promise 化的 setTimeout。等价 Kotlin delay(ms)。
   * 用箭头函数 + 显式 void 返回,避开 arkts-no-implicit-return-types。
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void): void => {
      setTimeout((): void => { resolve(); }, ms);
    });
  }
}
