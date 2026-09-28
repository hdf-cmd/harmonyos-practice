// FontSetting 单元测试：字号偏移模型的纯逻辑。
//
// 【被测规则】① sizeOf 的"基准 + 偏移"换算与非正数兜底；② 档位下标与偏移量的双向映射，
//   以及"存盘值不在档位表里"时的回落；③ stepTo/increase/decrease/reset 的越界与空操作约定。
// 【为什么不碰 PersistenceV2】connect 是与 UI 实例绑定的能力，本地单测跑在非 UI 环境。
//   所以这里只 new FontSetting() 测纯状态逻辑——这正是"取实例那一行留在 UI 侧"换来的可测性。
// 【断言为什么引用 FONT_LEVELS 而不是写死 -4/0/4】档位表是唯一事实源，
//   以后加一档减一档，这些用例应继续成立；写死数值会在改档位时假红或假绿。
import { describe, it, expect } from '@ohos/hypium'
import { FONT_LEVELS, FontSetting } from '../main/ets/model/FontSetting'

export default function fontSettingTest() {
  describe('fontSettingSizeOfTest', () => {
    // 默认即标准档：偏移 0 时实际字号 == 基准字号（视觉零改动的底线）
    it('should_keep_base_size_at_default_offset', 0, () => {
      const font: FontSetting = new FontSetting()
      expect(font.fontSize).assertEqual(0)
      expect(font.sizeOf(16)).assertEqual(16)
    })

    // 正常路径：偏移量加到基准上，两端各测一次
    it('should_add_offset_to_base', 0, () => {
      const font: FontSetting = new FontSetting()
      font.fontSize = FONT_LEVELS[0].size
      expect(font.sizeOf(16)).assertEqual(16 + FONT_LEVELS[0].size)
      font.fontSize = FONT_LEVELS[FONT_LEVELS.length - 1].size
      expect(font.sizeOf(16)).assertEqual(16 + FONT_LEVELS[FONT_LEVELS.length - 1].size)
    })

    // 边界兜底：基准很小又被调到最小档时，算出 0 或负数必须兜到 1，否则文字直接不渲染
    it('should_floor_at_one_for_non_positive_result', 0, () => {
      const font: FontSetting = new FontSetting()
      font.fontSize = FONT_LEVELS[0].size
      expect(font.sizeOf(4)).assertEqual(1)
      expect(font.sizeOf(2)).assertEqual(1)
      expect(font.sizeOf(0)).assertEqual(1)
    })
  })

  describe('fontSettingLevelTest', () => {
    // 双向映射：每一档的 size 都能反查出自己的下标
    it('should_map_every_level_size_to_its_own_index', 0, () => {
      const font: FontSetting = new FontSetting()
      for (let i = 0; i < FONT_LEVELS.length; i++) {
        font.fontSize = FONT_LEVELS[i].size
        expect(font.levelIndex()).assertEqual(i)
      }
    })

    // 容错：存盘值可能来自旧版本或被手改，不在档位表里时回落标准档而不是越界
    it('should_fall_back_to_standard_for_offset_not_in_levels', 0, () => {
      const font: FontSetting = new FontSetting()
      font.fontSize = 99
      expect(font.levelIndex()).assertEqual(FontSetting.standardIndex())
      expect(font.levelLabel()).assertEqual(FONT_LEVELS[FontSetting.standardIndex()].label)
    })

    // 约定：标准档就是"偏移量为 0"的那一档，standardIndex 必须指向它
    it('should_point_standard_index_at_zero_offset_level', 0, () => {
      expect(FONT_LEVELS[FontSetting.standardIndex()].size).assertEqual(0)
    })
  })

  describe('fontSettingStepTest', () => {
    // 正常路径：跳到指定档位，值与返回值都对
    it('should_jump_to_target_level', 0, () => {
      const font: FontSetting = new FontSetting()
      const last: number = FONT_LEVELS.length - 1
      expect(font.stepTo(last)).assertEqual(true)
      expect(font.fontSize).assertEqual(FONT_LEVELS[last].size)
      expect(font.stepTo(0)).assertEqual(true)
      expect(font.fontSize).assertEqual(FONT_LEVELS[0].size)
    })

    // 越界：返回 false 且不写值——保证 fontSize 永远只取档位表里的值
    it('should_reject_out_of_range_index_without_writing', 0, () => {
      const font: FontSetting = new FontSetting()
      font.stepTo(1)
      const before: number = font.fontSize
      expect(font.stepTo(-1)).assertEqual(false)
      expect(font.stepTo(FONT_LEVELS.length)).assertEqual(false)
      expect(font.fontSize).assertEqual(before)
    })

    // 空操作：选到当前档返回 false，避免白触发一次自动落盘
    it('should_return_false_when_already_on_target_level', 0, () => {
      const font: FontSetting = new FontSetting()
      expect(font.stepTo(FontSetting.standardIndex())).assertEqual(false)
      expect(font.fontSize).assertEqual(0)
    })

    // 逐级增减：一次只动一档，且方向正确
    it('should_step_up_and_down_by_one_level', 0, () => {
      const font: FontSetting = new FontSetting()
      expect(font.increase()).assertEqual(true)
      expect(font.fontSize).assertEqual(FONT_LEVELS[FontSetting.standardIndex() + 1].size)
      expect(font.decrease()).assertEqual(true)
      expect(font.decrease()).assertEqual(true)
      expect(font.fontSize).assertEqual(FONT_LEVELS[FontSetting.standardIndex() - 1].size)
    })

    // 两端撞墙：最小档再减、最大档再加都不动
    it('should_stop_at_both_ends', 0, () => {
      const font: FontSetting = new FontSetting()
      const last: number = FONT_LEVELS.length - 1
      font.stepTo(0)
      expect(font.decrease()).assertEqual(false)
      expect(font.fontSize).assertEqual(FONT_LEVELS[0].size)
      font.stepTo(last)
      expect(font.increase()).assertEqual(false)
      expect(font.fontSize).assertEqual(FONT_LEVELS[last].size)
    })

    // 边界标志：供 UI 置灰 +/- 按钮，必须与两端一致
    it('should_report_boundary_flags', 0, () => {
      const font: FontSetting = new FontSetting()
      const last: number = FONT_LEVELS.length - 1
      font.stepTo(0)
      expect(font.canDecrease()).assertEqual(false)
      expect(font.canIncrease()).assertEqual(true)
      font.stepTo(last)
      expect(font.canIncrease()).assertEqual(false)
      expect(font.canDecrease()).assertEqual(true)
      font.stepTo(FontSetting.standardIndex())
      expect(font.canIncrease()).assertEqual(true)
      expect(font.canDecrease()).assertEqual(true)
    })

    // 复位：非标准档时回标准并返回 true，已在标准档返回 false
    it('should_reset_to_standard_and_report_noop', 0, () => {
      const font: FontSetting = new FontSetting()
      font.stepTo(FONT_LEVELS.length - 1)
      expect(font.reset()).assertEqual(true)
      expect(font.fontSize).assertEqual(0)
      expect(font.reset()).assertEqual(false)
    })
  })
}
