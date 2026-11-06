// 主页面（TabDomain）：只负责 Tab 装配，不持有子栈、不注册路由
// 每个 Tab 对应的 Feature 根页面（HomeView / ExamSubjectView / MineView）自持 Navigation + 子栈 + 域内路由
//
// 【分层说明】MainPage 是"应用外壳页"，不属于任何业务 feature，所以留在 pages/ 下。
//   实训 4-2 起它不再是 @Entry（全应用唯一入口是 pages/AppNavigation.ets），
//   而是根栈里的一个路由页（RouteConstants.MAIN）——所以要去掉 @Entry、加上 export，
//   并在 build 的根节点用 NavDestination 包住整页。
// 【知识点 3.2.4 Tabs 选项卡组件】本文件是 Tabs 的重点示例：
//   Tabs = "内容区(TabContent) + 导航栏(tabBar)" 的组合容器，用于同层级页面间的切换，
//   最典型的场景就是 App 底部导航（本页：首页 / 刷题 / 我的）。
//   三个关键角色：
//     1) Tabs({ barPosition }) —— 容器本体；barPosition: End 把导航栏放到底部（默认 Start 在顶部）
//     2) TabContent() { ... }  —— 每个 Tab 对应的页面内容，同一时刻只有选中的那个会展示
//     3) .tabBar(...)          —— 挂在内容区上的"导航按钮"，可以只给文字，也可以像本页一样自定义样式
//   切换行为由 Tabs 内部管理（点导航栏自动换内容区），我们只需在 onChange 里同步状态做视觉反馈。
import { CommonConstants } from '@zhititong/common'
import { HomeView } from '../features/home/view/HomeView'
import { ExamSubjectView } from '../features/exam/view/ExamSubjectView'
import { MineView } from '../features/mine/view/MineView'

// 底部导航条高度：设计稿的 h-16 = 64vp（原 52）。
//   Tabs 的 barHeight 和自定义 tabBar 项的高度是两个 API，必须同值，所以收敛成一个常量，
//   避免以后改一处忘另一处——项高了但 bar 没高，文字就会被裁。
const TAB_BAR_HEIGHT: number = 64

// 注意这里是 @ComponentV2 + export，没有 @Entry——
// @Entry 只能有一个（在 AppNavigation 上），本组件是被 RootRouter 装配进来的路由页。
@ComponentV2
export struct MainPage {
  // 当前选中的 Tab 下标（0=首页，1=刷题，2=我的）
  // @Local：V2 的组件内部状态，值一变，引用它的 UI 自动刷新
  @Local currentIndex: number = 0

  // 自定义 TabBar：纯文字标签 + 选中变色。
  // 【为什么不加图标——裁决不变（spec §6.5 / T7-R3），但理由换成现在这条】
  //   旧注释写的"设计稿的 Material 图标字体 ArkUI 没有，所以不引素材管道"**已被推翻**：
  //   本机 SDK component/symbolglyph.d.ts:29-43 就声明了内置 SymbolGlyph 组件，构造参数直接吃
  //   $r('sys.symbol.*') 这类系统符号资源（例：:34 的 sys.symbol.ohos_wifi）——加图标是零素材成本的。
  //   真正的不加理由：换装只重排既有元素，Tab 条本来没有图标，加图标＝加当前没有的东西；
  //   而且选哪三个符号属用户审美，已列进待拍项，不由本轮代拍。
  // @Builder：轻量 UI 片段函数（不是独立组件），用于复用一段布局。
  // 三个导航按钮长得一样、只有文字不同，抽成 Builder 传 title/index 复用，避免写三遍。
  @Builder
  tabBarBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(CommonConstants.FONT_LABEL_SM)
        // 选中态：半粗 + 主色；未选中态：常规字重 + 灰色——底部导航的经典视觉反馈
        // 字重取设计稿的 font-semibold(600)/常规(400)，不套 §3.3 档位表里 label-sm 配对的 500：
        //   导航条要靠字重差表达"你在哪一格"，500/400 的落差在 12 号字上读不出来。
        // 依赖 this.currentIndex，所以 onChange 里更新状态后这里会自动重绘
        .fontWeight(this.currentIndex === index ? CommonConstants.WEIGHT_SEMI : CommonConstants.WEIGHT_REGULAR)
        .fontColor(this.currentIndex === index
          ? CommonConstants.COLOR_PRIMARY
          : CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .height(TAB_BAR_HEIGHT)
    .justifyContent(FlexAlign.Center)  // 文字在这 64 高度内垂直居中
    // 导航条卡面：设计稿写的是"半透白底 + 背景模糊"，但 DESIGN.md 的 Zero Decorative Bloat 段
    //   明令杜绝毛玻璃——设计源自相矛盾时以系统规则为准，落平面卡底 + Level 3 上沿阴影。
    // 阴影挂在每个 tabBar 项上：ArkUI 没给自定义 tabBar 暴露"整条 bar"的容器节点，
    //   三项横向铺满即是这条 bar；挂到 Tabs 或 NavDestination 上会投到屏幕顶边外，等于没挂。
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    .shadow(CommonConstants.SHADOW_BOTTOM_BAR)
  }

  build() {
    // NavDestination：本页作为"根栈里的一个页面"的根节点（替代原来 @Entry 页面的角色）
    NavDestination() {
      // barPosition: BarPosition.End —— 导航栏放底部（手机 App 惯例）
      // scrollable(false) —— 禁止"左右滑动内容区切换 Tab"，只允许点导航栏切换，
      //   避免和 Tab 页内部自己的横向手势（如 Swiper 轮播）打架
      Tabs({ barPosition: BarPosition.End }) {
        // 每个 TabContent 是一页"抽屉"：叠在一起，切到谁显示谁。
        // 三个 View 都没有 @Entry，是普通组件，被 import 进来直接嵌进 TabContent 即可，
        // 因此它们不需要注册到 main_pages.json 路由表；文件位置在各自 feature 的 view/ 目录下。
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
      // barHeight：自定义 tabBar 时这一项决定 bar 占多高，必须与 tabBarBuilder 里容器高度同值，
      //   否则项比 bar 高会被裁（所以两边都读 TAB_BAR_HEIGHT）
      .barHeight(TAB_BAR_HEIGHT)
      // onChange：Tab 切换完成后回调，参数是新选中的下标。
      // 在这里同步 @Local 状态 → tabBarBuilder 里依赖 currentIndex 的选中样式随之刷新。
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .width('100%')
      .height('100%')   // 撑满整屏：容器想铺满父组件必须显式给尺寸，否则包内容
    }
    .hideTitleBar(true)   // 隐藏系统标题栏：底部 Tab 页不需要顶部标题栏
  }
}