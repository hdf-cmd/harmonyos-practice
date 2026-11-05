/**
 * AuthExpiredError：会话失效专用错误（401）
 *
 * 【为什么要单独一个类型】BaseService.unwrap 失败时抛的是后端 message 原文，
 *   到 ViewModel 手里只剩一段字符串——"未登录"和"服务器 500"在 UI 上就成了同一个东西。
 *   但这两件事用户的下一步动作完全不同：后者重试即可，前者重试一万次也还是 401，
 *   必须重新登录。用类型把这一类错误标出来，View 才能决定给不给"重新登录"入口。
 */
export class AuthExpiredError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'AuthExpiredError'
  }
}
