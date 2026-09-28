// HomeViewModel 单元测试：推荐试卷业务的规则验证
//
// 【被测规则】loadRecommendedPapers 的业务承诺：恰好抽 4 张、无重复、
//   全部来自试卷池、loading 无论成败最终复位。
import { describe, it, expect } from '@ohos/hypium'
import { HomeViewModel } from '../main/ets/features/home/viewmodel/HomeViewModel'
import { PaperInfo, MOCK_PAPERS } from '@zhititong/common'

export default function homeViewModelTest() {
  describe('homeViewModelTest', () => {
    // 常规：加载成功，Result.ok，恰好 4 张（推荐位数量是业务承诺）
    it('should_load_four_recommended_papers', 0, async () => {
      const vm = new HomeViewModel()
      const res = await vm.loadRecommendedPapers()
      expect(res.ok).assertEqual(true)
      expect(vm.papers.length).assertEqual(4)
    })

    // 业务承诺：4 张互不重复（洗牌抽取不许出现同一张卷两次）
    it('should_load_unique_papers', 0, async () => {
      const vm = new HomeViewModel()
      await vm.loadRecommendedPapers()
      const ids: string[] = []
      for (const p of vm.papers) {
        expect(ids.indexOf(p.id) < 0).assertEqual(true)   // 出现过的 id 不许再出现
        ids.push(p.id)
      }
    })

    // 业务承诺：每张都来自试卷池（不许凭空造卷，id 必须能在 MOCK_PAPERS 找到）
    it('should_only_pick_from_paper_pool', 0, async () => {
      const vm = new HomeViewModel()
      await vm.loadRecommendedPapers()
      const poolIds: string[] = []
      for (const p of MOCK_PAPERS) {
        poolIds.push(p.id)
      }
      for (const p of vm.papers) {
        expect(poolIds.indexOf(p.id) >= 0).assertEqual(true)
      }
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new HomeViewModel()
      await vm.loadRecommendedPapers()
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })
  })
}
