/**
 * 考卷列表 ViewModel：按科目过滤考卷的业务与状态，零 UI
 *
 * 【分层说明】features/exam/viewmodel/ 是"刷题"Tab 考卷列表页的"业务大脑"：
 *   "进哪个科目就只看哪科的卷"这条过滤规则住在这里
 *   （Mock 三条铁律：Mock 只能被 ViewModel 消费），ExamListPage 只渲染 papers——
 *   项目 6 换接口取考卷时改这里，View 层零改动。
 *   数据流：ExamListPage.onReady → loadPapersByCategory(categoryName) → @Trace papers 变更 → List 自动刷新。
 */
import { BaseViewModel, Result, MOCK_PAPERS, PaperInfo, filterByCategory } from '@zhititong/common'

@ObservedV2
export class ExamListViewModel extends BaseViewModel {
  // 当前科目下的考卷列表（@Trace：变更自动刷新 View）
  @Trace papers: PaperInfo[] = []

  /**
   * 加载指定科目的考卷列表：对试卷池按 categoryName 过滤（Mock 阶段；接真接口时只改这里的取数代码）
   *
   * @param categoryName 上游科目卡片 push 进来的路由参数（科目名）
   */
  async loadPapersByCategory(categoryName: string): Promise<Result<PaperInfo[]>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：按科目过滤是本页的业务规则——所以住在 ViewModel，
      //    不住在 View（改造前它写在 ExamListPage 的 onReady 里，view 直连了 Mock）
      this.papers = filterByCategory(MOCK_PAPERS, categoryName)
      this.logger.info(`科目「${categoryName}」考卷加载完成，共 ${this.papers.length} 套`)
      return Result.ok<PaperInfo[]>(this.papers)
    } catch (e) {
      const errorMsg = '考卷加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }
}
