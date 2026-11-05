// 逐题回顾页：成绩摘要条 + 只看错题开关 + 逐题精讲列表
//
// 【路由】注册在根栈（RouteConstants.REVIEW），由结果页"查看逐题解析"push 进入，
//   onReady 从路由参数取 attemptId → vm.loadReview。
// 【分层】数据与派生全在 ReviewViewModel（@Trace review + showWrongOnly），本页只渲染。
import { CommonConstants } from '@zhititong/common'
import { ReviewViewModel } from '../viewmodel/ReviewViewModel'
import { ReviewQuestionDetail } from '../service/ExamService'
import { ReviewQuestionCard } from './ReviewQuestionCard'
import { AssistantEntry } from '../../assistant/AssistantEntry'

@Preview
@ComponentV2
export struct ReviewPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  @Local vm: ReviewViewModel = new ReviewViewModel()

  build() {
    NavDestination() {
      if (this.vm.review.questions.length === 0) {
        // 渲染守卫：错误优先 → 加载中 → 空卷兜底（与答题页同款口径）
        Column() {
          Text(this.vm.errorMessage !== '' ? this.vm.errorMessage :
            (this.vm.loading ? '回顾加载中…' : '本场暂无回顾数据'))
            .fontSize(CommonConstants.FONT_BODY)
            .fontColor(this.vm.errorMessage !== ''
              ? CommonConstants.COLOR_ERROR : CommonConstants.COLOR_TEXT_HINT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          // ===== 成绩摘要条 =====
          Column() {
            Text(this.vm.review.paperName)
              .fontSize(CommonConstants.FONT_BODY)
              .fontWeight(FontWeight.Bold)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')

            Row() {
              Text(`${this.vm.review.score}`)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.vm.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
              Text(` / ${this.vm.review.totalScore} 分`)
                .fontSize(CommonConstants.FONT_CAPTION)
                .fontColor(CommonConstants.COLOR_TEXT_SUB)
              Blank()
              Text(`答对 ${this.vm.correctCount} / 共 ${this.vm.review.questions.length} 题`)
                .fontSize(CommonConstants.FONT_CAPTION)
                .fontColor(CommonConstants.COLOR_TEXT_SUB)
            }
            .width('100%')
            .margin({ top: CommonConstants.SPACE_M })
          }
          .width('100%')
          .padding(CommonConstants.SPACE_M)
          .backgroundColor(Color.White)
          .borderRadius(8)

          // ===== 只看错题 =====
          Row() {
            Text('只看错题')
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.vm.showWrongOnly })
              .onChange((isOn: boolean) => {
                this.vm.showWrongOnly = isOn
              })
          }
          .width('100%')
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
          .height(52)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ top: CommonConstants.SPACE_M })

          // ===== 逐题精讲 + 右下角助教入口（Stack 叠放，入口不占列表布局） =====
          Stack({ alignContent: Alignment.BottomEnd }) {
            List({ space: CommonConstants.SPACE_M }) {
              ForEach(this.vm.visibleQuestions, (q: ReviewQuestionDetail) => {
                ListItem() {
                  ReviewQuestionCard({ question: q, index: this.vm.questionNoById(q.questionId) })
                }
              }, (q: ReviewQuestionDetail) => q.questionId)
            }
            .width('100%')
            .height('100%')
            .onScrollIndex((start: number, end: number, center: number): void => {
              // 中心项就是"正在看的那道题"：中心线落在谁身上，谁的可视面积过半
              this.vm.updateCurrentVisibleIndex(center)
            })

            // 【为什么要 ForEach 包一个 key】queryText 是 @Param @Once，入口创建后不再读新值；
            //   当前题一变 → key 变 → 旧入口销毁、新入口带着那道题的上下文重建。
            if (this.vm.assistantReady) {
              ForEach([this.vm.assistantQueryKey], (key: string) => {
                AssistantEntry({ queryText: this.vm.assistantQuery })
                  .margin({ right: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })
              }, (key: string) => key)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .margin({ top: CommonConstants.SPACE_M })
        }
        .width('100%')
        .height('100%')
        .padding(CommonConstants.SPACE_M)
        .backgroundColor(CommonConstants.COLOR_BG_PAGE)
      }
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      // 结果页 push 时把 attemptId 作为路由参数传进来
      this.vm.loadReview(ctx.pathInfo.param as string)
    })
  }
}
