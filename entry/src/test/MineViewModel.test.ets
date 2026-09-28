// MineViewModel 单元测试：个人中心业务规则的验证
//
// 【被测规则】loadUserInfo 与占位数据自洽、loading 复位、
//   菜单三项且顺序固定、logout 返回 Result.ok。
import { describe, it, expect } from '@ohos/hypium'
import { MineViewModel } from '../main/ets/features/mine/viewmodel/MineViewModel'
import { MOCK_MINE_USER } from '../main/ets/features/mine/model/MockMineData'

export default function mineViewModelTest() {
  describe('mineViewModelTest', () => {
    // 常规：加载成功，Result.ok，用户名/签名与占位数据逐字一致（视觉零变化的底线）
    it('should_load_user_info_ok', 0, async () => {
      const vm = new MineViewModel()
      const res = await vm.loadUserInfo()
      expect(res.ok).assertEqual(true)
      expect(vm.userName).assertEqual(MOCK_MINE_USER.userName)
      expect(vm.signature).assertEqual(MOCK_MINE_USER.signature)
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    it('should_reset_loading_after_load', 0, async () => {
      const vm = new MineViewModel()
      await vm.loadUserInfo()
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 业务承诺：菜单固定三项且顺序正确（顺序=页面渲染顺序，改错顺序即视觉回归）；
    //   原第三项"字体大小"已改由 MineView 在同位置渲染成字号档位行，不再属于菜单数据
    it('should_have_three_menu_items_in_order', 0, () => {
      const vm = new MineViewModel()
      expect(vm.menuItems.length).assertEqual(3)
      expect(vm.menuItems[0]).assertEqual('考试记录')
      expect(vm.menuItems[1]).assertEqual('我的证书')
      expect(vm.menuItems[2]).assertEqual('关于智题通')
    })

    // 业务承诺：logout 返回 ok（View 凭 res.ok 决定是否清根栈），且 loading 复位
    it('should_logout_ok_and_reset_loading', 0, async () => {
      const vm = new MineViewModel()
      const res = await vm.logout()
      expect(res.ok).assertEqual(true)
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })
  })
}
