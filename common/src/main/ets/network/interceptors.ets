/**
 * Token 注入与请求日志两个拦截器（教材 6.2.4 示例6-6）
 *
 * 【为什么 Token 要绕一道函数注入】"Token 从哪来"会变：6-1 搭基础设施时登录还没接网，
 *   Token 只能是空串；6-2 登录后由 SessionManager 提供。把"取 Token 的方式"做成可注入的
 *   函数，拦截器本身一行不用改，只换一个 provider——这就是先装插座、后拧灯泡。
 */
import { Interceptor, RequestConfig, HttpResult } from './types'
import { Logger } from '../log/Logger'

const logger: Logger = new Logger('HTTP')

/** Token 提供者：返回当前要使用的 Token；空字符串表示"未登录/不注入" */
export type TokenProvider = () => string

/** 拦截器①：自动注入 Authorization: Bearer <token> */
export class TokenInterceptor implements Interceptor {
  private tokenProvider: TokenProvider

  constructor(tokenProvider: TokenProvider) {
    this.tokenProvider = tokenProvider
  }

  onRequest(config: RequestConfig): RequestConfig {
    const token: string = this.tokenProvider()
    if (token !== '') {
      config.headers = config.headers ?? {}
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  }
}

/** 拦截器②：请求/响应日志。上线前由 AppConfig.ENABLE_HTTP_LOG 关掉，不注册即无日志 */
export class LoggingInterceptor implements Interceptor {
  onRequest(config: RequestConfig): RequestConfig {
    logger.info(`→ ${config.method} ${config.url}`)
    return config
  }

  onResponse(result: HttpResult): HttpResult {
    logger.info(`← HTTP ${result.code} (body ${result.raw.length} bytes)`)
    return result
  }
}
