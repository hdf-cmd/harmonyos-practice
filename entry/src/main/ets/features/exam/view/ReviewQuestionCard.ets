// 回顾页单题卡片：题号+题型、题干、选项双高亮、我的/正确答案行、解析区
//
// 【高亮规则】同一项既是我选的又是正确答案时显示绿色（对优先于错）：
//   我的答案橙色、正确答案绿色、双中绿色。多选题按字母串包含判断，不能整串相等。
// 【左边框色带】绿对红错——一条 4vp 的左边框，扫一眼就能看出这题对没对。
import { CommonConstants, questionTypeLabel } from '@zhititong/common'
import { OptionItem } from '@zhititong/common'
import { ReviewQuestionDetail } from '../service/ExamService'

@ComponentV2
export struct ReviewQuestionCard {
  @Param @Require question: ReviewQuestionDetail
  // 原卷题号（只看错题时也保持原始序号，不跟着过滤后的下标走）
  @Param @Require index: number

  private myAnswer(): string {
    const u: string | null = this.question.userAnswer
    return (u === null || u === '') ? '未作答' : u
  }

  private isMyPick(label: string): boolean {
    const u: string | null = this.question.userAnswer
    return u !== null && u.indexOf(label) !== -1
  }

  private isCorrectPick(label: string): boolean {
    return this.question.correctAnswer.indexOf(label) !== -1
  }

  // 选项底色三档（§3.2 的 tint 底）：正确项=成功浅底，我的错选=警示浅底，其余=卡面白底
  private optionBg(label: string): string {
    if (this.isCorrectPick(label)) {
      return CommonConstants.COLOR_SUCCESS_BG
    }
    if (this.isMyPick(label)) {
      return CommonConstants.COLOR_WARN_BG
    }
    return CommonConstants.COLOR_CARD_BG
  }

  // 选项描边三档：语义色只给"有信息"的两条（对/错），中性项退到发丝描边——
  //   换装前中性描边与语义描边同为 1vp 实色，整列表看起来像一堆框，靠颜色分不出主次
  private optionBorder(label: string): string {
    if (this.isCorrectPick(label)) {
      return CommonConstants.COLOR_SUCCESS
    }
    if (this.isMyPick(label)) {
      return CommonConstants.COLOR_WARN
    }
    return CommonConstants.COLOR_BORDER_HAIRLINE
  }

  build() {
    Column() {
      // 卡头：题号 + 题型 + 本题得分，三件同档（label-sm 12），靠字色而非字号分主次
      // 三件都是 metadata/badging：设计源 DESIGN.md §Application Rules 第三条只许可 label-sm 或
      //   caption-unit，label-md(14) 不在许可档位内 ⇒ 一律降到 label-sm（字重 500 不变，两档同重）
      Row() {
        Text(`第 ${this.index + 1} 题`)
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        // 题型标签：浅主色底 + 同色相饱和字的全圆胶囊，**无描边**（§6.4 裁决：胶囊只做 tint 底）。
        //   字号取 badging 许可档（DESIGN.md §Application Rules：status pill 用 label-sm/caption-unit，
        //     故此处为 FONT_LABEL_SM，与答题页/试卷卡的题型胶囊同档），其余属性链与那两屏同款。
        // RADIUS_TAG 是 9999，靠 ArkUI 把 borderRadius 钳到短边一半得到正胶囊
        Text(questionTypeLabel(this.question.type))
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ left: 8 })
        Blank()
        Text(`${this.question.earnedScore} / ${this.question.maxScore} 分`)
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(this.question.isCorrect ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
      }
      .width('100%')

      // 题干：卡片里唯一长度完全不可控的正文，窄屏/分屏/极大档都会折行 → 按 §3.3 配 body-lg 行高
      Text(this.question.content)
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(CommonConstants.LINE_BODY_LG)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .margin({ top: CommonConstants.SPACE_M })
        .width('100%')

      // 选项：正确项成功浅底、我的错选警示浅底、两者皆中成功浅底（对优先于错）
      // 与答题页选项行只对齐"容器形态"两处：padding 12/10 与圆角 RADIUS_INPUT（见本块下方那两个属性，
      //   对 ExamDetailPage 里同名的那两个属性——不写行号，本文件插入注释会让号漂）。
      //   字档刻意不统一——本卡用 body-md（14/400/22），答题页选项用 body-lg 的字号 16 配一个
      //   写死的 24（那边是 sizeOf(24)，不是 LINE_BODY_LG=26，两屏行高本就不同源）。
      //   设计源里没有回顾屏选项的逐档字号记载，对齐需要依据，没有就不编；
      //   此处 body-md 与本卡解析正文同档，属卡内自洽的选择，不是"形态分叉"的疏忽。
      Column({ space: CommonConstants.SPACE_CARD_GAP }) {
        ForEach(this.question.options, (option: OptionItem) => {
          Text(`${option.label}. ${option.content}`)
            .fontSize(CommonConstants.FONT_BODY_MD)
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            // 选项正文与题干同类：内容随题目变，会折行 → 配行高（body-md 与本卡的解析正文同档）
            .lineHeight(CommonConstants.LINE_BODY_MD)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .backgroundColor(this.optionBg(option.label))
            .border({ width: 1, color: this.optionBorder(option.label), radius: CommonConstants.RADIUS_INPUT })
        }, (option: OptionItem) => this.question.questionId + '_' + option.label)
      }
      .width('100%')
      .margin({ top: CommonConstants.SPACE_M })

      // 我的答案 / 正确答案：答案串只有字母（多选也就 A-B-C-D）或"未作答"，长度有界、单行判定 → 不配行高
      Row() {
        Text(`我的答案 ${this.myAnswer()}`)
          .fontSize(CommonConstants.FONT_BODY_MD)
          .fontWeight(CommonConstants.WEIGHT_REGULAR)
          .fontColor(CommonConstants.COLOR_WARN)
        Text(`正确答案 ${this.question.correctAnswer}`)
          .fontSize(CommonConstants.FONT_BODY_MD)
          .fontWeight(CommonConstants.WEIGHT_REGULAR)
          .fontColor(CommonConstants.COLOR_SUCCESS)
          .margin({ left: CommonConstants.SPACE_M })
      }
      .width('100%')
      .margin({ top: CommonConstants.SPACE_M })

      // 解析区：空串给占位，样式降一级（静息浅底 + 次文本色，占位再降一档到提示色）
      // 解析正文按题不同、几百字也常见，可换行 → 配 body-md 行高
      Text(this.question.analysis === '' ? '暂无解析' : this.question.analysis)
        .fontSize(CommonConstants.FONT_BODY_MD)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(CommonConstants.LINE_BODY_MD)
        .fontColor(this.question.analysis === ''
          ? CommonConstants.COLOR_TEXT_HINT : CommonConstants.COLOR_TEXT_SUB)
        .width('100%')
        .padding(CommonConstants.SPACE_M)
        .margin({ top: CommonConstants.SPACE_M })
        .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
        .borderRadius(CommonConstants.RADIUS_INPUT)
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .shadow(CommonConstants.SHADOW_CARD)
    // 左边框色带：绿对红错（其余三边宽度 0，只留左侧一条）。宽度 4vp 与两条语义色都不动——
    //   它们本来就是 COLOR_SUCCESS/COLOR_ERROR 令牌，本次只重排卡面（底色/圆角/阴影换成令牌）
    // 不 .clip(true)：卡内边距 16 与圆角半径 16 相等，内容碰不到圆角弧线（答题页同款论证）
    .border({
      width: { left: 4 },
      color: this.question.isCorrect ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR
    })
  }
}
