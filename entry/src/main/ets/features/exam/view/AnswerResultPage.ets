// 答题结果页：结果卡 + 证书提示条 + 答题卡 + 底部按钮行，数据由 AnswerResultViewModel 提供
//
// 【知识点 3.2.2 Grid 网格组件】本页"答题卡"是 Grid 的进阶示例：
//   用 6 列等分网格排 N 个格子，并演示 Grid 的一个重要坑——高度不会自适应子节点，
//   必须显式计算（高度公式在 AnswerResultViewModel.getAnswerCardHeight，有单测钉死），
//   否则会把页面下方内容顶出屏幕。
// 【分层说明】本文件位于 features/exam/view/：它是"考试"feature 的页面，
//   注册在**根栈**（RootDomain）的 RootRouter 上（路由名 RouteConstants.ANSWER_RESULT），
//   由答题页交卷后 push 进入，页面根节点用 NavDestination。
// 【MVVM】交卷结果与答题卡布局计算全在 AnswerResultViewModel（@Trace），本页只渲染与转发事件。
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { RouteConstants } from '../../../common/constants/RouteConstants'
import { AnswerItem } from '../../../common/model/QuestionModel'
import { formatDuration } from '../../../common/utils/TimeUtils'
import { AnswerResultViewModel, ANSWER_CARD_CELL_HEIGHT, ANSWER_CARD_GAP } from '../viewmodel/AnswerResultViewModel'

@Preview
@ComponentV2
export struct AnswerResultPage {
  // 跨层级直取根栈：结果页也是"沉浸式详情页"，注册在根栈上
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；result 是 @Trace 字段，VM 加载完成后页面自动刷新
  @Local vm: AnswerResultViewModel = new AnswerResultViewModel()

  // 页面创建时加载一次交卷结果。返回的 Result 这里不处理——
  // 失败态由 vm.errorMessage 承载，静态 Demo 阶段 Mock 结果不会失败
  aboutToAppear(): void {
    this.vm.loadResult()
  }

  build() {
    // NavDestination：Navigation 体系里"一个页面"的根节点
    NavDestination() {
      Column() {
        // ===== 结果卡：白底圆角大卡，居中展示得分、通过标签与交卷信息 =====
        Column() {
          // 大号得分：通过用成功色，未通过用错误色
          // Text 里嵌 Span：同一行文字用不同字号/颜色——48 号数字 + 小一号的"分"单位
          Text() {
            Span(`${this.vm.result.score}`)
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.vm.result.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
            Span(' 分')
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(this.vm.result.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
          }

          // 通过/未通过标签：同色描边胶囊（与试卷卡片等级标签同风格）
          // 三元表达式根据 passed 切换文字、颜色、描边色，一处数据驱动两套视觉
          Text(this.vm.result.passed ? '通过' : '未通过')
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(this.vm.result.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
            .border({
              width: 1,
              color: this.vm.result.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR,
              radius: 4
            })
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .margin({ top: CommonConstants.SPACE_M })

          // 及格线 · 用时 · 交卷方式（12 号次文本色）
          // 用时调 TimeUtils.formatDuration 把秒数转成"X 分 X 秒"；交卷方式文案由 VM 提供
          Text(`及格线 ${this.vm.result.passScore} 分・用时 ${formatDuration(this.vm.result.usedTime)}・${
            this.vm.getSubmitTypeLabel()}`)
            .fontSize(12)
            .fontColor(CommonConstants.COLOR_TEXT_SUB)
            .margin({ top: CommonConstants.SPACE_M })
        }
        .width('100%')
        .padding(CommonConstants.SPACE_L)
        .borderRadius(12)
        .backgroundColor(Color.White)
        .alignItems(HorizontalAlign.Center)   // 结果卡内容整体水平居中

        // ===== 证书提示条：仅通过后展示（浅色底静态占位） =====
        // 条件渲染：passed 为 false 时整块从布局中移除（不是隐藏占位）
        if (this.vm.result.passed) {
          Text('📜已生成电子证书，可在个人中心查看')
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_SUCCESS)
            .backgroundColor('#E8F5E9')
            .borderRadius(8)
            .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M, top: 10, bottom: 10 })
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: CommonConstants.SPACE_M })
        }

        // ===== 答题卡区：六列格子，逐题标识 答对/答错/未答 =====
        Text('答题卡')
          .fontSize(CommonConstants.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .margin({ top: CommonConstants.SPACE_L, bottom: CommonConstants.SPACE_M })

        // ===== Grid（3.2.2）=====
        // columnsTemplate 写 6 个 '1fr' → 精确 6 列等分（对照科目页的 2 列 '1fr 1fr'）
        // ForEach 里用格子下标 index 显示题号，用 answer 字段决定底色：
        //   未答 → 灰（提示色）；答对 → 绿（成功色）；答错 → 红（错误色）
        // 嵌套三元表达式按"先判未答、再判对错"的优先级取色——颜色是渲染决策，留在 View
        Grid() {
          ForEach(this.vm.result.answers, (answer: AnswerItem, index: number) => {
            GridItem() {
              Column() {
                Text(`${index + 1}`)   // 题号从 1 开始（下标 + 1）
                  .fontSize(CommonConstants.FONT_CAPTION)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
              .width('100%')
              .height(ANSWER_CARD_CELL_HEIGHT)   // 格子固定高，配合下方显式 Grid 高度
              .justifyContent(FlexAlign.Center)  // 题号在格子里垂直居中
              .borderRadius(ANSWER_CARD_GAP)
              .backgroundColor(
                !answer.answered ? CommonConstants.COLOR_TEXT_HINT
                  : answer.correct ? CommonConstants.COLOR_SUCCESS
                  : CommonConstants.COLOR_ERROR
              )
            }
          }, (answer: AnswerItem) => answer.questionId)
          // ↑ 键值生成器：用题目 id 当 key，答题数据顺序变化时不错位
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')   // 6 列
        .columnsGap(ANSWER_CARD_GAP)   // 列间距，与 VM 高度公式的行间距同源
        .rowsGap(ANSWER_CARD_GAP)      // 行间距，同上
        .width('100%')
        .height(this.vm.getAnswerCardHeight())   // 【重点】必须显式给高度，公式在 VM，原因见其注释

        // 弹性占位：把底部按钮行推至页面底部
        // layoutWeight(1)：空白 Row 吃掉剩余高度——"底部固定"的常用手法
        Row()
          .layoutWeight(1)

        // ===== 底部按钮行：查看回顾（白底主色字）+ 重新刷题（渐变主按钮） =====
        Row({ space: CommonConstants.SPACE_M }) {
          Button('查看回顾')
            .type(ButtonType.Normal)
            .layoutWeight(1)   // 两个按钮各占一半宽度
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_BODY)
            .backgroundColor(Color.White)
            .fontColor(CommonConstants.COLOR_PRIMARY)
            .border({ width: 1, color: CommonConstants.COLOR_PRIMARY })
            .onClick(() => {
              console.info('查看回顾')
            })

          Button('重新刷题')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_BODY)
            .fontColor(Color.White)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [[CommonConstants.GRADIENT_START, 0], [CommonConstants.GRADIENT_END, 1]]
            })
            .onClick(() => {
              // 弹出结果页，回到答题页重新作答（按记录跳转的完整逻辑项目 6 接入数据后实现）
              this.pageStack.pop()
            })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
      .padding(CommonConstants.SPACE_M)
    }
    .hideTitleBar(true)   // 沉浸式：页面自带结果卡当头部，不要系统标题栏
  }
}
