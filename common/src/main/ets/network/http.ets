/**
 * 全局唯一的 HttpClient 实例，拦截器链在此组装（教材 6.3.1 第 4 步）
 *
 * 【本任务最有嚼头的一笔】登录要到 6-2 才接，Token 现在从哪来？答案是先把插座装好、
 *   灯泡以后再拧：currentTokenProvider 占位返回空串，拦截器照常注册但注入不生效；
 *   6-2 只需调用一次 setTokenProvider，整条鉴权链路就通电。
 *   注册时传的是 () => currentTokenProvider() 这个箭头函数而不是变量本身——
 *   传变量传走的是"此刻的值"，传函数传走的才是"每次现取"的活水。
 */
import { HttpClient } from './HttpClient'
import { TokenInterceptor, LoggingInterceptor, TokenProvider } from './interceptors'
import { AppConfig } from '../config/AppConfig'

/**
 * Token 提供者占位：
 *   本实训阶段返回空字符串（不注入）；
 *   6-2 登录打通后一行 setTokenProvider(() => SessionManager.getToken()) 即激活。
 */
let currentTokenProvider: TokenProvider = () => ''

export function setTokenProvider(provider: TokenProvider): void {
  currentTokenProvider = provider
}

/** 全局唯一的 HttpClient 实例 */
export const httpClient: HttpClient = new HttpClient()

// 拦截器①：Token 注入——注意传入的是箭头函数而非变量本身
httpClient.use(new TokenInterceptor(() => currentTokenProvider()))

// 拦截器②：日志，受 AppConfig 开关控制
if (AppConfig.ENABLE_HTTP_LOG) {
  httpClient.use(new LoggingInterceptor())
}
