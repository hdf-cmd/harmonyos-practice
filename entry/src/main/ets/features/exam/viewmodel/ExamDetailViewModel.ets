/**
 * 答题页 ViewModel：考试链路的业务与状态机，零 UI
 *
 * 【6-4 真实化】从"读 Mock 题目"升级为"开考建场→逐题实时保存→服务端权威倒计时→
 *   交卷点灯"。ExamService 构造器注入，单测里塞假门即可跑，不打真网络。
 *
 * 【四个设计决策】
 *   1. 时间权威在服务端：倒计时以开考响应的 remainingSeconds 起跳，前端 setInterval 只做视觉递减；
 *      续考时后端把进行中场次的剩余时间原样还回来，前端不自己换算。
 *   2. tick() 公开化：把"跳一秒"做成公开方法，单测连调几次就模拟几秒，不必等真实时钟。
 *   3. submitting 闸门：超时与手动同时到达也只交一次；失败分支放开闸门允许重试。
 *   4. finishedAttemptId 信号灯：交卷成功后 VM 不碰导航栈，只把这个 @Trace 从空串点亮为场次号；
 *      View 用 @Monitor 看灯跳转。"状态点灯、View 看灯、导航单一出口"。
 *
 * 【切后台计数分工】计数发生在 EntryAbility.onBackground；本类只在开考 start() 让监视生效并清零、
 *   交卷时 stop() 定格。两边靠 StateKeys.BACKGROUND_MONITOR 同一 key 拿同一实例。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import {
  BaseViewModel, Result, QuestionItem, OptionItem, BackgroundMonitor, StateKeys
} from '@zhititong/common'
import { ExamService } from '../service/ExamService'

// 题型标签映射：后端存枚举码（JUDGE/SINGLE/MULTI），展示翻成中文；新增题型只改这一处
const TYPE_LABEL: Record<string, string> = {
  'JUDGE': '判断题',
  'SINGLE': '单选题',
  'MULTI': '多选题'
}

@ObservedV2
export class ExamDetailViewModel extends BaseViewModel {
  // 场次号（开考后由后端下发；@Trace 供 View 与结果页读取）
  @Trace attemptId: string = ''
  @Trace paperName: string = ''
  // 当前试卷的题目列表（开考响应带回）
  @Trace questions: QuestionItem[] = []
  // 当前题目索引：它一变，题目区整体刷新
  @Trace currentIndex: number = 0
  // 服务端权威剩余秒数，tick 每秒减一
  @Trace remainingSeconds: number = 0
  // 交卷完成信号灯：结果页导航的唯一出口（空串=未交卷）
  @Trace finishedAttemptId: string = ''
  // 单选/判断当前选中项（Radio 靠值相等判选中）
  @Trace radioSelected: string = ''
  // 多选当前选中集合（整体替换才触发 V2 刷新）
  @Trace checkboxSelected: Set<string> = new Set<string>()

  // 唯一事实源：questionId → 已选答案（字母拼接，如 'AC'）
  private answers: Map<string, string> = new Map<string, string>()
  // 防重复交卷闸门
  private submitting: boolean = false
  private timerId: number = -1

  private examService: ExamService

  // 切后台监视器：懒连接，单测不走到 startExam 就不碰 AppStorageV2
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
   * 开考（或断点续考）：装载场次、回填已答、以服务端时间起跳倒计时、开启切后台监视
   */
  async startExam(paperId: string): Promise<Result<void>> {
    this.clearError()
    this.setLoading(true)
    try {
      const info = await this.examService.startExam(paperId)
      this.attemptId = info.attemptId
      this.paperName = info.paperName
      this.questions = info.questions
      this.remainingSeconds = info.remainingSeconds
      this.currentIndex = 0

      // 断点续考：把后端回传的 myAnswer 灌进唯一事实源
      this.answers.clear()
      for (const q of info.questions) {
        if (q.myAnswer !== undefined && q.myAnswer !== null && q.myAnswer !== '') {
          this.answers.set(q.id, q.myAnswer)
        }
      }
      this.loadSelectionForCurrent()

      // 本地切后台监视归零起算（上报后端裁决留到 6-5）
      this.monitor.start()
      // 服务端倒计时：每秒一跳，到点自动交卷
      this.timerId = setInterval((): void => this.tick(), 1000)

      this.logger.info(`开考成功：场次 ${this.attemptId}，${this.questions.length} 题，剩余 ${this.remainingSeconds}s`)
      return Result.ok<void>(undefined)
    } catch (e) {
      const errorMsg = (e as Error).message || '开考失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`开考失败：${errorMsg}`)
      return Result.fail<void>(-1, errorMsg)
    } finally {
      this.setLoading(false)
    }
  }

  /** 每秒一跳：倒计时唯一推进口。做成公开方法，单测可直调而不必等真实时钟 */
  tick(): void {
    if (this.remainingSeconds > 0) {
      this.remainingSeconds--
    }
    if (this.remainingSeconds === 0) {
      this.submit('TIMEOUT')
    }
  }

  /** 交卷：MANUAL 手动 / TIMEOUT 超时 / TAB_SWITCH 切屏超限 */
  async submit(submitType: string): Promise<void> {
    if (this.submitting) {
      return   // 闸门：超时与手动同时到达也只交一次
    }
    this.submitting = true
    try {
      await this.examService.submit(this.attemptId, submitType, this.monitor.count)
      this.dispose()
      this.monitor.stop()   // 计数定格，结果页读到的就是本场最终次数
      this.finishedAttemptId = this.attemptId   // 点灯
      this.logger.info(`交卷成功：${submitType}，本场切出 ${this.monitor.count} 次`)
    } catch (e) {
      this.submitting = false   // 失败放行，允许用户重试
      this.setError((e as Error).message)
      this.logger.error(`交卷失败：${(e as Error).message}`)
    }
  }

  /** 清理定时器：交卷成功与页面销毁都要调 */
  dispose(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  // ===== 选题与渲染辅助 =====

  getCurrentQuestion(): QuestionItem {
    return this.questions[this.currentIndex]
  }

  getTypeLabel(type: string): string {
    const label: string = TYPE_LABEL[type]
    return label !== undefined ? label : '未知题型'
  }

  getOptionText(option: OptionItem): string {
    return option.label + '. ' + option.content
  }

  /** 倒计时显示文本：秒 → mm:ss（如 3599 → 59:59） */
  getRemainingText(): string {
    const m: number = Math.floor(this.remainingSeconds / 60)
    const s: number = this.remainingSeconds % 60
    return `${m < 10 ? '0' : ''}${m}:${s < 10 ? '0' : ''}${s}`
  }

  goToPrev(): void {
    if (this.currentIndex <= 0) {
      return
    }
    this.currentIndex--
    this.loadSelectionForCurrent()
  }

  goToNext(): void {
    if (this.currentIndex >= this.questions.length - 1) {
      return
    }
    this.currentIndex++
    this.loadSelectionForCurrent()
  }

  /** 单选/判断选中：更新渲染态 + 写唯一事实源 + 实时保存 */
  selectSingleOption(label: string): void {
    this.radioSelected = label
    this.persistAnswer(this.getCurrentQuestion().id, label)
  }

  /** 多选勾选/取消：整体替换 Set 触发刷新，并把集合拼成字母串保存 */
  toggleMultiOption(label: string, checked: boolean): void {
    const next: Set<string> = new Set<string>(this.checkboxSelected)
    if (checked) {
      next.add(label)
    } else {
      next.delete(label)
    }
    this.checkboxSelected = next
    const joined: string = Array.from(next).sort().join('')
    this.persistAnswer(this.getCurrentQuestion().id, joined)
  }

  // ===== 私有 =====

  // 把当前题的已存答案回填到渲染态（换题、开考回填都走它）
  private loadSelectionForCurrent(): void {
    if (this.currentIndex >= this.questions.length) {
      return
    }
    const saved: string = this.answers.get(this.getCurrentQuestion().id) ?? ''
    if (this.getCurrentQuestion().type === 'MULTI') {
      this.checkboxSelected = new Set<string>(saved.split('').filter((c: string): boolean => c !== ''))
      this.radioSelected = ''
    } else {
      this.radioSelected = saved
      this.checkboxSelected = new Set<string>()
    }
  }

  // 写唯一事实源并尽力实时保存（保存失败只记日志，不打断作答；交卷时以服务端记录为准）
  private persistAnswer(questionId: string, answer: string): void {
    if (answer === '') {
      this.answers.delete(questionId)
    } else {
      this.answers.set(questionId, answer)
    }
    this.examService.saveAnswer(this.attemptId, questionId, answer)
      .then((): void => {
        this.logger.info(`答案已保存：${questionId} → ${answer}`)
      })
      .catch((e: Error): void => {
        this.logger.warn(`答案保存失败（本地已记，交卷以服务端为准）：${e.message}`)
      })
  }
}
