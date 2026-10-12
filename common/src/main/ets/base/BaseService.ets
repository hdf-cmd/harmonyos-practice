/**
 * BaseService：两层拆包的落地处（教材 6.2.3 约定、6.3.1 第 5 步）
 *
 * 【为什么是 abstract】它自己不直接用，等着业务 Service 来继承。
 *   unwrap 失败时抛出的是后端 message 原文——这意味着从后端一直到 UI 错误提示区，
 *   中间没有任何一层需要自己编错误文案（"账号或密码错误"从 Tomcat 一路走到 Toast）。
 */
import { httpClient } from '../network/http'
import { HttpResult } from '../network/types'

/** 后端统一响应包（smart_exam_system 契约：成功 code=200） */
export interface ApiResponse<T> {
  code: number
  message: string
  data?: T
}

export abstract class BaseService {
  protected async getJson<T>(path: string, query?: Record<string, string>): Promise<T> {
    return BaseService.unwrap<T>(await httpClient.get(path, query))
  }

  protected async postJson<T>(path: string, body?: object): Promise<T> {
    return BaseService.unwrap<T>(await httpClient.post(path, body))
  }

  protected async putJson<T>(path: string, body?: object): Promise<T> {
    return BaseService.unwrap<T>(await httpClient.put(path, body))
  }

  /** 两层拆包：HTTP 层 → 业务层；成功返回 data */
  private static unwrap<T>(result: HttpResult): T {
    let body: ApiResponse<T>
    try {
      body = JSON.parse(result.raw) as ApiResponse<T>
    } catch (e) {
      throw new Error(`HTTP ${result.code}，响应解析失败`)
    }
    if (body.code !== 200) {
      // 后端把错误原因放在 message（如"账号或密码错误""未登录或token已过期"）
      throw new Error(body.message)
    }
    return body.data as T
  }
}
