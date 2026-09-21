/**
 * 首页 ViewModel：推荐试卷的业务与状态，零 UI
 *
 * 【分层说明】features/home/viewmodel/ 是首页 feature 的"业务大脑"：
 *   "从试卷池随机抽 4 张"这条推荐规则住在这里（Mock 三条铁律：Mock 只能被 ViewModel 消费），
 *   HomeView 只渲染 papers 字段——项目 6 换"接口推荐"时改这里，View 层零改动。
 *   数据流：HomeView.aboutToAppear → loadRecommendedPapers() → @Trace papers 变更 → 列表自动刷新。
 */
import { BaseViewModel } from '../../../common/base/BaseViewModel'
import { Result } from '../../../common/base/Result'
import { PaperInfo } from '../../../common/model/QuestionModel'
import { MOCK_PAPERS } from '../../../common/mock/MockExamData'
import { getRandomPapers } from '../../../common/utils/PaperUtils'

// 推荐位数量：首页固定抽 4 张（收成常量，避免魔法数散落）
const RECOMMEND_COUNT: number = 4

@ObservedV2
export class HomeViewModel extends BaseViewModel {
  // 推荐试卷列表（@Trace：变更自动刷新 View）
  @Trace papers: PaperInfo[] = []

  /**
   * 加载推荐试卷：从试卷池随机抽 4 张（Mock 阶段；接真接口时只改这里的取数代码）
   */
  async loadRecommendedPapers(): Promise<Result<PaperInfo[]>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：随机抽取是首页的推荐规则，属于业务——所以住在 ViewModel，
      //    不住在 View（改造前它写在 HomeView 的 @Local 初始化里，view 直连了 Mock）
      const picked: PaperInfo[] = getRandomPapers(MOCK_PAPERS, RECOMMEND_COUNT)
      this.papers = picked
      this.logger.info(`推荐试卷加载完成，共 ${this.papers.length} 张`)
      return Result.ok<PaperInfo[]>(this.papers)
    } catch (e) {
      const errorMsg = '推荐试卷加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }
}
