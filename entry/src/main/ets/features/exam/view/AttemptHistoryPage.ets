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
        // 页内标题：与"刷题"域页内标题（ExamSubjectView 的"考试科目"）同档同轨——
        // headline-md 20/600 + 配对行高。考卷列表页那颗标题不配行高，理由是系统标题栏的固定高度容器，
        // 属平台限制下的例外，不改变本页这种自排版标题的口径
        Text('考试记录')
          .fontSize(CommonConstants.FONT_HEADLINE_MD)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .lineHeight(CommonConstants.LINE_HEADLINE_MD)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .width('100%')
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M,
            top: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })

        if (this.vm.loading && this.vm.records.length === 0) {
          // 加载提示：文案定长且居中于整块剩余高度，判"不换行"——不配行高
          Column() {
            Text('加载中…')
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .fontColor(CommonConstants.COLOR_TEXT_HINT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.errorMessage !== '' && this.vm.records.length === 0) {
          // 错误态：文案来自后端/网络层，长度不可控→属"会换行"的文字，配对行高。
          // 字档取 F12 状态配方给错误文案的那一档（body-md 14/400 + 错误色），
          // 与"刷题"域失败区同轨——这三处错误文案本轮统一，不再一屏 16 一屏 14
          Column() {
            Text(this.vm.errorMessage)
              .fontSize(CommonConstants.FONT_BODY_MD)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .lineHeight(CommonConstants.LINE_BODY_MD)
              .fontColor(CommonConstants.COLOR_ERROR)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.records.length === 0) {
          // 空态容器卡：配方按导出屏 design/stitch/v2-final2/stitch_harmonyos_exam_client/
          // _10/code.html 里那张空态卡（class 含 bg-surface-container-lowest / rounded-xl /
          // p-space-lg / shadow-sm）= 白卡 COLOR_CARD_BG + RADIUS_CARD + SHADOW_CARD。
          // 本轮前写的 COLOR_SUBTLE_BG 落在页面底 COLOR_BG_PAGE 上（两档灰阶只差 1 个 R 值）
          // 对比度约 1.004:1，是无影无描边的隐形装饰（与 Ruling T8-1 判掉的手绘手柄条同一把尺）。
          // 卡面不给整周描边（spec §6.6）。源那个 folder_off 图标圆座不做（spec §6.5）。
          // 字档：本页空态只有一句 ⇒ 占配方里的首句档（源值 text-headline-sm text-on-surface
          // ⇒ FONT_HEADLINE_SM + WEIGHT_SEMI + COLOR_TEXT_MAIN）；
          // §3.3 表里 16 只有 600(HEADLINE_SM) 与 400(BODY_LG) 两个合法配对，
          // 本轮前那组 BODY_LG + WEIGHT_MEDIUM(16/500) 在表里不存在（Ruling T10-A）。
          // 只有一个子节点时 Column 构造参数 space 无效果 ⇒ 去掉那层内嵌 Column，
          // 卡片属性直接挂在这句 Text 上；textAlign(Center) 保持原「Column 默认居中对齐」的观感，
          // 也与源里的 text-center 一致。外层仍吃掉剩余高度并居中，横向补 16 页边距不贴屏边。
          Column() {
            Text('暂无考试记录')
              .fontSize(CommonConstants.FONT_HEADLINE_SM)
              .fontWeight(CommonConstants.WEIGHT_SEMI)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding(CommonConstants.SPACE_L)
              .borderRadius(CommonConstants.RADIUS_CARD)
              .backgroundColor(CommonConstants.COLOR_CARD_BG)
              .shadow(CommonConstants.SHADOW_CARD)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
        } else {
          // 卡片纵向间距 12（spec §3.4）：与首页推荐列表、考卷列表的 List space 同轨
          List({ space: CommonConstants.SPACE_CARD_GAP }) {
            ForEach(this.vm.records, (record: AttemptRecord) => {
              ListItem() {
                this.RecordRow(record)
              }
            }, (record: AttemptRecord) => record.id)

            // 触底加载哨兵：hasMore 为真时显示，同时 list 的 onReachEnd 触发翻页
            if (this.vm.hasMore) {
              ListItem() {
                Text('加载更多…')
                  .fontSize(CommonConstants.FONT_BODY_SM)
                  .fontWeight(CommonConstants.WEIGHT_REGULAR)
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
        // 卷名取小标题档（16/600，与首页 PaperCard 试卷名同链）；
        // maxLines(1) 已锁死行数，归"不换行"一类——不配行高
        Text(record.paperName)
          .fontSize(CommonConstants.FONT_HEADLINE_SM)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 开始时间＝时间戳，属设计源 badging 许可条管辖的对象，走许可档位 label-sm(12/500)
        Text(record.startTime)
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(CommonConstants.COLOR_TEXT_HINT)
          .margin({ top: 4 })

        // 交卷方式・用时：两个派生字段拼成的一行副文案，窄窗/分屏会折行→配对行高；
        // 用・连接，与结果页那行"及格线・用时・交卷方式"的写法一致
        Text(`${this.vm.getSubmitTypeLabel(record.submitType)}・用时 ${formatDuration(record.usedTime)}`)
          .fontSize(CommonConstants.FONT_BODY_SM)
          .fontWeight(CommonConstants.WEIGHT_REGULAR)
          .lineHeight(CommonConstants.LINE_BODY_SM)
          .fontColor(CommonConstants.COLOR_TEXT_HINT)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：得分 + 状态胶囊，垂直排列并右对齐。
      // 得分本身不再随通过与否染色（颜色判读交给下方胶囊），与考卷列表的角标分工一致
      Column() {
        Text(`${record.score} 分`)
          .fontSize(CommonConstants.FONT_HEADLINE_MD)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        // 通过/未通过胶囊：tint 底 + 同色相饱和字的全圆胶囊（§6.4：胶囊一律无描边）。
        // RADIUS_TAG 是 9999，靠 ArkUI 把 borderRadius 钳到短边一半得到正胶囊；
        // 状态胶囊属 badging，按 §3.3 许可条取 label-sm(12/500)
        Text(record.passed ? '通过' : '未通过')
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(record.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
          .backgroundColor(record.passed ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_ERROR_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .height(24)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    // 卡面配方（§6.6）：白底 + RADIUS_CARD + SHADOW_CARD，不给整周描边
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .shadow(CommonConstants.SHADOW_CARD)
  }
}
