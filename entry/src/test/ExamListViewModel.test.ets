// ExamListViewModel 单元测试：按科目过滤考卷业务的规则验证
//
// 【被测规则】loadPapersByCategory 的业务承诺：结果只含该科目的卷、
//   不存在的科目返回空数组、Result.ok 包装正确、loading 无论成败最终复位。
import { describe, it, expect } from '@ohos/hypium'
import { ExamListViewModel } from '../main/ets/features/exam/viewmodel/ExamListViewModel'
import { MOCK_PAPERS } from '@zhititong/common'

export default function examListViewModelTest() {
  describe('examListViewModelTest', () => {
    // 常规：加载成功，Result.ok，结果非空（Mock 试卷池里科目都有卷）
    it('should_load_papers_ok', 0, async () => {
      const vm = new ExamListViewModel()
      const res = await vm.loadPapersByCategory(MOCK_PAPERS[0].categoryName)
      expect(res.ok).assertEqual(true)
      expect(vm.papers.length > 0).assertEqual(true)
    })

    // 业务承诺：结果只含目标科目的卷，一条都不许混进别的科目
    it('should_only_contain_target_category_papers', 0, async () => {
      const target: string = MOCK_PAPERS[0].categoryName
      const vm = new ExamListViewModel()
      await vm.loadPapersByCategory(target)
      // 逐条核对：结果数量 = 试卷池中该科目的实际套数，且 categoryName 全部命中
      let actual = 0
      for (const p of MOCK_PAPERS) {
        if (p.categoryName === target) {
          actual++
        }
      }
      expect(vm.papers.length).assertEqual(actual)
      for (const p of vm.papers) {
        expect(p.categoryName).assertEqual(target)
      }
    })

    // 边界：不存在的科目返回空数组（空态由 View 渲染，VM 不崩不报错）
    it('should_return_empty_for_unknown_category', 0, async () => {
      const vm = new ExamListViewModel()
      const res = await vm.loadPapersByCategory('不存在的科目')
      expect(res.ok).assertEqual(true)
      expect(vm.papers.length).assertEqual(0)
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new ExamListViewModel()
      await vm.loadPapersByCategory(MOCK_PAPERS[0].categoryName)
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })
  })
}
