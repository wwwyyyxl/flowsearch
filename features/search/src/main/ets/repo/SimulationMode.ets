/**
 * @file SimulationMode.ets
 * @description Mock 模拟模式枚举。与 features/home 的 SimulationMode 同义,本期独立声明,
 *              避免 search 反向依赖 features/home(commons 才是真正的横向共享层)。
 *
 * S6 优化阶段可以把这个 type 提到 commons/base,但本期保持两份冗余比反向依赖干净。
 *
 *   normal  -> 200ms 延时,返回正常数据
 *   empty   -> 200ms 延时,返回空结果(演示 Empty 态)
 *   error   -> 500ms 延时,抛 500 错误(演示 Error 态)
 *   slow    -> 3000ms 延时,期间保持 Loading 态(演示弱网)
 */
export type SimulationMode = "normal" | "empty" | "error" | "slow";
