// 考试模式答题页：顶部标题区 + 中部题目区 + 底部操作区
//
// 本页知识点：@Local 状态驱动 UI、ForEach 渲染选项列表、Radio/Checkbox 受控用法。
// 注意：本页不是独立路由页——它注册在**根栈**（RootDomain）的 RootRouter 上
//   （路由名 RouteConstants.EXAM_DETAIL），由试卷卡片 push 进入，push 后盖住底部 Tab（沉浸式详情页）。
// 【分层说明】本文件位于 features/exam/view/：它是"考试"feature 的页面，
//   页面根节点用 NavDestination（Navigation 体系的要求），路由名统一见 @zhititong/common 的 RouteConstants。
// 【MVVM】试卷名/题目/索引/选中状态全在 ExamDetailViewModel（@Trace），本页只渲染与转发事件；
//   onReady 从路由参数取 paperId 调 vm.startExam(paperId)，场次/题目/倒计时都由开考响应带回。
// 【切后台防作弊】进页 onReady 调 vm.startExam() 开始监视、交卷时由 VM 调 monitor.stop() 定格计数；
//   计数本身由 EntryAbility.onBackground 累加；提醒用 @Monitor 记账、onShown 补弹
//   （count 变更那一刻应用在后台，当场弹等于弹给空气，原因见 hintPending 的注释）。
//   F05 起页内另有一条常驻告警条（build 里顶部卡片之上那段 if）：条负责"持续留痕"、
//   Toast 负责"回前台即时告知"，两者并存、不是替换关系。
import { CommonConstants, RouteConstants, OptionItem, QuestionItem, FontSetting, StateKeys, BackgroundMonitor, Logger } from '@zhititong/common'
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

  // 答题卡半模态开关
  @Local showAnswerCard: boolean = false

  // 切后台次数一变就记一笔待提示。monitoring 与 count>0 都要判：
  // 开考 start() 里 count 会从上一场的值归 0，那是一次"变更"但不是一次"切出"，不能弹。
  @Monitor('monitor.count')
  onBackgroundCountChanged(): void {
    if (this.monitor.monitoring && this.monitor.count > 0) {
      this.hintPending = true
      // 如实上报，裁决在服务端：超限由后端回 shouldAutoSubmit，VM 再走统一交卷出口
      this.vm.onTabSwitch(this.monitor.count)
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

  // 断点续考提示：回填发生过就弹一次。restored 只在开考时置位，
  // 不像切屏那样有"弹给空气"的时序问题（这一刻人已经在页面上了）。
  @Monitor('vm.restored')
  onExamRestored(): void {
    if (!this.vm.restored) {
      return
    }
    try {
      this.getUIContext().getPromptAction().showToast({
        message: '已恢复上次考试进度',
        duration: 3000
      })
    } catch (err) {
      const e: BusinessError = err as BusinessError
      this.logger.warn(`续考提示 Toast 弹出失败 code=${e.code} message=${e.message}`)
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

  // 选项行是否处于选中态：多选取 checkboxSelected、单选/判断取 radioSelected。
  // 判据住在 view 是因为它只为高亮服务，不参与提交数据（提交流转在 VM）。
  // 注意别和"已答"混：答题卡格子统计的是跨题累计，走 vm.isQuestionAnswered()（读 VM 的 answers 表）；
  // 这里只关心"当前题此刻勾了什么"，所以取的是当前题的渲染态。
  private isOptionActive(option: OptionItem): boolean {
    const q: QuestionItem = this.vm.getCurrentQuestion()
    return q.type === 'MULTI' ? this.vm.checkboxSelected.has(option.label) : this.vm.radioSelected === option.label
  }

  // 答题卡面板：四种格子态——当前=主色描边、已答=成功浅底、存疑=告警浅底 + 右上实心点、未答=静息浅底。
  // 底色、描边、圆点是三层独立叠加，谁都不覆盖谁：第 7 题那种"存疑 + 当前"的复合态
  // 必须同时是告警浅底、主色 2vp 描边，并且带点（spec §4 F06 的复合态就靠叠放成立，不靠三元互斥）。
  @Builder
  AnswerCardSheet() {
    Column({ space: CommonConstants.SPACE_M }) {
      Text('答题卡')
        .fontSize(CommonConstants.FONT_HEADLINE_MD)
        .fontWeight(CommonConstants.WEIGHT_SEMI)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .width('100%')

      Text('已答 · 存疑 · 当前题 · 点击跳转')
        .fontSize(CommonConstants.FONT_BODY_SM)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .width('100%')

      Grid() {
        ForEach(this.vm.questions, (q: QuestionItem, index: number) => {
          GridItem() {
            Stack({ alignContent: Alignment.TopEnd }) {
              Text(`${index + 1}`)
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .fontColor(this.vm.isQuestionAnswered(q.id) && !this.vm.isQuestionFlagged(q.id)
                  ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_MAIN)
                .width(40)
                .height(40)
                .textAlign(TextAlign.Center)
                .backgroundColor(
                  this.vm.isQuestionFlagged(q.id) ? CommonConstants.COLOR_WARN_BG
                    : (this.vm.isQuestionAnswered(q.id) ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_SUBTLE_BG))
                .borderRadius(CommonConstants.RADIUS_BUTTON)
                .border({
                  width: index === this.vm.currentIndex ? 2 : 0.5,
                  color: index === this.vm.currentIndex ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_BORDER_HAIRLINE
                })
                .onClick(() => {
                  this.vm.jumpTo(index)
                  this.showAnswerCard = false
                })

              if (this.vm.isQuestionFlagged(q.id)) {
                // F06 存疑标记点：数字 Text 保持原链不动，点叠在右上角。
                // position 相对 Stack 左上角——x=30 让 8vp 的点落在 40vp 格内、右边与上边各留 2vp 余量。
                // hitTestBehavior(None) 不是装饰：点正落在格子的可点区域内，默认模式会阻塞兄弟节点的命中测试，
                // 用户恰好点在点上时就会"按了没反应"；None 才是自身不响应、兄弟与祖先照常响应
                // （SDK component/enums.d.ts 的 HitTestMode 注释）。
                Text('')
                  .width(8)
                  .height(8)
                  .borderRadius(4)
                  .backgroundColor(CommonConstants.COLOR_WARN)
                  .position({ x: 30, y: 2 })
                  .hitTestBehavior(HitTestMode.None)
              }
            }
          }
        }, (q: QuestionItem) => q.id)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(CommonConstants.SPACE_CARD_GAP)
      .columnsGap(CommonConstants.SPACE_M)
      .layoutWeight(1)
    }
    .padding(CommonConstants.SPACE_M)
    .width('100%')
    .height('100%')
  }

  build() {
    // NavDestination：Navigation 体系里"一个页面"的根节点，替代原来 @Entry 页面的角色
    NavDestination() {
      // 渲染守卫：题目未就绪先渲染占位，避免取空数组下标。
      // 文案按"错误优先"排：开考失败时 loading 已归 false，若照剧本的 loading ? 加载 : errorMessage
      // 顺序，既不加载又没错的空卷会显示成空白——所以 errorMessage 判在最前，最后兜"暂无题目"。
      if (this.vm.questions.length === 0) {
        Column() {
          Text(this.vm.errorMessage !== '' ? this.vm.errorMessage :
            (this.vm.loading ? '试卷加载中…' : '本卷暂无题目'))
            .fontSize(CommonConstants.FONT_BODY_LG)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .lineHeight(CommonConstants.LINE_BODY_LG)
            .fontColor(this.vm.errorMessage !== ''
              ? CommonConstants.COLOR_ERROR : CommonConstants.COLOR_TEXT_HINT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          // ===== 切屏常驻告警条（spec §4 F05）=====
          // 只在"本场进行中且确实切出过"时出现：monitoring 为假（未开考/已交卷）或 count 归零都不渲染，
          // 与 @Monitor + onShown 的 Toast 并存——条是页内持续留痕，Toast 是回前台那一刻的及时告知。
          if (this.monitor.monitoring && this.monitor.count > 0) {
            Row({ space: 8 }) {
              Text('检测到切出应用，已记录 ' + this.monitor.count + ' 次，请专心作答')
                .fontSize(CommonConstants.FONT_BODY_SM)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .lineHeight(CommonConstants.LINE_BODY_SM)
                .fontColor(CommonConstants.COLOR_ERROR)
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(CommonConstants.RADIUS_INPUT)
            .backgroundColor(CommonConstants.COLOR_ERROR_BG)
            .margin({ bottom: CommonConstants.SPACE_CARD_GAP })
          }

          // ===== 顶部标题区 =====
          Column() {
            // 试卷名
            Text(this.vm.paperName)
              .fontSize(CommonConstants.FONT_HEADLINE_SM)
              .fontWeight(CommonConstants.WEIGHT_SEMI)
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
              .fontSize(CommonConstants.FONT_BODY_MD)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .fontColor(CommonConstants.COLOR_TEXT_SUB)

              Blank()   // 弹性空隙：把倒计时推到行尾

              // 倒计时：绑服务端权威剩余秒数格式化结果（6-4 起不再是写死的静态值）
              // 字重按 §3.3 取该档强调上限 600，不再用系统枚举 Bold(700)
              Text(this.vm.getRemainingText())
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_SEMI)
                .fontColor(CommonConstants.COLOR_WARN)
            }
            .width('100%')
            .margin({ top: CommonConstants.SPACE_CARD_GAP })

            // F05 纤细进度条（spec §4 答题页明文"进度条改主色纤细"）：轨道通铺、主色按当前题号占比叠在上层。
            // 数据只取现成的 currentIndex / questions.length，不新增任何数据通路；
            // 上面那行"第 N 题 / 共 M 题"仍是权威文字，本条只表达比例，不参与任何判定。
            // 除零无需防御：能进到本分支就代表外层判据已保证 questions.length > 0。
            // 取 Stack 叠放而非"把填充条塞进轨道内部"——两条平级、各自 width/height，一眼看出谁盖谁。
            Stack({ alignContent: Alignment.Start }) {
              // 轨道：静息浅底
              Row()
                .width('100%')
                .height(3)
                .borderRadius(2)
                .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)

              // 填充：主色，宽度＝ (currentIndex + 1) / questions.length
              Row()
                .width(`${Math.round((this.vm.currentIndex + 1) / this.vm.questions.length * 100)}%`)
                .height(3)
                .borderRadius(2)
                .backgroundColor(CommonConstants.COLOR_PRIMARY)
            }
            .width('100%')
            .margin({ top: CommonConstants.SPACE_CARD_GAP })
          }
          .width('100%')
          .padding(CommonConstants.SPACE_M)
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
          .borderRadius(CommonConstants.RADIUS_CARD)
          .shadow(CommonConstants.SHADOW_CARD)

          // ===== 中部题目区域 =====
          // 结构：外层 Column 是"卡壳"（底色/圆角/阴影/内边距全在它身上），里面只有一个 Scroll，
          //   Scroll 的唯一子节点是内容 Column（题型标签 + 题干 + 选项列表）。圆角/阴影留外层，
          //   是因为它们描述的是卡片外形，不该随内容一起滚走。
          // 为什么必须能滚：Step 4 给选项行加了上下各 10 的内边距与 1vp 描边，每行高约 +22vp、四行 +88vp；
          //   切屏告警条在场时顶部还要再吃掉约 56vp。本区高度由 layoutWeight(1) 分配、自己不会长，
          //   于是长题干 + 四选项在中小屏或极大字号档下必然超出——不滚就是裁掉且摸不着。
          // 两条被否决的替代写法：选项 Column 换 List 只救选项、救不了长题干与最大字号档；
          //   页级 Scroll 会把顶部/中部/底部的三段式 layoutWeight 结构拆掉。
          Column() {
            Scroll() {
              Column() {
                // 题型标签：浅蓝底全圆胶囊（与 Task 5 的等级标签同构；换装前是"透明底 + 主色 1vp 描边 + 圆角 4"）
                // 按 §6.4 定案：tint 底 + 同色相饱和字，**不加描边**。
                // RADIUS_TAG 是 9999，靠 ArkUI 把 borderRadius 钳到短边一半得到正胶囊。
                Text(this.vm.getTypeLabel(this.vm.getCurrentQuestion().type))
                  .fontSize(CommonConstants.FONT_LABEL_SM)
                  .fontWeight(CommonConstants.WEIGHT_MEDIUM)
                  .fontColor(CommonConstants.COLOR_PRIMARY)
                  .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
                  .borderRadius(CommonConstants.RADIUS_TAG)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .height(24)

                // 题干
                Text(this.vm.getCurrentQuestion().content)
                  .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY_LG))
                  .fontWeight(CommonConstants.WEIGHT_REGULAR)
                  .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                  // 行高与字号走同一个偏移量：只放大字不动行高，五档下会越挤越近（24/16=1.5 的余量被吃掉）
                  .lineHeight(this.font.sizeOf(24))
                  .margin({ top: CommonConstants.SPACE_M })
                  .width('100%')

                // 选项列表：Column + ForEach。行数确实封顶 4，但每行加了内边距与描边后已经不再"够短"，
                //   何况题干长度与字号档位本来就不可控——不溢出靠外层 Scroll 兜，不再靠"内容短"自证安全。
                Column({ space: CommonConstants.SPACE_CARD_GAP }) {
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
                        .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY_LG))
                        .fontWeight(CommonConstants.WEIGHT_REGULAR)
                        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                        // 选项正文与题干同类：内容长度随题目变，窄窗/分屏/极大档下会折行 → 配行高，
                        // 且与字号走同一偏移（不写死值，否则放大档位下行距会被压回原尺寸）
                        .lineHeight(this.font.sizeOf(24))
                        .margin({ left: 8 })
                    }
                    .width('100%')
                    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                    .borderRadius(CommonConstants.RADIUS_INPUT)
                    .backgroundColor(this.isOptionActive(option) ? CommonConstants.COLOR_PRIMARY_BG : CommonConstants.COLOR_CARD_BG)
                    .border({
                      width: 1,
                      color: this.isOptionActive(option) ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_BORDER_HAIRLINE
                    })
                  }, (option: OptionItem) => this.vm.getCurrentQuestion().id + '_' + option.label)
                  // ↑ 键值生成器：必须带题目 id。选项 label 只有 A/B/C/D，跨题重复——
                  //   若只用 label 当 key，切题时 key 不变，ForEach 判定"没变"就复用旧节点，
                  //   选项文字会永远卡在第一题（实测：高级卷 12/13/14 题全显示第 1 题选项）。
                }
                .margin({ top: CommonConstants.SPACE_L })
                .width('100%')
              }
              .width('100%')
              // 内容一律左对齐：Column 默认 alignItems 是 Center，不写明则题型胶囊会被推到卡片正中，
              // 与它下面左起的题干/选项不成一条排版线（这是进 Scroll 时顺手收掉的一处错位）。
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)   // Scroll 取卡内剩余高度作视口：没有确定视口就没有"可滚"，只有溢出
            .scrollBar(BarState.Auto)
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)   // 中部吃掉剩余高度，把顶部/底部压在两端
          .padding(CommonConstants.SPACE_M)
          .margin({ top: CommonConstants.SPACE_CARD_GAP })
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
          .borderRadius(CommonConstants.RADIUS_CARD)
          .shadow(CommonConstants.SHADOW_CARD)

          // ===== 底部操作区 =====
          Column() {
            // 四个操作按钮
            Row({ space: 8 }) {
              Button('上一题')
                .type(ButtonType.Normal)
                .height(CommonConstants.BTN_HEIGHT)
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_MEDIUM)   // 按钮默认字重即 500（SDK button.d.ts），写明不改观感
                .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
                .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                .borderRadius(CommonConstants.RADIUS_BUTTON)
                .enabled(this.vm.currentIndex > 0)   // 第 1 题时禁用，防越界
                .onClick(() => {
                  // 边界判断 + 换题重置选中，规则都在 VM 里
                  this.vm.goToPrev()
                })

              Button('下一题')
                .type(ButtonType.Normal)
                .height(CommonConstants.BTN_HEIGHT)
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_MEDIUM)
                .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
                .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                .borderRadius(CommonConstants.RADIUS_BUTTON)
                .enabled(this.vm.currentIndex < this.vm.questions.length - 1)   // 最后一题时禁用
                .onClick(() => {
                  this.vm.goToNext()
                })

              // 标记存疑：再点一次取消；标记与答案一起实时上报（同一保存接口承载两者）
              // 选中态底：换装前是写死的浅橙值，现取告警浅底令牌 COLOR_WARN_BG（与答题卡存疑格同一档）
              Button(this.vm.isQuestionFlagged(this.vm.getCurrentQuestion().id)
                ? '已存疑' : '标记存疑')
                .type(ButtonType.Normal)
                .height(CommonConstants.BTN_HEIGHT)
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_MEDIUM)
                .backgroundColor(this.vm.isQuestionFlagged(this.vm.getCurrentQuestion().id)
                  ? CommonConstants.COLOR_WARN_BG : CommonConstants.COLOR_CARD_BG)
                .fontColor(CommonConstants.COLOR_WARN)
                .borderRadius(CommonConstants.RADIUS_BUTTON)
                .border({ width: 1, color: CommonConstants.COLOR_WARN })
                .onClick(() => {
                  this.vm.toggleFlagCurrent()
                })

              Button('答题卡')
                .type(ButtonType.Normal)
                .height(CommonConstants.BTN_HEIGHT)
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_MEDIUM)
                .backgroundColor(CommonConstants.COLOR_CARD_BG)
                .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                .borderRadius(CommonConstants.RADIUS_BUTTON)
                .border({ width: 1, color: CommonConstants.COLOR_BORDER_HAIRLINE })
                .onClick(() => {
                  this.showAnswerCard = true
                })
                .bindSheet(this.showAnswerCard, this.AnswerCardSheet(), {
                  height: 440,
                  showClose: true,
                  onDisappear: () => {
                    this.showAnswerCard = false
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)   // 四个按钮两端对齐铺满一行

            // 提交试卷按钮：纯色主按钮（spec §6.1——本计划去掉的最后一处渐变）
            Button('提交试卷')
              .type(ButtonType.Normal)
              .width('100%')
              .height(CommonConstants.BTN_HEIGHT)
              .borderRadius(CommonConstants.RADIUS_BUTTON)
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_MEDIUM)
              .fontColor(CommonConstants.COLOR_CARD_BG)
              .backgroundColor(CommonConstants.COLOR_PRIMARY)
              // 按下态：与登录页主按钮同一机制（stateStyles 的 pressed 键，纯声明式、只支持通用属性）。
              // 用 SDK 认可的属性调用写法 `{ .backgroundColor(...) }`，不是对象字面量写法。
              .stateStyles({
                pressed: {
                  .backgroundColor(CommonConstants.COLOR_PRIMARY_PRESSED)
                }
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
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
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
