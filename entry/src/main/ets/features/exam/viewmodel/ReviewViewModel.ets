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
import { BaseViewModel, Result, OptionItem, questionTypeLabel } from '@zhititong/common'
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
  // 当前浏览题在"可见列表"里的下标（-1 表示还没滚动过，按第一题算）
  @Trace visibleIndex: number = -1

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

  /**
   * 记住"此刻屏幕中央在看哪道题"。
   *
   * 【为什么取 onScrollIndex 的中心项】回调给的是可视区首项、末项和中心项下标；
   *   中心线落在哪道题上，那道题在屏上的可视面积必然过半——比"第一道可见题"更符合
   *   "我正在看这题"的直觉（首项常常只露出半截）。
   * 【为什么相同就不写】写同一个值也会触发 @Trace 变更通知，白白让入口重建一次。
   */
  updateCurrentVisibleIndex(center: number): void {
    const list: ReviewQuestionDetail[] = this.visibleQuestions
    // 负数与越界一律不动状态：入口绝不能因为一个怪下标就跳回第一题（用户看到的题没变）
    if (center < 0 || center >= list.length) {
      return
    }
    if (center !== this.visibleIndex) {
      this.visibleIndex = center
    }
  }

  /** 当前题：越界与"还没滚过"都回落到列表第一题 */
  get currentQuestion(): ReviewQuestionDetail | undefined {
    const list: ReviewQuestionDetail[] = this.visibleQuestions
    if (list.length === 0) {
      return undefined
    }
    const index: number = this.visibleIndex >= 0 && this.visibleIndex < list.length ? this.visibleIndex : 0
    return list[index]
  }

  /** 原卷题号（从 0 起）：开了"只看错题"后仍按原顺序编号，过滤不改编号 */
  questionNoById(questionId: string): number {
    return this.review.questions.findIndex((it: ReviewQuestionDetail): boolean => it.questionId === questionId)
  }

  /** 助教入口能否创建：回顾数据就绪才创建（入口参数只在创建时生效） */
  get assistantReady(): boolean {
    return !this.loading && this.errorMessage === '' && this.review.questions.length > 0
  }

  /**
   * 入口重建的键值：只跟"当前题是哪道"绑定。
   *
   * 【为什么要它】queryText 是 @Param @Once，创建后不再读取新值。让 View 用只含一个元素的
   *   ForEach 包住入口并以此值当 key——key 一变，旧入口销毁、新入口带着新题的上下文重建。
   */
  get assistantQueryKey(): string {
    const current: ReviewQuestionDetail | undefined = this.currentQuestion
    return current === undefined ? 'none' : current.questionId
  }

  /**
   * 回顾页带给助教的上下文：当前题的题型、题干、选项、我的答案与正确答案。
   *
   * 【答错/答对走两种请求】答错请它"先给正确结论，再解释我错在哪与相关考点"（与助教
   *   角色指令里的错题解析三段式呼应）；答对请它"讲考点，再出一道同考点变式题"。
   * 【未作答要说"未作答"】userAnswer 为 null 时留空会被大模型当成"没给答案"去猜。
   */
  get assistantQuery(): string {
    const header: string = `试卷：${this.review.paperName}\n得分：${this.review.score}/${this.review.totalScore}`
    const current: ReviewQuestionDetail | undefined = this.currentQuestion
    if (current === undefined) {
      return `${header}\n本次没有错题，请基于知识库给出巩固建议。`
    }
    const no: number = this.questionNoById(current.questionId) + 1
    const optionLines: string = current.options
      .map((option: OptionItem): string => `${option.label}：${option.content}`).join('\n')
    if (current.isCorrect) {
      return `${header}\n第${no}题（${questionTypeLabel(current.type)}·我答对了）\n题干：${current.content}\n` +
        `选项：\n${optionLines}\n正确答案：${current.correctAnswer}\n` +
        '请讲解本题考点，再出一道同考点的变式题让我练习；知识库没有的内容请明确说明。'
    }
    const answer: string = current.userAnswer === null || current.userAnswer === '' ? '未作答' : current.userAnswer
    return `${header}\n第${no}题（${questionTypeLabel(current.type)}·我答错了）\n题干：${current.content}\n` +
      `选项：\n${optionLines}\n我的答案：${answer} / 正确答案：${current.correctAnswer}\n` +
      '请先给出正确结论，再解释我的答案错在哪与相关考点；知识库没有的内容请明确说明。'
  }
}
