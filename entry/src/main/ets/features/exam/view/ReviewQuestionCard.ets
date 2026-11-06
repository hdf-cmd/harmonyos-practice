// 回顾页单题卡片：题号+题型、题干、选项双高亮、我的/正确答案行、解析区
//
// 【高亮规则】同一项既是我选的又是正确答案时显示绿色（对优先于错）：
//   我的答案橙色、正确答案绿色、双中绿色。多选题按字母串包含判断，不能整串相等。
// 【左边框色带】绿对红错——一条 4vp 的左边框，扫一眼就能看出这题对没对。
import { CommonConstants, FontSetting, questionTypeLabel } from '@zhititong/common'
import { OptionItem } from '@zhititong/common'
import { ReviewQuestionDetail } from '../service/ExamService'

@ComponentV2
export struct ReviewQuestionCard {
  @Param @Require question: ReviewQuestionDetail
  // 原卷题号（只看错题时也保持原始序号，不跟着过滤后的下标走）
  @Param @Require index: number
  // 字号档位：由 ReviewPage 连好一次再传进来，不在本卡里 connect——
  //   这卡是 List 里逐题渲染的（一份卷 30 题就是 30 个实例），每实例各连一次是白花的开销。
  //   sizeOf 读的是 FontSetting 上的 @Trace 字段，V2 在渲染期建立依赖，档位一变全部卡片自动重绘。
  @Param @Require font: FontSetting

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
        // 高度 24 与答题页那颗同款（那页也是字面量 .height(24)，不是令牌，这里照它的写法对齐、不自造常量）：
        //   不设高的话这颗实高由 "12 号字 + 上下各 4 内边距" 得出约 20，既不在源许可的 {24, 28}
        //   （DESIGN.md:237 「Height: 24px or 28px」）内，也不在本仓自己的胶囊配方里——
        //   这是全仓 10 个状态胶囊中唯一一个"同元素跨屏两配方"（终审 Important 4）。
        //   24 不会裁字：内容区 = 24 − 上下内边距 8 = 16，容得下 12fp 这一行；
        //   题型胶囊的字档是 FONT_LABEL_SM(12) 且**不过 sizeOf**（与答题页那颗一致），字号档位变化不影响它。
        Text(questionTypeLabel(this.question.type))
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .height(24)
          .margin({ left: 8 })
        Blank()
        Text(`${this.question.earnedScore} / ${this.question.maxScore} 分`)
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(this.question.isCorrect ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
      }
      .width('100%')

      // 题干：卡片里唯一长度完全不可控的正文，窄屏/分屏/极大档都会折行 → 按 §3.3 配 body-lg 行高
      // 字号与行高都过 sizeOf：与答题页题干同一机制（那边 :392/:396 就是 sizeOf 成对出现）。
      //   只放大字不动行高，五档下越挤越近；只动字不动行高则是本卡改之前的状态——
      //   同一道题在答题页会跟随档位、在回顾页纹丝不动，两屏自相矛盾。
      Text(this.question.content)
        .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY_LG))
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(this.font.sizeOf(CommonConstants.LINE_BODY_LG))
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .margin({ top: CommonConstants.SPACE_M })
        .width('100%')

      // 选项：正确项成功浅底、我的错选警示浅底、两者皆中成功浅底（对优先于错）
      // 与答题页选项行对齐的三处：padding 12/10、圆角 RADIUS_INPUT、**字档 body-lg**
      //   （见本块下方那两个属性，对 ExamDetailPage 里同名的那两个属性——不写行号，本文件插入注释会让号漂）。
      // 【档位这条并过的来龙去脉，别当成又一次翻烧饼】
      //   原先这里刻意留 body-md(14)，理由是"设计源没有回顾屏选项的逐档字号记载，对齐需要依据，没有就不编"。
      //   那条理由本身没错，但它挡住的代价是：**同一条选项正文在答题页 16、在回顾页 14**，
      //   用户回顾自己刚答过的题时，看到的是一道被缩小过的同一句话——这是跨屏不一致，不是风格差异。
      //   2026-11-06 由用户明确拍板"并"，所以按"两屏同内容同档"这条更上位的规矩统一到 body-lg。
      //   行高仍按**本卡自己的档位配对**取 LINE_BODY_LG(26)，不抄答题页那个写死的 24：
      //   两屏行高本就不同源（那边是 sizeOf(24)），本卡题干也是 BODY_LG/LINE_BODY_LG，卡内配对优先。
      Column({ space: CommonConstants.SPACE_CARD_GAP }) {
        ForEach(this.question.options, (option: OptionItem) => {
          Text(`${option.label}. ${option.content}`)
            .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY_LG))
            .fontWeight(CommonConstants.WEIGHT_REGULAR)
            // 选项正文与题干同类：内容随题目变，会折行 → 配行高，且与字号走同一个偏移量，理由同题干。
            .lineHeight(this.font.sizeOf(CommonConstants.LINE_BODY_LG))
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            // 圆角写法与答题页选项行统一：圆角挂在 .borderRadius() 上，.border() 只给宽与色。
            //   原先这里只把圆角写在 .border({ radius }) 里，两屏同形态两种写法。
            //   本机 SDK 文案核到的是：component/common.d.ts:18179-18180「Sets the border. When neither color nor
            //   radius is specified, set borderColor and borderRadius after border to ensure they take effect」
            //   —— 只说 border 里不给 radius 时要用 borderRadius 兜，**没有任何一句说 border 的 radius 会不会
            //   裁剪背景填充**；18238-18241 的 borderRadius 条目也只提"配 clip 时裁子节点"。
            //   依据缺失 ⇒ 按零风险对齐走：改写成答题页那种（两屏同写法），浅底 tint 的圆角观感列入装机目检清单。
            .borderRadius(CommonConstants.RADIUS_INPUT)
            .backgroundColor(this.optionBg(option.label))
            .border({ width: 1, color: this.optionBorder(option.label) })
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
      // 与题干、选项同批过 sizeOf：三处都是"随档位变的正文"，只补两处等于把缺陷留在原地
      Text(this.question.analysis === '' ? '暂无解析' : this.question.analysis)
        .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY_MD))
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .lineHeight(this.font.sizeOf(CommonConstants.LINE_BODY_MD))
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
