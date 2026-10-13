/**
 * PaperService：考卷相关接口声明
 *
 * 【为什么一个 if 都没有】列表接口契约已长成 App 模型的形状：
 *   字段名与类型与 PaperInfo 逐项对齐，BaseService.unwrap 统一拆包抛错，
 *   Service 瘦成纯声明——接口类型 + 路径。需要 DTO/映射那是契约对不上的后手。
 */
import { BaseService, PaperInfo } from '@zhititong/common'

export class PaperService extends BaseService {
  /** 可考试卷列表：契约命名以 App 模型为基准，直取直用 */
  getPapers(): Promise<PaperInfo[]> {
    return this.getJson<PaperInfo[]>('/api/exam/papers')
  }
}
