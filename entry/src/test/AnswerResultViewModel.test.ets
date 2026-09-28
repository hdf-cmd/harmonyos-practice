// AnswerResultViewModel 单元测试：交卷结果展示业务规则的验证
//
// 【被测规则】loadResult 字段与 Mock 自洽、loading 复位、交卷方式文案映射、
//   答题卡行数按列数向上取整、Grid 高度公式（行数×格高+(行数−1)×行间距）。
import { describe, it, expect } from '@ohos/hypium'
import { AnswerResultViewModel } from '../main/ets/features/exam/viewmodel/AnswerResultViewModel'
import { ExamResult, AnswerItem, MOCK_RESULT } from '@zhititong/common'

// 构造 n 道题的作答记录：全部已作答，对错交替
function makeAnswers(n: number): AnswerItem[] {
  const answers: AnswerItem[] = []
  for (let i = 0; i < n; i++) {
    const answer: AnswerItem = { questionId: `qid_${i}`, correct: i % 2 === 0, answered: true }
    answers.push(answer)
  }
  return answers
}

// 构造带 n 道题的结果（score/及格线等字段取 Mock 值，题目数按需替换）
function makeResult(n: number, submitType: string): ExamResult {
  const r: ExamResult = {
    score: MOCK_RESULT.score,
    totalScore: MOCK_RESULT.totalScore,
    passScore: MOCK_RESULT.passScore,
    passed: MOCK_RESULT.passed,
    usedTime: MOCK_RESULT.usedTime,
    submitType: submitType,
    answers: makeAnswers(n)
  }
  return r
}

export default function answerResultViewModelTest() {
  describe('answerResultViewModelTest', () => {
    // 常规：加载成功，Result.ok，字段与 Mock 自洽（80 分 / 通过 / 6 条作答记录）
    it('should_load_result_ok', 0, async () => {
      const vm = new AnswerResultViewModel()
      const res = await vm.loadResult()
      expect(res.ok).assertEqual(true)
      expect(vm.result.score).assertEqual(80)
      expect(vm.result.passed).assertEqual(true)
      expect(vm.result.answers.length).assertEqual(6)
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new AnswerResultViewModel()
      await vm.loadResult()
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 业务承诺：MANUAL 交卷方式翻成"手动交卷"
    it('should_label_manual_submit', 0, async () => {
      const vm = new AnswerResultViewModel()
      await vm.loadResult()   // MOCK_RESULT.submitType = 'MANUAL'
      expect(vm.getSubmitTypeLabel()).assertEqual('手动交卷')
    })

    // 业务承诺：非 MANUAL（TIMEOUT）翻成"超时自动交卷"
    it('should_label_timeout_submit', 0, () => {
      const vm = new AnswerResultViewModel()
      vm.result = makeResult(6, 'TIMEOUT')
      expect(vm.getSubmitTypeLabel()).assertEqual('超时自动交卷')
    })

    // 业务承诺：行数 = 题目数按列数(6)向上取整
    // 6 题 → 1 行；13 题 → ceil(13/6)=3 行（最后一行只放 1 个）
    it('should_calc_row_count_by_ceiling', 0, () => {
      const vm = new AnswerResultViewModel()
      vm.result = makeResult(6, 'MANUAL')
      expect(vm.getAnswerCardRowCount()).assertEqual(1)
      vm.result = makeResult(13, 'MANUAL')
      expect(vm.getAnswerCardRowCount()).assertEqual(3)
    })

    // 业务承诺：Grid 高度 = 行数×格高(40) + (行数−1)×行间距(8)
    // 1 行 → 40；3 行 → 3×40+2×8=136——Grid 不自适应高度，这个公式算错会把按钮行顶出屏幕
    it('should_calc_card_height_by_formula', 0, () => {
      const vm = new AnswerResultViewModel()
      vm.result = makeResult(6, 'MANUAL')
      expect(vm.getAnswerCardHeight()).assertEqual(40)
      vm.result = makeResult(13, 'MANUAL')
      expect(vm.getAnswerCardHeight()).assertEqual(136)
    })
  })
}
