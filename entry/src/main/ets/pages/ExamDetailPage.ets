// 考试模式答题页：顶部标题区 + 中部题目区 + 底部操作区
import { CommonConstants } from '../constants/CommomConstants'
import { MOCK_PAPER, MOCK_QUESTIONS } from '../mock/MockExamData'
import { QuestionItem, OptionItem } from '../model/QuestionModel'

// 题型标签映射
const TYPE_LABEL: Record<string, string> = {
  'JUDGE': '判断题',
  'SINGLE': '单选题',
  'MULTI': '多选题'
}

@Preview
@Entry
@ComponentV2
struct ExamDetailPage {
  // 当前题目索引
  @Local currentIndex: number = 0
  // 单选/判断选中项（记录选中的 label）
  @Local radioSelected: string = ''
  // 多选选中项集合
  @Local checkboxSelected: Set<string> = new Set<string>()

  // 获取当前题目
  getCurrentQuestion(): QuestionItem {
    return MOCK_QUESTIONS[this.currentIndex]
  }

  // 题型标签文本
  getTypeLabel(type: string): string {
    const label: string = TYPE_LABEL[type]
    return label !== undefined ? label : '未知题型'
  }

  // 选项显示文本，如 "A. 正确"
  getOptionText(option: OptionItem): string {
    return option.label + '. ' + option.content
  }

  // 切换题目时重置选中状态
  resetSelection(): void {
    this.radioSelected = ''
    this.checkboxSelected = new Set<string>()
  }

  build() {
    Column() {
      // ===== 顶部标题区 =====
      Column() {
        // 试卷名
        Text(MOCK_PAPER.paperName)
          .fontSize(CommonConstants.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 第二行：题目进度 + 倒计时
        Row() {
          Text() {
            Span('第 ')
            Span((this.currentIndex + 1).toString())
              .fontColor(CommonConstants.COLOR_WARN)
            Span(' 题 / 共 ')
            Span(MOCK_QUESTIONS.length.toString())
            Span(' 题')
          }
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)

          Blank()

          Text('29:59')
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_WARN)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .margin({ top: CommonConstants.SPACE_M })
      }
      .width('100%')
      .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M, top: CommonConstants.SPACE_M, bottom: CommonConstants.SPACE_M })
      .backgroundColor(Color.White)
      .borderRadius(8)

      // ===== 中部题目区域 =====
      Column() {
        // 题型标签
        Text(this.getTypeLabel(this.getCurrentQuestion().type))
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .border({ width: 1, color: CommonConstants.COLOR_PRIMARY, radius: 4 })
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })

        // 题干
        Text(this.getCurrentQuestion().content)
          .fontSize(CommonConstants.FONT_BODY)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .lineHeight(24)
          .margin({ top: CommonConstants.SPACE_M })
          .width('100%')

        // 选项列表
        Column({ space: CommonConstants.SPACE_M }) {
          ForEach(this.getCurrentQuestion().options, (option: OptionItem) => {
            Row() {
              if (this.getCurrentQuestion().type === 'MULTI') {
                // 多选：Checkbox
                Checkbox()
                  .select(this.checkboxSelected.has(option.label))
                  .onChange((checked: boolean) => {
                    if (checked) {
                      this.checkboxSelected.add(option.label)
                    } else {
                      this.checkboxSelected.delete(option.label)
                    }
                  })
              } else {
                // 单选/判断：Radio
                Radio({ value: option.label, group: 'options' })
                  .checked(this.radioSelected === option.label)
                  .onChange((checked: boolean) => {
                    if (checked) {
                      this.radioSelected = option.label
                    }
                  })
              }

              Text(this.getOptionText(option))
                .fontSize(CommonConstants.FONT_BODY)
                .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                .margin({ left: 8 })
            }
            .width('100%')
          }, (option: OptionItem) => option.label)
        }
        .margin({ top: CommonConstants.SPACE_L })
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .padding(CommonConstants.SPACE_M)
      .margin({ top: CommonConstants.SPACE_M })
      .backgroundColor(Color.White)
      .borderRadius(8)

      // ===== 底部操作区 =====
      Column() {
        // 四个操作按钮
        Row({ space: 8 }) {
          Button('上一题')
            .type(ButtonType.Normal)
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_CAPTION)
            .backgroundColor(CommonConstants.COLOR_TEXT_HINT)
            .fontColor(Color.White)
            .enabled(this.currentIndex > 0)
            .onClick(() => {
              this.currentIndex--
              this.resetSelection()
            })

          Button('下一题')
            .type(ButtonType.Normal)
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_CAPTION)
            .backgroundColor(CommonConstants.COLOR_TEXT_HINT)
            .fontColor(Color.White)
            .enabled(this.currentIndex < MOCK_QUESTIONS.length - 1)
            .onClick(() => {
              this.currentIndex++
              this.resetSelection()
            })

          Button('标记存疑')
            .type(ButtonType.Normal)
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_CAPTION)
            .backgroundColor(Color.White)
            .fontColor(CommonConstants.COLOR_WARN)
            .border({ width: 1, color: CommonConstants.COLOR_WARN })

          Button('答题卡')
            .type(ButtonType.Normal)
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_CAPTION)
            .backgroundColor(Color.White)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .border({ width: 1, color: CommonConstants.COLOR_TEXT_HINT })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 提交试卷按钮
        Button('提交试卷')
          .type(ButtonType.Normal)
          .width('100%')
          .height(CommonConstants.BTN_HEIGHT)
          .fontSize(CommonConstants.FONT_SUBTITLE)
          .fontColor(Color.White)
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [[CommonConstants.GRADIENT_START, 0], [CommonConstants.GRADIENT_END, 1]]
          })
          .margin({ top: CommonConstants.SPACE_M })
          .onClick(() => {
            console.info('提交试卷')
          })
      }
      .width('100%')
      .padding(CommonConstants.SPACE_M)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    .padding(CommonConstants.SPACE_M)
  }
}
