// 首页：顶部轮播区 + 推荐试卷区
import { CommonConstants } from '../constants/CommomConstants'
import { PaperInfo } from '../model/QuestionModel'
import { MOCK_PAPERS } from '../mock/MockExamData'
import { getRandomPapers } from '../common/utils/PaperUtils'

// 试卷卡片组件：白底圆角，上行试卷名+等级标签，下行题量/时长/及格分，右侧角标
@ComponentV2
struct PaperCard {
  @Param @Require paper: PaperInfo

  build() {
    Row() {
      // 左侧主内容区
      Column() {
        // 试卷名
        Text(this.paper.paperName)
          .fontSize(CommonConstants.FONT_BODY)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 下行：共 X 题 · Y 分钟 · 及格 Z 分
        Text(`共 ${this.paper.questionCount} 题 · ${this.paper.duration} 分钟 · 及格 ${this.paper.passScore} 分`)
          .fontSize(12)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：等级标签 + 角标垂直排列，居中对齐
      Column() {
        // 等级标签：主色边框圆角
        Text(this.paper.levelName)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .border({ width: 1, color: CommonConstants.COLOR_PRIMARY })
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })

        // 角标：已考显示最好成绩（成功色），未考显示"未考"（提示色）
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
    .backgroundColor('#FFFFFF')
  }
}

@Preview
@Entry
@ComponentV2
struct HomePage {
  // 推荐试卷：从 Mock 数据中随机抽取 4 张
  @Local papers: PaperInfo[] = getRandomPapers(MOCK_PAPERS, 4)

  build() {
    Scroll() {
      Column() {
        // 顶部轮播区：六张 banner 自动播放，间隔 3 秒，开启指示器
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

        // 推荐试卷列表：键值使用试卷 id 避免渲染错位
        List() {
          ForEach(this.papers, (paper: PaperInfo) => {
            ListItem() {
              PaperCard({ paper: paper })
                .onClick(() => {
                  console.info(paper.paperName)
                })
            }
            .margin({ bottom: CommonConstants.SPACE_M })
          }, (paper: PaperInfo) => paper.id)
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
