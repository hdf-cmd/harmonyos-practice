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
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { RouteConstants } from '../../../common/constants/RouteConstants'
import { MOCK_PAPERS } from '../../../common/mock/MockExamData'
import { CategoryGroup, groupByCategory } from '../../../common/utils/PaperUtils'
import { ExamSubjectCard } from './components/ExamSubjectCard'
import { ExamListPage } from './ExamListPage'

@ComponentV2
export struct ExamSubjectView {
  // 三级导航：Exam 域自持子栈
  @Provider('examStack') examStack: NavPathStack = new NavPathStack()
  // 科目分组：对 MOCK_PAPERS 按 categoryName 聚合，页面加载时计算一次
  // （Mock 阶段数据固定，接入接口后只需替换这里的数据源，UI 不用动）
  @Local groups: CategoryGroup[] = groupByCategory(MOCK_PAPERS)

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
        // 页面标题
        Text('考试科目')
          .fontSize(CommonConstants.FONT_SUBTITLE)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: CommonConstants.SPACE_M })

        // ===== Grid 网格（3.2.2）=====
        // 关键属性逐一说明：
        //   columnsTemplate('1fr 1fr') —— 定义 2 列，每列宽度均分。
        //     "fr" 是份数单位，1fr:1fr 即对半分；3 列写 '1fr 1fr 1fr'；
        //     也可以混写如 '2fr 1fr'（第一列占 2/3）。不写 columnsTemplate 时 Grid 会按行排（需配 rowsTemplate）。
        //   columnsGap / rowsGap —— 列间距 / 行间距（vp），这里都用 SPACE_M(16)。
        //   layoutWeight(1) —— 在外层 Column 里吃掉剩余高度；内容超出高度时 Grid 自带滚动能力。
        // 注意：Grid 的子项必须包在 GridItem 里，直接放组件会不参与网格布局。
        Grid() {
          ForEach(this.groups, (group: CategoryGroup) => {
            GridItem() {
              // 点击跳转由 ExamSubjectCard 自己处理（取 examStack push 域内路由）
              ExamSubjectCard({ group: group })
            }
          }, (group: CategoryGroup) => group.categoryName)
          // ↑ 键值生成器：科目名在本页数据里唯一，用它当 key 保证聚合结果变化时正确复用
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(CommonConstants.SPACE_M)
        .rowsGap(CommonConstants.SPACE_M)
        .width('100%')
        .layoutWeight(1)
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