// 考卷列表页：用 List 渲染当前科目下的考卷（数据由 ExamListViewModel 按科目过滤 MOCK_PAPERS 提供）
//
// 【分层说明】本文件位于 features/exam/view/：
//   它是 Exam 域的**域内路由页**——注册在 ExamSubjectView 的 ExamRouter 上
//   （路由名 RouteConstants.EXAM_LIST），由科目卡片 push 进 examStack，
//   所以它出现时**底部 Tab 仍然可见**（对比答题页走根栈的"沉浸式盖住 Tab"）。
// 【参数怎么传进来】上游用 pushPathByName(EXAM_LIST, group.categoryName) 压栈，
//   本页在 NavDestination 的 onReady 里从 ctx.pathInfo.param 取出——
//   onReady 是 Navigation 体系里接收路由参数的推荐时机（页面创建时触发一次）。
import { CommonConstants, RouteConstants, PaperInfo } from '@zhititong/common'
import { ExamListViewModel } from '../viewmodel/ExamListViewModel'

// 考卷行组件：卡面走方案A 令牌（圆角 16 + Level 1 阴影 + 0.5 发丝描边，与首页 PaperCard 同构），
// 展示试卷名 / 等级胶囊 / 题量信息 / 已考次数 / 成绩角标
// 独立成 @ComponentV2 子组件（而不是塞在页面的 ForEach 里），列表项逻辑才不糊成一团
@ComponentV2
struct PaperRow {
  // @Param @Require：父组件（ExamListPage）把一条试卷数据传进来
  @Param @Require paper: PaperInfo
  // 行点击要跳答题页，而答题页是"沉浸式详情页"——它注册在**根栈**上，
  // 所以这里取的是 pageStack 而不是 examStack：点考卷会盖住底部 Tab，
  // 与首页卡片点进去的体验保持一致（而不是像科目列表那样保留 Tab）
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()

