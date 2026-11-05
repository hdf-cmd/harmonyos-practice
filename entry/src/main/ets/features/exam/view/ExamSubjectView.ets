// 考试科目页：顶部标题 + 两列科目网格，数据来自 MOCK_PAPERS 按 categoryName 客户端聚合
//
// 【分层说明】本文件位于 features/exam/view/：
//   ExamSubjectView 是"刷题"Tab 的内容组件——没加 @Entry，不是路由页，
//   由 pages/MainPage.ets 的 TabContent 直接嵌套使用，因此不需要注册到 main_pages.json。
//   本 feature 私有的子组件已抽到 ./components/ExamSubjectCard.ets。
// 【三级导航】Exam 域自持子栈（examStack）并把域内子页（考卷列表）注册到 ExamRouter——
//   域内跳转保留底部 Tab，与首页卡片走根栈的"沉浸式"形成对照。
// 【知识点 3.2.2 Grid 网格组件】本页是 Grid 的基础示例：两列科目卡片。
// Grid 是"二维网格容器"，子项必须包在 GridItem 里，按"行 × 列"铺排。
// 与 List 的分工：List 是一维流式列表（一列/一行）；Grid 天生管"多列对齐"的布局，
// 典型场景：九宫格、相册、分类入口（本页）。
import { CommonConstants, RouteConstants, CategoryGroup } from '@zhititong/common'
import { ExamSubjectViewModel } from '../viewmodel/ExamSubjectViewModel'
import { ExamSubjectCard } from './components/ExamSubjectCard'
import { ExamListPage } from './ExamListPage'

@ComponentV2
export struct ExamSubjectView {
  // 三级导航：Exam 域自持子栈
  @Provider('examStack') examStack: NavPathStack = new NavPathStack()
  // 会话失效要跳登录页——登录页注册在根栈，这里跨层级取根栈（与首页同一套口径）
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；groups 是 @Trace 字段，VM 加载完成后 Grid 自动刷新
  @Local vm: ExamSubjectViewModel = new ExamSubjectViewModel()

  // 页面创建时加载一次科目分组。返回的 Result 这里不处理——失败态由 vm.errorMessage 承载，
  // 由下面的 LoadFailed 分支渲染成可见的错误区（曾经这里什么都不画，401 时整页只剩一个标题）
  aboutToAppear(): void {
    this.vm.loadSubjectGroups()
  }

  // 加载失败区：与首页同一套分流——会话失效跳登录，其它失败留在本页重拉
  @Builder
  LoadFailed() {
    Column() {
      // 错误文案来自后端/网络层，长度不可控→属"会换行"的文字，按 §3.3 配对行高
      //（同首页 HomeView 的失败区口径；三态视觉的统一归口留给 Task 12）
      Text(this.vm.errorMessage)
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(CommonConstants.LINE_BODY_LG)
        .fontColor(CommonConstants.COLOR_ERROR)
        .textAlign(TextAlign.Center)

      // 按钮只做令牌同值迁移（旧别名 16 → 大正文档 16）：形态保持主色胶囊不变，
      // 白色字取 COLOR_CARD_BG（常量表注明该令牌接管全部白色用法）；
      // 文案 ≤4 字且按钮自定高度，属"不换行"类——不配行高，套上只会裁字
      Button(this.vm.authExpired ? '重新登录' : '重试')
        .type(ButtonType.Capsule)
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_MEDIUM)
        .fontColor(CommonConstants.COLOR_CARD_BG)
        .backgroundColor(CommonConstants.COLOR_PRIMARY)
        .margin({ top: CommonConstants.SPACE_M })
        .onClick(() => {
          if (this.vm.authExpired) {
            this.vm.clearExpiredSession()
            this.pageStack.replacePathByName(RouteConstants.LOGIN, null)
          } else {
            this.vm.loadSubjectGroups()
          }
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // 加载区：只在"科目还空着"时出现，占满网格那格剩余高度
  //   （断后端到超时那几秒，页面既不该空着、也不该让人以为一个科目都没有）
  @Builder
  Loading() {
    Column() {
      // 同首页加载提示的口径：整句提示在窄窗/分屏可折行，父 Column 自适应高度不裁切；
      // 字阶同值迁移（旧别名 16 → 大正文档 16），降档统一留给 Task 12
      Text('科目加载中…')
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(CommonConstants.LINE_BODY_LG)
        .fontColor(CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  // Exam 域内路由注册：name 与 push 时用的 RouteConstants 常量一一对应
  @Builder
  ExamRouter(name: string, param: Object) {
    if (name === RouteConstants.EXAM_LIST) {
      ExamListPage()
    }
  }

  build() {
    // Navigation：Exam 域的子栈容器，域内页面在这里层层压栈，不会影响根栈和底部 Tab
    Navigation(this.examStack) {
      Column() {
        // 页面标题：与首页分区标题同一档（20/600 + 配对行高，Task 5 对四字页面级标题判"可换行"）
        Text('考试科目')
          .fontSize(CommonConstants.FONT_HEADLINE_MD)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .lineHeight(CommonConstants.LINE_HEADLINE_MD)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .margin({ bottom: CommonConstants.SPACE_M })

        // ===== Grid 网格（3.2.2）=====
        // 关键属性逐一说明：
        //   columnsTemplate('1fr 1fr') —— 定义 2 列，每列宽度均分。
        //     "fr" 是份数单位，1fr:1fr 即对半分；3 列写 '1fr 1fr 1fr'；
        //     也可以混写如 '2fr 1fr'（第一列占 2/3）。不写 columnsTemplate 时 Grid 会按行排（需配 rowsTemplate）。
        //   columnsGap / rowsGap —— 横向沟 16（SPACE_M）、纵向节奏 12（SPACE_CARD_GAP）。
        //     spec §3.4 的间距模型只有这一套，横纵两轴对网格同样成立，不是列表专属。
        //   layoutWeight(1) —— 在外层 Column 里吃掉剩余高度；内容超出高度时 Grid 自带滚动能力。
        // 注意：Grid 的子项必须包在 GridItem 里，直接放组件会不参与网格布局。
        // 三态顺序：加载中 → 加载失败 → 正常网格。错误优先于"空网格"判：
        // 拉到了但真没科目，和根本没拉到，界面要说的是两句话。
        if (this.vm.loading && this.vm.groups.length === 0) {
          this.Loading()
        } else if (this.vm.errorMessage !== '' && this.vm.groups.length === 0) {
          this.LoadFailed()
        } else {
          Grid() {
            ForEach(this.vm.groups, (group: CategoryGroup) => {
              GridItem() {
                // 点击跳转由 ExamSubjectCard 自己处理（取 examStack push 域内路由）
                ExamSubjectCard({ group: group })
              }
            }, (group: CategoryGroup) => group.categoryName)
            // ↑ 键值生成器：科目名在本页数据里唯一，用它当 key 保证聚合结果变化时正确复用
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(CommonConstants.SPACE_M)          // 16 横向沟
          .rowsGap(CommonConstants.SPACE_CARD_GAP)      // 12 纵向节奏，与列表同轨
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .padding({
        left: CommonConstants.SPACE_M,
        right: CommonConstants.SPACE_M,
        top: CommonConstants.SPACE_M
      })
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    }
    .navDestination(this.ExamRouter)   // 域内路由表：EXAM_LIST → 考卷列表页（ExamListPage）
    .hideTitleBar(true)                // 不要系统标题栏：Tab 页有自己的标题排版
    .mode(NavigationMode.Stack)        // 栈模式：域内页面层层压栈
  }
}