// ExamSubjectViewModel 单元测试：科目聚合业务的规则验证（hamock 化）
//
// 【被测规则】groupByCategory 的业务承诺：分组数 = 试卷池去重科目数、
//   每组 count = 该科目在试卷池中的实际套数、组顺序与首次出现顺序一致。
// 【为什么用 hamock】把 PaperService.getPapers mock 成返回固定夹具 MOCK_PAPERS，
//   根除后端依赖与数据污染，单测可重复。
import { describe, it, expect, beforeEach } from '@ohos/hypium'
import { MockKit, when } from '@ohos/hamock'
import { ExamSubjectViewModel } from '../main/ets/features/exam/viewmodel/ExamSubjectViewModel'
import { PaperService } from '../main/ets/features/exam/service/PaperService'
import { MOCK_PAPERS } from '@zhititong/common'

export default function examSubjectViewModelTest() {
  describe('examSubjectViewModelTest', () => {
    let service: PaperService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new PaperService()
      const mockGetPapers: Function = mocker.mockFunc(service, service.getPapers)
      when(mockGetPapers)().afterReturn(Promise.resolve(MOCK_PAPERS))
    })

    // 常规 + 业务承诺：加载成功，Result.ok；分组数 = 试卷池去重后的科目数
    it('should_group_count_equal_distinct_categories', 0, async () => {
      const vm = new ExamSubjectViewModel(service)
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
      const vm = new ExamSubjectViewModel(service)
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
      const vm = new ExamSubjectViewModel(service)
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
      const vm = new ExamSubjectViewModel(service)
      await vm.loadSubjectGroups()
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })
  })
}
