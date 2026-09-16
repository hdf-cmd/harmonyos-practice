// LoginViewModel 单元测试：MVVM 可测性红利的兑现
//
// 【为什么这个文件能存在】重构前，登录校验逻辑长在 LoginPage 的 onClick 里，
//   想验证"密码少于 6 位要报错"只能开预览器手点一遍。
//   4-4 把业务搬进 LoginViewModel（全文零 UI）后，测试里 new 一个出来就能跑——
//   不启动预览器、不点一次界面，直接验证业务规则。
// 【注意】用例都是 async：submit 是异步方法，hypium 支持直接 await。
import { describe, it, expect } from '@ohos/hypium'
import { LoginViewModel } from '../main/ets/features/login/viewmodel/LoginViewModel'

export default function loginViewModelTest() {
  describe('loginViewModelSubmitTest', () => {
    // 常规：空用户名直接失败，且给出可展示的错误信息
    it('should_fail_when_username_empty', 0, async () => {
      const vm = new LoginViewModel()
      vm.username = ''
      vm.password = '123456'
      const res = await vm.submit()
      expect(res.ok).assertEqual(false)
      expect(vm.errorMessage.length > 0).assertEqual(true)
    })

    // 常规：正确账号登录成功，用户信息就位
    it('should_login_success_with_admin', 0, async () => {
      const vm = new LoginViewModel()
      vm.username = 'admin'
      vm.password = '123456'
      const res = await vm.submit()
      expect(res.ok).assertEqual(true)
      expect(vm.userInfo?.username).assertEqual('admin')
    })

    // 常规：密码错误
    it('should_fail_with_wrong_password', 0, async () => {
      const vm = new LoginViewModel()
      vm.username = 'admin'
      vm.password = '654321'
      const res = await vm.submit()
      expect(res.ok).assertEqual(false)
      expect(res.errorMessage).assertEqual('用户名或密码错误')
    })

    // 常规：注册已存在用户名
    it('should_fail_register_existing_username', 0, async () => {
      const vm = new LoginViewModel()
      vm.isReg = true
      vm.username = 'admin'
      vm.password = '123456'
      vm.confirmPwd = '123456'
      const res = await vm.submit()
      expect(res.ok).assertEqual(false)
      expect(res.errorMessage).assertEqual('用户名已存在')
    })

    // 常规：注册新用户成功并自动登录
    it('should_register_and_auto_login', 0, async () => {
      const vm = new LoginViewModel()
      vm.isReg = true
      vm.username = 'student01'
      vm.password = '123456'
      vm.confirmPwd = '123456'
      const res = await vm.submit()
      expect(res.ok).assertEqual(true)
      expect(vm.userInfo?.username).assertEqual('student01')
    })

    // 隐含约定：无论成败，loading 最终必须回到 false（finally 兜底）
    // 漏了这条约定，真实界面会在登录失败后永远转圈
    it('should_reset_loading_after_submit', 0, async () => {
      const vm = new LoginViewModel()
      vm.username = 'admin'
      vm.password = '654321'   // 故意失败
      await vm.submit()
      expect(vm.loading).assertEqual(false)
    })
  })
}