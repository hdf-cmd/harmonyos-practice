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
        Text('我的证书')
          .fontSize(CommonConstants.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .width('100%')
          .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M,
            top: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })

        if (this.vm.loading && this.vm.certificates.length === 0) {
          Column() {
            Text('加载中…')
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_TEXT_HINT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.errorMessage !== '' && this.vm.certificates.length === 0) {
          Column() {
            Text(this.vm.errorMessage)
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_ERROR)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.certificates.length === 0) {
          Column() {
            Text('通过考试即可获得证书')
              .fontSize(CommonConstants.FONT_BODY)
              .fontColor(CommonConstants.COLOR_TEXT_HINT)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: CommonConstants.SPACE_M }) {
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
        Text(cert.name)
          .fontSize(CommonConstants.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 状态徽标：英文枚举进、中文徽标出
        Text(this.vm.getStatusLabel(cert.status))
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(this.vm.isValid(cert.status)
            ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_HINT)
          .border({
            width: 1,
            color: this.vm.isValid(cert.status)
              ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_HINT,
            radius: 4
          })
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .margin({ left: 8 })
      }
      .width('100%')

      Text(`证书编号：${cert.certificateNo}`)
        .fontSize(CommonConstants.FONT_CAPTION)
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .width('100%')
        .margin({ top: CommonConstants.SPACE_M })

      Text(`颁发日期：${cert.issueDate}`)
        .fontSize(CommonConstants.FONT_CAPTION)
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .width('100%')
        .margin({ top: 4 })

      Text(`到期日期：${cert.expiryDate}`)
        .fontSize(CommonConstants.FONT_CAPTION)
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .width('100%')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}
