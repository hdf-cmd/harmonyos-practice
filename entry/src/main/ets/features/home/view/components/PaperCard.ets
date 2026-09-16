// 试卷卡片组件：白底圆角，上行试卷名+等级标签，下行题量/时长/及格分，右侧角标
//
// 【分层说明】放在 features/home/view/components/ 下：
//   它是"首页"这个业务 feature 私有的展示型子组件，只被同 feature 的 HomeView 复用，
//   所以不放进 common/（common 是跨 feature 共享层），也没有 @Entry（不是路由页）。
// 没加 @Entry：它是列表项子组件，只被 HomeView 复用，不构成独立页面
import { CommonConstants } from '../../../../common/constants/CommonConstants'
import { PaperInfo } from '../../../../common/model/QuestionModel'

@ComponentV2
export struct PaperCard {
  // @Param：接收父组件传入的数据（单向）；@Require：必填，父组件不传会编译报错
  @Param @Require paper: PaperInfo

  build() {
    Row() {
      // 左侧主内容区：layoutWeight(1) 吃掉剩余宽度，把右侧挤到最右边
      Column() {
        // 试卷名：maxLines(1) + Ellipsis 超长省略，防止长试卷名把卡片撑爆
        Text(this.paper.paperName)
          .fontSize(CommonConstants.FONT_BODY)
          .fontColor(CommonConstants.COLOR_TEXT_MAIN)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 下行：共 X 题 · Y 分钟 · 及格 Z 分
        // 模板字符串把三个契约字段拼成一行说明文字
        Text(`共 ${this.paper.questionCount} 题 · ${this.paper.duration} 分钟 · 及格 ${this.paper.passScore} 分`)
          .fontSize(12)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)   // Column 内子组件左对齐（默认也是 Start，写明意图）

      // 右侧：等级标签 + 角标垂直排列，居中对齐
      Column() {
        // 等级标签：主色描边圆角胶囊（描边样式：透明底 + 边框色 = 主色）
        Text(this.paper.levelName)
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_PRIMARY)
          .border({ width: 1, color: CommonConstants.COLOR_PRIMARY })
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })

        // 角标：条件渲染——考过显示最好成绩（成功色），没考过显示"未考"（提示色）
        // if 分支在 build 里直接写即可，条件变化时这块 UI 自动切换
        if (this.paper.bestScore > 0) {
          Text(`最好 ${this.paper.bestScore} 分`)
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_SUCCESS)
            .margin({ top: 6 })
        } else {
          Text('未考')
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
            .margin({ top: 6 })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)   // 右侧内容在卡片高度内垂直居中
    }
    .width('100%')
    .padding(CommonConstants.SPACE_M)
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
  }
}