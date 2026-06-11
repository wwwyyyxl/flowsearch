/**
 * @file PreferencesHelper.ets
 * @description HarmonyOS Preferences 轻量封装。只处理 JSON string 的读写。
 *
 * 设计要点:
 *
 * 1. 零装饰器(plain class):
 *    放在 commons/base 的 persistence 目录,不引入 @ObservedV2 / @Trace。
 *    类比 Kotlin: object PreferencesHelper(纯工具函数)。
 *
 * 2. 只暴露两个静态方法:
 *    getJson(context, storeName, key) -> Promise<string | null>
 *    putJson(context, storeName, key, json) -> Promise<void>
 *    调用方自己负责 JSON.stringify / JSON.parse。
 *    职责单一:本类不关心业务语义(收藏 / 历史 / 设置)。
 *
 * 3. 每次 put 后自动 flush:
 *    Preferences 的 put 只写内存缓存,flush 才落盘。
 *    本 helper 封装 flush,调用方不用记这一步。
 *
 * 4. Context 由调用方传入(来自 Page.getContext(this)):
 *    VM 是 plain class 没有 getContext 能力,
 *    Page.aboutToAppear() 取 Context 传给 VM -> Repository -> 本 helper。
 *    这个模式在 S5 Settings 也会复用。
 *
 * ArkTS ↔ Kotlin 对照:
 *   PreferencesHelper.getJson(ctx, "store", "key")
 *     ≈ context.getSharedPreferences("store", MODE_PRIVATE).getString("key", null)
 */

import preferences from "@ohos.data.preferences";

export class PreferencesHelper {
  /**
   * 从 Preferences 读取 JSON string。
   * @param context   应用上下文(Page.getContext(this) 获取)
   * @param storeName Preferences 实例名(如 "fsearch_favorites")
   * @param key       存储键名(如 "favorites_json")
   * @returns         JSON string 或 null(不存在/空)
   */
  static async getJson(context: Context, storeName: string, key: string): Promise<string | null> {
    const store: preferences.Preferences = await preferences.getPreferences(context, storeName);
    const val: preferences.ValueType = await store.get(key, "");
    if (typeof val === "string" && val.length > 0) {
      return val;
    }
    return null;
  }

  /**
   * 写入 JSON string 到 Preferences 并落盘。
   * @param context   应用上下文
   * @param storeName Preferences 实例名
   * @param key       存储键名
   * @param json      已 stringify 的 JSON string
   */
  static async putJson(context: Context, storeName: string, key: string, json: string): Promise<void> {
    const store: preferences.Preferences = await preferences.getPreferences(context, storeName);
    await store.put(key, json);
    await store.flush();
  }
}
