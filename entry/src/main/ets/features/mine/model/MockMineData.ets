/**
 * "我的"页种子数据与数据契约（单 feature 专属，零逻辑）
 *
 * 【分层说明】按技能规则「单 feature 专属的种子数据放该 feature 的 model/」：
 *   用户信息与菜单在接入真实接口/登录态前先用这里的占位数据，
 *   Mock 只能被 ViewModel 消费（MineView 不 import 本文件）。
 *   项目 6 接入登录态后：MineUserInfo 可替换为登录侧的用户契约，只改 ViewModel 取数。
 */

// "我的"页展示的用户信息（占位契约：接登录态前的临时形状）
export interface MineUserInfo {
  userName: string     // 用户名
  signature: string    // 个性签名
}

// 占位用户信息：文字与改造前页面上的静态展示逐字一致，保证视觉零变化
export const MOCK_MINE_USER: MineUserInfo = {
  userName: '用户名',
  signature: '这个人很懒，什么都没写'
}
