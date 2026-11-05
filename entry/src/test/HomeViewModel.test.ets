// HomeViewModel 单元测试：推荐试卷业务的规则验证（hamock 化）
//
// 【被测规则】loadRecommendedPapers 的业务承诺：恰好抽 4 张、无重复、
//   全部来自试卷池、loading 无论成败最终复位。
// 【为什么用 hamock】接真后端后，原单测退化为集成测试（依赖后端、数据污染、断言过期）。
//   这里把 PaperService.getPapers mock 成返回固定夹具 MOCK_PAPERS，单测回到毫秒级、可重复。
import { describe, it, expect, beforeEach } from '@ohos/hypium'
import { MockKit, when } from '@ohos/hamock'
import { HomeViewModel } from '../main/ets/features/home/viewmodel/HomeViewModel'
import { PaperService } from '../main/ets/features/exam/service/PaperService'
import { PaperInfo, Result, MOCK_PAPERS, AuthExpiredError } from '@zhititong/common'

export default function homeViewModelTest() {
  describe('homeViewModelTest', () => {
    let service: PaperService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new PaperService()
      const mockGetPapers: Function = mocker.mockFunc(service, service.getPapers)
      when(mockGetPapers)().afterReturn(Promise.resolve(MOCK_PAPERS))
    })

    // 常规：加载成功，Result.ok，恰好 4 张（推荐位数量是业务承诺）
    it('should_load_four_recommended_papers', 0, async () => {
      const vm = new HomeViewModel(service)
      const res = await vm.loadRecommendedPapers()
      expect(res.ok).assertEqual(true)
      expect(vm.papers.length).assertEqual(4)
    })

    // 业务承诺：4 张互不重复（洗牌抽取不许出现同一张卷两次）
    it('should_load_unique_papers', 0, async () => {
      const vm = new HomeViewModel(service)
      await vm.loadRecommendedPapers()
      const ids: string[] = []
      for (const p of vm.papers) {
        expect(ids.indexOf(p.id) < 0).assertEqual(true)   // 出现过的 id 不许再出现
        ids.push(p.id)
      }
    })

    // 业务承诺：每张都来自试卷池（不许凭空造卷，id 必须能在 MOCK_PAPERS 找到）
    it('should_only_pick_from_paper_pool', 0, async () => {
      const vm = new HomeViewModel(service)
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
      const vm = new HomeViewModel(service)
      await vm.loadRecommendedPapers()
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 加载态契约：请求还在路上时 loading 必须已经置真——首页"推荐试卷加载中…"这块
    // UI 就挂在这个字段上，VM 漏置位（或置位在 await 之后）等于界面永远不显示
    it('should_be_loading_while_request_pending', 0, async () => {
      let resolveFn: (v: PaperInfo[]) => void = () => {}
      const pending: Promise<PaperInfo[]> =
        new Promise<PaperInfo[]>((res: (v: PaperInfo[]) => void) => { resolveFn = res })
      const mPend: Function = mocker.mockFunc(service, service.getPapers)
      when(mPend)().afterReturn(pending)

      const vm = new HomeViewModel(service)
      const inflight: Promise<Result<PaperInfo[]>> = vm.loadRecommendedPapers()
      expect(vm.loading).assertEqual(true)

      resolveFn(MOCK_PAPERS)
      await inflight
      expect(vm.loading).assertEqual(false)
    })

    // 会话失效（401）：错误类型要单独标出来，View 才有依据给"重新登录"而不是"重试"
    it('should_flag_auth_expired_on_401', 0, async () => {
      const mFail: Function = mocker.mockFunc(service, service.getPapers)
      when(mFail)().afterReturn(Promise.reject(new AuthExpiredError('登录已过期，请重新登录')))
      const vm = new HomeViewModel(service)
      const res = await vm.loadRecommendedPapers()
      expect(res.ok).assertEqual(false)
      expect(vm.authExpired).assertEqual(true)
      expect(vm.errorMessage).assertEqual('登录已过期，请重新登录')
    })

    // 反向断言：普通失败不许被标成会话失效——否则断网也会把用户往登录页踢
    it('should_not_flag_auth_expired_on_ordinary_failure', 0, async () => {
      const mFail: Function = mocker.mockFunc(service, service.getPapers)
      when(mFail)().afterReturn(Promise.reject(new Error('后端没起')))
      const vm = new HomeViewModel(service)
      await vm.loadRecommendedPapers()
      expect(vm.authExpired).assertEqual(false)
      expect(vm.errorMessage).assertEqual('后端没起')
    })

    // 复位：重新登录成功后再拉一次，authExpired 必须归 false
    // （漏复位的话，用户已经登录了页面还在提示"重新登录"）
    it('should_clear_auth_expired_after_next_success', 0, async () => {
      const vm = new HomeViewModel(service)
      const mFail: Function = mocker.mockFunc(service, service.getPapers)
      when(mFail)().afterReturn(Promise.reject(new AuthExpiredError('登录已过期，请重新登录')))
      await vm.loadRecommendedPapers()
      expect(vm.authExpired).assertEqual(true)

      const mOk: Function = mocker.mockFunc(service, service.getPapers)
      when(mOk)().afterReturn(Promise.resolve(MOCK_PAPERS))
      await vm.loadRecommendedPapers()
      expect(vm.authExpired).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
      expect(vm.papers.length).assertEqual(4)
    })
  })
}
