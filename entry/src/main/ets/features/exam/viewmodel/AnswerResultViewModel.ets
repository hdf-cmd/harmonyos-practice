/**
 * 答题结果 ViewModel：交卷结果展示的业务与状态，零 UI
 *
 * 【6-4 真实化】loadResult(attemptId) 从后端拉两份数据拼出结果页：
 *   - result(3.7)：总分/及格线/是否通过/用时/交卷方式（判分卡）；
 *   - review(3.8)：逐题 isCorrect/userAnswer（答题卡着色）。
 *   交卷响应本身不含逐题对错，所以答题卡必须另调 review——这是契约拆出来的两趟。
 *   ExamService 构造器注入，单测塞假门不打网络。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import {
  BaseViewModel, Result, ExamResult, AnswerItem, BackgroundMonitor, StateKeys
} from '@zhititong/common'
import { ExamService, SubmitResult, ReviewInfo, ReviewQuestion } from '../service/ExamService'

// 答题卡布局参数：列数 / 格子高度 / 格子间距（vp）
// 抽成导出常量：高度公式与 View 的格子渲染共用同一份，改任何一个都不会失联
export const ANSWER_CARD_COLUMNS: number = 6
export const ANSWER_CARD_CELL_HEIGHT: number = 40
export const ANSWER_CARD_GAP: number = 8

@ObservedV2
export class AnswerResultViewModel extends BaseViewModel {
  // 交卷结果（@Trace：整体赋值变更自动刷新 View；loadResult 后才有真实数据）
  @Trace result: ExamResult = {
    score: 0,
    totalScore: 0,
    passScore: 0,
    passed: false,
    usedTime: 0,
    submitType: 'MANUAL',
    answers: []
  }

  private examService: ExamService

  // 切后台监视器：与答题页/Ability 同一 key，读到的就是本场定格的次数（懒连接）
  private monitorInstance: BackgroundMonitor | undefined = undefined

  // 构造器注入：默认用真 Service，测试可塞 mock 过的实例
  constructor(service: ExamService = new ExamService()) {
    super()
    this.examService = service
  }

  private get monitor(): BackgroundMonitor {
    if (this.monitorInstance === undefined) {
      this.monitorInstance = AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
        () => new BackgroundMonitor())!
    }
    return this.monitorInstance
  }

  /**
   * 加载交卷结果：判分卡取 result、答题卡取 review，两趟拼成 ExamResult
   */
  async loadResult(attemptId: string): Promise<Result<ExamResult>> {
    this.clearError()
    this.setLoading(true)
    try {
      const score: SubmitResult = await this.examService.getResult(attemptId)
      const review: ReviewInfo = await this.examService.getReview(attemptId)
      const answers: AnswerItem[] = review.questions.map((q: ReviewQuestion): AnswerItem => {
        const item: AnswerItem = {
          questionId: q.questionId,
          correct: q.isCorrect,
          answered: q.userAnswer !== undefined && q.userAnswer !== null && q.userAnswer !== ''
        }
        return item
      })
      this.result = {
        score: score.score,
        totalScore: score.totalScore,
        passScore: score.passScore,
        passed: score.passed,
        usedTime: score.usedTime,
        submitType: score.submitType,
        answers: answers
      }
      this.logger.info(`交卷结果加载完成：${this.result.score} 分，共 ${answers.length} 题`)
      return Result.ok<ExamResult>(this.result)
    } catch (e) {
      const errorMsg = (e as Error).message || '结果加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`结果加载失败：${errorMsg}`)
      return Result.fail<ExamResult>(-1, errorMsg)
    } finally {
      this.setLoading(false)
    }
  }

  // 交卷方式文案：MANUAL → 手动交卷，TIMEOUT → 超时自动交卷，TAB_SWITCH → 切屏强制交卷
  getSubmitTypeLabel(): string {
    if (this.result.submitType === 'TIMEOUT') {
      return '超时自动交卷'
    }
    if (this.result.submitType === 'TAB_SWITCH') {
      return '切屏超限强制交卷'
    }
    return '手动交卷'
  }

  // 本场切后台提示文案：一次没切也要明说，别让访客以为功能没做
  getBackgroundHint(): string {
    const count: number = this.monitor.count
    return count > 0 ? `本场切出应用 ${count} 次` : '本场未切出应用'
  }

  // 答题卡行数：题目数按列数向上取整
  getAnswerCardRowCount(): number {
    return Math.ceil(this.result.answers.length / ANSWER_CARD_COLUMNS)
  }

  // 【Grid 重点】Grid 不自适应子节点高度，必须显式算：行数 × 格子高 + (行数 − 1) × 行间距
  getAnswerCardHeight(): number {
    return this.getAnswerCardRowCount() * ANSWER_CARD_CELL_HEIGHT
      + (this.getAnswerCardRowCount() - 1) * ANSWER_CARD_GAP
  }
}
