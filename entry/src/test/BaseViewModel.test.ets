// BaseViewModel.handleErrorAction 单元测试：错误区那颗按钮的分支决策
//
// 【被测规则】（2026-11-06 从 View 上收到 VM 的那段判断）
//   authExpired 为真 → 只清会话，不重试；为假 → 只重试，不动会话。两条互斥。
// 【为什么值得单测】这段原先写在 View 的 onClick 里，只能开模拟器手点；
//   收进 VM 后它变成零 UI 的纯逻辑，正是分层换来的可测性红利。
// 【为什么不打断言在 session.loggedIn 上——踩出来的】
//   第一版写的是 `expect(user.loggedIn).assertEqual(false)`，红了：产品代码里
//   `SessionManager.logout()` 的 `user.loggedIn = false` 明明是同步的。
//   差别在于 user 来自 AppStorageV2 全局单例，而 **LocalUnit 环境下测试侧 connect 到的
//   与 SessionManager 内部 connect 到的不是同一个实例**，读不到那次写。
//   真机上登出是可用的（同日装机实测：点登出 → 登录页出现、TabBar 归零）。
//   ⇒ 这个单元真正该验的是"分支走了哪条"，所以用子类覆盖把两条出口都变成可数的记号，
//     不依赖全局单例，也不依赖 mock 框架的调用计数 API。
import { describe, it, expect } from '@ohos/hypium'
import { BaseViewModel } from '@zhititong/common'

/**
 * 两条出口都记一笔：
 *   clearExpiredSession 覆盖掉父类那句 SessionManager.logout()（外部副作用，单测里不可观测），
 *   retryLoad 父类给的是空实现，这里覆盖成计数。
 * 于是"走了哪条分支"变成两个纯本地整数，断言与运行环境无关。
 */
class ProbingViewModel extends BaseViewModel {
  cleared: number = 0
  retried: number = 0

  clearExpiredSession(): void {
    this.cleared += 1
  }

  protected retryLoad(): void {
    this.retried += 1
  }
}

export default function baseViewModelTest() {
  describe('baseViewModelTest', () => {
    // 401 分支：清会话，且**不许**同时重试
    it('should_clear_session_and_not_retry_when_auth_expired', 0, () => {
      const vm = new ProbingViewModel()
      vm.authExpired = true

      vm.handleErrorAction()

      expect(vm.cleared).assertEqual(1)   // 该发生的
      expect(vm.retried).assertEqual(0)   // 不该发生的
    })

    // 非 401 分支：重试加载，且**不许**把人家会话清了
    it('should_retry_and_keep_session_when_error_is_not_auth', 0, () => {
      const vm = new ProbingViewModel()
      vm.authExpired = false

      vm.handleErrorAction()

      expect(vm.retried).assertEqual(1)    // 该发生的：重试被调到，且只调一次
      expect(vm.cleared).assertEqual(0)    // 不该发生的：普通网络错误不该把人登出
    })

    // 分支互斥：两条各跑一次，计数必须各自停在"只走了一条"的形状上
    it('should_not_leak_state_between_the_two_branches', 0, () => {
      const expired = new ProbingViewModel()
      expired.authExpired = true
      expired.handleErrorAction()
      expect(expired.cleared).assertEqual(1)
      expect(expired.retried).assertEqual(0)

      const ordinary = new ProbingViewModel()
      ordinary.authExpired = false
      ordinary.handleErrorAction()
      expect(ordinary.retried).assertEqual(1)
      expect(ordinary.cleared).assertEqual(0)
    })

    // 冒牌实现专杀：把 handleErrorAction 写成"两条都调"会同时违反上面两条的 0 断言，
    //   写成"一条都不调"会违反 1 断言。这一条再补一个方向——authExpired 反复翻转时不许累积。
    it('should_be_idempotent_across_repeated_taps', 0, () => {
      const vm = new ProbingViewModel()
      vm.authExpired = false
      vm.handleErrorAction()
      vm.handleErrorAction()
      expect(vm.retried).assertEqual(2)   // 用户连点两次重试，就该真的重试两次
      expect(vm.cleared).assertEqual(0)

      vm.authExpired = true
      vm.handleErrorAction()
      expect(vm.cleared).assertEqual(1)   // 切到 401 后走的是清会话
      expect(vm.retried).assertEqual(2)   // 且不再追加重试
    })
  })
}
