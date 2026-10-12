/**
 * 当前登录用户：登录态的"运行态半身"（教材 5.2.5 示例5-8 的实战落地）
 *
 * 【为什么不持久化】这个类只服务 UI 的响应式消费——字段一变，connect 到它的页面自动刷新。
 *   要跨进程生死的是 token 与用户信息本体，那份落盘归 SessionManager 用 Preferences 管，
 *   冷启动时由它回填这里。运行态与持久化各管一段，不互相顶替。
 */

/**
 * 当前登录用户（运行态）：AppStorageV2 全局单例
 *   - UI 侧 connect 后，字段变化（登录/登出）自动刷新
 *   - 不持久化：冷启动时由 SessionManager.loadFromDisk 从 Preferences 回填
 */
@ObservedV2
export class SessionUser {
  @Trace id: string = ''
  @Trace username: string = ''
  @Trace role: string = ''
  @Trace loggedIn: boolean = false
}

/** 会话数据的持久化形状（写进 Preferences 的 JSON） */
export interface SessionUserData {
  id: string
  username: string
  role: string
}
