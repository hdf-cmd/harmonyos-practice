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
          // 空态容器卡：与考试记录页、考卷列表页同一套配方，源值是导出屏
          // design/stitch/v2-final2/stitch_harmonyos_exam_client/_10/code.html 里那张空态卡
          // （bg-surface-container-lowest / rounded-xl / p-space-lg / shadow-sm）⇒ 白卡 + SHADOW_CARD。
          // 本轮前的 COLOR_SUBTLE_BG 落在 COLOR_BG_PAGE 上两档灰阶只差 1 个 R 值、对比度约 1.004:1，
          // 等于一张看不见的容器（Ruling T8-1 同一把尺）；卡面不给整周描边（spec §6.6）。
          // 字档：本页空态只有这一个句子 ⇒ 占配方的首句档
          // （FONT_HEADLINE_SM + WEIGHT_SEMI + COLOR_TEXT_MAIN，源值 text-headline-sm text-on-surface），
          // 与两个兄弟页同向；本轮前按"这句属引导句、永远落第二行"把它降成 BODY_SM + 提示色是反向的。
          // 配方里的次句档（BODY_SM + WEIGHT_REGULAR + COLOR_TEXT_SUB + LINE_BODY_SM，
          // 源值 text-secondary）这里没有第二个句子，故不套那层 Column({ space })——
          // 单子节点时构造参数 space 无效果；textAlign(Center) 保持原 Column 默认居中观感，
          // 也与源里的 text-center 一致。
          Column() {
            Text('通过考试即可获得证书')
              .fontSize(CommonConstants.FONT_HEADLINE_SM)
              .fontWeight(CommonConstants.WEIGHT_SEMI)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding(CommonConstants.SPACE_M)   // 16：§3.4 「卡片内边距 16」；设计源空态屏写 p-space-lg，而其 tailwind 配置 space-lg=1rem=16（不是 24，见 spec §3.4 标尺映射表）
              .borderRadius(CommonConstants.RADIUS_CARD)
              .backgroundColor(CommonConstants.COLOR_CARD_BG)
              .shadow(CommonConstants.SHADOW_CARD)
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
    // 卡面配方（§6.6）：白底 + RADIUS_CARD + SHADOW_CARD，不给整周描边。
    // 这里不写 alignItems：本 Column 的两个子节点（标题 Row 与字段区 Column）都已 .width('100%')，
    // 横向对齐属性对满宽子节点没有可作用的空间，写了也不改变渲染
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .shadow(CommonConstants.SHADOW_CARD)
  }
}
