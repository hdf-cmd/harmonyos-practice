// 考试科目页：顶部标题 + 两列科目网格，数据来自 MOCK_PAPERS 按 categoryName 客户端聚合
import { CommonConstants } from '../constants/CommomConstants'
import { MOCK_PAPERS } from '../mock/MockExamData'
import { CategoryGroup, groupByCategory } from '../common/utils/PaperUtils'

// 科目卡片组件：白底圆角 12，展示科目名与该科目试卷数
@ComponentV2
struct ExamSubjectCard {
  @Param @Require group: CategoryGroup

  build() {
    Column() {
      // 科目名
      Text(this.group.categoryName)
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 该科目试卷数
      Text(`共 ${this.group.count} 套`)
        .fontSize(CommonConstants.FONT_CAPTION)
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Entry
@ComponentV2
struct ExamSubjectPage {
  // 科目分组：对 MOCK_PAPERS 按 categoryName 聚合，页面加载时计算一次
  @Local groups: CategoryGroup[] = groupByCategory(MOCK_PAPERS)

  build() {
    Column() {
      // 页面标题
      Text('考试科目')
        .fontSize(CommonConstants.FONT_SUBTITLE)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: CommonConstants.SPACE_M })

      // 两列科目网格：每格一个科目卡片，键值使用 categoryName 避免渲染错位
      Grid() {
        ForEach(this.groups, (group: CategoryGroup) => {
          GridItem() {
            ExamSubjectCard({ group: group })
              .onClick(() => {
                console.info(group.categoryName)
              })
          }
        }, (group: CategoryGroup) => group.categoryName)
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
}
