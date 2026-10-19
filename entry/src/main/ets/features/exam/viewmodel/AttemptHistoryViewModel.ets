/**
 * 考试记录 ViewModel：分页列表的业务与状态，零 UI
 *
 * 【分页三件套】page（已加载到第几页）/ hasMore（还翻不翻）/ records（累计结果）。
 *   首屏 loadFirstPage 重置三件套；触底 loadMore 只追加，不重拉已加载页。
 * 【为什么按 id 去重】后端分页在数据变动时可能出现同一条跨页重复（新记录插队）。
 *   追加前按 id 过滤，保证"不重复"；hasMore 用 total 而不是"本页是否满 10 条"判断，
 *   保证"不丢页"（最后一页不足 10 条时也能正确停下）。
 */
import { BaseViewModel, Result, submitTypeLabel } from '@zhititong/common'
import { ExamService, AttemptRecord, AttemptPage } from '../service/ExamService'

const PAGE_SIZE: number = 10

@ObservedV2
export class AttemptHistoryViewModel extends BaseViewModel {
  // 已加载的记录（累计）
  @Trace records: AttemptRecord[] = []
  // 是否还有下一页
  @Trace hasMore: boolean = true
  // 后端总条数（空态与"到底了"文案用）
  @Trace total: number = 0

  private page: number = 0
  private loadingMore: boolean = false
  private examService: ExamService

  constructor(service: ExamService = new ExamService()) {
    super()
    this.examService = service
  }

  /** 首屏：重置分页状态并从第 1 页开始 */
  async loadFirstPage(): Promise<Result<AttemptRecord[]>> {
    this.clearError()
    this.setLoading(true)
    this.page = 0
    this.records = []
    this.hasMore = true
    try {
      const p: AttemptPage = await this.examService.getAttempts(1, PAGE_SIZE)
      this.page = 1
      this.records = p.records
      this.total = p.total
      this.hasMore = this.records.length < p.total
      this.logger.info(`考试记录首屏：${this.records.length}/${p.total}`)
      return Result.ok<AttemptRecord[]>(this.records)
    } catch (e) {
      const errorMsg = (e as Error).message || '考试记录加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`考试记录加载失败：${errorMsg}`)
      return Result.fail<AttemptRecord[]>(-1, errorMsg)
    } finally {
      this.setLoading(false)
    }
  }

  /** 触底：追加下一页（到底或正在加载时直接返回） */
  async loadMore(): Promise<void> {
    if (!this.hasMore || this.loading || this.loadingMore) {
      return
    }
    this.loadingMore = true
    try {
      const next: number = this.page + 1
      const p: AttemptPage = await this.examService.getAttempts(next, PAGE_SIZE)
      this.page = next
      const seen: Set<string> = new Set<string>(this.records.map((r: AttemptRecord): string => r.id))
      const fresh: AttemptRecord[] = p.records.filter((r: AttemptRecord): boolean => !seen.has(r.id))
      this.records = this.records.concat(fresh)
      this.total = p.total
      // 以 total 为准判到底；顺带挡住"后端返回空页但 total 没变"的僵局
      this.hasMore = this.records.length < p.total && p.records.length > 0
      this.logger.info(`考试记录加载第 ${next} 页：新增 ${fresh.length} 条，累计 ${this.records.length}/${p.total}`)
    } catch (e) {
      this.logger.warn(`考试记录翻页失败：${(e as Error).message}`)
    } finally {
      this.loadingMore = false
    }
  }

  /** 交卷方式中文：与结果页同一份翻译口径 */
  getSubmitTypeLabel(submitType: string): string {
    return submitTypeLabel(submitType)
  }
}
