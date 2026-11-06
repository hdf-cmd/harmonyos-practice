// 主页面（TabDomain）：只负责 Tab 装配，不持有子栈、不注册路由
// 每个 Tab 对应的 Feature 根页面（HomeView / ExamSubjectView / MineView）自持 Navigation + 子栈 + 域内路由
//
// 【分层说明】MainPage 是"应用外壳页"，不属于任何业务 feature，所以留在 pages/ 下。
//   实训 4-2 起它不再是 @Entry（全应用唯一入口是 pages/AppNavigation.ets），
//   build 的根节点用 NavDestination 包住整页。
//   ⚠️ 2026-11-06 改了承载方式：它**不再是根栈上的路由页**（RouteConstants.MAIN 已删），
//   而是 AppNavigation 在 session.loggedIn 为真时的**内容区**。这一改是为了断掉
//   "主页盖在登录页之上 → 返回键弹空 → 露出登录页但 loggedIn 仍为 true → 再登录无反应"的死锁。
//   详见 AppNavigation.ets 顶部那段。
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
// 导航图标边长：设计稿每格是 `text-[24px]` 的图标压在 label-sm 文字上方，纵向两行。
//   24 是这个数字在 vp 下的直读值，也是鸿蒙系统 TabBar 图标的常见档，不另立标尺。
const TAB_ICON_SIZE: number = 24
// 图标与标签的间隙：设计稿 `gap-0.5` = 2px。
const TAB_ICON_LABEL_GAP: number = 2

// 注意这里是 @ComponentV2 + export，没有 @Entry——
// @Entry 只能有一个（在 AppNavigation 上），本组件是被 RootRouter 装配进来的路由页。
@ComponentV2
export struct MainPage {
  // 当前选中的 Tab 下标（0=首页，1=刷题，2=我的）
  // @Local：V2 的组件内部状态，值一变，引用它的 UI 自动刷新
  @Local currentIndex: number = 0

  // 自定义 TabBar：图标 + 文字纵向两行，选中态只变颜色与字重。
  // 【图标这条为什么现在做，而上一轮判"不做"——判据换了，不是同一件事翻烧饼】
  //   上一轮的理由是"Tab 条本来没有图标，加图标属于新增 UI 元素，超出只移植设计语言的范围"。
  //   对着导出屏复核：`_7/_8/_9` 三屏的底部导航**每一格都画了图标**（`flex-col` 里
  //   24px 的 `dashboard` / `menu_book` / `account_circle` 压在 label-sm 文字上方）。
  //   所以图标不是"新增"，是设计源本来有、上一轮没搬——它属于"移植设计语言"，本轮补上。
  //   顺带纠正同一段里更早的一处错判：曾写"稿子的图标是 Material Symbols 连字，ArkUI 没有这套字体"，
  //   实际 `SymbolGlyph` 是 ArkUI 内置组件、`sys.symbol.*` 是系统自带符号资源，加图标零素材成本。
  // 【Material 名到鸿蒙符号的映射】系统符号表（SDK toolchains/id_defined.json，type=symbol 共 4042 条）
  //   里没有 dashboard / menu_book / account_circle 这三个名字，按语义就近取：
  //   dashboard→house（首页）、menu_book→book（刷题）、account_circle→person（我的）。
  // Tab 下标 → 系统符号资源。
  // 【为什么不写成三行 if/else 的组件分支】ArkUI 的 `if/else` 是**组件语法**，
  //   分支块后面不能接属性链（`.fontSize(...)` 挂在 `}` 上会直接编译失败：
  //   "Declaration or statement expected" + "Cannot find name 'fontSize'"，本轮实测撞过）。
  //   而 `$r()` 又只收编译期字面量、不能拼字符串，所以把"选哪个资源"下沉成一个返回 Resource 的普通方法：
  //   三个 $r 仍是各自的字面量（约束没破），属性链只写一遍（不用为三格复制三遍样式）。
  // 【选中态换 fill 版：2026-11-06 由老大拍板，覆盖导出屏那条读法】
  //   导出屏 `_7/_8/_9` 两态用的是同一字形（`data-active-classes` 只改色与字重），
  //   但 fill 是鸿蒙系统 TabBar 自己的惯例，选中"变实"比只换个颜色读得清楚——审美归用户，这里按他说的做。
  //   配对必须**同字形**，否则一按下去图标会换形状。系统符号表（SDK toolchains/id_defined.json，
  //   type=symbol 共 4042 条）实测：house/house_fill ✓、person/person_fill ✓，
  //   但 `book_fill` **不存在**、`book_open` 也不存在（只有孤零零一个 `book_open_fill`）。
  //   拿 `book` 配 `book_open_fill` 会让两态变成两个形状，所以整颗改用 book_pages / book_pages_fill 这一对。
  private tabIcon(index: number, selected: boolean): Resource {
    if (index === 0) {
      return selected ? $r('sys.symbol.house_fill') : $r('sys.symbol.house')
    } else if (index === 1) {
      return selected ? $r('sys.symbol.book_pages_fill') : $r('sys.symbol.book_pages')
    }
    return selected ? $r('sys.symbol.person_fill') : $r('sys.symbol.person')
  }

  // @Builder：轻量 UI 片段函数（不是独立组件），用于复用一段布局。
  // 三个导航按钮长得一样、只有图标与文字不同，抽成 Builder 传 title/index 复用，避免写三遍。
  @Builder
  tabBarBuilder(title: string, index: number) {
    Column({ space: TAB_ICON_LABEL_GAP }) {
      SymbolGlyph(this.tabIcon(index, this.currentIndex === index))
        .fontSize(TAB_ICON_SIZE)
        // SymbolGlyph 的 fontColor 收的是**数组**（多色分层用），单色就传一个元素的数组
        .fontColor([this.currentIndex === index
          ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_TEXT_HINT])
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
    // 系统标题栏在这里（外壳这一层）关掉是对的，但**不等于三个 Tab 页没有顶栏**：
    //   导出屏 _7/_8/_9 每屏都画了 h-14 顶栏（logo + `/` + 页面名），那一层由各 Tab 页自绘
    //   PageHeader 落地（本轮只补页面名，logo 按裁决不补）。系统栏与自绘顶栏同时存在会叠两条。
    .hideTitleBar(true)
  }
}