/**
 * 我的证书 ViewModel：证书列表的业务与状态，零 UI
 *
 * 【契约坑】列表接口的 status 是英文枚举 VALID / EXPIRED，详情接口却是中文——
 *   两套口径不可混用。这里只做"原样收下 + 提供中文徽标翻译"，
 *   翻译留在 View 调用的方法里，避免把枚举值写进状态。
 */
import { BaseViewModel, Result } from '@zhititong/common'
import { ExamService, CertificateItem } from '../service/ExamService'

@ObservedV2
export class CertificateViewModel extends BaseViewModel {
  // 证书列表（@Trace：整体赋值后页面自动刷新）
  @Trace certificates: CertificateItem[] = []

  private examService: ExamService

  constructor(service: ExamService = new ExamService()) {
    super()
    this.examService = service
  }

  /** 拉取我的证书列表 */
  async loadCertificates(): Promise<Result<CertificateItem[]>> {
    this.clearError()
    this.setLoading(true)
    try {
      const list: CertificateItem[] = await this.examService.getCertificates()
      this.certificates = list
      this.logger.info(`证书加载完成：${list.length} 张`)
      return Result.ok<CertificateItem[]>(list)
    } catch (e) {
      const errorMsg = (e as Error).message || '证书加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`证书加载失败：${errorMsg}`)
      return Result.fail<CertificateItem[]>(-1, errorMsg)
    } finally {
      this.setLoading(false)
    }
  }

  /** 英文枚举 → 中文徽标：VALID 有效 / 其它一律按已过期处理 */
  getStatusLabel(status: string): string {
    return status === 'VALID' ? '有效' : '已过期'
  }

  /** 徽标是否有效（决定颜色：绿 / 灰） */
  isValid(status: string): boolean {
    return status === 'VALID'
  }
}
