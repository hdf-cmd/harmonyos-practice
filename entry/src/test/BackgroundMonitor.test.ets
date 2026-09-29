// 【知识点 3.2.8 hypium】BackgroundMonitor 的用例设计示例：切后台计数的四条规则。
// 设计思路与 PaperUtils.test 同口径：一条规则 = 正常路径 + 边界 + 不变式。
//   ① start 要同时做到"进入监视"和"清零"，只断言 monitoring 就漏掉了清零那一半；
//   ② 监视中 increase 逐次 +1，连测三次并每次都对账，防"只加第一次"和"一次多加"；
//   ③ 非监视态一律不计数——未 start 与已 stop 是两个不同入口，各自一条（合在一起测不出"漏判 stop"）；
//   ④ stop 只关监视不清零，因为结果页还要读这一场的次数。
// 【为什么每条用例各自 new 一个实例】BackgroundMonitor 是可变状态对象，共用实例会让上一条的
//   count 漏进下一条，一旦失败分不清是谁弄脏了状态。
// 【为什么这里不碰 AppStorageV2】connect 是与 UI 实例绑定的能力，本地单测跑在非 UI 环境。
//   只测类自身的规则，"取实例那一行"留在 EntryAbility / 页面侧——与 FontSetting.test 同理。
import { describe, it, expect } from '@ohos/hypium'
import { BackgroundMonitor } from '@zhititong/common'

export default function backgroundMonitorTest() {
  // 套件名：被测类名 + Test，一看便知测的是谁
  describe('backgroundMonitorTest', () => {
    // ① start：先把 count 造成非 0，才测得出"清零"而不是"它本来就是 0"
    it('should_start_monitoring_and_reset_count', 0, () => {
      const monitor: BackgroundMonitor = new BackgroundMonitor()
      monitor.count = 7
      monitor.start()
      expect(monitor.monitoring).assertTrue()
      expect(monitor.count).assertEqual(0)
    })

    // ② 监视中 increase：连续三次逐次 +1，每加一次就断言一次
    it('should_increase_one_by_one_while_monitoring', 0, () => {
      const monitor: BackgroundMonitor = new BackgroundMonitor()
      monitor.start()
      monitor.increase()
      expect(monitor.count).assertEqual(1)
      monitor.increase()
      expect(monitor.count).assertEqual(2)
      monitor.increase()
      expect(monitor.count).assertEqual(3)
    })

    // ③ 未 start（默认态就是 monitoring=false）：increase 一律不计
    it('should_ignore_increase_before_start', 0, () => {
      const monitor: BackgroundMonitor = new BackgroundMonitor()
      expect(monitor.monitoring).assertFalse()
      monitor.increase()
      monitor.increase()
      expect(monitor.count).assertEqual(0)
    })

    // ③' 已 stop：先证明它计数过，再证明 stop 之后再加两次仍是原值——
    //    少了前半段，"从头到尾都是 0"也能骗过这条断言
    it('should_ignore_increase_after_stop', 0, () => {
      const monitor: BackgroundMonitor = new BackgroundMonitor()
      monitor.start()
      monitor.increase()
      expect(monitor.count).assertEqual(1)
      monitor.stop()
      monitor.increase()
      monitor.increase()
      expect(monitor.count).assertEqual(1)
    })

    // ④ stop：只关监视，计数保留给结果页读
    it('should_keep_count_after_stop', 0, () => {
      const monitor: BackgroundMonitor = new BackgroundMonitor()
      monitor.start()
      monitor.increase()
      monitor.increase()
      monitor.increase()
      monitor.stop()
      expect(monitor.monitoring).assertFalse()
      expect(monitor.count).assertEqual(3)
    })
  })
}
