// 首页：顶部轮播区 + 推荐试卷区
//
// 【分层说明】本文件位于 features/home/view/：
//   HomeView 是"首页"Tab 的内容组件——没加 @Entry，不是路由页，
//   由 pages/MainPage.ets 的 TabContent 直接嵌套使用，因此不需要注册到 main_pages.json。
//   本 feature 私有的子组件已抽到 ./components/PaperCard.ets。
// 【三级导航】Home 域自持子栈（homeStack）并注册域内路由（HomeRouter）。
//   本章 Home 域暂无域内子页——它的详情页走根栈（见 PaperCard 的 push EXAM_DETAIL），
//   子栈与路由注册先立空架子，后续扩展直接往里填。
// 【知识点 3.2.7 Scroll 滚动组件】整个页面套在最外层 Scroll 里：
//   内容高度超过一屏时即可竖向滚动浏览（试卷列表长了以后整页往下滑）。
// 【知识点 3.2.3 Swiper 轮播组件】顶部 banner 用 Swiper 自动轮播。
// 【知识点 3.2.1 List 列表组件】推荐试卷区用 List + ListItem + ForEach 驱动。
// 三者嵌套关系：Navigation > Scroll(外层滚动) > Swiper(轮播) / List(列表)。
import { CommonConstants, PaperInfo, RouteConstants } from '@zhititong/common'
import { PaperCard } from './components/PaperCard'
import { HomeViewModel } from '../viewmodel/HomeViewModel'

// @Preview：让预览器能单独渲染 HomeView（不影响它继续被 MainPage 嵌套使用）
@Preview
@ComponentV2
export struct HomeView {
  // 三级导航：Home 域自持子栈（本章 Home 域详情走根栈，子栈与路由先预留空架子）
  @Provider('homeStack') homeStack: NavPathStack = new NavPathStack()
  // 会话失效要跳登录页——登录页注册在根栈，这里跨层级取根栈（与 PaperCard 同一套口径）
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；papers 是 @Trace 字段，VM 加载完成后列表自动刷新
  @Local vm: HomeViewModel = new HomeViewModel()

  // 页面创建时加载一次推荐试卷。返回的 Result 这里不处理——失败态由 vm.errorMessage 承载，
  // 由下面的 LoadFailed 分支渲染成可见的错误区（曾经这里什么都不画，401 时整页只剩占位插画）
  aboutToAppear(): void {
    this.vm.loadRecommendedPapers()
  }

