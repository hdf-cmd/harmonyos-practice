/**
 * 考卷列表 ViewModel：按科目过滤考卷的业务与状态，零 UI
 *
 * 【分层说明】features/exam/viewmodel/ 是"刷题"Tab 考卷列表页的"业务大脑"：
 *   "进哪个科目就只看哪科的卷"这条过滤规则住在这里，ExamListPage 只渲染 papers。
 *   项目 6 换接口取考卷时改这里，View 层零改动。
 *   数据流：ExamListPage.onReady → loadPapersByCategory(categoryName) → @Trace papers 变更 → List 自动刷新。
 */
import { BaseViewModel, Result, PaperInfo } from '@zhititong/common'
import { PaperService } from '../service/PaperService'

@ObservedV2
export class ExamListViewModel extends BaseViewModel {
  // 当前科目下的考卷列表（@Trace：变更自动刷新 View）
  @Trace papers: PaperInfo[] = []

  private paperService: PaperService

  // 构造器注入：默认用真 Service，测试时可塞进 mock 过的实例
  constructor(service: PaperService = new PaperService()) {
    super()
    this.paperService = service
  }

  /**
   * 加载指定科目的考卷列表：真实接口全量拉取后按 categoryName 过滤
   *
   * @param categoryName 上游科目卡片 push 进来的路由参数（科目名）
   */
  async loadPapersByCategory(categoryName: string): Promise<Result<PaperInfo[]>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：按科目过滤是本页的业务规则——所以住在 ViewModel
      const all = await this.paperService.getPapers()
      this.papers = all.filter((p: PaperInfo): boolean => p.categoryName === categoryName)
      this.logger.info(`考卷列表加载成功：${categoryName} 共 ${this.papers.length} 套`)
      return Result.ok<PaperInfo[]>(this.papers)
    } catch (e) {
      const errorMsg = (e as Error).message || '考卷加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`考卷列表加载失败：${errorMsg}`)
      return Result.fail(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }
}
