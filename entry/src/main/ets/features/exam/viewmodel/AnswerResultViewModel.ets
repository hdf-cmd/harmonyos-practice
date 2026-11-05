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
  BaseViewModel, Result, ExamResult, AnswerItem, BackgroundMonitor, StateKeys, submitTypeLabel
} from '@zhititong/common'
import { ExamService, SubmitResult, ReviewInfo, ReviewQuestion } from '../service/ExamService'
import { ASSISTANT_WRONG_TITLE_LIMIT } from '../../assistant/AssistantConstants'

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

  // 试卷名（review 下发，判分卡不需要它，但助教上下文要用）：空串即"还没加载完"
  @Trace paperName: string = ''

  // 前 N 道错题题干：从答题卡那一趟请求里顺带提取，不额外发请求。
  //   带上它，助教给的复习建议才针对本场考试，而不是千篇一律的通用建议。
  @Trace wrongTitles: string[] = []

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
      // 同一次 review 响应里顺手取走试卷名与前 N 道错题题干：判分卡用不到它们，
      //   但助教上下文用得到，为这两项再发一趟请求纯属浪费
      this.paperName = review.paperName
      this.wrongTitles = review.questions
        .filter((q: ReviewQuestion): boolean => !q.isCorrect)
        .slice(0, ASSISTANT_WRONG_TITLE_LIMIT)
        .map((q: ReviewQuestion): string => q.content)
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

  // 交卷方式文案三态：翻译口径收在 common 的 submitTypeLabel，记录页共用同一份
  getSubmitTypeLabel(): string {
    return submitTypeLabel(this.result.submitType)
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

  /**
   * 助教入口能否创建：成绩数据就绪才创建。
   *
   * 【为什么要这个开关】FunctionComponent 的 options/queryText 只在组件创建时读一次，
   *   在数据到位前创建，入口就会永远带着"0 分、空卷面"的初始值。
   */
  get assistantReady(): boolean {
    return !this.loading && this.errorMessage === '' && this.paperName !== ''
  }

  /**
   * 成绩页带给助教的上下文：成绩摘要 + 前若干道错题题干，请求按优先级排序的复习建议。
   *
   * 【为什么用 \n 分行】对话里逐行显示更易读，大模型也更容易把题干、得分、请求区分开。
   * 【措辞刻意保守】"本卷全部答对"与"部分错题"分开说，避免它把答对的题也当成薄弱点。
   */
  get assistantQuery(): string {
    const correct: number = this.result.answers.filter((item: AnswerItem): boolean => item.correct).length
    const header: string = `试卷：${this.paperName}\n` +
      `得分：${this.result.score}/${this.result.totalScore}（及格线 ${this.result.passScore}）\n` +
      `结果：${this.result.passed ? '通过' : '未通过'} · 答对 ${correct}/${this.result.answers.length} 题`
    if (this.wrongTitles.length === 0) {
      return `${header}\n本卷全部答对，请基于知识库给出巩固与进阶建议。`
    }
    const wrongLines: string = this.wrongTitles
      .map((title: string, index: number): string => `${index + 1}. ${title}`)
      .join('\n')
    return `${header}\n部分错题题干：\n${wrongLines}\n` +
      '请结合这些错题对应的考点，基于知识库给出按优先级排序的复习建议（不超过3条）。'
  }
}
