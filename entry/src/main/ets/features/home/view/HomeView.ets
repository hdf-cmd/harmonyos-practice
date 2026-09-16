// 首页：顶部轮播区 + 推荐试卷区
//
// 【分层说明】本文件位于 features/home/view/：
//   HomeView 是"首页"Tab 的内容组件——没加 @Entry，不是路由页，
//   由 pages/MainPage.ets 的 TabContent 直接嵌套使用，因此不需要注册到 main_pages.json。
//   本 feature 私有的子组件已抽到 ./components/PaperCard.ets。
// 【知识点 3.2.7 Scroll 滚动组件】整个页面套在最外层 Scroll 里：
//   内容高度超过一屏时即可竖向滚动浏览（试卷列表长了以后整页往下滑）。
// 【知识点 3.2.3 Swiper 轮播组件】顶部 banner 用 Swiper 自动轮播。
// 【知识点 3.2.1 List 列表组件】推荐试卷区用 List + ListItem + ForEach 驱动。
// 三者嵌套关系：Scroll(外层滚动) > Swiper(轮播) / List(列表)。
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { PaperInfo } from '../../../common/model/QuestionModel'
import { MOCK_PAPERS } from '../../../common/mock/MockExamData'
import { getRandomPapers } from '../../../common/utils/PaperUtils'
import { PaperCard } from './components/PaperCard'

// @Preview：让预览器能单独渲染 HomeView（不影响它继续被 MainPage 嵌套使用）
@Preview
@ComponentV2
export struct HomeView {
  // 推荐试卷：从 Mock 数据中随机抽取 4 张
  // @Local 初始化：页面创建时执行一次 getRandomPapers，之后不再变化（静态 Demo 阶段）
  @Local papers: PaperInfo[] = getRandomPapers(MOCK_PAPERS, 4)

  build() {
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
        List() {
          // ForEach：数据驱动渲染。三个参数：
          //   1) 数据源 this.papers
          //   2) itemGenerator：每条数据生成一个 ListItem（数据变 → UI 自动跟着变）
          //   3) keyGenerator：键值生成器（见下方注释）
          ForEach(this.papers, (paper: PaperInfo) => {
            ListItem() {
              PaperCard({ paper: paper })   // 把一条试卷数据传给卡片子组件
                .onClick(() => {
                  console.info(paper.paperName)   // 占位：后续接 router 跳转答题页
                })
            }
            .margin({ bottom: CommonConstants.SPACE_M })   // 卡片间距加在 ListItem 上
          }, (paper: PaperInfo) => paper.id)
          // ↑ 键值生成器：用试卷唯一 id 当 key。
          // 数据增删/顺序变化时，框架按 key 判断哪些项要重建、哪些可复用；
          // 用稳定 id 可避免列表项复用错位（比如图片、角标串位）——这是 List 的必配项。
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CommonConstants.COLOR_BG_PAGE)
  }
}