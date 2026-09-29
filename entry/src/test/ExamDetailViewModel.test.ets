// ExamDetailViewModel 单元测试：答题流程业务规则的验证
//
// 【被测规则】题型标签映射与兜底、选项文本拼接、切题边界防越界、
//   换题重置选中、单选/多选选中流转、loadPaper 按 id 命中与回退、loading 复位、
//   考试生命周期（startExam 开监视并清零 / submitPaper 关监视并定格计数）。
import { describe, it, expect } from '@ohos/hypium'
import { AppStorageV2 } from '@kit.ArkUI'
import { ExamDetailViewModel } from '../main/ets/features/exam/viewmodel/ExamDetailViewModel'
import { OptionItem, MOCK_PAPER, MOCK_PAPERS, MOCK_QUESTIONS, BackgroundMonitor, StateKeys } from '@zhititong/common'

// 取共享监视器实例：与 VM 内部同一个 key，AppStorageV2 同 key 必返同实例（本机 LocalUnit 实测）。
// 断言写在这个外部句柄上才有意义——它证明 VM 动的确实是那个全局实例，而不是自己 new 的私有对象。
function sharedMonitor(): BackgroundMonitor {
  return AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
    () => new BackgroundMonitor())!
}

export default function examDetailViewModelTest() {
  describe('examDetailViewModelTest', () => {
    // 常规：加载成功，Result.ok，题目就位、索引归零
    it('should_load_paper_by_id', 0, async () => {
      const vm = new ExamDetailViewModel()
      const target = MOCK_PAPERS[3]   // 用一张非默认卷验证 id 命中
      const res = await vm.loadPaper(target.id)
      expect(res.ok).assertEqual(true)
      expect(vm.paperName).assertEqual(target.paperName)
      expect(vm.questions.length).assertEqual(MOCK_QUESTIONS.length)
      expect(vm.currentIndex).assertEqual(0)
    })

    // 业务承诺：未知 id 回退默认卷，不崩、不空屏
    it('should_fallback_to_default_paper_for_unknown_id', 0, async () => {
      const vm = new ExamDetailViewModel()
      await vm.loadPaper('不存在的试卷 id')
      expect(vm.paperName).assertEqual(MOCK_PAPER.paperName)
      expect(vm.questions.length > 0).assertEqual(true)
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new ExamDetailViewModel()
      await vm.loadPaper(MOCK_PAPERS[0].id)
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 纯逻辑：三种题型码都翻成中文
    it('should_map_type_labels', 0, () => {
      const vm = new ExamDetailViewModel()
      expect(vm.getTypeLabel('JUDGE')).assertEqual('判断题')
      expect(vm.getTypeLabel('SINGLE')).assertEqual('单选题')
      expect(vm.getTypeLabel('MULTI')).assertEqual('多选题')
    })

    // 纯逻辑：映射表查不到时兜底"未知题型"，避免 undefined 上屏
    it('should_fallback_unknown_type', 0, () => {
      const vm = new ExamDetailViewModel()
      expect(vm.getTypeLabel('ESSAY')).assertEqual('未知题型')
    })

    // 纯逻辑：选项文本 = label + '. ' + content
    it('should_concat_option_text', 0, () => {
      const vm = new ExamDetailViewModel()
      const option: OptionItem = { label: 'A', content: '正确' }
      expect(vm.getOptionText(option)).assertEqual('A. 正确')
    })

    // 边界：首题时"上一题"不动（防越界）
    it('should_block_prev_at_first_question', 0, async () => {
      const vm = new ExamDetailViewModel()
      await vm.loadPaper(MOCK_PAPERS[0].id)
      vm.goToPrev()
      expect(vm.currentIndex).assertEqual(0)
    })

    // 边界：末题时"下一题"不动（防越界）
    it('should_block_next_at_last_question', 0, async () => {
      const vm = new ExamDetailViewModel()
      await vm.loadPaper(MOCK_PAPERS[0].id)
      const last = vm.questions.length - 1
      for (let i = 0; i < last; i++) {
        vm.goToNext()
      }
      expect(vm.currentIndex).assertEqual(last)
      vm.goToNext()
      expect(vm.currentIndex).assertEqual(last)
    })

    // 业务承诺：换题必须重置选中——上一题的勾选不许"串"到下一题
    it('should_reset_selection_on_switch', 0, async () => {
      const vm = new ExamDetailViewModel()
      await vm.loadPaper(MOCK_PAPERS[0].id)
      vm.selectSingleOption('A')
      vm.toggleMultiOption('B', true)
      vm.goToNext()
      expect(vm.radioSelected).assertEqual('')
      expect(vm.checkboxSelected.size).assertEqual(0)
    })

    // 业务承诺：多选勾选进 Set、取消从 Set 删，互不干扰
    it('should_toggle_multi_options', 0, () => {
      const vm = new ExamDetailViewModel()
      vm.toggleMultiOption('A', true)
      vm.toggleMultiOption('C', true)
      expect(vm.checkboxSelected.size).assertEqual(2)
      vm.toggleMultiOption('A', false)
      expect(vm.checkboxSelected.size).assertEqual(1)
      expect(vm.checkboxSelected.has('C')).assertEqual(true)
    })

    // 业务承诺：开考 = 进入监视态 + 把上一场残留的计数清零。
    // 先把共享实例故意弄脏（count=5、monitoring=false），否则"清零"和"本来就是 0"分不开
    it('should_start_exam_enable_monitoring_and_reset_count', 0, () => {
      const monitor: BackgroundMonitor = sharedMonitor()
      monitor.count = 5
      monitor.monitoring = false
      const vm = new ExamDetailViewModel()
      vm.startExam()
      expect(monitor.monitoring).assertEqual(true)
      expect(monitor.count).assertEqual(0)
    })

    // 业务承诺：交卷只关监视、计数定格（结果页还要读这一场的次数，清零就丢数据了）
    it('should_stop_monitoring_and_freeze_count_on_submit', 0, () => {
      const monitor: BackgroundMonitor = sharedMonitor()
      const vm = new ExamDetailViewModel()
      vm.startExam()
      // 模拟 EntryAbility.onBackground 侧累加两次：VM 不参与计数，只负责开关监视
      monitor.increase()
      monitor.increase()
      expect(monitor.count).assertEqual(2)
      vm.submitPaper()
      expect(monitor.monitoring).assertEqual(false)
      expect(monitor.count).assertEqual(2)
    })
  })
}
