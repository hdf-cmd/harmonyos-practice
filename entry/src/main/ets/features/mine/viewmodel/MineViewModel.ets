/**
 * "我的"页 ViewModel：个人中心的业务与状态，零 UI
 *
 * 【分层说明】features/mine/viewmodel/ 是"我的"Tab 的"业务大脑"：
 *   用户信息取数、菜单配置、退出登录动作住在这里
 *   （Mock 三条铁律：Mock 只能被 ViewModel 消费），MineView 只渲染与转发事件——
 *   项目 6 接入真实用户接口/登录态时改这里，View 层零改动。
 *   数据流：MineView.aboutToAppear → loadUserInfo() → @Trace 字段变更 → 页面自动刷新。
 */
import { BaseViewModel, Result, SessionManager, SessionUser } from '@zhititong/common'
import { MOCK_MINE_USER, MineUserInfo } from '../model/MockMineData'

@ObservedV2
export class MineViewModel extends BaseViewModel {
  // 用户名与签名（@Trace：变更自动刷新 View；loadUserInfo 前为空串，页面不显示占位文案）
  @Trace userName: string = ''
  @Trace signature: string = ''
  // 菜单项标题：应用静态配置（不是接口数据），默认值即为最终顺序。
  // 原第三项"字体大小"已删——字号改成了可交互的档位行，由 MineView 插在同一位置顶替它
  @Trace menuItems: string[] = ['考试记录', '我的证书', '关于智题通']

  /**
   * 加载用户信息（占位数据；接入登录态后只改这里的取数来源）
   */
  async loadUserInfo(): Promise<Result<MineUserInfo>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：用户名来自登录态（SessionManager 的 AppStorageV2 运行态半身）；
      //    签名仍是 Mock——后端没有个人资料接口，按剧本留到后续章节接真数据。
      //    用户名属业务数据，住在 ViewModel 而不是 View，所以 MineView 一行不用改。
      const session: SessionUser = SessionManager.getUser()
      const user: MineUserInfo = MOCK_MINE_USER
      this.userName = session.username
      this.signature = user.signature
      if (this.userName === '') {
        this.logger.warn('登录态用户名为空：会话未建立或 token 已过期')
      }
      this.logger.info(`用户信息加载完成：${this.userName}`)
      return Result.ok<MineUserInfo>(user)
    } catch (e) {
      const errorMsg = '用户信息加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail<MineUserInfo>(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }

  /**
   * 退出登录：真登出（清 token / 调登出接口）在会话层建好后落到这个方法里；
   * 当前阶段只做状态复位与日志，导航由 View 按返回值决定（清根栈回落登录页）
   */
  async logout(): Promise<Result<void>> {
    this.clearError()
    this.setLoading(true)
    try {
      // 真登出：清内存 token + 清运行态用户 + 异步清盘，全部收口在 SessionManager。
      // 顺序敏感——先清会话，View 才按返回值清根栈，否则回落登录页时旧 token 还在。
      SessionManager.logout()
      this.userName = ''
      this.signature = ''
      this.logger.info('用户退出登录')
      return Result.ok<void>(undefined)
    } catch (e) {
      const errorMsg = '退出登录失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail<void>(-1, errorMsg)
    } finally {
      this.setLoading(false)
    }
  }
}
