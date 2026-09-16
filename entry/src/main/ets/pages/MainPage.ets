// 主页面：Tabs 装配首页/刷题/我的三个 Tab，本组件只负责装配
//
// 【分层说明】MainPage 是全局唯一的"应用外壳页"，不属于任何业务 feature，
//   所以它留在 pages/ 下；三个 Tab 的内容组件分别来自 features/home、features/exam、features/mine。
// 【知识点 3.2.4 Tabs 选项卡组件】本文件是 Tabs 的重点示例：
//   Tabs = "内容区(TabContent) + 导航栏(tabBar)" 的组合容器，用于同层级页面间的切换，
//   最典型的场景就是 App 底部导航（本页：首页 / 刷题 / 我的）。
//   三个关键角色：
//     1) Tabs({ barPosition }) —— 容器本体；barPosition: End 把导航栏放到底部（默认 Start 在顶部）
//     2) TabContent() { ... }  —— 每个 Tab 对应的页面内容，同一时刻只有选中的那个会展示
//     3) .tabBar(...)          —— 挂在内容区上的"导航按钮"，可以只给文字，也可以像本页一样自定义样式
//   切换行为由 Tabs 内部管理（点导航栏自动换内容区），我们只需在 onChange 里同步状态做视觉反馈。
import { CommonConstants } from '../common/constants/CommonConstants'
import { HomeView } from '../features/home/view/HomeView'
import { ExamSubjectView } from '../features/exam/view/ExamSubjectView'
import { MineView } from '../features/mine/view/MineView'

// @Entry：把这个组件标记为"独立页面"，才能被 EntryAbility 的 loadContent('pages/MainPage') 加载。
//   一个文件只能有一个 @Entry；没加 @Entry 的文件（如 HomeView）只能作为子组件被嵌进来用。
// @ComponentV2：声明自定义组件，走 V2 状态管理（配 @Local / @Param，不能用 V1 的 @State）。
@Entry
@ComponentV2
struct MainPage {
  // 当前选中的 Tab 下标（0=首页，1=刷题，2=我的）
  // @Local：V2 的组件内部状态，值一变，引用它的 UI 自动刷新
  @Local currentIndex: number = 0

  // 自定义 TabBar：文字 + 选中变色
  // @Builder：轻量 UI 片段函数（不是独立组件），用于复用一段布局。
  // 三个导航按钮长得一样、只有文字不同，抽成 Builder 传 title/index 复用，避免写三遍。
  @Builder
  tabBarBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(CommonConstants.FONT_BODY)
        // 选中态：加粗 + 主色；未选中态：常规字重 + 灰色——底部导航的经典视觉反馈
        // 依赖 this.currentIndex，所以 onChange 里更新状态后这里会自动重绘
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentIndex === index
          ? CommonConstants.COLOR_PRIMARY
          : CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)  // 文字在这 52 高度内垂直居中
  }

  build() {
    // barPosition: BarPosition.End —— 导航栏放底部（手机 App 惯例）
    // scrollable(false) —— 禁止"左右滑动内容区切换 Tab"，只允许点导航栏切换，
    //   避免和 Tab 页内部自己的横向手势（如 Swiper 轮播）打架
    Tabs({ barPosition: BarPosition.End }) {
      // 每个 TabContent 是一页"抽屉"：叠在一起，切到谁显示谁。
      // 注意：HomeView/ExamSubjectView/MineView 都没有 @Entry，是普通组件，
      // 被 import 进来直接嵌进 TabContent 即可，因此它们不需要注册到 main_pages.json 路由表；
      // 它们的文件位置在各自 feature 的 view/ 目录下（见顶部 import 路径）。
      TabContent() {
        HomeView()
      }
      .tabBar(this.tabBarBuilder('首页', 0))   // 第 0 个 Tab 的导航按钮

      TabContent() {
        ExamSubjectView()
      }
      .tabBar(this.tabBarBuilder('刷题', 1))   // 第 1 个 Tab

      TabContent() {
        MineView()
      }
      .tabBar(this.tabBarBuilder('我的', 2))   // 第 2 个 Tab
    }
    .scrollable(false)
    // onChange：Tab 切换完成后回调，参数是新选中的下标。
    // 在这里同步 @Local 状态 → tabBarBuilder 里依赖 currentIndex 的选中样式随之刷新。
    .onChange((index: number) => {
      this.currentIndex = index
    })
    .width('100%')
    .height('100%')   // 撑满整屏：容器想铺满父组件必须显式给尺寸，否则包内容
  }
}