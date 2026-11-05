/**
 * ViewModel 基类：统一的 loading / error 状态管理
 *
 * 【为什么用 @ObservedV2 + @Trace】普通的 class 属性变化 View 是感知不到的——
 *   加了 @ObservedV2 类装饰器后，类里标了 @Trace 的字段一旦变更，就会通知引用了它的 View 重绘。
 *   这就是"ViewModel 改状态 → 界面自动刷新"这条数据流的实现基础。
 */
import { Logger } from '../log/Logger'
import { AuthExpiredError } from './AuthExpiredError'
import { SessionManager } from '../session/SessionManager'

@ObservedV2
export abstract class BaseViewModel {
  // 页面加载态
  @Trace loading: boolean = false

  // 页面可展示的错误信息（怎么渲染由 View 决定，ViewModel 不关心）
  @Trace errorMessage: string = ''

  // 错误是不是"会话失效"：View 据此决定按钮给"重新登录"还是"重试"
  // （不合并进 errorMessage 去匹配文案——后端文案会改，类型判断才是稳的）
  @Trace authExpired: boolean = false

  // 子类可覆盖 tag
  protected logger: Logger = new Logger('[ViewModel]')

  protected setLoading(v: boolean): void {
    this.loading = v
  }

  protected setError(msg: string): void {
    this.errorMessage = msg
  }

  protected clearError(): void {
    this.errorMessage = ''
    this.authExpired = false
  }

  /**
   * 加载类失败的统一落点：记下错误类型、给出可展示文案。
   * 返回最终文案，方便调用方接着塞进 Result.fail 与日志。
   */
  protected handleFailure(e: Object, fallback: string): string {
    this.authExpired = e instanceof AuthExpiredError
    const msg: string = (e as Error).message || fallback
    this.setError(msg)
    return msg
  }

  /**
   * 清掉已失效的本地会话（仅当确实是 401）。
   * 只清凭证不导航——跳不跳登录页由 View 决定，ViewModel 零 UI。
   */
  clearExpiredSession(): void {
    if (this.authExpired) {
      SessionManager.logout()
    }
  }
}