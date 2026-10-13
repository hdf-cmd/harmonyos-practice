// LoginViewModel 单元测试：MVVM 可测性红利的兑现（hamock 化）
//
// 【为什么这个文件能存在】重构前，登录校验逻辑长在 LoginPage 的 onClick 里，
//   想验证"密码少于 6 位要报错"只能开预览器手点一遍。
//   4-4 把业务搬进 LoginViewModel（全文零 UI）后，测试里 new 一个出来就能跑——
//   不启动预览器、不点一次界面，直接验证业务规则。
// 【为什么用 hamock】接真后端后，原单测退化为集成测试：依赖后端启动、注册测试污染真库、
//   断言文案过期。这里 mock 掉 LoginService 与 SessionManager.save，让单测回到零依赖、可重复。
// 【注意】用例都是 async：submit 是异步方法，hypium 支持直接 await。
import { describe, it, expect, beforeEach } from '@ohos/hypium'
import { MockKit, when, ArgumentMatchers } from '@ohos/hamock'
import { LoginViewModel } from '../main/ets/features/login/viewmodel/LoginViewModel'
import { LoginService, LoginResult } from '../main/ets/features/login/service/LoginService'
import { SessionManager, SessionUserData } from '@zhititong/common'

export default function loginViewModelTest() {
  describe('loginViewModelSubmitTest', () => {
    let service: LoginService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new LoginService()
    })

    // 常规：空用户名直接失败，且给出可展示的错误信息
    it('should_fail_when_username_empty', 0, async () => {
      const vm = new LoginViewModel(service)
      vm.username = ''
      vm.password = '123456'
      const res = await vm.submit()
      expect(res.ok).assertEqual(false)
      expect(vm.errorMessage.length > 0).assertEqual(true)
    })

    // 常规：正确账号登录成功，用户信息就位
    it('should_login_success_with_admin', 0, async () => {
      const mockLogin: Function = mocker.mockFunc(service, service.login)
      when(mockLogin)(ArgumentMatchers.any).afterReturn(Promise.resolve({
        token: 'fake-token',
        userInfo: { id: '1', username: 'admin', role: '考生' } as SessionUserData
      } as LoginResult))

      const saveMock: Function = mocker.mockFunc(SessionManager, SessionManager.save)
      when(saveMock)(ArgumentMatchers.any).afterReturn(Promise.resolve())

      const vm = new LoginViewModel(service)
      vm.username = 'admin'
      vm.password = 'admin123'
      const res = await vm.submit()
      expect(res.ok).assertEqual(true)
      expect(vm.userInfo?.username).assertEqual('admin')
    })

    // 常规：密码错误
    it('should_fail_with_wrong_password', 0, async () => {
      const mockLogin: Function = mocker.mockFunc(service, service.login)
      when(mockLogin)(ArgumentMatchers.any).afterReturn(
        Promise.reject(new Error('账号或密码错误')))

      const vm = new LoginViewModel(service)
      vm.username = 'admin'
      vm.password = 'wrong-password'
      const res = await vm.submit()
      expect(res.ok).assertEqual(false)
      expect(res.errorMessage).assertEqual('账号或密码错误')
    })

    // 常规：注册已存在用户名
    it('should_fail_register_existing_username', 0, async () => {
      const mockRegister: Function = mocker.mockFunc(service, service.register)
      when(mockRegister)(ArgumentMatchers.any).afterReturn(
        Promise.reject(new Error('账号已存在')))

      const vm = new LoginViewModel(service)
      vm.isReg = true
      vm.username = 'student'
      vm.password = '123456'
      vm.confirmPwd = '123456'
      const res = await vm.submit()
      expect(res.ok).assertEqual(false)
      expect(res.errorMessage).assertEqual('账号已存在')
    })

    // 常规：注册新用户成功并自动登录
    it('should_register_and_auto_login', 0, async () => {
      const mockRegister: Function = mocker.mockFunc(service, service.register)
      when(mockRegister)(ArgumentMatchers.any).afterReturn(Promise.resolve(
        { id: '2', username: 'student01', role: '考生' } as SessionUserData))

      const mockLogin: Function = mocker.mockFunc(service, service.login)
      when(mockLogin)(ArgumentMatchers.any).afterReturn(Promise.resolve({
        token: 'fake-token-01',
        userInfo: { id: '2', username: 'student01', role: '考生' } as SessionUserData
      } as LoginResult))

      const saveMock: Function = mocker.mockFunc(SessionManager, SessionManager.save)
      when(saveMock)(ArgumentMatchers.any).afterReturn(Promise.resolve())

      const vm = new LoginViewModel(service)
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
      const mockLogin: Function = mocker.mockFunc(service, service.login)
      when(mockLogin)(ArgumentMatchers.any).afterReturn(
        Promise.reject(new Error('账号或密码错误')))

      const vm = new LoginViewModel(service)
      vm.username = 'admin'
      vm.password = 'wrong-password'   // 故意失败
      await vm.submit()
      expect(vm.loading).assertEqual(false)
    })
  })
}
