// 试卷卡片组件：卡面走方案A 令牌（白底 + 圆角 16 + Level 1 阴影，不给整周描边，见 spec §6.6），
// 上行试卷名+等级标签，下行题量/时长/及格分，右侧是浅底全圆胶囊角标
//
// 【分层说明】放在 features/home/view/components/ 下：
//   它是"首页"这个业务 feature 私有的展示型子组件，只被同 feature 的 HomeView 复用，
//   所以不放进 common/（common 是跨 feature 共享层），也没有 @Entry（不是路由页）。
// 没加 @Entry：它是列表项子组件，只被 HomeView 复用，不构成独立页面
import { CommonConstants, RouteConstants, PaperInfo } from '@zhititong/common'

@ComponentV2
export struct PaperCard {
  // @Param：接收父组件传入的数据（单向）；@Require：必填，父组件不传会编译报错
  @Param @Require paper: PaperInfo
  // 跨层级直取根栈：卡片嵌在 HomeView > List > ListItem 里也算"深处"，
  // @Consumer 按 key 取 AppNavigation 提供的 pageStack，不需要层层传参
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()

  build() {
    Row() {
      // 左侧主内容区：layoutWeight(1) 吃掉剩余宽度，把右侧挤到最右边
      Column() {
        // 试卷名：maxLines(1) + Ellipsis 超长省略，防止长试卷名把卡片撑爆
        // 字阶取"小标题"档（16/600）；既不换行也被 maxLines(1) 锁死，故不配 lineHeight——
        // 套上去只会把行盒撑高、基线漂移，单行标签/胶囊一类一律不配行高
        Text(this.paper.paperName)
          .fontSize(CommonConstants.FONT_HEADLINE_SM)
          .fontWeight(CommonConstants.WEIGHT_SEMI)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 下行：共 X 题 · Y 分钟 · 及格 Z 分
        // 模板字符串把三个契约字段拼成一行说明文字
        // 副文案行按 §3.3 配对行高：三个契约值拼接后长度不可控，窄窗/分屏/折叠屏窄态会折行，
        // 且父 Column 高度自适应，套 18 的行高不会裁切
        Text(`共 ${this.paper.questionCount} 题 · ${this.paper.duration} 分钟 · 及格 ${this.paper.passScore} 分`)
          .fontSize(CommonConstants.FONT_BODY_SM)
          .fontWeight(CommonConstants.WEIGHT_REGULAR)
          .lineHeight(CommonConstants.LINE_BODY_SM)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)   // Column 内子组件左对齐（默认也是 Start，写明意图）

      // 右侧：等级标签 + 角标垂直排列，居中对齐
      Column() {
        // 等级标签：浅蓝底全圆胶囊（换装前是"透明底 + 主色 1vp 描边 + 圆角 4"）
        // RADIUS_TAG 是 9999，靠 ArkUI 把 borderRadius 钳到短边一半得到正胶囊
        Text(this.paper.levelName)
          .fontSize(CommonConstants.FONT_LABEL_SM)
          .fontWeight(CommonConstants.WEIGHT_MEDIUM)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
          .borderRadius(CommonConstants.RADIUS_TAG)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .height(24)

        // 角标：条件渲染——考过显示最好成绩（成功色 + 成功浅底），没考过显示"未考"（提示色 + 静息底）
        // 形态与等级标签同构（同一套胶囊属性链），if 分支在 build 里直接写即可，条件变化时这块 UI 自动切换
        if (this.paper.bestScore > 0) {
          Text(`最好 ${this.paper.bestScore} 分`)
            .fontSize(CommonConstants.FONT_LABEL_SM)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(CommonConstants.COLOR_SUCCESS)
            .backgroundColor(CommonConstants.COLOR_SUCCESS_BG)
            .borderRadius(CommonConstants.RADIUS_TAG)
            .height(24)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .margin({ top: 6 })
        } else {
          Text('未考')
            .fontSize(CommonConstants.FONT_LABEL_SM)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
            .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
            .borderRadius(CommonConstants.RADIUS_TAG)
            .height(24)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .margin({ top: 6 })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)   // 右侧内容在卡片高度内垂直居中
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .borderRadius(CommonConstants.RADIUS_CARD)
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    // 卡面不给整周描边（spec §6.6）：导出的 12 屏里 63 个卡级容器 0 个带 border、51 个带 shadow，
    //   prose 的「描边 + 阴影」两件套按 §6.4 取克制一读 ⇒ 只留 Level 1 阴影。
    .shadow(CommonConstants.SHADOW_CARD)
    .onClick(() => {
      // 沉浸式详情：push 到**根栈**，答题页会盖住底部 Tab（对比"刷题"Tab 里的域内跳转，
      // 后者 push 到 examStack，底部 Tab 仍在——两种栈的行为差异是本章的教学点）
      this.pageStack.pushPathByName(RouteConstants.EXAM_DETAIL, this.paper.id)
    })
  }
}