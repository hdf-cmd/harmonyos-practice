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
      // 错误文案来自后端/网络层，长度不可控→属"会换行"的文字，按 §3.3 配对行高（父 Column 自适应高度，不裁切）
      // 档位收口：这里曾是 body-lg(16/400)，注释挂着"是否降到正文中档留给三态统一"的号；
      // 本轮三态统一定的就是 body-md——全仓 5 处 errorMessage 文案站点里 4 处已是 body-md
      //（刷题域、考卷列表、考试记录、我的证书），设计源给状态句的档也是 text-body-md
      //（导出屏 _10 的「登录已过期，请重新登录」那一行），此处补齐，不再留单点
      Text(this.vm.errorMessage)
        .fontSize(CommonConstants.FONT_BODY_MD)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(CommonConstants.LINE_BODY_MD)
        .fontColor(CommonConstants.COLOR_ERROR)
        .textAlign(TextAlign.Center)

      // 错误态按钮走次级形态：静息浅蓝底 + 主色字，高 36、圆角 8
      // 圆角必须配 ButtonType.Normal——Capsule 由组件自定端头，borderRadius 会被吞掉
      // 字档取 §3.3 给次级按钮的 label-md(14/500)，与刷题域失败区那颗同写法；
      // 这里曾是 body-lg + weight-medium，而 §3.3 的字号表里 16 只有 600(HEADLINE_SM) 与 400(BODY_LG) 两档
      // 注意不要把这条推广到主按钮：§3.3 明文"CTA 用 body-lg、次级按钮用 label-md"，
      // 全仓那些实心主钮（登录、交卷、抽屉提交、结果页两颗）的 16 加 Button 默认字重是许可形态，不属本条
      Button(this.vm.authExpired ? '重新登录' : '重试')
        .type(ButtonType.Normal)
        .height(CommonConstants.BTN_HEIGHT_SECONDARY)
        .borderRadius(CommonConstants.RADIUS_BUTTON)
        .fontSize(CommonConstants.FONT_LABEL_MD)
        .fontWeight(CommonConstants.WEIGHT_MEDIUM)
        .fontColor(CommonConstants.COLOR_PRIMARY)
        .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
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
      // 提示行同样可能折行（窄窗/分屏），配对行高
      // 档位收口：这句注释一度挂着"是否降到正文中档留给三态统一"的未决号。三态统一做完后的结论是
      // **加载提示保持 body-lg(16/400)**——它不在 F12 的空态/错误态/会话失效三种状态里（理由见
      // 刷题域 Loading 区的注释），全仓四处加载提示也内部一致，故这里字号与行高都不动
      Text('推荐试卷加载中…')
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(CommonConstants.LINE_BODY_LG)
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
          .borderRadius(CommonConstants.RADIUS_CARD)
          // clip(true) 是圆角真正生效的前提：ArkUI 容器默认不裁剪子节点，
          // 而六个 Image 是 100% 宽 × 160 高的满铺内容——不裁剪就是"方图盖在圆框上"，
          // 圆角轮播等于没落地（spec §4 F02）。视觉只装机可验，这里只保证属性链成立。
          .clip(true)
          .margin({ bottom: CommonConstants.SPACE_L })

          // 推荐试卷标题（分区标题档 20/600 + 配对行高）
          // 归"会换行"一类：极小窗/分屏下四字标题也可能折行，且父 Column 高度自适应，行高 28 不裁切
          Text('推荐试卷')
            .fontSize(CommonConstants.FONT_HEADLINE_MD)
            .fontWeight(CommonConstants.WEIGHT_SEMI)
            .lineHeight(CommonConstants.LINE_HEADLINE_MD)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .margin({ bottom: CommonConstants.SPACE_CARD_GAP })

          // ===== List 列表区（3.2.1）=====
          // List：列表容器，子项必须包在 ListItem 里。要点：
          //   1) 按需渲染 + 自带滚动，子项多时比"ForEach 塞进 Column"更流畅，是长列表首选
          //   2) 默认竖向排列（Axis.Vertical），.listDirection(Axis.Horizontal) 可改横向列表
          //   3) 构造参数 { space: N } 统一设子项间距——换装后卡片纵向间距取令牌 12（方案A §3.4），
          //      原先加在 ListItem 上的 margin(SPACE_M=16) 一并撤掉，否则与 space 叠加成 28
          // 三态顺序：加载中 → 加载失败 → 正常列表。错误优先于"空列表"判：
          // 真·零张卷（池子空）和"没拉到"是两回事，后者必须说清楚
          if (this.vm.loading && this.vm.papers.length === 0) {
            this.Loading()
          } else if (this.vm.errorMessage !== '' && this.vm.papers.length === 0) {
            this.LoadFailed()
          } else {
            List({ space: CommonConstants.SPACE_CARD_GAP }) {
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