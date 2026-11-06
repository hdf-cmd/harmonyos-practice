// 科目卡片组件：卡面走方案A 令牌（白底 + 圆角 16 + Level 1 阴影，不给整周描边，见 spec §6.6），展示科目名与该科目试卷数
//
// 【分层说明】放在 features/exam/view/components/ 下：
//   它是"考试"这个业务 feature 私有的展示型子组件，只被同 feature 的 ExamSubjectView 复用，
//   所以不放进 common/（common 是跨 feature 共享层），也没有 @Entry（不是路由页）。
// 没加 @Entry：它是 GridItem 里的子组件，只被 ExamSubjectView 复用
import { CommonConstants, RouteConstants, CategoryGroup } from '@zhititong/common'

@ComponentV2
export struct ExamSubjectCard {
  // @Param @Require：父组件必须传入一份分组数据（科目名 + 数量）
  @Param @Require group: CategoryGroup
  // 域内栈：这里取的是 examStack（由 ExamSubjectView 用 @Provider('examStack') 提供），
  // 不是根栈——两个栈的取舍决定了"跳转后底部 Tab 还在不在"
  @Consumer('examStack') examStack: NavPathStack = new NavPathStack()

  build() {
    Column() {
      // 科目名：单行省略，防止长科目名撑破格子
      // 字阶取"小标题"档（16/600，与首页 PaperCard 试卷名同档同重）；
      // maxLines(1) 已把行数锁死，归"不换行"一类——套行高只会撑行盒、移基线，不配
      Text(this.group.categoryName)
        .fontSize(CommonConstants.FONT_HEADLINE_SM)
        .fontWeight(CommonConstants.WEIGHT_SEMI)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 该科目试卷数：短计数句"共 N 套"，半格宽度下不可能折行，同样不配行高
      Text(`共 ${this.group.count} 套`)
        .fontSize(CommonConstants.FONT_BODY_SM)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .margin({ top: 8 })
    }
    .width('100%')      // 撑满 GridItem 分给的格子宽度
    .padding(CommonConstants.SPACE_M)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    // 卡面不给整周描边（spec §6.6）：导出的 12 屏里 63 个卡级容器 0 个带 border、51 个带 shadow，
    //   prose 的「描边 + 阴影」两件套按 §6.4 取克制一读 ⇒ 只留 Level 1 阴影。
    .shadow(CommonConstants.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      // 域内跳转：push 到 examStack，考卷列表会压在"刷题"Tab 内部，底部 Tab 仍然可见
      // （对比首页卡片的根栈跳转——那里会盖住 Tab，这是本章要对比的两种栈行为）
      this.examStack.pushPathByName(RouteConstants.EXAM_LIST, this.group.categoryName)
    })
  }
}