// 考试模式答题页：顶部标题区 + 中部题目区 + 底部操作区
//
// 本页知识点：@Local 状态驱动 UI、ForEach 渲染选项列表、Radio/Checkbox 受控用法。
// 注意：本页不是独立路由页——它注册在**根栈**（RootDomain）的 RootRouter 上
//   （路由名 RouteConstants.EXAM_DETAIL），由试卷卡片 push 进入，push 后盖住底部 Tab（沉浸式详情页）。
// 【分层说明】本文件位于 features/exam/view/：它是"考试"feature 的页面，
//   页面根节点用 NavDestination（Navigation 体系的要求），路由名统一见 common/constants/RouteConstants.ets。
// 【MVVM】试卷名/题目/索引/选中状态全在 ExamDetailViewModel（@Trace），本页只渲染与转发事件；
//   onReady 从路由参数取 paperId 调 vm.loadPaper(paperId)，按 id 命中试卷名（Mock 阶段题目固定 MOCK_QUESTIONS）。
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { RouteConstants } from '../../../common/constants/RouteConstants'
import { OptionItem } from '../../../common/model/QuestionModel'
import { ExamDetailViewModel } from '../viewmodel/ExamDetailViewModel'

@Preview
@ComponentV2
export struct ExamDetailPage {
  // 跨层级直取根栈：答题页是"沉浸式详情页"，统一 push 到根栈，盖住底部 Tab
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；paperName/questions/index/选中态都是 @Trace 字段，变更自动刷新
  @Local vm: ExamDetailViewModel = new ExamDetailViewModel()

  build() {
    // NavDestination：Navigation 体系里"一个页面"的根节点，替代原来 @Entry 页面的角色
    NavDestination() {
      // 渲染守卫：题目未就绪（loadPaper 完成前）先渲染占位，避免取空数组下标
      if (this.vm.questions.length === 0) {
        Column() {
          Text('试卷加载中…')
            .fontSize(CommonConstants.FONT_BODY)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          // ===== 顶部标题区 =====
          Column() {
            // 试卷名
            Text(this.vm.paperName)
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
                Span((this.vm.currentIndex + 1).toString())
                  .fontColor(CommonConstants.COLOR_WARN)
                Span(' 题 / 共 ')
                Span(this.vm.questions.length.toString())
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
            Text(this.vm.getTypeLabel(this.vm.getCurrentQuestion().type))
              .fontSize(CommonConstants.FONT_CAPTION)
              .fontColor(CommonConstants.COLOR_PRIMARY)
              .border({ width: 1, color: CommonConstants.COLOR_PRIMARY, radius: 4 })
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })

            // 题干
            Text(this.vm.getCurrentQuestion().content)
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .lineHeight(24)
              .margin({ top: CommonConstants.SPACE_M })
              .width('100%')

            // 选项列表：Column + ForEach（题目最多 4 个选项，够短，没必要上 List）
            Column({ space: CommonConstants.SPACE_M }) {
              ForEach(this.vm.getCurrentQuestion().options, (option: OptionItem) => {
                Row() {
                  // 按题型分流：多选用 Checkbox（可多勾），单选/判断用 Radio（互斥单勾）
                  if (this.vm.getCurrentQuestion().type === 'MULTI') {
                    // 多选：Checkbox
                    // select(条件)：受控模式——勾选态由 VM 的 Set 决定，而非组件自己记忆
                    Checkbox()
                      .select(this.vm.checkboxSelected.has(option.label))
                      .onChange((checked: boolean) => {
                        // 勾选/取消流转住在 VM：整体替换 Set，UI 与数据始终保持一致
                        this.vm.toggleMultiOption(option.label, checked)
                      })
                  } else {
                    // 单选/判断：Radio
                    // 同一 group 的 Radio 天然互斥：选中一个，其余自动取消
                    Radio({ value: option.label, group: 'options' })
                      .checked(this.vm.radioSelected === option.label)
                      .onChange((checked: boolean) => {
                        // 只处理"被选中"分支：取消选中时不动状态（单选总有一个新选中项）
                        if (checked) {
                          this.vm.selectSingleOption(option.label)
                        }
                      })
                  }

                  Text(this.vm.getOptionText(option))
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
                .enabled(this.vm.currentIndex > 0)   // 第 1 题时禁用，防越界
                .onClick(() => {
                  // 边界判断 + 换题重置选中，规则都在 VM 里
                  this.vm.goToPrev()
                })

              Button('下一题')
                .type(ButtonType.Normal)
                .height(CommonConstants.BTN_HEIGHT)
                .fontSize(CommonConstants.FONT_CAPTION)
                .backgroundColor(CommonConstants.COLOR_TEXT_HINT)
                .fontColor(Color.White)
                .enabled(this.vm.currentIndex < this.vm.questions.length - 1)   // 最后一题时禁用
                .onClick(() => {
                  this.vm.goToNext()
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
    }
    .hideTitleBar(true)   // 沉浸式：本页自带标题区，不要系统标题栏
    .onReady((ctx: NavDestinationContext) => {
      // onReady：NavDestination 创建时触发一次，是接收路由参数的推荐时机。
      // 上游试卷卡片 pushPathByName(EXAM_DETAIL, paper.id) 传的就是试卷 id。
      // pathInfo.param 的静态类型是 unknown，ArkTS 禁止显式声明 unknown（arkts-no-any-unknown），
      // 直接 as string 断言成约定的类型
      this.vm.loadPaper(ctx.pathInfo.param as string)
    })
  }
}
