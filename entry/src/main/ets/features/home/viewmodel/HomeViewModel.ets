/**
 * 首页 ViewModel：推荐试卷的业务与状态，零 UI
 *
 * 【分层说明】features/home/viewmodel/ 是首页 feature 的"业务大脑"：
 *   "从试卷池随机抽 4 张"这条推荐规则住在这里，HomeView 只渲染 papers 字段。
 *   项目 6 换真接口时只改这里的取数代码，View 层零改动。
 *   数据流：HomeView.aboutToAppear → loadRecommendedPapers() → @Trace papers 变更 → 列表自动刷新。
 */
import { BaseViewModel, Result, PaperInfo, getRandomPapers } from '@zhititong/common'
import { PaperService } from '../../exam/service/PaperService'

// 推荐位数量：首页固定抽 4 张（收成常量，避免魔法数散落）
const RECOMMEND_COUNT: number = 4

@ObservedV2
export class HomeViewModel extends BaseViewModel {
  // 推荐试卷列表（@Trace：变更自动刷新 View）
  @Trace papers: PaperInfo[] = []

  private paperService: PaperService

  // 构造器注入：默认用真 Service，测试时可塞进 mock 过的实例
  constructor(service: PaperService = new PaperService()) {
    super()
    this.paperService = service
  }

  /**
   * 加载推荐试卷：真实接口全量拉取后随机抽取（池子不足推荐数时有多少显示多少）
   */
  async loadRecommendedPapers(): Promise<Result<PaperInfo[]>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：随机抽取是首页的推荐规则，属于业务——所以住在 ViewModel
      const all = await this.paperService.getPapers()
      const picked: PaperInfo[] = getRandomPapers(all, RECOMMEND_COUNT)
      this.papers = picked
      this.logger.info(`推荐试卷加载成功：${picked.length} 张（池 ${all.length} 张）`)
      return Result.ok<PaperInfo[]>(this.papers)
    } catch (e) {
      const errorMsg = (e as Error).message || '推荐试卷加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(`推荐试卷加载失败：${errorMsg}`)
      return Result.fail(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }
}
