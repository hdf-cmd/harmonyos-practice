// AttemptHistoryViewModel 单元测试：分页列表规则的验证
//
// 【为什么这里不用 hamock】分页要看"第几页"决定返回什么，而 hamock 的
//   ArgumentMatchers 每个方法只能给 0~1 个匹配器（多参方法等于全匹配），
//   没法按 page 分支。改用一个手写假门（ExamService 子类覆写 getAttempts），
//   既保留"零网络"的前提，又能精确控制每一页的返回与调用次数。
import { describe, it, expect } from '@ohos/hypium'
import { AttemptHistoryViewModel } from '../main/ets/features/exam/viewmodel/AttemptHistoryViewModel'
import { ExamService, AttemptRecord, AttemptPage } from '../main/ets/features/exam/service/ExamService'

function rec(i: number): AttemptRecord {
  const r: AttemptRecord = {
    id: `r${i}`, startTime: '2026-10-19 09:00:00', score: i, passed: i >= 6,
    usedTime: 60 + i, submitType: 'MANUAL', paperId: 'P1', paperName: '基础卷'
  }
  return r
}

function makeRange(from: number, count: number): AttemptRecord[] {
  const out: AttemptRecord[] = []
  for (let i = 0; i < count; i++) {
    out.push(rec(from + i))
  }
  return out
}

// 假门：第 1 页固定 10 条，第 2 页由构造参数决定；total 固定 12
class PagingService extends ExamService {
  calls: number = 0
  private second: AttemptRecord[]

  constructor(second: AttemptRecord[]) {
    super()
    this.second = second
  }

  async getAttempts(page: number, size: number): Promise<AttemptPage> {
    this.calls++
    const p: AttemptPage = {
      records: page === 1 ? makeRange(0, 10) : this.second,
      total: 12,
      page: page,
      size: size
    }
    return p
  }
}

export default function attemptHistoryViewModelTest() {
  describe('attemptHistoryViewModelTest', () => {
    // 首屏：10 条 + 还有下一页
    it('should_load_first_page_and_keep_has_more', 0, async () => {
      const svc = new PagingService(makeRange(10, 2))
      const vm = new AttemptHistoryViewModel(svc)
      await vm.loadFirstPage()
      expect(vm.records.length).assertEqual(10)
      expect(vm.total).assertEqual(12)
      expect(vm.hasMore).assertEqual(true)
      expect(vm.loading).assertEqual(false)
    })

    // 触底：追加第 2 页，累计 12 条，hasMore 翻转
    it('should_append_second_page_and_stop', 0, async () => {
      const svc = new PagingService(makeRange(10, 2))
      const vm = new AttemptHistoryViewModel(svc)
      await vm.loadFirstPage()
      await vm.loadMore()
      expect(vm.records.length).assertEqual(12)
      expect(vm.hasMore).assertEqual(false)
    })

    // 到底后再调 loadMore 不再发请求
    it('should_not_request_again_after_end', 0, async () => {
      const svc = new PagingService(makeRange(10, 2))
      const vm = new AttemptHistoryViewModel(svc)
      await vm.loadFirstPage()
      await vm.loadMore()
      await vm.loadMore()
      expect(svc.calls).assertEqual(2)
    })

    // 跨页重复的记录按 id 去重，累计条数 = 唯一条数
    it('should_drop_duplicates_across_pages', 0, async () => {
      // 第 2 页把第 1 页最后一条 r9 又返回了一次
      const second: AttemptRecord[] = [rec(9), rec(10)]
      const svc = new PagingService(second)
      const vm = new AttemptHistoryViewModel(svc)
      await vm.loadFirstPage()
      await vm.loadMore()
      expect(vm.records.length).assertEqual(11)
      const ids: Set<string> = new Set<string>(vm.records.map((r: AttemptRecord): string => r.id))
      expect(ids.size).assertEqual(11)
    })

    // 交卷方式中文与结果页同一口径
    it('should_translate_submit_type', 0, () => {
      const vm = new AttemptHistoryViewModel(new PagingService([]))
      expect(vm.getSubmitTypeLabel('MANUAL')).assertEqual('手动交卷')
      expect(vm.getSubmitTypeLabel('TIMEOUT')).assertEqual('超时自动交卷')
      expect(vm.getSubmitTypeLabel('TAB_SWITCH')).assertEqual('切屏超限自动交卷')
    })
  })
}
