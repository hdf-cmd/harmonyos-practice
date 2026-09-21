/**
 * 答题结果 ViewModel：交卷结果展示的业务与状态，零 UI
 *
 * 【分层说明】features/exam/viewmodel/ 是答题结果页的"业务大脑"：
 *   交卷方式文案映射、答题卡行数与 Grid 高度计算这些规则住在这里
 *   （Mock 三条铁律：Mock 只能被 ViewModel 消费），AnswerResultPage 只渲染 result——
 *   项目 6 接入真实判分接口时改这里，View 层零改动。
 *   数据流：AnswerResultPage.aboutToAppear → loadResult() → @Trace result 变更 → 页面自动刷新。
 */
import { BaseViewModel } from '../../../common/base/BaseViewModel'
import { Result } from '../../../common/base/Result'
import { MOCK_RESULT } from '../../../common/mock/MockResultData'
import { ExamResult } from '../../../common/model/QuestionModel'

// 答题卡布局参数：列数 / 格子高度 / 格子间距（vp）
// 抽成导出常量：高度公式与 View 的格子渲染共用同一份，改任何一个都不会失联（避免魔法数散落）
export const ANSWER_CARD_COLUMNS: number = 6
export const ANSWER_CARD_CELL_HEIGHT: number = 40
export const ANSWER_CARD_GAP: number = 8

@ObservedV2
export class AnswerResultViewModel extends BaseViewModel {
  // 交卷结果（@Trace：整体赋值变更自动刷新 View；初始为空壳，loadResult 后才有真实数据）
  @Trace result: ExamResult = {
    score: 0,
    totalScore: 0,
    passScore: 0,
    passed: false,
    usedTime: 0,
    submitType: 'MANUAL',
    answers: []
  }

  /**
   * 加载交卷结果（Mock 阶段固定 MOCK_RESULT；接入真实判分接口时只改这里的取数代码）
   */
  async loadResult(): Promise<Result<ExamResult>> {
    // 1. 清错误 + 进加载态
    this.clearError()
    this.setLoading(true)

    try {
      // 2. 取数：交卷结果属业务数据——住在 ViewModel，不住在 View
      //    （改造前它写在 AnswerResultPage 的 @Local 初始化里，view 直连了 Mock）
      this.result = MOCK_RESULT
      this.logger.info(`交卷结果加载完成：${this.result.score} 分，共 ${this.result.answers.length} 题作答记录`)
      return Result.ok<ExamResult>(this.result)
    } catch (e) {
      const errorMsg = '结果加载失败，请稍后重试'
      this.setError(errorMsg)
      this.logger.error(errorMsg)
      return Result.fail<ExamResult>(-1, errorMsg)
    } finally {
      // 3. 退出加载态（放 finally：不管成败都要复位，否则界面会永远转圈）
      this.setLoading(false)
    }
  }

  // 交卷方式文案：MANUAL → 手动交卷，其余（TIMEOUT）→ 超时自动交卷（纯逻辑，可单测）
  getSubmitTypeLabel(): string {
    return this.result.submitType === 'MANUAL' ? '手动交卷' : '超时自动交卷'
  }

  // 答题卡行数：题目数按列数向上取整
  // 例：13 道题、6 列 → ceil(13/6)=3 行（最后一行只放 1 个）（纯逻辑，可单测）
  getAnswerCardRowCount(): number {
    return Math.ceil(this.result.answers.length / ANSWER_CARD_COLUMNS)
  }

  // 【Grid 重点】答题卡高度：Grid 不会自适应子节点高度——不设置高度时它会撑到与父组件同高，
  // 把"底部按钮行"顶出屏幕，这是 Grid 最常见的踩坑点。
  // 所以要显式算：行数 × 格子高 + (行数 − 1) × 行间距（类比 n 个点有 n−1 个间隔）（纯逻辑，可单测）
  getAnswerCardHeight(): number {
    return this.getAnswerCardRowCount() * ANSWER_CARD_CELL_HEIGHT
      + (this.getAnswerCardRowCount() - 1) * ANSWER_CARD_GAP
  }
}
