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
import { CommonConstants, RouteConstants, AnswerItem, formatDuration, Logger } from '@zhititong/common'
import { AnswerResultViewModel, ANSWER_CARD_CELL_HEIGHT, ANSWER_CARD_GAP } from '../viewmodel/AnswerResultViewModel'
import { AssistantEntry } from '../../assistant/AssistantEntry'

@Preview
@ComponentV2
export struct AnswerResultPage {
  // 跨层级直取根栈：结果页也是"沉浸式详情页"，注册在根栈上
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；result 是 @Trace 字段，VM 加载完成后页面自动刷新
  @Local vm: AnswerResultViewModel = new AnswerResultViewModel()
  // 本场场次号：onReady 从路由参数取到后留住，供"查看逐题解析"二次跳转
  @Local attemptId: string = ''
  private logger: Logger = new Logger('[AnswerResultPage]')

  build() {
    // NavDestination：Navigation 体系里"一个页面"的根节点
    NavDestination() {
      Column() {
        // ===== 结果卡：白底圆角大卡，居中展示得分、通过标签与交卷信息 =====
        Column() {
          // 大号得分：通过用主色，未通过用错误色（方案A F07：大分值改主色）
          // Text 里嵌 Span：同一行文字用不同字号/颜色——36 号数字 + FONT_CAPTION_UNIT 弱化的"分"单位
          // 得分行与"分"都不换行（定宽内容），按行高规则不配 lineHeight——配了反而裁切
          Text() {
            Span(`${this.vm.result.score}`)
              .fontSize(CommonConstants.FONT_DISPLAY_SCORE_MOBILE)
              .fontWeight(CommonConstants.WEIGHT_BOLD)
              .fontColor(this.vm.result.passed ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_ERROR)
            Span(' 分')
              .fontSize(CommonConstants.FONT_CAPTION_UNIT)
              .fontWeight(CommonConstants.WEIGHT_MEDIUM)
              .fontColor(CommonConstants.COLOR_TEXT_SUB)
          }

          // 通过/未通过徽章：tint 底 + 同色相饱和字的全圆胶囊（§6.4 裁决：胶囊一律无描边）
          // 三元表达式根据 passed 切换文字、字色、底色，一处数据驱动两套视觉
          // RADIUS_TAG 是 9999，靠 ArkUI 把 borderRadius 钳到短边一半得到正胶囊
          Text(this.vm.result.passed ? '通过' : '未通过')
            .fontSize(CommonConstants.FONT_LABEL_SM)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(this.vm.result.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
            .backgroundColor(this.vm.result.passed ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_ERROR_BG)
            .borderRadius(CommonConstants.RADIUS_TAG)
            .height(28)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .margin({ top: CommonConstants.SPACE_M })

          // 及格线 · 用时 · 交卷方式（body-sm 次文本色）
          // 用时调 TimeUtils.formatDuration 把秒数转成"X 分 X 秒"；交卷方式文案由 VM 提供
          // 三段拼在一行，窄屏或交卷方式文案变长时会换行——本页唯一"可换行"文本，配行高
          Text(`及格线 ${this.vm.result.passScore} 分・用时 ${formatDuration(this.vm.result.usedTime)}・${
            this.vm.getSubmitTypeLabel()}`)
            .fontSize(CommonConstants.FONT_BODY_SM)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .lineHeight(CommonConstants.LINE_BODY_SM)
            .fontColor(CommonConstants.COLOR_TEXT_SUB)
            .margin({ top: CommonConstants.SPACE_M })

          // 防作弊提示（成绩区下方一行）：文案由 VM 派生，本页不读 AppStorageV2——
          // 与"数据归 VM、View 只渲染"同一口径，样式沿用上面那行说明文字（body-sm + 次文本色）。
          // 最长也就"本场切出应用 N 次"十来个字，卡内宽度装不下换行，单行判定——不配行高
          Text(this.vm.getBackgroundHint())
            .fontSize(CommonConstants.FONT_BODY_SM)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .fontColor(CommonConstants.COLOR_TEXT_SUB)
            .margin({ top: CommonConstants.SPACE_M })
        }
        .width('100%')
        .padding(CommonConstants.SPACE_L)
        .borderRadius(CommonConstants.RADIUS_CARD)
        .backgroundColor(CommonConstants.COLOR_CARD_BG)
        .shadow(CommonConstants.SHADOW_CARD)   // §6.6 卡面配方：白底 + RADIUS_CARD + SHADOW_CARD，不加整周描边（旧 Ruling T9-C"不补阴影"已被翻掉）
        .alignItems(HorizontalAlign.Center)   // 结果卡内容整体居中
        // 不加 .clip(true)：卡内边距 24 大于圆角半径 16，内容永远碰不到圆角弧线（Task 7 同一论证）

        // ===== 证书提示条：仅通过后展示（成功色 tint 底的通栏句子） =====
        // 条件渲染：passed 为 false 时整块从布局中移除（不是隐藏占位）
        // Ruling T10-F（§3.3）：判 badging 看语义角色不看外观——本条带 tint 底 + 圆角只是 banner 形态，
        //   语义是"要人读一句通栏话"，属正文家族 ⇒ FONT_BODY_MD(14/400) + LINE_BODY_MD，不套许可档 label-sm。
        //   许可条只管状态胶囊/章节题号标识/时间戳三类；label-sm(12) 在 §6.2 极小档会落到 10fp，跌破中文辅助可读线。
        if (this.vm.result.passed) {
          Text('📜已生成电子证书，可在个人中心查看')
            .fontSize(CommonConstants.FONT_BODY_MD)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .lineHeight(CommonConstants.LINE_BODY_MD)
            .fontColor(CommonConstants.COLOR_SUCCESS)
            .backgroundColor(CommonConstants.COLOR_SUCCESS_BG)
            .borderRadius(CommonConstants.RADIUS_BUTTON)
            .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M, top: 10, bottom: 10 })
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: CommonConstants.SPACE_M })
        }

