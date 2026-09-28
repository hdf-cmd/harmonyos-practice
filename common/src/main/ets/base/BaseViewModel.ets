/**
 * ViewModel 基类：统一的 loading / error 状态管理
 *
 * 【为什么用 @ObservedV2 + @Trace】普通的 class 属性变化 View 是感知不到的——
 *   加了 @ObservedV2 类装饰器后，类里标了 @Trace 的字段一旦变更，就会通知引用了它的 View 重绘。
 *   这就是"ViewModel 改状态 → 界面自动刷新"这条数据流的实现基础。
 */
import { Logger } from '../log/Logger'

@ObservedV2
export abstract class BaseViewModel {
  // 页面加载态
  @Trace loading: boolean = false

  // 页面可展示的错误信息（怎么渲染由 View 决定，ViewModel 不关心）
  @Trace errorMessage: string = ''

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
  }
}