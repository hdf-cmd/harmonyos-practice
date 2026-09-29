/**
 * 答题页 ViewModel：答题流程的业务与状态，零 UI
 *
 * 【分层说明】features/exam/viewmodel/ 是考试答题页的"业务大脑"：
 *   切题边界、换题重置、单选/多选选中流转、题型标签映射这些规则住在这里
 *   （Mock 三条铁律：Mock 只能被 ViewModel 消费），ExamDetailPage 只渲染状态、转发事件——
 *   项目 6 换接口取卷/取题时改这里，View 层零改动。
 *   数据流：ExamDetailPage.onReady → loadPaper(paperId) → @Trace 状态变更 → 页面自动刷新。
 *
 * 【切后台计数怎么分工】计数发生在 EntryAbility.onBackground（应用级事件只有 Ability 收得到），
 *   本类只负责"什么时候算一场"：开考 start() 让监视生效并清零，交卷 stop() 让计数定格。
 *   两边靠 StateKeys.BACKGROUND_MONITOR 这同一个 key 拿到同一个实例，不需要互相持有引用。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import {
  BaseViewModel, Result, MOCK_PAPER, MOCK_PAPERS, MOCK_QUESTIONS,
  PaperInfo, QuestionItem, OptionItem, BackgroundMonitor, StateKeys
} from '@zhititong/common'

// 题型标签映射：后端存的是枚举码（JUDGE/SINGLE/MULTI），展示时翻成中文
// 用 Record 集中管理映射关系，新增题型只改这一处
const TYPE_LABEL: Record<string, string> = {
  'JUDGE': '判断题',
  'SINGLE': '单选题',
  'MULTI': '多选题'
}

@ObservedV2
export class ExamDetailViewModel extends BaseViewModel {
  // 当前试卷名（@Trace：变更自动刷新 View）
  @Trace paperName: string = ''
  // 当前试卷的题目列表
  @Trace questions: QuestionItem[] = []
  // 当前题目索引：答题页最核心的状态——它一变，题目区所有内容跟着刷新
  @Trace currentIndex: number = 0
  // 单选/判断选中项（记录选中的 label，如 'A'）
  // 用 string 而不是 boolean：Radio 组件靠"值相等"判断谁被选中
  @Trace radioSelected: string = ''
  // 多选选中项集合：Set 天然去重，勾选/取消对应加/删
  // 注意 Set 整体替换（toggleMultiOption 里 new 一个新的）才会触发 V2 状态刷新
  @Trace checkboxSelected: Set<string> = new Set<string>()

  // 切后台监视器：懒连接——第一次真要用的时候才 connect。
  // 为什么不写成字段初始化就 connect：本地单测跑在非 UI 环境，既有 10 条用例只测取题/切题/选中，
  //   压根不会走到 startExam/submitPaper；懒连接让它们一行都不用动。
  // 不加 @Trace：本类不需要因它刷新 UI（提醒 Toast 由页面自己 @Monitor 这个实例），
  //   @ObservedV2 类里放普通字段是合法的，只是不触发刷新。
  private monitorInstance: BackgroundMonitor | undefined = undefined

  private get monitor(): BackgroundMonitor {
    if (this.monitorInstance === undefined) {
      this.monitorInstance = AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
        () => new BackgroundMonitor())!
    }
    return this.monitorInstance
  }

  // 获取当前题目：题目区 UI 都经由它取数据，改 currentIndex 即整体换题
  getCurrentQuestion(): QuestionItem {
    return this.questions[this.currentIndex]
  }

  // 题型标签文本：映射表查不到时兜底"未知题型"，避免 undefined 直接上屏（纯逻辑，可单测）
  getTypeLabel(type: string): string {
    const label: string = TYPE_LABEL[type]
    return label !== undefined ? label : '未知题型'
  }

  // 选项显示文本，如 "A. 正确"（纯逻辑，可单测）
  getOptionText(option: OptionItem): string {
    return option.label + '. ' + option.content
  }

  // 上一题：首题时不动（防越界），换题后重置选中状态
  goToPrev(): void {
    if (this.currentIndex <= 0) {
      return
    }
    this.currentIndex--
    this.resetSelection()
  }

  // 下一题：末题时不动（防越界），换题后重置选中状态
  // 两道题共用同一组选中状态，不重置的话上一题的勾选会"串"到下一题
  goToNext(): void {
    if (this.currentIndex >= this.questions.length - 1) {
      return
    }
    this.currentIndex++
    this.resetSelection()
  }

  // 单选/判断选中：Radio 的 onChange 只处理"被选中"分支（单选总有一个新选中项）
  selectSingleOption(label: string): void {
    this.radioSelected = label
  }

  // 多选勾选/取消：勾选进 Set、取消从 Set 删，UI 与数据始终保持一致
  // 整体替换新 Set，确保 V2 状态刷新
  toggleMultiOption(label: string, checked: boolean): void {
    const next: Set<string> = new Set<string>(this.checkboxSelected)
    if (checked) {
      next.add(label)
    } else {
      next.delete(label)
    }
    this.checkboxSelected = next
  }

  // 切换题目时重置选中状态
  resetSelection(): void {
    this.radioSelected = ''
    this.checkboxSelected = new Set<string>()
  }

  // 开考：进入监视态并把切后台计数清零（"每场独立计数"就落在这一次调用上）
  startExam(): void {
    this.monitor.start()
    this.logger.info('开考：切后台监视已开启')
  }

  // 交卷：停止监视，计数定格（不清零，结果页还要读这一场的次数）
  submitPaper(): void {
    this.monitor.stop()
    this.logger.info(`交卷：切后台监视已停止，本场共切出 ${this.monitor.count} 次`)
  }

  /**
   * 加载试卷与题目：按路由传入的 paperId 从试卷池命中试卷名，
   * 查不到回退默认卷（Mock 阶段题目固定 MOCK_QUESTIONS；接真接口时只改这里的取数代码）
   *
   * @param paperId 上游试卷卡片 push 进来的路由参数
   */
  async loadPaper(paperId: string): Promise<Result<void>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：按 id 命中试卷，未命中回退 MOCK_PAPER（默认卷）
      let paper: PaperInfo = MOCK_PAPER
      for (const p of MOCK_PAPERS) {
        if (p.id === paperId) {
          paper = p
          break
        }
      }
      this.paperName = paper.paperName
      this.questions = MOCK_QUESTIONS
      this.currentIndex = 0
      this.resetSelection()
      this.logger.info(`试卷「${this.paperName}」加载完成，共 ${this.questions.length} 题`)
      return Result.ok<void>(undefined)
    } catch (e) {
      const errorMsg = '试卷加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail<void>(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }
}