  // 加载失败区：文案来自后端，按钮动作按失败性质分流——
  //   会话失效：重试没有意义，清掉本地凭证后跳登录页重新拿 token
  //   其它失败（断网、5xx）：留在本页再拉一次
  @Builder
  LoadFailed() {
    Column() {
      Text(this.vm.errorMessage)
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_ERROR)
        .textAlign(TextAlign.Center)

      Button(this.vm.authExpired ? '重新登录' : '重试')
        .type(ButtonType.Capsule)
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(Color.White)
        .backgroundColor(CommonConstants.COLOR_PRIMARY)
        .margin({ top: CommonConstants.SPACE_M })
        .onClick(() => {
          if (this.vm.authExpired) {
            this.vm.clearExpiredSession()
            this.pageStack.replacePathByName(RouteConstants.LOGIN, null)
          } else {
            this.vm.loadRecommendedPapers()
          }
        })
    }
    .width('100%')
    .padding({ top: CommonConstants.SPACE_L, bottom: CommonConstants.SPACE_L })
    .justifyContent(FlexAlign.Center)
  }

  // 加载区：只在"列表还空着"时出现（断后端到超时那几秒，页面既不该空着、
  //   也不该让人以为一张卷都没有）；已有数据时再刷新不打断阅读，与考试记录页同一口径
  @Builder
  Loading() {
    Column() {
      Text('推荐试卷加载中…')
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .padding({ top: CommonConstants.SPACE_L, bottom: CommonConstants.SPACE_L })
    .justifyContent(FlexAlign.Center)
  }

  // Home 域内路由注册（预留：暂无域内子页，后续加"更多推荐""试卷详情"等往这里填）
  @Builder
  HomeRouter(name: string, param: Object) {
  }

  build() {
    // Navigation：三级导航里"域"这一层的容器。每个 Tab 的根页面自持一个 Navigation + 子栈，
    // 这样域内的 push/pop 只在域内发生，不会把底部 Tab 顶掉。
    Navigation(this.homeStack) {
      // ===== Scroll（3.2.7）=====
      // Scroll 是"单子组件滚动容器"，规则：
      //   1) 有且只能有一个直接子组件——所以惯例在里面套一个 Column 把全部内容装一起
      //   2) 滚动方向由内容与容器的尺寸差决定：内容更高 → 竖向滚动（本页情形）
      //   3) 子组件要 .width('100%')，否则 Scroll 默认让子组件自适应窗口宽
      Scroll() {
        Column() {
          // ===== Swiper 轮播区（3.2.3）=====
          // Swiper：滑动切换容器，子组件按顺序一屏一张。
          //   autoPlay(true)   —— 自动播放
          //   interval(3000)   —— 每 3000ms 切一张
          //   indicator(true)  —— 显示小圆点指示器
          //   loop 默认 true   —— 播到最后一张自动回到第一张
          // 六个 Image 就是六页轮播内容，逐张铺满同一块 160 高的区域
          Swiper() {
            Image($r('app.media.banner1'))
              .width('100%')
              .height(160)
            Image($r('app.media.banner2'))
              .width('100%')
              .height(160)
            Image($r('app.media.banner3'))
              .width('100%')
              .height(160)
            Image($r('app.media.banner4'))
              .width('100%')
              .height(160)
            Image($r('app.media.banner5'))
              .width('100%')
              .height(160)
            Image($r('app.media.banner6'))
              .width('100%')
              .height(160)
          }
          .autoPlay(true)
          .interval(3000)
          .indicator(true)
          .height(160)
          .borderRadius(12)
          .margin({ bottom: CommonConstants.SPACE_L })

          // 推荐试卷标题
          Text('推荐试卷')
            .fontSize(CommonConstants.FONT_SUBTITLE)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: CommonConstants.SPACE_M })

          // ===== List 列表区（3.2.1）=====
          // List：列表容器，子项必须包在 ListItem 里。要点：
          //   1) 按需渲染 + 自带滚动，子项多时比"ForEach 塞进 Column"更流畅，是长列表首选
          //   2) 默认竖向排列（Axis.Vertical），.listDirection(Axis.Horizontal) 可改横向列表
          //   3) 构造参数 { space: N } 可统一设子项间距；本页间距用 ListItem 的 margin 实现，两种方式等价
          // 三态顺序：加载中 → 加载失败 → 正常列表。错误优先于"空列表"判：
          // 真·零张卷（池子空）和"没拉到"是两回事，后者必须说清楚
          if (this.vm.loading && this.vm.papers.length === 0) {
            this.Loading()
          } else if (this.vm.errorMessage !== '' && this.vm.papers.length === 0) {
            this.LoadFailed()
          } else {
            List() {
              // ForEach：数据驱动渲染。三个参数：
              //   1) 数据源 this.papers
              //   2) itemGenerator：每条数据生成一个 ListItem（数据变 → UI 自动跟着变）
              //   3) keyGenerator：键值生成器（见下方注释）
              ForEach(this.vm.papers, (paper: PaperInfo) => {
                ListItem() {
                  // 点击跳转由 PaperCard 自己处理（它用 @Consumer 取根栈 push EXAM_DETAIL），
                  // 容器这里只管排版——"卡片管自己的交互"比在列表里堆 onClick 更好维护
                  PaperCard({ paper: paper })
                }
                .margin({ bottom: CommonConstants.SPACE_M })   // 卡片间距加在 ListItem 上
              }, (paper: PaperInfo) => paper.id)
              // ↑ 键值生成器：用试卷唯一 id 当 key。
              // 数据增删/顺序变化时，框架按 key 判断哪些项要重建、哪些可复用；
              // 用稳定 id 可避免列表项复用错位（比如图片、角标串位）——这是 List 的必配项。
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    }
    .navDestination(this.HomeRouter)   // 域内路由表（本章为空）
    .hideTitleBar(true)                // 不要系统标题栏：Tab 页有自己的排版
    .mode(NavigationMode.Stack)        // 栈模式：域内页面层层压栈
  }
}