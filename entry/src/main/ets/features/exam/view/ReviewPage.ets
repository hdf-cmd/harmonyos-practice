// 逐题回顾页：成绩摘要条 + 只看错题开关 + 逐题精讲列表
//
// 【路由】注册在根栈（RouteConstants.REVIEW），由结果页"查看逐题解析"push 进入，
//   onReady 从路由参数取 attemptId → vm.loadReview。
// 【分层】数据与派生全在 ReviewViewModel（@Trace review + showWrongOnly），本页只渲染。
import { CommonConstants, FontSetting, StateKeys } from '@zhititong/common'
import { PersistenceV2 } from '@kit.ArkUI'
import { ReviewViewModel } from '../viewmodel/ReviewViewModel'
import { ReviewQuestionDetail } from '../service/ExamService'
import { ReviewQuestionCard } from './ReviewQuestionCard'
import { AssistantEntry } from '../../assistant/AssistantEntry'

@Preview
@ComponentV2
export struct ReviewPage {
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  @Local vm: ReviewViewModel = new ReviewViewModel()
  // 字号档位：本页连一次，逐题传给 ReviewQuestionCard（卡片是 List 里多实例，不在每张卡里各连一遍）。
  //   与答题页 :30 同一写法、同一个 StateKeys.FONT_SETTING——落盘由 PersistenceV2 接管，
  //   在「我的」页改档位，这里和答题页一起刷新。
  @Local font: FontSetting = PersistenceV2.connect(FontSetting, StateKeys.FONT_SETTING,
    () => new FontSetting())!

  build() {
    NavDestination() {
      if (this.vm.review.questions.length === 0) {
        // 渲染守卫：错误优先 → 加载中 → 空卷兜底（与答题页同款口径）
        Column() {
          Text(this.vm.errorMessage !== '' ? this.vm.errorMessage :
            (this.vm.loading ? '回顾加载中…' : '本场暂无回顾数据'))
            .fontSize(CommonConstants.FONT_BODY_LG)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            // 错误文案是后端消息直通，长度不可控、会折行 → 配 body-lg 行高
            .lineHeight(CommonConstants.LINE_BODY_LG)
            .fontColor(this.vm.errorMessage !== ''
              ? CommonConstants.COLOR_ERROR : CommonConstants.COLOR_TEXT_HINT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          // ===== 成绩摘要条 =====
          // 卡面配方按 §6.6 全局裁决：白底 + RADIUS_CARD + SHADOW_CARD，不给整周 hairline 描边。
          //   本条已翻掉旧的"本屏不单方面补阴影、避免同屏两套卡面"结论（那是 Ruling T9-C 时代口径），
          //   判据是导出的 12 屏 63 个卡级容器实测 0 描边 / 51 阴影；单题卡、开关行、结果卡同配方。
          Column() {
            Text(this.vm.review.paperName)
              .fontSize(CommonConstants.FONT_HEADLINE_SM)
              .fontWeight(CommonConstants.WEIGHT_SEMI)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')

            Row() {
              // 得分取主色档（与结果页同口径：通过用主色、未通过用错误色——同一份数据两屏不分叉）
              // 定宽数字 + 单位，单行判定 → 不配行高
              Text(`${this.vm.review.score}`)
                .fontSize(CommonConstants.FONT_DISPLAY_SCORE_MOBILE)
                .fontWeight(CommonConstants.WEIGHT_BOLD)
                .fontColor(this.vm.passed ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_ERROR)
              Text(` / ${this.vm.review.totalScore} 分`)
                .fontSize(CommonConstants.FONT_CAPTION_UNIT)
                .fontWeight(CommonConstants.WEIGHT_MEDIUM)
                .fontColor(CommonConstants.COLOR_TEXT_SUB)
              Blank()
              Text(`答对 ${this.vm.correctCount} / 共 ${this.vm.review.questions.length} 题`)
                .fontSize(CommonConstants.FONT_CAPTION_UNIT)
                .fontWeight(CommonConstants.WEIGHT_MEDIUM)
                .fontColor(CommonConstants.COLOR_TEXT_SUB)
                // 与同屏卷名一致：摘要行按单行判定（得分 36fp + 单位 + Blank + 本项，极小屏/极大档
                //   会挤），补 maxLines(1) 让"单行不配行高"这个前提被代码守住而非仅靠假设。
                .maxLines(1)
            }
            .width('100%')
            .margin({ top: CommonConstants.SPACE_M })
          }
          .width('100%')
          .padding(CommonConstants.SPACE_M)
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
          .borderRadius(CommonConstants.RADIUS_CARD)
          .shadow(CommonConstants.SHADOW_CARD)
          // 不 .clip(true)：卡内边距 16 与圆角半径 16 相等，内容碰不到圆角弧线

          // ===== 只看错题 =====
          // Toggle 的类型与 onChange 行为原样保留，本行只动样式：字阶、底色与圆角换成令牌、
          //   容器高度 52 → BTN_HEIGHT(48)、与上卡的间距 16 → 纵向节奏 12
          Row() {
            Text('只看错题')
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.vm.showWrongOnly })
              .onChange((isOn: boolean) => {
                this.vm.showWrongOnly = isOn
              })
          }
          .width('100%')
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
          .height(CommonConstants.BTN_HEIGHT)
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
          .borderRadius(CommonConstants.RADIUS_CARD)
          .shadow(CommonConstants.SHADOW_CARD)
          .margin({ top: CommonConstants.SPACE_CARD_GAP })

          // ===== 逐题精讲 + 右下角助教入口（Stack 叠放，入口不占列表布局） =====
          // 列表行距与上面的容器间距都走纵向节奏 12（§3.4：只管容器之间，与刷题页列表同一裁决）
          Stack({ alignContent: Alignment.BottomEnd }) {
            List({ space: CommonConstants.SPACE_CARD_GAP }) {
              ForEach(this.vm.visibleQuestions, (q: ReviewQuestionDetail) => {
                ListItem() {
                  ReviewQuestionCard({
                    question: q,
                    index: this.vm.questionNoById(q.questionId),
                    font: this.font
                  })
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
          .margin({ top: CommonConstants.SPACE_CARD_GAP })
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
