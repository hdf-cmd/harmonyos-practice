// CertificateViewModel 单元测试：证书列表与状态徽标翻译（hamock 化）
//
// 【被测规则】loadCertificates 装载与 loading 归位、英文枚举→中文徽标、
//   VALID 判定、失败分支。
import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium'
import { MockKit, when, ArgumentMatchers } from '@ohos/hamock'
import { CertificateViewModel } from '../main/ets/features/exam/viewmodel/CertificateViewModel'
import { ExamService, CertificateItem } from '../main/ets/features/exam/service/ExamService'

// 1 张有效 + 1 张过期（覆盖两种枚举值）
function fixtureCertificates(): CertificateItem[] {
  const valid: CertificateItem = {
    id: 'c1', certificateNo: 'CERT-20261007-000001', name: 'HarmonyOS 基础认证',
    issueDate: '2026-10-07', expiryDate: '2028-10-07', status: 'VALID'
  }
  const expired: CertificateItem = {
    id: 'c2', certificateNo: 'CERT-20250101-000002', name: 'HarmonyOS 高级认证',
    issueDate: '2025-01-01', expiryDate: '2026-01-01', status: 'EXPIRED'
  }
  return [valid, expired]
}

export default function certificateViewModelTest() {
  describe('certificateViewModelTest', () => {
    let service: ExamService
    let mocker: MockKit

    beforeEach(() => {
      mocker = new MockKit()
      service = new ExamService()
      const mGet: Function = mocker.mockFunc(service, service.getCertificates)
      when(mGet)(ArgumentMatchers.any).afterReturn(Promise.resolve(fixtureCertificates()))
    })

    afterEach(() => {
      mocker.clearAll()
    })

    it('should_load_certificates_and_reset_loading', 0, async () => {
      const vm = new CertificateViewModel(service)
      const res = await vm.loadCertificates()
      expect(res.ok).assertEqual(true)
      expect(vm.certificates.length).assertEqual(2)
      expect(vm.loading).assertEqual(false)
      expect(vm.errorMessage).assertEqual('')
    })

    // 英文枚举进、中文徽标出
    it('should_translate_status_enum', 0, () => {
      const vm = new CertificateViewModel(service)
      expect(vm.getStatusLabel('VALID')).assertEqual('有效')
      expect(vm.getStatusLabel('EXPIRED')).assertEqual('已过期')
      // 未知值一律按已过期处理（不让脏数据渲染成"有效"）
      expect(vm.getStatusLabel('SOMETHING')).assertEqual('已过期')
    })

    it('should_tell_valid_status', 0, () => {
      const vm = new CertificateViewModel(service)
      expect(vm.isValid('VALID')).assertEqual(true)
      expect(vm.isValid('EXPIRED')).assertEqual(false)
    })

    // 失败分支：错误上屏、loading 归位
    it('should_set_error_on_failure', 0, async () => {
      const svc: ExamService = new ExamService()
      const mFail: Function = mocker.mockFunc(svc, svc.getCertificates)
      when(mFail)(ArgumentMatchers.any).afterReturn(Promise.reject(new Error('证书炸了')))
      const vm = new CertificateViewModel(svc)
      const res = await vm.loadCertificates()
      expect(res.ok).assertEqual(false)
      expect(vm.errorMessage).assertEqual('证书炸了')
      expect(vm.loading).assertEqual(false)
    })
  })
}
