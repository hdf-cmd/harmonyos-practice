// 回顾页单题卡片：题号+题型、题干、选项双高亮、我的/正确答案行、解析区
//
// 【高亮规则】同一项既是我选的又是正确答案时显示绿色（对优先于错）：
//   我的答案橙色、正确答案绿色、双中绿色。多选题按字母串包含判断，不能整串相等。
// 【左边框色带】绿对红错——一条 4vp 的左边框，扫一眼就能看出这题对没对。
import { CommonConstants, questionTypeLabel } from '@zhititong/common'
import { OptionItem } from '@zhititong/common'
import { ReviewQuestionDetail } from '../service/ExamService'

const COLOR_CORRECT_BG: string = '#E8F5E9'
const COLOR_MINE_BG: string = '#FFF3E0'
const COLOR_PLAIN_BG: string = '#FFFFFF'

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

  private optionBg(label: string): string {
    if (this.isCorrectPick(label)) {
      return COLOR_CORRECT_BG
    }
    if (this.isMyPick(label)) {
      return COLOR_MINE_BG
    }
    return COLOR_PLAIN_BG
  }

  private optionBorder(label: string): string {
    if (this.isCorrectPick(label)) {
      return CommonConstants.COLOR_SUCCESS
    }
    if (this.isMyPick(label)) {
      return CommonConstants.COLOR_WARN
    }
    return '#E0E0E0'
  }

  build() {
    Column() {
      // 题号 + 题型
      Row() {
        Text(`第 ${this.index + 1} 题`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        Text(questionTypeLabel(this.question.type))
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .border({ width: 1, color: CommonConstants.COLOR_PRIMARY, radius: 4 })
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .margin({ left: 8 })
        Blank()
        Text(`${this.question.earnedScore} / ${this.question.maxScore} 分`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(this.question.isCorrect ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
      }
      .width('100%')

      // 题干
      Text(this.question.content)
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .margin({ top: CommonConstants.SPACE_M })
        .width('100%')

      // 选项：正确项绿底、我的错选橙底、两者皆中绿底
      Column({ space: 8 }) {
        ForEach(this.question.options, (option: OptionItem) => {
          Text(`${option.label}. ${option.content}`)
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .width('100%')
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor(this.optionBg(option.label))
            .border({ width: 1, color: this.optionBorder(option.label), radius: 6 })
        }, (option: OptionItem) => this.question.questionId + '_' + option.label)
      }
      .width('100%')
      .margin({ top: CommonConstants.SPACE_M })

      // 我的答案 / 正确答案
      Row() {
        Text(`我的答案 ${this.myAnswer()}`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_WARN)
        Text(`正确答案 ${this.question.correctAnswer}`)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_SUCCESS)
          .margin({ left: CommonConstants.SPACE_M })
      }
      .width('100%')
      .margin({ top: CommonConstants.SPACE_M })

      // 解析区：空串给占位，样式降一级（浅灰底 + 次文本色）
      Text(this.question.analysis === '' ? '暂无解析' : this.question.analysis)
        .fontSize(CommonConstants.FONT_CAPTION)
        .fontColor(this.question.analysis === ''
          ? CommonConstants.COLOR_TEXT_HINT : CommonConstants.COLOR_TEXT_SUB)
        .width('100%')
        .padding(CommonConstants.SPACE_M)
        .margin({ top: CommonConstants.SPACE_M })
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .backgroundColor(Color.White)
    .borderRadius(8)
    // 左边框色带：绿对红错（其余三边宽度 0，只留左侧一条）
    .border({
      width: { left: 4 },
      color: this.question.isCorrect ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR
    })
  }
}
