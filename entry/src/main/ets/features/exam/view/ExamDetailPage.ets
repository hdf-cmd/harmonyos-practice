// 考试模式答题页：顶部标题区 + 中部题目区 + 底部操作区
//
// 本页知识点：@Local 状态驱动 UI、ForEach 渲染选项列表、Radio/Checkbox 受控用法。
// 注意：本页不是独立路由页——它注册在**根栈**（RootDomain）的 RootRouter 上
//   （路由名 RouteConstants.EXAM_DETAIL），由试卷卡片 push 进入，push 后盖住底部 Tab（沉浸式详情页）。
// 【分层说明】本文件位于 features/exam/view/：它是"考试"feature 的页面，
//   页面根节点用 NavDestination（Navigation 体系的要求），路由名统一见 @zhititong/common 的 RouteConstants。
// 【MVVM】试卷名/题目/索引/选中状态全在 ExamDetailViewModel（@Trace），本页只渲染与转发事件；
//   onReady 从路由参数取 paperId 调 vm.loadPaper(paperId)，按 id 命中试卷名（Mock 阶段题目固定 MOCK_QUESTIONS）。
// 【切后台防作弊】进页 onReady 调 vm.startExam() 开始监视、交卷前先调 vm.submitPaper() 定格计数；
//   计数本身由 EntryAbility.onBackground 累加；提醒用 @Monitor 记账、onShown 补弹
//   （count 变更那一刻应用在后台，当场弹等于弹给空气，原因见 hintPending 的注释）。
import { CommonConstants, RouteConstants, OptionItem, FontSetting, StateKeys, BackgroundMonitor, Logger } from '@zhititong/common'
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'
import { ExamDetailViewModel } from '../viewmodel/ExamDetailViewModel'

@Preview
@ComponentV2
export struct ExamDetailPage {
  // 跨层级直取根栈：答题页是"沉浸式详情页"，统一 push 到根栈，盖住底部 Tab
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；paperName/questions/index/选中态都是 @Trace 字段，变更自动刷新
  @Local vm: ExamDetailViewModel = new ExamDetailViewModel()
  // 全局字号：与"我的"页用同一个 key connect，拿回来的是同一个实例——
  //   所以在设置页拨档位，本页的题干/选项会跟着即时变（应用级状态的"全局"就落在这）
  @Local font: FontSetting = PersistenceV2.connect(FontSetting, StateKeys.FONT_SETTING,
    () => new FontSetting())!
  // 切后台监视器：与 EntryAbility.onBackground、ExamDetailViewModel 同一个 key，取回同一个实例。
  // 在页面里持有它只为让下面的 @Monitor 能盯住 count —— 计数是在 Ability 侧加的，本页不参与计数。
  @Local monitor: BackgroundMonitor = AppStorageV2.connect(BackgroundMonitor, StateKeys.BACKGROUND_MONITOR,
    () => new BackgroundMonitor())!
  private logger: Logger = new Logger('[ExamDetailPage]')
  // 有切出待提示：@Monitor 置位、onShown 消费。
  // 为什么要拆两处 —— 实测（Pura 90，09:32:50 那轮）：count 变更发生在 onBackground 那一刻，
  // 应用已在后台，Toast 虽然真的挂载了（AceOverlay: Toast node mount to root node），
  // 但 3 秒生命周期整个烧在没人看的窗口里，回到前台时只剩退场日志。
  // 所以"记账"留在 @Monitor（它才是 count 变化的第一现场），"弹给人看"交给回前台必走的 onShown。
  @Local hintPending: boolean = false

  // 切后台次数一变就记一笔待提示。monitoring 与 count>0 都要判：
  // 开考 start() 里 count 会从上一场的值归 0，那是一次"变更"但不是一次"切出"，不能弹。
  @Monitor('monitor.count')
  onBackgroundCountChanged(): void {
    if (this.monitor.monitoring && this.monitor.count > 0) {
      this.hintPending = true
    }
  }

  // 交卷信号灯：VM 把 finishedAttemptId 从空串点亮为场次号，这里看灯跳结果页。
  // 用 replace 而不是 push——交卷后不允许物理返回返回答题页（导航单一出口，VM 不碰栈）。
  @Monitor('vm.finishedAttemptId')
  onExamFinished(): void {
    if (this.vm.finishedAttemptId !== '') {
      this.pageStack.replacePathByName(RouteConstants.ANSWER_RESULT, this.vm.finishedAttemptId)
    }
  }

  // 回前台补提示：一次切出弹一次（hintPending 消费后即复位），连切多次回来只弹一次总数——
  // 观众只有一个，逐条弹反而刷不完。
  private showBackgroundHint(): void {
    if (!this.hintPending) {
      return
    }
    this.hintPending = false
    try {
      this.getUIContext().getPromptAction().showToast({
        message: `检测到切出应用，已记录 ${this.monitor.count} 次，请专心作答`,
        duration: 3000
      })
    } catch (err) {
      const e: BusinessError = err as BusinessError
      this.logger.warn(`切后台提醒 Toast 弹出失败 code=${e.code} message=${e.message}`)
    }
  }

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

              // 倒计时：绑服务端权威剩余秒数格式化结果（6-4 起不再是写死的静态值）
              Text(this.vm.getRemainingText())
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
              .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY))
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              // 行高与字号走同一个偏移量：只放大字不动行高，五档下会越挤越近（24/16=1.5 的余量被吃掉）
              .lineHeight(this.font.sizeOf(24))
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
                    .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY))
                    .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                    .margin({ left: 8 })
                }
                .width('100%')
              }, (option: OptionItem) => this.vm.getCurrentQuestion().id + '_' + option.label)
              // ↑ 键值生成器：必须带题目 id。选项 label 只有 A/B/C/D，跨题重复——
              //   若只用 label 当 key，切题时 key 不变，ForEach 判定"没变"就复用旧节点，
              //   选项文字会永远卡在第一题（实测：高级卷 12/13/14 题全显示第 1 题选项）。
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
                // 手动交卷：VM 内部会停表、定格切后台计数、点亮 finishedAttemptId；
                // 跳转不在这做——统一由下面的 @Monitor('vm.finishedAttemptId') 看灯导航（单一出口）
                this.vm.submit('MANUAL')
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
      // pathInfo.param 静态类型 unknown，ArkTS 禁显式声明 unknown，直接 as string。
      // 开考（或断点续考）：一次性装载场次/题目/倒计时并开启切后台监视。
      // 【为什么必须 onReady 不能 onShown】onShown 在应用从后台切回时也会触发，
      //   一旦用它开考，用户切出去再回来就把这一场重开/清零了——防作弊计数与场次都乱。
      this.vm.startExam(ctx.pathInfo.param as string)
    })
    .onShown(() => {
      // 回到本页/回到前台都走这里：把后台期间欠下的切出提醒补弹出来
      this.showBackgroundHint()
    })
    .onWillDisappear(() => {
      // 兜底清定时器：交卷成功路径已 dispose，这里是用户物理返回时的保险，防定时器泄漏
      this.vm.dispose()
    })
  }
}
