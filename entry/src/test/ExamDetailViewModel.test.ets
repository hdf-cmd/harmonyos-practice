// ExamDetailViewModel 单元测试：考试链路业务规则的验证（hamock 化）
//
// 【被测规则】开考装载场次/题目/剩余时间、断点续考 myAnswer 回填、换题重置选中、
//   单选/多选选中流转、倒计时 tick 递减与归零触发交卷、submitting 闸门只交一次、
//   交卷成功点亮 finishedAttemptId、题型标签映射与兜底、mm:ss 格式化、切题边界防越界。
// 【为什么用 hamock】6-4 后 startExam/submit/saveAnswer 全打后端。这里 mock 掉 ExamService，
//   单测毫秒级、零网络、可重复；tick() 直调模拟时间流逝。
import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium'
import { MockKit, when, ArgumentMatchers } from '@ohos/hamock'
import { ExamDetailViewModel } from '../main/ets/features/exam/viewmodel/ExamDetailViewModel'
import { ExamService, AttemptInfo, SubmitResult } from '../main/ets/features/exam/service/ExamService'
import { OptionItem, QuestionItem } from '@zhititong/common'

// 3 题小卷夹具：q0 单选已答 A（测回填）、q1 多选未答、q2 判断未答
function fixtureQuestions(): QuestionItem[] {
  const a: QuestionItem = { id: 'q0', type: 'SINGLE', content: '单选干', score: 10,
    options: [{ label: 'A', content: '甲' }, { label: 'B', content: '乙' }], myAnswer: 'A' }
  const b: QuestionItem = { id: 'q1', type: 'MULTI', content: '多选干', score: 10,
    options: [{ label: 'A', content: '甲' }, { label: 'B', content: '乙' }, { label: 'C', content: '丙' }] }
  const c: QuestionItem = { id: 'q2', type: 'JUDGE', content: '判断干', score: 10,
    options: [{ label: 'A', content: '正确' }, { label: 'B', content: '错误' }] }
  return [a, b, c]
}

function fixtureAttempt(): AttemptInfo {
  return {
    attemptId: 'A1', paperName: '3 题小卷', totalScore: 30, passScore: 18,
    duration: 1, remainingSeconds: 3600, questions: fixtureQuestions()
  }
}

function fixtureSubmit(): SubmitResult {
  return { score: 20, totalScore: 30, passScore: 18, passed: true, usedTime: 100,
    submitType: 'MANUAL', certificateGenerated: true }
}

