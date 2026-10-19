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
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
      Blank()   // 弹性空隙：把箭头推到行尾
      Text('>')
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .height(52)   // 固定行高，四行菜单视觉统一
    .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
    .onClick(() => {
      this.onTap()
    })
  }
}