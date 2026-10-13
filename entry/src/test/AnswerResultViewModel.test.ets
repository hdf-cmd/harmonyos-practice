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

    // 业务承诺：TAB_SWITCH → 切屏超限强制交卷
    it('should_label_tab_switch_submit', 0, () => {
      const vm = new AnswerResultViewModel(service)
      vm.result = makeResult(6, 'TAB_SWITCH')
      expect(vm.getSubmitTypeLabel()).assertEqual('切屏超限强制交卷')
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
  })
}
