/**
 * 逐题回顾 ViewModel：回顾页精讲的业务与状态，零 UI
 *
 * 【数据源】ExamService.getFullReview(attemptId)（契约 3.8，wrongOnly=false 全量）。
 *   与结果页的 getReview 同一个后端接口，区别只在查询参数：结果页只要对错着色，
 *   回顾页要 correctAnswer / analysis / 每题得分。
 * 【派生而不复制】showWrongOnly 是过滤开关，visibleQuestions 按需过滤，
 *   原始 review.questions 一份不动——关掉开关立刻回到全量，不需要重新请求。
 * 【契约坑】isPassed 是数字 1/0；userAnswer 未作答时为 null；analysis 可能是空串。
 */
import { BaseViewModel, Result } from '@zhititong/common'
import { ExamService, ReviewDetail, ReviewQuestionDetail } from '../service/ExamService'

@ObservedV2
export class ReviewViewModel extends BaseViewModel {
  // 回顾数据（@Trace：loadReview 整体赋值后页面自动刷新）
  @Trace review: ReviewDetail = {
    attemptId: '',
    paperName: '',
    score: 0,
    totalScore: 0,
    isPassed: 0,
    questions: []
  }
  // 只看错题开关（@Trace：Toggle 绑它，变更即重算 visibleQuestions）
  @Trace showWrongOnly: boolean = false

  private examService: ExamService

  // 构造器注入：默认用真 Service，测试塞 mock 过的实例
  constructor(service: ExamService = new ExamService()) {
    super()
    this.examService = service
  }

  /** 拉取全量逐题回顾 */
  async loadReview(attemptId: string): Promise<Result<ReviewDetail>> {
    this.clearError()
    this.setLoading(true)
    try {
      const detail: ReviewDetail = await this.examService.getFullReview(attemptId)
      this.review = detail
      this.logger.info(`回顾加载完成：${detail.paperName}，${detail.questions.length} 题`)
      return Result.ok<ReviewDetail>(detail)
    } catch (e) {
      const errorMsg = (e as Error).message || '回顾加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`回顾加载失败：${errorMsg}`)
      return Result.fail<ReviewDetail>(-1, errorMsg)
    } finally {
      this.setLoading(false)
    }
  }

  /** 答对题数（成绩摘要与"只看错题"的数量互为印证） */
  get correctCount(): number {
    let n: number = 0
    for (const q of this.review.questions) {
      if (q.isCorrect) {
        n++
      }
    }
    return n
  }

  /** 当前可见题目：开关开时只留错题，关时是全量 */
  get visibleQuestions(): ReviewQuestionDetail[] {
    if (!this.showWrongOnly) {
      return this.review.questions
    }
    return this.review.questions.filter((q: ReviewQuestionDetail): boolean => !q.isCorrect)
  }

  /** 是否通过（isPassed 是数字 1/0，翻译成布尔给 View 用） */
  get passed(): boolean {
    return this.review.isPassed === 1
  }
}
