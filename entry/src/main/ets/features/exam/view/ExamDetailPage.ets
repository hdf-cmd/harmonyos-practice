// 考试模式答题页：顶部标题区 + 中部题目区 + 底部操作区
//
// 本页知识点：@Local 状态驱动 UI、ForEach 渲染选项列表、Radio/Checkbox 受控用法。
// 注意：本页改造后不再是独立路由页——它注册在**根栈**（RootDomain）的 RootRouter 上
//   （路由名 RouteConstants.EXAM_DETAIL），由首页试卷卡片 push 进入，push 后盖住底部 Tab（沉浸式详情页）。
// 数据目前直接读 MOCK_PAPER / MOCK_QUESTIONS，接入接口后需换成路由传参 + 请求结果。
// 【分层说明】本文件位于 features/exam/view/：它是"考试"feature 的页面，
//   页面根节点用 NavDestination（Navigation 体系的要求），路由名统一见 common/constants/RouteConstants.ets。
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { RouteConstants } from '../../../common/constants/RouteConstants'
import { MOCK_PAPER, MOCK_QUESTIONS } from '../../../common/mock/MockExamData'
import { QuestionItem, OptionItem } from '../../../common/model/QuestionModel'

// 题型标签映射：后端存的是枚举码（JUDGE/SINGLE/MULTI），展示时翻成中文
// 用 Record 集中管理映射关系，新增题型只改这一处
const TYPE_LABEL: Record<string, string> = {
  'JUDGE': '判断题',
  'SINGLE': '单选题',
  'MULTI': '多选题'
}

@Preview
@ComponentV2
export struct ExamDetailPage {
  // 跨层级直取根栈：答题页是"沉浸式详情页"，统一 push 到根栈，盖住底部 Tab
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 当前题目索引：整页最核心的状态——它一变，题目区所有内容跟着刷新
  @Local currentIndex: number = 0
  // 单选/判断选中项（记录选中的 label，如 'A'）
  // 用 string 而不是 boolean：Radio 组件靠"值相等"判断谁被选中
  @Local radioSelected: string = ''
  // 多选选中项集合：Set 天然去重，add/delete 对应勾选/取消
  // 注意 Set 整体替换（resetSelection 里 new 一个新的）才会触发 V2 状态刷新
  @Local checkboxSelected: Set<string> = new Set<string>()

  // 获取当前题目：所有题目区 UI 都经由它取数据，改 currentIndex 即整体换题
  getCurrentQuestion(): QuestionItem {
    return MOCK_QUESTIONS[this.currentIndex]
  }

  // 题型标签文本：映射表查不到时兜底"未知题型"，避免 undefined 直接上屏
  getTypeLabel(type: string): string {
    const label: string = TYPE_LABEL[type]
    return label !== undefined ? label : '未知题型'
  }

  // 选项显示文本，如 "A. 正确"
  getOptionText(option: OptionItem): string {
    return option.label + '. ' + option.content
  }

  // 切换题目时重置选中状态
  // 因为两道题共用同一组状态变量，不重置的话上一题的勾选会"串"到下一题
  resetSelection(): void {
    this.radioSelected = ''
    this.checkboxSelected = new Set<string>()   // 整体替换新 Set，确保状态刷新
  }

