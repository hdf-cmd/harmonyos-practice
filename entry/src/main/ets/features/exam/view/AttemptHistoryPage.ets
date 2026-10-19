// 考试记录页：分页列表（触底加载），Mine 域内子页
//
// 【路由】注册在 MineView 的域内子栈（mineStack）——从"我的"进入时底部 Tab 保留，
//   与"刷题"域内的跳转同一套三级导航口径。
// 【分页】首屏 loadFirstPage，触底 onReachEnd 调 loadMore；不重复不丢页的规则在 VM。
import { CommonConstants, formatDuration } from '@zhititong/common'
import { AttemptHistoryViewModel } from '../viewmodel/AttemptHistoryViewModel'
import { AttemptRecord } from '../service/ExamService'

@Preview
@ComponentV2
export struct AttemptHistoryPage {
  @Consumer('mineStack') mineStack: NavPathStack = new NavPathStack()
  @Local vm: AttemptHistoryViewModel = new AttemptHistoryViewModel()

  build() {
    NavDestination() {
      Column() {
        Text('考试记录')
          .fontSize(CommonConstants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .width('100%')
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M,
            top: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })

        if (this.vm.loading && this.vm.records.length === 0) {
          Column() {
            Text('加载中…')
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_TEXT_HINT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.errorMessage !== '' && this.vm.records.length === 0) {
          Column() {
            Text(this.vm.errorMessage)
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_ERROR)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.records.length === 0) {
          Column() {
            Text('暂无考试记录')
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_TEXT_HINT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: CommonConstants.SPACE_M }) {
            ForEach(this.vm.records, (record: AttemptRecord) => {
              ListItem() {
                this.RecordRow(record)
              }
            }, (record: AttemptRecord) => record.id)

            // 触底加载哨兵：hasMore 为真时显示，同时 list 的 onReachEnd 触发翻页
            if (this.vm.hasMore) {
              ListItem() {
                Text('加载更多…')
                  .fontSize(CommonConstants.FONT_CAPTION)
                  .fontColor(CommonConstants.COLOR_TEXT_HINT)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding(CommonConstants.SPACE_M)
              }
            }
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
          .onReachEnd(() => {
            this.vm.loadMore()
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    }
    .hideTitleBar(true)
    .onReady(() => {
      this.vm.loadFirstPage()
    })
  }

  @Builder
  RecordRow(record: AttemptRecord) {
    Row() {
      // 左侧：卷名 + 开始时间 + 交卷方式/用时
      Column() {
        Text(record.paperName)
          .fontSize(CommonConstants.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(record.startTime)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_TEXT_HINT)
          .margin({ top: 4 })

        Text(`${this.vm.getSubmitTypeLabel(record.submitType)}・用时 ${formatDuration(record.usedTime)}`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：得分（通过绿/未过红）+ 状态标签
      Column() {
        Text(`${record.score} 分`)
          .fontSize(CommonConstants.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(record.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
        Text(record.passed ? '通过' : '未通过')
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(record.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}
