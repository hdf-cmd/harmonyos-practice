// ExamSubjectViewModel 单元测试：科目聚合业务的规则验证
//
// 【被测规则】groupByCategory 的业务承诺：分组数 = 试卷池去重科目数、
//   每组 count = 该科目在试卷池中的实际套数、组顺序与首次出现顺序一致。
import { describe, it, expect } from '@ohos/hypium'
import { ExamSubjectViewModel } from '../main/ets/features/exam/viewmodel/ExamSubjectViewModel'
import { PaperInfo } from '../main/ets/common/model/QuestionModel'
import { MOCK_PAPERS } from '../main/ets/common/mock/MockExamData'

export default function examSubjectViewModelTest() {
  describe('examSubjectViewModelTest', () => {
    // 常规 + 业务承诺：加载成功，Result.ok；分组数 = 试卷池去重后的科目数
    it('should_group_count_equal_distinct_categories', 0, async () => {
      const vm = new ExamSubjectViewModel()
      const res = await vm.loadSubjectGroups()
      expect(res.ok).assertEqual(true)
      // 统计去重科目（按首次出现顺序）
      const names: string[] = []
      for (const p of MOCK_PAPERS) {
        if (names.indexOf(p.categoryName) < 0) {
          names.push(p.categoryName)
        }
      }
      expect(vm.groups.length).assertEqual(names.length)
    })

    // 业务承诺：每科 count = 该科目在试卷池里的实际套数（聚合不许数错）
    it('should_count_match_papers_per_category', 0, async () => {
      const vm = new ExamSubjectViewModel()
      await vm.loadSubjectGroups()
      for (const g of vm.groups) {
        let actual = 0
        for (const p of MOCK_PAPERS) {
          if (p.categoryName === g.categoryName) {
            actual++
          }
        }
        expect(g.count).assertEqual(actual)
      }
    })

    // 业务承诺：组顺序与科目在试卷池中的首次出现顺序一致（Grid 渲染顺序即此顺序）
    it('should_keep_first_occurrence_order', 0, async () => {
      const vm = new ExamSubjectViewModel()
      await vm.loadSubjectGroups()
      const names: string[] = []
      for (const p of MOCK_PAPERS) {
        if (names.indexOf(p.categoryName) < 0) {
          names.push(p.categoryName)
        }
      }
      for (let i = 0; i < names.length; i++) {
        expect(vm.groups[i].categoryName).assertEqual(names[i])
      }
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new ExamSubjectViewModel()
      await vm.loadSubjectGroups()
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })
  })
}
