// 考卷列表页：按科目过滤 MOCK_PAPERS，用 List 渲染该科目下的考卷
//
// 【分层说明】本文件位于 features/exam/view/：
//   它是 Exam 域的**域内路由页**——注册在 ExamSubjectView 的 ExamRouter 上
//   （路由名 RouteConstants.EXAM_LIST），由科目卡片 push 进 examStack，
//   所以它出现时**底部 Tab 仍然可见**（对比答题页走根栈的"沉浸式盖住 Tab"）。
// 【参数怎么传进来】上游用 pushPathByName(EXAM_LIST, group.categoryName) 压栈，
//   本页在 NavDestination 的 onReady 里从 ctx.pathInfo.param 取出——
//   onReady 是 Navigation 体系里接收路由参数的推荐时机（页面创建时触发一次）。
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { RouteConstants } from '../../../common/constants/RouteConstants'
import { MOCK_PAPERS } from '../../../common/mock/MockExamData'
import { PaperInfo } from '../../../common/model/QuestionModel'

// 考卷行组件：白底圆角，展示试卷名 / 等级标签 / 题量信息 / 已考次数 / 成绩角标
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
        Text(this.paper.paperName)
          .fontSize(CommonConstants.FONT_BODY)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 第二行：共 X 题 · Y 分钟 · 及格 Z 分
        Text(`共 ${this.paper.questionCount} 题 · ${this.paper.duration} 分钟 · 及格 ${this.paper.passScore} 分`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 8 })

        // 第三行：已考次数（读契约字段 attemptCount / maxAttempts）
        Text(`已考 ${this.paper.attemptCount}/${this.paper.maxAttempts} 次`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_TEXT_HINT)
          .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：等级标签 + 成绩角标，垂直排列并居中
      Column() {
        // 等级标签：主色描边胶囊（与首页 PaperCard 保持同一套视觉语言）
        Text(this.paper.levelName)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .border({ width: 1, color: CommonConstants.COLOR_PRIMARY })
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })

        // 成绩角标：条件渲染——考过显示最好成绩，没考过显示"未考"
        if (this.paper.bestScore > 0) {
          Text(`最好 ${this.paper.bestScore} 分`)
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_SUCCESS)
            .margin({ top: 6 })
        } else {
          Text('未考')
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
            .margin({ top: 6 })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .borderRadius(12)
    .backgroundColor(Color.White)
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
  // 该科目下的考卷列表，onReady 里按 categoryName 过滤 MOCK_PAPERS 得到
  @Local papers: PaperInfo[] = []

  // 自定义标题栏：不能直接写 .title(this.categoryName)——字符串标题只在 NavDestination
  // 创建的那一刻求值一次，而 categoryName 要等 onReady 才拿到，那时标题早渲染完了（会显示空白）。
  // 套一层 @Builder，里面的 Text 才会跟着 @Local 变化重新渲染
  @Builder
  titleBuilder() {
    Text(this.categoryName)
      .fontSize(CommonConstants.FONT_SUBTITLE)
      .fontColor(CommonConstants.COLOR_TEXT_MAIN)
      .fontWeight(FontWeight.Bold)
  }

  build() {
    NavDestination() {
      // 条件渲染：有卷就列出来，没卷显示空态
      if (this.papers.length === 0) {
        // 空态：某个科目一张卷都没有时（当前 Mock 数据里不存在这种科目，逻辑先备好）
        Column() {
          Text('该科目暂无考卷')
            .fontSize(CommonConstants.FONT_BODY)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // ===== List 列表（3.2.1）=====
        // 考卷行用 List + ListItem + ForEach 驱动；考卷可能很多，List 的按需渲染正是为此
        List() {
          ForEach(this.papers, (paper: PaperInfo) => {
            ListItem() {
              // 点击跳转由 PaperRow 自己处理（取根栈 push 答题页），容器这里只管排版
              PaperRow({ paper: paper })
            }
            .margin({ bottom: CommonConstants.SPACE_M })   // 行间距加在 ListItem 上
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
      // 按科目过滤：只留 categoryName 与上游一致的试卷
      this.papers = MOCK_PAPERS.filter((paper: PaperInfo): boolean =>
        paper.categoryName === this.categoryName)
    })
  }
}