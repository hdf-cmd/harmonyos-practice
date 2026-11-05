// AnswerResultViewModel 单元测试：交卷结果展示业务规则的验证（hamock 化）
//
// 【被测规则】loadResult 用 result+review 两趟拼出判分卡与答题卡、loading 复位、
//   交卷方式文案映射（MANUAL/TIMEOUT/TAB_SWITCH）、答题卡行数向上取整、
//   Grid 高度公式、切后台提示两分支。
// 【为什么用 hamock】loadResult 现在打后端 getResult/getReview。mock 掉 ExamService，
//   单测零网络、可重复。布局类用例直接改 vm.result，不碰服务。
import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium'
import { AppStorageV2 } from '@kit.ArkUI'
import { MockKit, when, ArgumentMatchers } from '@ohos/hamock'
import { AnswerResultViewModel } from '../main/ets/features/exam/viewmodel/AnswerResultViewModel'
import { ExamService, SubmitResult, ReviewInfo, ReviewQuestion } from '../main/ets/features/exam/service/ExamService'
import { ExamResult, AnswerItem, BackgroundMonitor, StateKeys } from '@zhititong/common'

function sharedMonitor(): BackgroundMonitor {
  return AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
    () => new BackgroundMonitor())!
}

function makeAnswers(n: number): AnswerItem[] {
  const answers: AnswerItem[] = []
  for (let i = 0; i < n; i++) {
    const answer: AnswerItem = { questionId: `qid_${i}`, correct: i % 2 === 0, answered: true }
    answers.push(answer)
  }
  return answers
}

function makeResult(n: number, submitType: string): ExamResult {
  const r: ExamResult = {
    score: 80, totalScore: 100, passScore: 60, passed: true, usedTime: 754,
    submitType: submitType, answers: makeAnswers(n)
  }
  return r
}

// 造 n 题的回顾数据（userAnswer 非空即视为已作答）
function makeReview(n: number): ReviewInfo {
  const qs: ReviewQuestion[] = []
  for (let i = 0; i < n; i++) {
    const q: ReviewQuestion = {
      questionId: `qid_${i}`, type: 'SINGLE', content: `题干${i}`,
      correctAnswer: 'A', userAnswer: i % 2 === 0 ? 'A' : 'B', isCorrect: i % 2 === 0,
      earnedScore: 10, maxScore: 10, options: []
    }
    qs.push(q)
  }
  return { attemptId: 'A1', paperName: '3 题小卷', score: 80, totalScore: 100, isPassed: 1, questions: qs }
}

