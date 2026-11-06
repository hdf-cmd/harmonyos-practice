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
   *
   * 【2026-11-06 更正这句旧注释】原先写的是"只清凭证不导航——跳不跳登录页由 View 决定"。
   *   前半句仍然对，后半句已经作废：登录页不再是 View 跳过去的栈项，而是 AppNavigation
   *   按 loggedIn 选出来的内容区。所以"导航"这件事既不在 VM 也不在 View，
   *   它是会话状态的自然结果。VM 零 UI 这条铁律不变，而且比原来更干净——
   *   View 连"要不要跳"都不用判断了。
   */
  clearExpiredSession(): void {
    if (this.authExpired) {
      SessionManager.logout()
    }
  }

  /**
   * 错误区那颗按钮的统一入口——**决策在这里，不在 View**。
   *
   * 为什么要有这个方法：View 原先写的是
   *   `if (this.vm.authExpired) { this.vm.clearExpiredSession() } else { this.vm.loadXxx() }`
   * 那个 if 是把 VM 内部已有的判断（clearExpiredSession 自己就守着 authExpired）
   * 在 View 里又抄了一遍——违反"View 零业务判断"，而且两处一旦改一处就会分叉。
   * 现在 View 只转发点击事件，分支收在这一处。
   *
   * 子类要参与的部分只有"重试加载做什么"，覆盖 retryLoad 即可；
   * 基类给空实现，所以现有 10 个子类不覆盖也照常编译、行为不变。
   */
  handleErrorAction(): void {
    if (this.authExpired) {
      this.clearExpiredSession()
      return
    }
    this.retryLoad()
  }

  /** 非 401 的失败点"重试"时要做的加载——子类覆盖成自己那一条加载。 */
  protected retryLoad(): void {
  }
}