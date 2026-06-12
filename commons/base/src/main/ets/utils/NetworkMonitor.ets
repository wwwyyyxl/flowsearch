/**
 * @file NetworkMonitor.ets
 * @description 全局网络状态监听器。基于 @kit.NetworkKit 的 connection API。
 *
 * 鸿蒙文档依据:
 *   - connection.createNetConnection()  → 创建监听对象
 *   - netConn.on('netAvailable', cb)    → 网络恢复回调
 *   - netConn.on('netLost', cb)         → 网络断开回调
 *   - netConn.register(cb)              → 开始监听
 *   - netConn.unregister(cb)            → 停止监听
 *   - 权限: ohos.permission.GET_NETWORK_INFO (normal 级,module.json5 声明即可)
 *
 * 使用方式:
 *   1. FsearchAbility.onCreate 中调 NetworkMonitor.getInstance().start(context)
 *   2. 页面中通过 NetworkMonitor.getInstance().isOnline 判断网络状态
 *   3. FsearchAbility.onDestroy 中调 NetworkMonitor.getInstance().stop()
 *
 * 为什么放 commons/base:
 *   网络状态是基础设施,多个 feature 模块需要读取,放在叶子模块避免循环依赖。
 */

import { connection } from "@kit.NetworkKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const TAG: string = "NetworkMonitor";
const DOMAIN: number = 0x0000;

@ObservedV2
export class NetworkMonitor {
  /** 当前是否在线。@Trace 保证 UI 自动响应。 */
  @Trace isOnline: boolean = true;

  private static instance: NetworkMonitor | null = null;
  private netConn: connection.NetConnection | null = null;
  private started: boolean = false;

  /** 单例获取。 */
  static getInstance(): NetworkMonitor {
    if (NetworkMonitor.instance === null) {
      NetworkMonitor.instance = new NetworkMonitor();
    }
    return NetworkMonitor.instance;
  }

  /**
   * 启动网络监听。
   * 应在 FsearchAbility.onCreate 中调用。
   *
   * 流程:
   *   1. createNetConnection() 创建监听对象
   *   2. on('netAvailable') 注册恢复回调
   *   3. on('netLost') 注册断开回调
   *   4. register() 开始监听
   */
  start(context: Context): void {
    if (this.started) {
      return;
    }
    try {
      this.netConn = connection.createNetConnection();

      this.netConn.on('netAvailable', (_data: connection.NetHandle): void => {
        hilog.info(DOMAIN, TAG, 'Network available');
        this.isOnline = true;
      });

      this.netConn.on('netLost', (): void => {
        hilog.info(DOMAIN, TAG, 'Network lost');
        this.isOnline = false;
      });

      this.netConn.register((err: BusinessError): void => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'Register failed: %{public}s', JSON.stringify(err));
        } else {
          hilog.info(DOMAIN, TAG, 'Network monitor registered');
        }
      });

      this.started = true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Start failed: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 停止网络监听,释放资源。
   * 应在 FsearchAbility.onDestroy 中调用。
   */
  stop(): void {
    if (!this.started || this.netConn === null) {
      return;
    }
    try {
      this.netConn.unregister((err: BusinessError): void => {
        if (err) {
          hilog.error(DOMAIN, TAG, 'Unregister failed: %{public}s', JSON.stringify(err));
        } else {
          hilog.info(DOMAIN, TAG, 'Network monitor unregistered');
        }
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Stop failed: %{public}s', JSON.stringify(err));
    }
    this.netConn = null;
    this.started = false;
  }
}
