/**
 * 登录请求参数模型（纯数据类：零逻辑）
 *
 * 【分层说明】features/login/model/ 是登录 feature 的数据层：
 *   只放"数据长什么样"，不放任何行为与判断。字段名与后端契约对齐，
 *   项目 6 换真实接口时这里不用返工。
 */
export class LoginModel {
  username: string = ''
  password: string = ''
}