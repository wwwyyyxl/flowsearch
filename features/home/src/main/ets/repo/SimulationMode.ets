/**
 * @file SimulationMode.ets
 * @description Mock 接口的模拟模式枚举。对应 PRD §07 §3 异常场景矩阵。
 *
 * 为什么单独抽一个文件:
 *   1. simulationMode 既要被 Repository 接收(数据层),又要被 VM 暴露(UI 层),
 *      还可能被调试浮层修改。放在 commons/base 怕污染基础契约,放在 VM 里
 *      又得 Repository 反向 import VM -> 干脆放 features/home 内部独立文件,
 *      谁要用都 import 这里。
 *   2. 类型与函数严格分离,等价 Kotlin: enum class + extension function。
 */

/**
 * 数据层模拟模式。本地调试用,真实接口不存在这个概念。
 *
 *   normal  -> 200ms 延时,返回正常数据
 *   empty   -> 200ms 延时,返回空数组(演示 Empty 态)
 *   error   -> 500ms 延时,抛 500 错误(演示 Error 态)
 *   slow    -> 3000ms 延时,期间保持 Loading 态(演示弱网)
 */
export type SimulationMode = "normal" | "empty" | "error" | "slow";