  build() {
    // NavDestination：Navigation 体系里"一个页面"的根节点，替代原来 @Entry 页面的角色
    NavDestination() {
      Column() {
        // ===== 顶部标题区 =====
        Column() {
          // 试卷名
          Text(MOCK_PAPER.paperName)
            .fontSize(CommonConstants.FONT_BODY)
            .fontWeight(FontWeight.Bold)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
  
          // 第二行：题目进度 + 倒计时
          Row() {
            // Text 嵌 Span：一行文字里"当前题号"单独标橙色强调
            Text() {
              Span('第 ')
              Span((this.currentIndex + 1).toString())
                .fontColor(CommonConstants.COLOR_WARN)
              Span(' 题 / 共 ')
              Span(MOCK_QUESTIONS.length.toString())
              Span(' 题')
            }
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_TEXT_SUB)
  
            Blank()   // 弹性空隙：把倒计时推到行尾
  
            // 倒计时目前是写死的静态值，后续阶段换成定时器驱动
            Text('29:59')
              .fontSize(CommonConstants.FONT_CAPTION)
              .fontColor(CommonConstants.COLOR_WARN)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .margin({ top: CommonConstants.SPACE_M })
        }
        .width('100%')
        .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M, top: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })
        .backgroundColor(Color.White)
        .borderRadius(8)
  
        // ===== 中部题目区域 =====
        Column() {
          // 题型标签
          Text(this.getTypeLabel(this.getCurrentQuestion().type))
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_PRIMARY)
            .border({ width: 1, color: CommonConstants.COLOR_PRIMARY, radius: 4 })
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
  
          // 题干
          Text(this.getCurrentQuestion().content)
            .fontSize(CommonConstants.FONT_BODY)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .lineHeight(24)
            .margin({ top: CommonConstants.SPACE_M })
            .width('100%')
  
          // 选项列表：Column + ForEach（题目最多 4 个选项，够短，没必要上 List）
          Column({ space: CommonConstants.SPACE_M }) {
            ForEach(this.getCurrentQuestion().options, (option: OptionItem) => {
              Row() {
                // 按题型分流：多选用 Checkbox（可多勾），单选/判断用 Radio（互斥单勾）
                if (this.getCurrentQuestion().type === 'MULTI') {
                  // 多选：Checkbox
                  // select(条件)：受控模式——勾选态由我们的 Set 决定，而非组件自己记忆
                  Checkbox()
                    .select(this.checkboxSelected.has(option.label))
                    .onChange((checked: boolean) => {
                      // 勾选进 Set、取消从 Set 删，UI 与数据始终保持一致
                      if (checked) {
                        this.checkboxSelected.add(option.label)
                      } else {
                        this.checkboxSelected.delete(option.label)
                      }
                    })
                } else {
                  // 单选/判断：Radio
                  // 同一 group 的 Radio 天然互斥：选中一个，其余自动取消
                  Radio({ value: option.label, group: 'options' })
                    .checked(this.radioSelected === option.label)
                    .onChange((checked: boolean) => {
                      // 只处理"被选中"分支：取消选中时不动状态（单选总有一个新选中项）
                      if (checked) {
                        this.radioSelected = option.label
                      }
                    })
                }
  
                Text(this.getOptionText(option))
                  .fontSize(CommonConstants.FONT_BODY)
                  .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                  .margin({ left: 8 })
              }
              .width('100%')
            }, (option: OptionItem) => option.label)
            // ↑ 键值生成器：选项 label（A/B/C/D）在单题内唯一，用它当 key
          }
          .margin({ top: CommonConstants.SPACE_L })
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)   // 中部吃掉剩余高度，把顶部/底部压在两端
        .padding(CommonConstants.SPACE_M)
        .margin({ top: CommonConstants.SPACE_M })
        .backgroundColor(Color.White)
        .borderRadius(8)
  
        // ===== 底部操作区 =====
        Column() {
          // 四个操作按钮
          Row({ space: 8 }) {
            Button('上一题')
              .type(ButtonType.Normal)
              .height(CommonConstants.BTN_HEIGHT)
              .fontSize(CommonConstants.FONT_CAPTION)
              .backgroundColor(CommonConstants.COLOR_TEXT_HINT)
              .fontColor(Color.White)
              .enabled(this.currentIndex > 0)   // 第 1 题时禁用，防越界
              .onClick(() => {
                this.currentIndex--
                this.resetSelection()   // 换题后清空上一题的勾选
              })
  
            Button('下一题')
              .type(ButtonType.Normal)
              .height(CommonConstants.BTN_HEIGHT)
              .fontSize(CommonConstants.FONT_CAPTION)
              .backgroundColor(CommonConstants.COLOR_TEXT_HINT)
              .fontColor(Color.White)
              .enabled(this.currentIndex < MOCK_QUESTIONS.length - 1)   // 最后一题时禁用
              .onClick(() => {
                this.currentIndex++
                this.resetSelection()
              })
  
            // 标记存疑 / 答题卡：UI 先行，事件后续阶段补
            Button('标记存疑')
              .type(ButtonType.Normal)
              .height(CommonConstants.BTN_HEIGHT)
              .fontSize(CommonConstants.FONT_CAPTION)
              .backgroundColor(Color.White)
              .fontColor(CommonConstants.COLOR_WARN)
              .border({ width: 1, color: CommonConstants.COLOR_WARN })
  
            Button('答题卡')
              .type(ButtonType.Normal)
              .height(CommonConstants.BTN_HEIGHT)
              .fontSize(CommonConstants.FONT_CAPTION)
              .backgroundColor(Color.White)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .border({ width: 1, color: CommonConstants.COLOR_TEXT_HINT })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)   // 四个按钮两端对齐铺满一行
  
          // 提交试卷按钮：渐变主按钮（整页视觉重心）
          Button('提交试卷')
            .type(ButtonType.Normal)
            .width('100%')
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_SUBTITLE)
            .fontColor(Color.White)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [[CommonConstants.GRADIENT_START, 0], [CommonConstants.GRADIENT_END, 1]]
            })
            .margin({ top: CommonConstants.SPACE_M })
            .onClick(() => {
              // 交卷后进结果页：push 到根栈（同样盖住底部 Tab，与答题页同一套"沉浸式"口径）
              this.pageStack.pushPathByName(RouteConstants.ANSWER_RESULT, null)
            })
        }
        .width('100%')
        .padding(CommonConstants.SPACE_M)
        .backgroundColor(Color.White)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
      .padding(CommonConstants.SPACE_M)
    }
    .hideTitleBar(true)   // 沉浸式：本页自带标题区，不要系统标题栏
  }
}
