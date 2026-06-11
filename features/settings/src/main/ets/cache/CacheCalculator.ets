/**
 * @file CacheCalculator.ets
 * @description 缓存大小计算与清理工具。用 @ohos.file.fs 递归遍历 cacheDir。
 *
 * 设计要点:
 *
 * 1. 零装饰器(plain class + static 方法),与 PreferencesHelper 同级。
 *
 * 2. context.cacheDir 是 HarmonyOS 应用的缓存目录,系统可在磁盘不足时自动清理。
 *    我们手动清理时只删文件不删目录本身。
 *
 * 3. formatSize() 把字节数格式化为 "12.4 MB" / "356 KB" 等可读文本。
 */

import fs from "@ohos.file.fs";

export class CacheCalculator {
  /** 递归计算目录内所有文件的总大小(字节)。 */
  static async getCacheSize(dirPath: string): Promise<number> {
    let totalSize: number = 0;
    try {
      const entries: string[] = await fs.listFile(dirPath);
      for (let i = 0; i < entries.length; i++) {
        const fullPath: string = dirPath + "/" + entries[i];
        try {
          const statInfo: fs.Stat = fs.statSync(fullPath);
          if (statInfo.isDirectory()) {
            const subSize: number = await CacheCalculator.getCacheSize(fullPath);
            totalSize += subSize;
          } else {
            totalSize += statInfo.size;
          }
        } catch (_e) {
          // 单文件 stat 失败跳过(可能已删除)
        }
      }
    } catch (_e) {
      // 目录不存在或无权限,返回 0
    }
    return totalSize;
  }

  /** 字节数 → 可读文本。 */
  static formatSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + " B";
    }
    if (bytes < 1024 * 1024) {
      const kb: number = Math.round(bytes / 102.4) / 10;
      return kb + " KB";
    }
    const mb: number = Math.round(bytes / (1024 * 102.4)) / 10;
    return mb + " MB";
  }

  /** 清空缓存目录内所有文件(保留目录本身)。 */
  static async clearCacheDir(dirPath: string): Promise<void> {
    try {
      const entries: string[] = await fs.listFile(dirPath);
      for (let i = 0; i < entries.length; i++) {
        const fullPath: string = dirPath + "/" + entries[i];
        try {
          const statInfo: fs.Stat = fs.statSync(fullPath);
          if (statInfo.isDirectory()) {
            await CacheCalculator.clearCacheDir(fullPath);
            fs.rmdirSync(fullPath);
          } else {
            fs.unlinkSync(fullPath);
          }
        } catch (_e) {
          // 单文件删除失败跳过
        }
      }
    } catch (_e) {
      // 目录不存在或无权限
    }
  }
}
