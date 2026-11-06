// 设置项行组件：标题 + 右箭头，一次封装四处复用（DRY）
//
// 【分层说明】放在 features/mine/view/components/ 下：
//   它是"我的"这个业务 feature 私有的展示型子组件，只被同 feature 的 MineView 复用，
//   所以不放进 common/（common 是跨 feature 共享层），也没有 @Entry（不是路由页）。
// 没加 @Entry：纯子组件。列表项长得一样只是文字不同，抽组件比 @Builder 更适合这种"自带样式"的单元
import { CommonConstants } from '@zhititong/common'

@ComponentV2
export struct SettingItem {
  // @Param @Require：标题由父组件传入
  @Param @Require title: string
  // 点击行为由父组件给：默认空实现——不传就当纯展示行（如"关于智题通"）
  @Param onTap: () => void = () => {
  }

  build() {
    Row() {
      Text(this.title)
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
      Blank()   // 弹性空隙：把箭头推到行尾
      // 箭头是"这一行可点"的交互指示（不是状态徽章），所以跟着正文档走，不降到 badging 档
      Text('>')
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .fontColor(CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .height(CommonConstants.BTN_HEIGHT)   // 48：与字号档位行同高，整组菜单的节奏统一
    .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
    // 组内用内嵌发丝线分隔，而不是靠间距把行拉开（设计源 Cards 段的分组规则）。
    // 线画在自身盒内，不额外占高；末行这条压在卡的底边上，由父卡的圆角 + clip 收边，不会伸到弧线外。
    .border({ width: { bottom: CommonConstants.DIVIDER_WIDTH }, color: CommonConstants.COLOR_BORDER_HAIRLINE })
    .onClick(() => {
      this.onTap()
    })
  }
}