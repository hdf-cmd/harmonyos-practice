/**
 * LoginService：登录/注册的接口声明（教材 6.3.1 基础设施的第一个业务消费者）
 *
 * 【为什么一个 if 都没有】二版对接 exam-java 时，Service 里要自己检查 code、区分 200/201；
 *   V3 因为契约统一了响应包与成功码，拆包全部收进 BaseService.unwrap——Service 瘦成纯声明：
 *   接口类型 + 路径。错误处理没消失，它在 unwrap 里变成 throw new Error(message)，
 *   由 ViewModel 的 catch 统一接住。
 */
import { BaseService, SessionUserData } from '@zhititong/common'

/** 登录请求（契约 2.2） */
export interface LoginRequest {
  username: string
  password: string
}

/** 注册请求（契约 2.1：两次密码由后端再校验一次） */
export interface RegisterRequest {
  username: string
  password: string
  confirmPassword: string
}

/** 登录成功时 data 的形状（契约 2.2）：token + 用户信息 */
export interface LoginResult {
  token: string
  userInfo: SessionUserData
}

export class LoginService extends BaseService {
  login(req: LoginRequest): Promise<LoginResult> {
    return this.postJson<LoginResult>('/api/auth/login', req)
  }

  register(req: RegisterRequest): Promise<SessionUserData> {
    return this.postJson<SessionUserData>('/api/auth/register', req)
  }
}
