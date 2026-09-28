// 【知识点 3.2.8 hypium】formatDuration 的用例设计示例。
// 设计思路：格式化函数重点测"边界值"——最容易出 bug 的往往是 0、整除、临界这几类输入。
// 四条用例分别覆盖：常规值 / 整分钟（60）/ 不足一分钟（59）/ 零值（0）。
// 另外两条格式约定也被断言固定下来：秒位不省略、分位不省略（防止后人"优化"格式破坏契约）。
import { describe, it, expect } from '@ohos/hypium'
import { formatDuration } from '@zhititong/common'

export default function timeUtilsTest() {
  describe('formatDurationTest', () => {
    // 断言1（常规值）：754 秒 = 12 分 34 秒
    it('should_format_754_as_12min34s', 0, () => {
      expect(formatDuration(754)).assertEqual('12 分 34 秒')
    })
    // 断言2（整分钟边界）：60 秒 = 1 分 0 秒（秒位"0"不省略）
    it('should_format_60_as_1min0s', 0, () => {
      expect(formatDuration(60)).assertEqual('1 分 0 秒')
    })
    // 断言3（不足一分钟边界）：59 秒 = 0 分 59 秒（分位"0"不省略）
    it('should_format_59_as_0min59s', 0, () => {
      expect(formatDuration(59)).assertEqual('0 分 59 秒')
    })
    // 断言4（零值边界）：0 秒 = 0 分 0 秒
    it('should_format_0_as_0min0s', 0, () => {
      expect(formatDuration(0)).assertEqual('0 分 0 秒')
    })
  })
}
