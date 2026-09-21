/**
 * 考试科目 ViewModel：科目聚合的业务与状态，零 UI
 *
 * 【分层说明】features/exam/viewmodel/ 是"刷题"Tab 科目页的"业务大脑"：
 *   "把试卷池按 categoryName 聚合成科目入口"这条规则住在这里
 *   （Mock 三条铁律：Mock 只能被 ViewModel 消费），ExamSubjectView 只渲染 groups——
 *   项目 6 换接口取科目时改这里，View 层零改动。
 *   数据流：ExamSubjectView.aboutToAppear → loadSubjectGroups() → @Trace groups 变更 → Grid 自动刷新。
 */
import { BaseViewModel } from '../../../common/base/BaseViewModel'
import { Result } from '../../../common/base/Result'
import { MOCK_PAPERS } from '../../../common/mock/MockExamData'
import { CategoryGroup, groupByCategory } from '../../../common/utils/PaperUtils'

@ObservedV2
export class ExamSubjectViewModel extends BaseViewModel {
  // 科目分组列表（@Trace：变更自动刷新 View）
  @Trace groups: CategoryGroup[] = []

  /**
   * 加载科目分组：对试卷池按科目聚合（Mock 阶段；接真接口时只改这里的取数代码）
   */
  async loadSubjectGroups(): Promise<Result<CategoryGroup[]>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：科目聚合是本页的推荐规则，属于业务——所以住在 ViewModel，
      //    不住在 View（改造前它写在 ExamSubjectView 的 @Local 初始化里，view 直连了 Mock）
      const groups: CategoryGroup[] = groupByCategory(MOCK_PAPERS)
      this.groups = groups
      this.logger.info(`科目分组加载完成，共 ${this.groups.length} 个科目`)
      return Result.ok<CategoryGroup[]>(this.groups)
    } catch (e) {
      const errorMsg = '科目加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }
}
