/**
 * @file PerfTracker.ets
 * @description 性能追踪工具类。S24 新增:封装 hiTraceMeter + hiAppEvent。
 *
 * 鸿蒙文档依据:
 *   - @kit.PerformanceAnalysisKit → hiTraceMeter.startTrace / finishTrace / traceByValue
 *   - @kit.PerformanceAnalysisKit → hiAppEvent.write({ domain, name, eventType, params })
 *   - hiTraceMeter: SmartPerf / hitrace 命令行可捕获
 *   - hiAppEvent: 应用事件打点,EventType: FAULT / STATISTIC / BEHAVIOR / SECURITY
 *
 * 设计要点:
 *   1. 零装饰器(plain class),与 NetworkMonitor / UrlDebounceGuard 同层
 *   2. markStart / markEnd 封装 startTrace / finishTrace,调用方不用记 taskId 细节
 *   3. reportEvent 封装 hiAppEvent.write,异步写入不阻塞主流程
 *   4. 全部 try-catch 包裹 — 性能监控不应导致业务崩溃
 */

import { hiTraceMeter, hiAppEvent } from "@kit.PerformanceAnalysisKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "PerfTracker";
const DOMAIN: number = 0x0000;

export class PerfTracker {
  /** 自增任务 ID,用于并发 trace 区分。 */
  private static nextTaskId: number = 1;

  /**
   * 标记性能追踪起点。
   *
   * @param label 追踪标签(如 "home_feed_load", "search_query")
   * @returns     taskId,传给对应的 markEnd
   */
  static markStart(label: string): number {
    const taskId: number = PerfTracker.nextTaskId;
    PerfTracker.nextTaskId += 1;
    try {
      hiTraceMeter.startTrace(label, taskId);
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, "startTrace failed: %{public}s", label);
    }
    return taskId;
  }

  /**
   * 标记性能追踪终点。
   *
   * @param label  追踪标签(必须与 markStart 一致)
   * @param taskId markStart 返回的任务 ID
   */
  static markEnd(label: string, taskId: number): void {
    try {
      hiTraceMeter.finishTrace(label, taskId);
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, "finishTrace failed: %{public}s", label);
    }
  }

  /**
   * 记录数值型指标。
   *
   * @param label 指标名(如 "search_result_count")
   * @param value 数值
   */
  static traceValue(label: string, value: number): void {
    try {
      hiTraceMeter.traceByValue(label, value);
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, "traceByValue failed: %{public}s", label);
    }
  }

  /**
   * 上报应用事件(异步,不阻塞)。
   *
   * @param event  事件名(如 "home_feed_loaded")
   * @param params 事件参数(键值对)
   */
  static reportEvent(event: string, params: Record<string, number | string | boolean>): void {
    try {
      hiAppEvent.write({
        domain: "FlowSearch",
        name: event,
        eventType: hiAppEvent.EventType.BEHAVIOR,
        params: params
      }).catch((_err: object): void => {
        hilog.warn(DOMAIN, TAG, "hiAppEvent.write failed: %{public}s", event);
      });
    } catch (_e) {
      hilog.warn(DOMAIN, TAG, "reportEvent failed: %{public}s", event);
    }
  }
}
