// 我的证书页：证书卡片列表，Mine 域内子页
//
// 【契约坑落地】列表接口状态是英文枚举 VALID/EXPIRED，详情接口是中文——
//   页面只认列表口径，徽标翻译收在 ViewModel（VALID→有效绿 / 其它→已过期灰）。
import { CommonConstants } from '@zhititong/common'
import { CertificateViewModel } from '../viewmodel/CertificateViewModel'
import { CertificateItem } from '../service/ExamService'

@Preview
@ComponentV2
export struct CertificatePage {
  @Consumer('mineStack') mineStack: NavPathStack = new NavPathStack()
  @Local vm: CertificateViewModel = new CertificateViewModel()

  build() {
    NavDestination() {
      Column() {
        // 页内标题：与"刷题"域页内标题（ExamSubjectView 的"考试科目"）及考试记录页同档同轨——
        // headline-md 20/600 + 配对行高
        Text('我的证书')
          .fontSize(CommonConstants.FONT_HEADLINE_MD)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .lineHeight(CommonConstants.LINE_HEADLINE_MD)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .width('100%')
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M,
            top: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })

        if (this.vm.loading && this.vm.certificates.length === 0) {
          Column() {
            Text('加载中…')
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .fontColor(CommonConstants.COLOR_TEXT_HINT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.errorMessage !== '' && this.vm.certificates.length === 0) {
          // 错误态：文案来自后端/网络层，长度不可控→属"会换行"的文字，配对行高。
          // 字档取 F12 状态配方给错误文案的那一档（body-md 14/400 + 错误色），
          // 与"刷题"域失败区、考试记录页错误区同轨
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
        } else if (this.vm.certificates.length === 0) {
          // 空态：按 spec §4 F12 的空态配方（静息底 + RADIUS_CARD + SPACE_L 内边距），
          // 与考卷列表页/考试记录页同一套。本页只有这一句引导文案，
          // 按简报的分档它落空态块的第二行（body-sm + 提示色）
          Column() {
            Column({ space: CommonConstants.SPACE_COMPACT }) {
              Text('通过考试即可获得证书')
                .fontSize(CommonConstants.FONT_BODY_SM)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .fontColor(CommonConstants.COLOR_TEXT_HINT)
            }
            .width('100%')
            .padding(CommonConstants.SPACE_L)
            .borderRadius(CommonConstants.RADIUS_CARD)
            .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
        } else {
          // 卡片纵向间距 12（spec §3.4）：与考试记录页、首页推荐列表的 List space 同轨
          List({ space: CommonConstants.SPACE_CARD_GAP }) {
            ForEach(this.vm.certificates, (cert: CertificateItem) => {
              ListItem() {
                this.CertificateCard(cert)
              }
            }, (cert: CertificateItem) => cert.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    }
    .hideTitleBar(true)
    .onReady(() => {
      this.vm.loadCertificates()
    })
  }

  @Builder
  CertificateCard(cert: CertificateItem) {
    Column() {
      Row() {
        // 证书名：小标题档（16/600）。maxLines(2) 是明说的"会折行"，配对行高
        Text(cert.name)
          .fontSize(CommonConstants.FONT_HEADLINE_SM)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .lineHeight(CommonConstants.LINE_HEADLINE_SM)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 状态胶囊：有效=成功色 + 成功浅底，已过期=提示色 + 静息底。
        // 枚举判等（VALID/EXPIRED 列表口径）留在 ViewModel 的 isValid/getStatusLabel，视图不碰字面量；
        // 状态胶囊属 badging，按 §3.3 许可条取 label-sm(12/500)；tint 底、无描边（§6.4）
        Text(this.vm.getStatusLabel(cert.status))
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(this.vm.isValid(cert.status)
            ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_HINT)
          .backgroundColor(this.vm.isValid(cert.status)
            ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_SUBTLE_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .height(24)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ left: 8 })
      }
      .width('100%')

      // 编号 / 颁发日期 / 到期日期：Row 版两列网格——左列标签（弱），右列值（强，吃掉剩余宽度右对齐）。
      // 三行标签同为五个字，列宽天然对齐；Grid 要显式算高度，三行定高内容用不上那套。
      // 值是编号与日期，归"数字配单位"一类不配行高；长编号在格子内自然折行，父 Row 自适应高度不裁切
      Column({ space: CommonConstants.SPACE_COMPACT }) {
        Row() {
          Text('证书编号：')
            .fontSize(CommonConstants.FONT_CAPTION_UNIT)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
          Text(cert.certificateNo)
            .fontSize(CommonConstants.FONT_BODY_MD)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')

        Row() {
          Text('颁发日期：')
            .fontSize(CommonConstants.FONT_CAPTION_UNIT)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
          Text(cert.issueDate)
            .fontSize(CommonConstants.FONT_BODY_MD)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')

        Row() {
          Text('到期日期：')
            .fontSize(CommonConstants.FONT_CAPTION_UNIT)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
          Text(cert.expiryDate)
            .fontSize(CommonConstants.FONT_BODY_MD)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
      }
      .width('100%')
      .margin({ top: CommonConstants.SPACE_M })
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    // 卡面配方（§6.6）：白底 + RADIUS_CARD + SHADOW_CARD，不给整周描边
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .shadow(CommonConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }
}