export default function answerResultViewModelTest() {
  describe('answerResultViewModelTest', () => {
    let service: ExamService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new ExamService()
      const score: SubmitResult = { score: 80, totalScore: 100, passScore: 60, passed: true,
        usedTime: 754, submitType: 'MANUAL', certificateGenerated: true }
      const mGet: Function = mocker.mockFunc(service, service.getResult)
      when(mGet)(ArgumentMatchers.any).afterReturn(Promise.resolve(score))
      const mReview: Function = mocker.mockFunc(service, service.getReview)
      when(mReview)(ArgumentMatchers.any).afterReturn(Promise.resolve(makeReview(6)))
    })

    afterEach(() => {
      mocker.clearAll()
    })

    // 常规：loadResult 拼出判分卡 + 答题卡（6 题）
    it('should_load_result_ok', 0, async () => {
      const vm = new AnswerResultViewModel(service)
      const res = await vm.loadResult('A1')
      expect(res.ok).assertEqual(true)
      expect(vm.result.score).assertEqual(80)
      expect(vm.result.passed).assertEqual(true)
      expect(vm.result.answers.length).assertEqual(6)
    })

    // 隐含约定：无论成败，loading 最终回到 false
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 业务承诺：MANUAL → 手动交卷
    it('should_label_manual_submit', 0, async () => {
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      expect(vm.getSubmitTypeLabel()).assertEqual('手动交卷')
    })

    // 业务承诺：TIMEOUT → 超时自动交卷
    it('should_label_timeout_submit', 0, () => {
      const vm = new AnswerResultViewModel(service)
      vm.result = makeResult(6, 'TIMEOUT')
      expect(vm.getSubmitTypeLabel()).assertEqual('超时自动交卷')
    })

    // 业务承诺：TAB_SWITCH → 切屏超限自动交卷
    it('should_label_tab_switch_submit', 0, () => {
      const vm = new AnswerResultViewModel(service)
      vm.result = makeResult(6, 'TAB_SWITCH')
      expect(vm.getSubmitTypeLabel()).assertEqual('切屏超限自动交卷')
    })

    // 业务承诺：行数 = 题目数按列数(6)向上取整
    it('should_calc_row_count_by_ceiling', 0, () => {
      const vm = new AnswerResultViewModel(service)
      vm.result = makeResult(6, 'MANUAL')
      expect(vm.getAnswerCardRowCount()).assertEqual(1)
      vm.result = makeResult(13, 'MANUAL')
      expect(vm.getAnswerCardRowCount()).assertEqual(3)
    })

    // 业务承诺：Grid 高度 = 行数×40 + (行数−1)×8
    it('should_calc_card_height_by_formula', 0, () => {
      const vm = new AnswerResultViewModel(service)
      vm.result = makeResult(6, 'MANUAL')
      expect(vm.getAnswerCardHeight()).assertEqual(40)
      vm.result = makeResult(13, 'MANUAL')
      expect(vm.getAnswerCardHeight()).assertEqual(136)
    })

    // 业务承诺：切出过就把次数报出来（期望串手写，避免同义反复）
    it('should_report_switch_count_in_hint', 0, () => {
      const monitor: BackgroundMonitor = sharedMonitor()
      monitor.start()
      monitor.increase()
      monitor.increase()
      monitor.increase()
      const vm = new AnswerResultViewModel(service)
      expect(vm.getBackgroundHint()).assertEqual('本场切出应用 3 次')
    })

    // 业务承诺：一次没切也明说
    it('should_report_no_switch_when_count_zero', 0, () => {
      sharedMonitor().start()
      const vm = new AnswerResultViewModel(service)
      expect(vm.getBackgroundHint()).assertEqual('本场未切出应用')
    })

    // ===== 助教上下文（实训 7-2 入口 2：成绩页） =====

    // 同一次 review 响应里顺带取走试卷名与错题题干：不额外发请求
    it('should_pick_paper_name_and_wrong_titles_from_review', 0, async () => {
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      expect(vm.paperName).assertEqual('3 题小卷')
      // 6 题里错 3 道（qid_1/3/5），未超过 5 条上限，题干按原顺序进列表
      expect(vm.wrongTitles.length).assertEqual(3)
      expect(vm.wrongTitles[0]).assertEqual('题干1')
    })

    // 错题线索上限 5 条：20 题错 10 道也只带前 5 道（上下文越长，建议越容易被稀释）
    it('should_cap_wrong_titles_at_limit', 0, async () => {
      const mReview: Function = mocker.mockFunc(service, service.getReview)
      when(mReview)(ArgumentMatchers.any).afterReturn(Promise.resolve(makeReview(20)))
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      expect(vm.wrongTitles.length).assertEqual(5)
    })

    // 就绪判据：加载前不成立（入口绝不能带着初始空数据创建），加载后成立
    it('should_gate_assistant_entry_until_data_ready', 0, async () => {
      const vm = new AnswerResultViewModel(service)
      expect(vm.assistantReady).assertEqual(false)
      await vm.loadResult('A1')
      expect(vm.assistantReady).assertEqual(true)
    })

    // 加载失败时入口不出现：没有卷面数据，助教只能靠猜
    it('should_not_ready_when_load_failed', 0, async () => {
      const mScore: Function = mocker.mockFunc(service, service.getResult)
      when(mScore)(ArgumentMatchers.any).afterReturn(Promise.reject(new Error('后端没起')))
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      expect(vm.assistantReady).assertEqual(false)
      expect(vm.paperName).assertEqual('')
    })

    // 发给助教的问题全文钉死：试卷/得分/及格线/结果/错题题干/请求，一条不多一条不少
    it('should_build_assistant_query_with_score_and_wrong_titles', 0, async () => {
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      const expected: string = '试卷：3 题小卷\n得分：80/100（及格线 60）\n结果：通过 · 答对 3/6 题\n' +
        '部分错题题干：\n1. 题干1\n2. 题干3\n3. 题干5\n' +
        '请结合这些错题对应的考点，基于知识库给出按优先级排序的复习建议（不超过3条）。'
      expect(vm.assistantQuery).assertEqual(expected)
    })

    // 全对的卷子不能谎报错题，改口要巩固与进阶建议
    it('should_ask_for_consolidation_when_all_correct', 0, async () => {
      const qs: ReviewQuestion[] = []
      for (let i = 0; i < 4; i++) {
        const q: ReviewQuestion = {
          questionId: `qid_${i}`, type: 'SINGLE', content: `题干${i}`,
          correctAnswer: 'A', userAnswer: 'A', isCorrect: true,
          earnedScore: 10, maxScore: 10, options: []
        }
        qs.push(q)
      }
      const allRight: ReviewInfo = {
        attemptId: 'A1', paperName: '满分小卷', score: 40, totalScore: 40, isPassed: 1, questions: qs
      }
      // 判分与回顾都要改：assistantQuery 里的得分取自 result(3.5)，不是 review
      const allRightScore: SubmitResult = { score: 40, totalScore: 40, passScore: 60, passed: true,
        usedTime: 300, submitType: 'MANUAL', certificateGenerated: true }
      const mScore: Function = mocker.mockFunc(service, service.getResult)
      when(mScore)(ArgumentMatchers.any).afterReturn(Promise.resolve(allRightScore))
      const mReview: Function = mocker.mockFunc(service, service.getReview)
      when(mReview)(ArgumentMatchers.any).afterReturn(Promise.resolve(allRight))
      const vm = new AnswerResultViewModel(service)
      await vm.loadResult('A1')
      expect(vm.wrongTitles.length).assertEqual(0)
      expect(vm.assistantQuery).assertEqual(
        '试卷：满分小卷\n得分：40/40（及格线 60）\n结果：通过 · 答对 4/4 题\n本卷全部答对，请基于知识库给出巩固与进阶建议。')
    })
  })
}
