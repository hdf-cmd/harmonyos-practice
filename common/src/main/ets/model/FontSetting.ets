/**
 * 字号设置：存的是"偏移量"，不是绝对字号。
 *
 * 【为什么存偏移量】页面各处文字本来有自己的层级（标题 24 / 副标题 18 / 正文 16 / 辅助 14）。
 *   若存绝对字号，用户一改就把所有层级塌成同一个数，标题和说明文字一样大。
 *   存偏移量则每处保留自己的基准：实际字号 = 基准字号 + 偏移量，整体一起缩放、层级不变。
 * 【为什么档位是一个数组】五档的 label 与 size 只写在 FONT_LEVELS 这一处，
 *   加一档减一档只改这个数组，上下限、当前档位下标、下拉框选项全部由它推导，不留散落的魔法数。
 * 【label 为什么跟档位放在一起】Select 这类控件要显示档位名，若 label 另存一份，
 *   增减档位时两处必须同步改——单源化正是常量数组这个设计的意义。
 * 【@ObservedV2 + @Trace 只负责 UI 刷新，不负责写盘】自动落盘由 PersistenceV2 接管：
 *   只有 @Trace 属性的变更触发持久化，且被持久化的属性必须有初值（见 fontSize）。
 *   connect 那一行留在 EntryAbility 的 loadContent 成功回调里——PersistenceV2 是与 UI 实例
 *   关联的单例，放进 ViewModel 会让本地单测（跑在非 UI 环境）直接失效。
 */

// 一档字号：label 是给人看的档位名，size 是加到各处基准字号上的偏移量
export interface FontLevel {
  label: string
  size: number
}

// 五档字号偏移档位。增减档位只改这一处
export const FONT_LEVELS: FontLevel[] = [
  { label: '极小', size: -4 },
  { label: '小', size: -2 },
  { label: '标准', size: 0 },
  { label: '大', size: 2 },
  { label: '极大', size: 4 }
]

// 标准档的偏移量：档位表里没有 size 为 0 的档时用它兜底
const STANDARD_SIZE: number = 0

@ObservedV2
export class FontSetting {
  // 当前字号偏移量，0 = 标准档。必须有初值，否则 PersistenceV2 不支持持久化
  @Trace fontSize: number = STANDARD_SIZE

  // 标准档在档位数组中的下标；数组里没有 0 偏移时返回 -1（配置出错，由调用方兜底）
  static standardIndex(): number {
    return FONT_LEVELS.findIndex((level: FontLevel): boolean => level.size === STANDARD_SIZE)
  }

  // 由基准字号算出实际字号：加偏移后不足 1 时兜到 1，避免基准很小的文字被算成 0 或负数
  sizeOf(base: number): number {
    const size: number = base + this.fontSize
    return size > 0 ? size : 1
  }

  // 当前档位下标。持久化值可能来自旧版本或手改，不在档位表里时回落到标准档
  levelIndex(): number {
    const index: number = FONT_LEVELS.findIndex((level: FontLevel): boolean => level.size === this.fontSize)
    return index >= 0 ? index : FontSetting.standardIndex()
  }

  // 当前档位名：供 Select 显示；档位被删改后查不到时回落到标准档名
  levelLabel(): string {
    return FONT_LEVELS[this.levelIndex()].label
  }

  // 放大一档：已到最大档则原地不动并返回 false，调用方可据此置灰按钮
  increase(): boolean {
    return this.step(1)
  }

  // 缩小一档：已到最小档则原地不动并返回 false
  decrease(): boolean {
    return this.step(-1)
  }

  // 回到标准档：已在标准档返回 false（避免无意义的写盘触发）
  reset(): boolean {
    return this.stepTo(FontSetting.standardIndex())
  }

  canIncrease(): boolean {
    return this.levelIndex() < FONT_LEVELS.length - 1
  }

  canDecrease(): boolean {
    return this.levelIndex() > 0
  }

  // 直接跳到指定档位（Select 的 onSelect 走这里）：越界一律不写值
  stepTo(index: number): boolean {
    if (index < 0 || index >= FONT_LEVELS.length) {
      return false
    }
    const target: number = FONT_LEVELS[index].size
    if (target === this.fontSize) {
      return false
    }
    this.fontSize = target
    return true
  }

  // 档位移动的唯一实现：越界一律不写值，保证 fontSize 永远只取档位表里的值
  private step(delta: number): boolean {
    return this.stepTo(this.levelIndex() + delta)
  }
}
