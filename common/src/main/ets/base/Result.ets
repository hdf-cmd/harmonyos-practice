/**
 * 统一结果封装：调用方只看 ok，不用 try/catch 满天飞
 *
 * 【分层说明】common/base/ 存放所有 ViewModel 的公共基座。
 *   约定：ViewModel 的异步操作一律返回 Result<T>——成功带 value、失败带 code 与可展示的 message，
 *   这样 View 层只判断 res.ok，不必关心底层是 Mock 还是真实网络请求。
 */
export class Result<T> {
  ok: boolean = false
  code: number = 0
  value?: T
  errorMessage?: string

  static ok<T>(value: T): Result<T> {
    const r = new Result<T>()
    r.ok = true
    r.code = 0
    r.value = value
    return r
  }

  static fail<T>(code: number, message: string): Result<T> {
    const r = new Result<T>()
    r.ok = false
    r.code = code
    r.errorMessage = message
    return r
  }
}