        // ===== 助教入口：成绩加载完成后再创建 =====
        // 【为什么用 assistantReady 卡时机】FunctionComponent 的 queryText 只在创建时读一次，
        //   数据没到位就创建，入口会永远带着初始的"0 分 / 空卷面"。
        if (this.vm.assistantReady) {
          AssistantEntry({
            title: '问问 AI 助教',
            queryText: this.vm.assistantQuery
          })
            .margin({ top: CommonConstants.SPACE_M })
        }

        // ===== 答题卡区：六列格子，逐题标识 答对/答错/未答 =====
        // 分区标题走 headline-md 档（与抽屉"答题卡"标题同档），单行标题不配行高。
        // bottom 取 SPACE_CARD_GAP(12)：spec §3.4 把"分区标题→下方内容"定死 12，与首页/刷题页同轨；
        // top 是"上一区块到本标题"的容器间距，阶梯上有现成的 SPACE_L，保留不动
        Text('答题卡')
          .fontSize(CommonConstants.FONT_HEADLINE_MD)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .margin({ top: CommonConstants.SPACE_L, bottom: CommonConstants.SPACE_CARD_GAP })

        // ===== Grid（3.2.2）=====
        // columnsTemplate 写 6 个 '1fr' → 精确 6 列等分（对照科目页的 2 列 '1fr 1fr'）
        // ForEach 里用格子下标 index 显示题号，按 answer 字段取 tint 底 + 同色相题号：
        //   未答 → 静息浅底 + 提示色字；答对 → 成功浅底 + 成功色字；答错 → 错误浅底 + 错误色字
        //   （迷你分布图换 tint 色是 F07 的核心变化；0.5 发丝边框用 DIVIDER_WIDTH + 发丝描边色）
        // 嵌套三元表达式按"先判未答、再判对错"的优先级取色——颜色是渲染决策，留在 View
        Grid() {
          ForEach(this.vm.result.answers, (answer: AnswerItem, index: number) => {
            GridItem() {
              Column() {
                Text(`${index + 1}`)   // 题号从 1 开始（下标 + 1）；定宽单行，不配行高
                  .fontSize(CommonConstants.FONT_BODY_MD)
                  .fontWeight(CommonConstants.WEIGHT_REGULAR)
                  .fontColor(
                    !answer.answered ? CommonConstants.COLOR_TEXT_HINT
                      : answer.correct ? CommonConstants.COLOR_SUCCESS
                      : CommonConstants.COLOR_ERROR
                  )
              }
              .width('100%')
              .height(ANSWER_CARD_CELL_HEIGHT)   // 格子固定高，配合下方显式 Grid 高度
              .justifyContent(FlexAlign.Center)  // 题号在格子里垂直居中
              .borderRadius(CommonConstants.RADIUS_BUTTON)
              .border({ width: CommonConstants.DIVIDER_WIDTH, color: CommonConstants.COLOR_BORDER_HAIRLINE })
              .backgroundColor(
                !answer.answered ? CommonConstants.COLOR_SUBTLE_BG
                  : answer.correct ? CommonConstants.COLOR_SUCCESS_BG
                  : CommonConstants.COLOR_ERROR_BG
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

        // ===== 底部按钮行：查看回顾（白底主色描边）+ 重新刷题（实心主色，§6.1 去渐变） =====
        Row({ space: CommonConstants.SPACE_M }) {
          Button('查看回顾')
            .type(ButtonType.Normal)   // Capsule 会吞掉 borderRadius，设 RADIUS_BUTTON 必须用 Normal
            .layoutWeight(1)   // 两个按钮各占一半宽度
            .height(CommonConstants.BTN_HEIGHT)
            .borderRadius(CommonConstants.RADIUS_BUTTON)
            .fontSize(CommonConstants.FONT_BODY_LG)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)   // 按钮默认字重即 500，写明不改观感（与答题页按钮一致）
            .backgroundColor(CommonConstants.COLOR_CARD_BG)
            .fontColor(CommonConstants.COLOR_PRIMARY)
            .border({ width: 1, color: CommonConstants.COLOR_PRIMARY })
            .onClick(() => {
              // 逐题精讲：push 到根栈，带本场 attemptId（回顾页 onReady 读它拉全量）
              this.pageStack.pushPathByName(RouteConstants.REVIEW, this.attemptId)
            })

          Button('重新刷题')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(CommonConstants.BTN_HEIGHT)
            .borderRadius(CommonConstants.RADIUS_BUTTON)
            .fontSize(CommonConstants.FONT_BODY_LG)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(CommonConstants.COLOR_CARD_BG)
            // 换装后全项目杜绝渐变（§6.1）：原来的整块横向渐变填充删除，改纯色主色底
            .backgroundColor(CommonConstants.COLOR_PRIMARY)
            // 按下态：与登录页/答题页那几颗实心主色钮同一机制（stateStyles 的 pressed 键，
            // 纯声明式样式，不加页面状态、不改行为）。COLOR_PRIMARY_PRESSED 这枚令牌的唯一用途就是它
            .stateStyles({
              pressed: {
                .backgroundColor(CommonConstants.COLOR_PRIMARY_PRESSED)
              }
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
    .onReady((ctx: NavDestinationContext) => {
      // 答题页交卷后 replacePathByName(ANSWER_RESULT, attemptId) 把场次号传进来
      // 按场次号拉真实判分与答题卡；失败态由 vm.errorMessage 承载，这里不处理返回值
      this.attemptId = ctx.pathInfo.param as string
      this.vm.loadResult(this.attemptId)
    })
  }
}
