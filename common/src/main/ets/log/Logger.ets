/**
 * 轻量日志封装：业务代码不直接依赖 hilog 细节
 *
 * 【分层说明】common/log/ 是公共基础设施层（4-1 时预留、4-4 开始住人）：
 *   它被所有 feature 共用，所以放在 common/ 而不是某个 feature 里。
 *   包一层的好处：将来换日志方案（比如加文件落盘、上报）只改这里，业务代码零改动。
 */
import { hilog } from '@kit.PerformanceAnalysisKit'

export class Logger {
  private static readonly DOMAIN: number = 0x0000
  private tag: string

  constructor(tag: string) {
    this.tag = tag
  }

  info(msg: string): void {
    hilog.info(Logger.DOMAIN, this.tag, '%{public}s', msg)
  }

  warn(msg: string): void {
    hilog.warn(Logger.DOMAIN, this.tag, '%{public}s', msg)
  }

  error(msg: string): void {
    hilog.error(Logger.DOMAIN, this.tag, '%{public}s', msg)
  }
}