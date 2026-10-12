/**
 * SessionManager：登录态生命周期的唯一管理者（教材 6.2.1 选型表的"活页"）
 *
 * 【一个类同时驾驭两种状态工具，三层各司其职】
 *   token 走 Preferences——它是凭证，不是 UI 数据，要求重启还在；
 *   "当前用户是谁"走 AppStorageV2——它是运行态 UI 状态，MinePage 等页面要响应式消费；
 *   token 另备一份内存缓存 cachedToken——TokenInterceptor 每次请求都要读，不能走磁盘 IO。
 *   没有一层是多余的：去掉任一层，分别会在"重启后掉登录""页面不刷新""每次请求打磁盘"上现形。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import { PreferencesUtil } from '../utils/PreferencesUtil'
import { StateKeys } from '../constants/StateKeys'
import { SessionUser, SessionUserData } from './SessionUser'
import { Logger } from '../log/Logger'

const logger: Logger = new Logger('SessionManager')

export class SessionManager {
  private static readonly PREF_NAME: string = 'user_session'
  private static readonly KEY_TOKEN: string = 'token'
  private static readonly KEY_USER: string = 'user_info'

  /** token 内存缓存：TokenInterceptor 每次请求都读，必须零 IO */
  private static cachedToken: string = ''

  /** 运行态用户（AppStorageV2 全局单例；UI 侧也用同一行 connect 消费） */
  static getUser(): SessionUser {
    return AppStorageV2.connect(SessionUser, StateKeys.SESSION_USER, () => new SessionUser())!
  }

  /** 同步取 token（供 TokenInterceptor 高频调用） */
  static getToken(): string {
    return SessionManager.cachedToken
  }

  static isLoggedIn(): boolean {
    return SessionManager.cachedToken !== ''
  }

  /** 应用启动时调用一次：把上次会话从磁盘恢复到内存与运行态 */
  static loadFromDisk(): void {
    SessionManager.cachedToken = PreferencesUtil.getString(
      SessionManager.PREF_NAME, SessionManager.KEY_TOKEN, '')
    const userJson: string = PreferencesUtil.getString(
      SessionManager.PREF_NAME, SessionManager.KEY_USER, '')
    if (SessionManager.cachedToken === '' || userJson === '') {
      return
    }
    try {
      const saved = JSON.parse(userJson) as SessionUserData
      const user = SessionManager.getUser()
      user.id = saved.id
      user.username = saved.username
      user.role = saved.role
      user.loggedIn = true
      logger.info(`已恢复上次会话：${saved.username}`)
    } catch (e) {
      logger.warn('本地会话数据解析失败，按未登录处理')
    }
  }

  /** 登录成功时调用：token 入 Preferences（凭证），用户信息进运行态并落盘 */
  static async save(token: string, data: SessionUserData): Promise<void> {
    SessionManager.cachedToken = token
    const user = SessionManager.getUser()
    user.id = data.id
    user.username = data.username
    user.role = data.role
    user.loggedIn = true
    await PreferencesUtil.putString(
      SessionManager.PREF_NAME, SessionManager.KEY_TOKEN, token)
    await PreferencesUtil.putString(
      SessionManager.PREF_NAME, SessionManager.KEY_USER, JSON.stringify(data))
  }

  /** 登出：内存与运行态立即清空，磁盘异步清理（失败仅记日志，不阻塞 UI） */
  static logout(): void {
    SessionManager.cachedToken = ''
    const user = SessionManager.getUser()
    user.id = ''
    user.username = ''
    user.role = ''
    user.loggedIn = false
    PreferencesUtil.clear(SessionManager.PREF_NAME)
      .catch((e: Error) => logger.warn(`登出清盘失败：${e.message}`))
  }
}