  build() {
    Row() {
      // 左侧主内容区：layoutWeight(1) 吃掉剩余宽度，把右侧标签挤到最右边
      Column() {
        // 试卷名：单行省略，防止长试卷名把行撑爆
        // 字阶取"小标题"档（16/600，与 PaperCard 试卷名同链）；maxLines(1) 锁死行数，不配行高
        Text(this.paper.paperName)
          .fontSize(CommonConstants.FONT_HEADLINE_SM)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 第二行：共 X 题 · Y 分钟 · 及格 Z 分
        // 模板字符串把三个契约字段拼成一行说明文字，长度随数据变→判"可换行"，配对行高
        //（父 Column 高度自适应，折行能显示，不裁切——与 PaperCard 副行同一判定）
        Text(`共 ${this.paper.questionCount} 题 · ${this.paper.duration} 分钟 · 及格 ${this.paper.passScore} 分`)
          .fontSize(CommonConstants.FONT_BODY_SM)
          .fontWeight(CommonConstants.WEIGHT_REGULAR)
          .lineHeight(CommonConstants.LINE_BODY_SM)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 8 })

        // 第三行：已考次数（读契约字段 attemptCount / maxAttempts）
        // "已考 x/y 次"最宽也就十来字符，左列宽度容得下，归"不换行"类——不配行高
        Text(`已考 ${this.paper.attemptCount}/${this.paper.maxAttempts} 次`)
          .fontSize(CommonConstants.FONT_BODY_SM)
          .fontWeight(CommonConstants.WEIGHT_REGULAR)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：等级胶囊 + 成绩角标，垂直排列并居中
      Column() {
        // 等级标签：浅蓝底全圆胶囊（换装前是"透明底 + 主色 1vp 描边 + 圆角 4"）
        // RADIUS_TAG 是 9999，靠 ArkUI 把 borderRadius 钳到短边一半得到正胶囊
        Text(this.paper.levelName)
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .height(24)

        // 成绩角标：条件渲染——考过显示最好成绩（成功色 + 成功浅底），没考过显示"未考"（提示色 + 静息底）
        // 形态与等级胶囊同构（同一套属性链）；原先是两个 if 分支各一条 Text，
        // 现按简报合写为一条三元 Text——条件在这里是真的（不再是分支内的"永真死代码"），
        // 属性链顺序与 PaperCard 右侧角标逐字一致
        Text(this.paper.bestScore > 0 ? `最好 ${this.paper.bestScore} 分` : '未考')
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(this.paper.bestScore > 0 ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_HINT)
          .backgroundColor(this.paper.bestScore > 0 ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_SUBTLE_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .height(24)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    // 卡面不给整周描边（spec §6.6）：导出的 12 屏里 63 个卡级容器 0 个带 border、51 个带 shadow，
    //   prose 的「描边 + 阴影」两件套按 §6.4 取克制一读 ⇒ 只留 Level 1 阴影。
    .shadow(CommonConstants.SHADOW_CARD)
    .onClick(() => {
      // 沉浸式跳转：push 到根栈，答题页全屏盖住底部 Tab
      // 第二个参数传的是这张卷的 id（答题页后续按它取卷，当前 Mock 阶段答题页还没用上）
      this.pageStack.pushPathByName(RouteConstants.EXAM_DETAIL, this.paper.id)
    })
  }
}

@ComponentV2
export struct ExamListPage {
  // 上游传进来的科目名，onReady 里从路由参数读取
  @Local categoryName: string = ''
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；papers 是 @Trace 字段，VM 加载完成后 List 自动刷新
  @Local vm: ExamListViewModel = new ExamListViewModel()

  // 自定义标题栏：不能直接写 .title(this.categoryName)——字符串标题只在 NavDestination
  // 创建的那一刻求值一次，而 categoryName 要等 onReady 才拿到，那时标题早渲染完了（会显示空白）。
  // 套一层 @Builder，里面的 Text 才会跟着 @Local 变化重新渲染
  @Builder
  titleBuilder() {
    // 档级对齐首页/科目页标题（20/600）；标题栏是系统固定高度的容器，
    // 科目名超长由标题栏自身处理——这里归"单行标签"类，不配行高，套上会在栏内裁字
    Text(this.categoryName)
      .fontSize(CommonConstants.FONT_HEADLINE_MD)
      .fontWeight(CommonConstants.WEIGHT_SEMI)
      .fontColor(CommonConstants.COLOR_TEXT_MAIN)
  }

  build() {
    NavDestination() {
      // 条件渲染：有卷就列出来，没卷显示空态
      if (this.vm.papers.length === 0) {
        // 空态：某个科目一张卷都没有时（当前 Mock 数据里不存在这种科目，逻辑先备好）
        // 六字定文案居中于整页 Column，判"不换行"——不配行高
        Column() {
          Text('该科目暂无考卷')
            .fontSize(CommonConstants.FONT_BODY_MD)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // ===== List 列表（3.2.1）=====
        // 考卷行用 List + ListItem + ForEach 驱动；考卷可能很多，List 的按需渲染正是为此
        // 行间距统一交给构造参数 { space: 12 }（令牌 SPACE_CARD_GAP，spec §3.4 纵向节奏），
        // 与首页 HomeView 的推荐试卷列表同轨——原先加在 ListItem 上的 margin(SPACE_M=16) 一并撤掉，
        // 否则 space 与 margin 叠加成 28（HomeView 已踩过并留了同样的说明）。
        List({ space: CommonConstants.SPACE_CARD_GAP }) {
          ForEach(this.vm.papers, (paper: PaperInfo) => {
            ListItem() {
              // 点击跳转由 PaperRow 自己处理（取根栈 push 答题页），容器这里只管排版
              PaperRow({ paper: paper })
            }
          }, (paper: PaperInfo) => paper.id)   // 键值用试卷全局唯一的 id，禁止用下标
          // ↑ 用稳定 id 当 key：数据增删/顺序变化时框架才判断得准哪些项可复用，
          //   用下标会导致复用错位（角标、标签串到别的行上）
        }
        .width('100%')
        .height('100%')
        .padding(CommonConstants.SPACE_M)
      }
    }
    .title(this.titleBuilder)   // 标题栏显示科目名（用 @Builder 才响应状态；自带返回箭头可回科目页）
    .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    .onReady((ctx: NavDestinationContext) => {
      // onReady：NavDestination 创建时触发一次，是接收路由参数的推荐时机。
      // ctx.pathInfo.param 就是上游 pushPathByName 时传的第二个参数（这里是 categoryName 字符串）
      // pathInfo.param 的静态类型是 unknown（路由参数允许传任意类型）。
      // ArkTS 不允许显式声明 unknown 变量（arkts-no-any-unknown 规则），
      // 所以这里直接断言成我们约定的类型——传参方 ExamSubjectCard 传的就是 string
      this.categoryName = ctx.pathInfo.param as string
      // MVVM：按科目过滤属业务规则，收拢在 ViewModel；View 只转发事件与渲染
      // 返回的 Result 这里不处理——失败态由 vm.errorMessage 承载，静态 Demo 阶段 Mock 过滤不会失败
      this.vm.loadPapersByCategory(this.categoryName)
    })
  }
}