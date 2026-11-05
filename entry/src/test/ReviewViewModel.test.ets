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

    // ===== 助教上下文（实训 7-2 入口 3：回顾页当前题） =====

    // 就绪判据 + 未滚动时的默认当前题（列表第一题）
    it('should_gate_entry_and_default_to_first_question', 0, async () => {
      const vm = new ReviewViewModel(service)
      expect(vm.assistantReady).assertEqual(false)
      await vm.loadReview('A1')
      expect(vm.assistantReady).assertEqual(true)
      const current: ReviewQuestionDetail | undefined = vm.currentQuestion
      expect(current !== undefined ? current.questionId : 'none').assertEqual('q0')
      expect(vm.assistantQueryKey).assertEqual('q0')
    })

    // 中心项变化 → 当前题变化 → key 变化（View 靠它重建入口，带上新题的 queryText）
    it('should_switch_current_question_by_center_index', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      vm.updateCurrentVisibleIndex(1)
      expect(vm.assistantQueryKey).assertEqual('q1')
      // 答错的题：三段式请求（先结论、再解释错因与考点）
      expect(vm.assistantQuery).assertEqual(
        '试卷：3 题小卷\n得分：10/30\n第2题（单选题·我答错了）\n题干：题干1\n选项：\nA：甲\nB：乙\n' +
        '我的答案：A / 正确答案：B\n请先给出正确结论，再解释我的答案错在哪与相关考点；知识库没有的内容请明确说明。')
    })

    // 答对的题走另一种问法：讲考点 + 出一道同考点变式题
    it('should_ask_variant_for_correct_question', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      expect(vm.assistantQuery).assertEqual(
        '试卷：3 题小卷\n得分：10/30\n第1题（单选题·我答对了）\n题干：题干0\n选项：\nA：甲\nB：乙\n' +
        '正确答案：A\n请讲解本题考点，再出一道同考点的变式题让我练习；知识库没有的内容请明确说明。')
    })

    // 契约坑：userAnswer 为 null（未作答）必须写成"未作答"，留空会被大模型当成没给答案去猜
    it('should_mark_unanswered_in_query', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      vm.updateCurrentVisibleIndex(2)
      expect(vm.assistantQuery).assertEqual(
        '试卷：3 题小卷\n得分：10/30\n第3题（多选题·我答错了）\n题干：题干2\n选项：\nA：甲\nB：乙\nC：丙\n' +
        '我的答案：未作答 / 正确答案：AC\n请先给出正确结论，再解释我的答案错在哪与相关考点；知识库没有的内容请明确说明。')
    })

    // 开了"只看错题"后，题号仍按原卷编号（q2 在原卷是第 3 题，不是可见列表的第 2 题）
    it('should_keep_original_number_when_wrong_only', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      vm.showWrongOnly = true
      expect(vm.visibleQuestions.length).assertEqual(2)
      vm.updateCurrentVisibleIndex(1)
      const current: ReviewQuestionDetail | undefined = vm.currentQuestion
      expect(current !== undefined ? current.questionId : 'none').assertEqual('q2')
      expect(vm.questionNoById('q2')).assertEqual(2)
      // 整段比对：题号必须是"第3题"（原卷编号），而不是可见列表里的第 2 条
      expect(vm.assistantQuery).assertEqual(
        '试卷：3 题小卷\n得分：10/30\n第3题（多选题·我答错了）\n题干：题干2\n选项：\nA：甲\nB：乙\nC：丙\n' +
        '我的答案：未作答 / 正确答案：AC\n请先给出正确结论，再解释我的答案错在哪与相关考点；知识库没有的内容请明确说明。')
    })

    // 非法下标（-1 / 越界）不改状态：越界由 currentQuestion 回落到第一题
    it('should_ignore_invalid_center_index', 0, async () => {
      const vm = new ReviewViewModel(service)
      await vm.loadReview('A1')
      vm.updateCurrentVisibleIndex(1)
      vm.updateCurrentVisibleIndex(-1)
      vm.updateCurrentVisibleIndex(99)
      expect(vm.assistantQueryKey).assertEqual('q1')
      vm.showWrongOnly = true
      vm.updateCurrentVisibleIndex(-1)
      vm.visibleIndex = 5
      const current: ReviewQuestionDetail | undefined = vm.currentQuestion
      expect(current !== undefined ? current.questionId : 'none').assertEqual('q1')
    })
  })
}