export default function examDetailViewModelTest() {
  describe('examDetailViewModelTest', () => {
    let service: ExamService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new ExamService()
      const mStart: Function = mocker.mockFunc(service, service.startExam)
      when(mStart)(ArgumentMatchers.any).afterReturn(Promise.resolve(fixtureAttempt()))
      const mSubmit: Function = mocker.mockFunc(service, service.submit)
      when(mSubmit)(ArgumentMatchers.any).afterReturn(Promise.resolve(fixtureSubmit()))
      const mSave: Function = mocker.mockFunc(service, service.saveAnswer)
      when(mSave)(ArgumentMatchers.any).afterReturn(Promise.resolve())
    })

    afterEach(() => {
      mocker.clearAll()
    })

    // 开考：装载场次号、题目、服务端剩余时间
    it('should_load_attempt_on_start', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      expect(vm.attemptId).assertEqual('A1')
      expect(vm.questions.length).assertEqual(3)
      expect(vm.remainingSeconds).assertEqual(3600)
      vm.dispose()
    })

    // 断点续考：myAnswer 回填到当前题选中态
    it('should_backfill_single_answer_from_my_answer', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      expect(vm.radioSelected).assertEqual('A')
      vm.dispose()
    })

    // 换题重置：q1 多选未答，切过去后单选清空、多选空集
    it('should_reset_selection_on_switch', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.goToNext()
      expect(vm.radioSelected).assertEqual('')
      expect(vm.checkboxSelected.size).assertEqual(0)
      vm.dispose()
    })

    // 多选勾选：整体替换 Set，连勾两个再取消一个（在多选题 q1 上操作）
    it('should_toggle_multi_options', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.goToNext()   // 切到 q1（MULTI）
      vm.toggleMultiOption('A', true)
      vm.toggleMultiOption('C', true)
      expect(vm.checkboxSelected.size).assertEqual(2)
      vm.toggleMultiOption('A', false)
      expect(vm.checkboxSelected.size).assertEqual(1)
      expect(vm.checkboxSelected.has('C')).assertEqual(true)
      vm.dispose()
    })

    // 倒计时：tick 每秒减一
    it('should_decrement_remaining_on_tick', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.remainingSeconds = 5
      vm.tick()
      expect(vm.remainingSeconds).assertEqual(4)
      vm.dispose()
    })

    // 超时自动交卷：remainingSeconds 归零时 tick 触发 submit 并点灯
    it('should_autosubmit_when_timeout', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.remainingSeconds = 1
      vm.tick()   // 归零 → 内部调 submit('TIMEOUT')
      await Promise.resolve()   // 让 submit 的 await 链跑完
      expect(vm.remainingSeconds).assertEqual(0)
      expect(vm.finishedAttemptId).assertEqual('A1')
      vm.dispose()
    })

    // 手动交卷：成功后点亮 finishedAttemptId
    it('should_light_finished_on_manual_submit', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.dispose()   // 先停表，避免定时器干扰
      await vm.submit('MANUAL')
      expect(vm.finishedAttemptId).assertEqual('A1')
    })

    // 防重复交卷闸门：连交两次只点亮一次、不报错
    it('should_submit_only_once', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.dispose()
      const p1: Promise<void> = vm.submit('MANUAL')
      const p2: Promise<void> = vm.submit('MANUAL')   // 第二次被闸门挡下，立即 return
      await p1
      await p2
      expect(vm.finishedAttemptId).assertEqual('A1')
    })

    // 边界：首题"上一题"不动
    it('should_block_prev_at_first_question', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.goToPrev()
      expect(vm.currentIndex).assertEqual(0)
      vm.dispose()
    })

    // 边界：末题"下一题"不动
    it('should_block_next_at_last_question', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.goToNext()
      vm.goToNext()
      vm.goToNext()   // 已在末题，再点不动
      expect(vm.currentIndex).assertEqual(2)
      vm.dispose()
    })

    // 纯逻辑：三种题型码翻中文
    it('should_map_type_labels', 0, () => {
      const vm = new ExamDetailViewModel(service)
      expect(vm.getTypeLabel('JUDGE')).assertEqual('判断题')
      expect(vm.getTypeLabel('SINGLE')).assertEqual('单选题')
      expect(vm.getTypeLabel('MULTI')).assertEqual('多选题')
    })

    // 纯逻辑：未知题型兜底
    it('should_fallback_unknown_type', 0, () => {
      const vm = new ExamDetailViewModel(service)
      expect(vm.getTypeLabel('ESSAY')).assertEqual('未知题型')
    })

    // 纯逻辑：选项文本 = label + '. ' + content
    it('should_concat_option_text', 0, () => {
      const vm = new ExamDetailViewModel(service)
      const option: OptionItem = { label: 'A', content: '正确' }
      expect(vm.getOptionText(option)).assertEqual('A. 正确')
    })

    // 纯逻辑：倒计时 mm:ss 格式化（3599 → 59:59）
    it('should_format_remaining_as_mmss', 0, async () => {
      const vm = new ExamDetailViewModel(service)
      await vm.startExam('P1')
      vm.remainingSeconds = 3599
      expect(vm.getRemainingText()).assertEqual('59:59')
      vm.remainingSeconds = 5
      expect(vm.getRemainingText()).assertEqual('00:05')
      vm.dispose()
    })
  })
}
