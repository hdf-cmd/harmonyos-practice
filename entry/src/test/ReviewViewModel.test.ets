// ReviewViewModel 单元测试：回顾页精讲规则的验证（hamock 化）
//
// 【被测规则】loadReview 装载全量回顾、loading 复位、correctCount 统计、
//   showWrongOnly 过滤（原始数据不动）、isPassed 数字转布尔。
// 【契约坑覆盖】userAnswer 为 null（未作答）、analysis 为空串（暂无解析）。
import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium'
import { MockKit, when, ArgumentMatchers } from '@ohos/hamock'
import { ReviewViewModel } from '../main/ets/features/exam/viewmodel/ReviewViewModel'
import { ExamService, ReviewDetail, ReviewQuestionDetail } from '../main/ets/features/exam/service/ExamService'
import { OptionItem } from '@zhititong/common'

function opt(label: string, content: string): OptionItem {
  const o: OptionItem = { label: label, content: content }
  return o
}

// 3 题 1 错：q0 对且有解析、q1 错且无解析（analysis 空串）、q2 未作答（userAnswer null）
function fixtureReview(): ReviewDetail {
  const q0: ReviewQuestionDetail = {
    questionId: 'q0', type: 'SINGLE', content: '题干0', correctAnswer: 'A', userAnswer: 'A',
    isCorrect: true, earnedScore: 10, maxScore: 10, analysis: '这是解析0',
    options: [opt('A', '甲'), opt('B', '乙')]
  }
  const q1: ReviewQuestionDetail = {
    questionId: 'q1', type: 'SINGLE', content: '题干1', correctAnswer: 'B', userAnswer: 'A',
    isCorrect: false, earnedScore: 0, maxScore: 10, analysis: '',
    options: [opt('A', '甲'), opt('B', '乙')]
  }
  const q2: ReviewQuestionDetail = {
    questionId: 'q2', type: 'MULTI', content: '题干2', correctAnswer: 'AC', userAnswer: null,
    isCorrect: false, earnedScore: 0, maxScore: 10, analysis: '这是解析2',
    options: [opt('A', '甲'), opt('B', '乙'), opt('C', '丙')]
  }
  return {
    attemptId: 'A1', paperName: '3 题小卷', score: 10, totalScore: 30, isPassed: 0,
    questions: [q0, q1, q2]
  }
}

export default function reviewViewModelTest() {
  describe('reviewViewModelTest', () => {
    let service: ExamService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new ExamService()
      const mGet: Function = mocker.mockFunc(service, service.getFullReview)
      when(mGet)(ArgumentMatchers.any).afterReturn(Promise.resolve(fixtureReview()))
    })

    afterEach(() => {
      mocker.clearAll()
    })

    it('should_load_review_and_reset_loading', 0, async () => {
      const vm = new ReviewViewModel(service)
      const res = await vm.loadReview('A1')
      expect(res.ok).assertEqual(true)
      expect(vm.review.questions.length).assertEqual(3)
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 答对题数：3 题里只有 q0 对
    it('should_count_correct_questions', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      expect(vm.correctCount).assertEqual(1)
    })

    // 只看错题：开关开 → 只剩 2 道错题；关 → 回到全量（原始数据一份不动）
    it('should_filter_wrong_only_without_mutating_source', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      vm.showWrongOnly = true
      expect(vm.visibleQuestions.length).assertEqual(2)
      expect(vm.review.questions.length).assertEqual(3)
      vm.showWrongOnly = false
      expect(vm.visibleQuestions.length).assertEqual(3)
    })

    // isPassed 是数字 1/0，翻译成布尔给 View
    it('should_translate_is_passed_number', 0, () => {
      const vm = new ReviewViewModel(service)
      expect(vm.passed).assertEqual(false)
      vm.review = {
        attemptId: 'A1', paperName: 'p', score: 20, totalScore: 30, isPassed: 1,
        questions: []
      }
      expect(vm.passed).assertEqual(true)
    })

    // 失败分支：错误上屏、loading 归位
    it('should_set_error_on_failure', 0, async () => {
      const svc: ExamService = new ExamService()
      const mFail: Function = mocker.mockFunc(svc, svc.getFullReview)
      when(mFail)(ArgumentMatchers.any).afterReturn(Promise.reject(new Error('回顾炸了')))
      const vm = new ReviewViewModel(svc)
      const res = await vm.loadReview('A1')
      expect(res.ok).assertEqual(false)
      expect(vm.errorMessage).assertEqual('回顾炸了')
      expect(vm.loading).assertEqual(false)
    })
  })
}
