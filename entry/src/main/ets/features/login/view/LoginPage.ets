// 登录页：上部 Logo 区 + 下部表单区
//
// 独立路由页（@Entry，已注册 main_pages.json）。
// 目前是纯静态表单：输入只存进 @Local，登录按钮未做校验/请求；
// 登录态、跳转 MainPage 的逻辑留待后续阶段补。
// 布局要点：外层 Column 用 justifyContent(FlexAlign.Center) 让整体在屏幕垂直居中。
// 【分层说明】本文件位于 features/login/view/：它是"登录"feature 的路由页（@Entry），
//   会被注册进 main_pages.json，所以放在 feature 的 view 层而不是 pages/ 下。
import { CommonConstants } from '../../../common/constants/CommonConstants'

@Preview
@Entry
@ComponentV2
struct LoginPage {
  // 输入框内容：onChange 里同步进来，点登录时即可拿到（目前只存不用）
  @Local username: string = ''
  @Local password: string = ''

  build() {
    Column() {
      // ===== 上部 Logo 区 =====
      // $r('app.media.ic_app')：引用 resources/base/media 下的应用图标
      Image($r('app.media.ic_app'))
        .width(80)
        .height(80)
        .objectFit(ImageFit.Contain)   // 保持宽高比完整显示，不裁剪

      Text('欢迎使用智题通')
        .fontSize(CommonConstants.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .margin({ top: CommonConstants.SPACE_M })

      // ===== 下部表单区 =====
      // TextInput：单行输入框。placeholder 是未输入时的灰色提示
      TextInput({ placeholder: '请输入用户名' })
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .onChange((value: string) => {
          this.username = value   // 每次输入变化都同步到状态
        })
        .margin({ top: CommonConstants.SPACE_L })

      // 密码框：type(InputType.Password) 自动打点掩码
      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .onChange((value: string) => {
          this.password = value
        })
        .margin({ top: CommonConstants.SPACE_M })

      Button('登录')
        .type(ButtonType.Capsule)   // 胶囊按钮：两端全圆角
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .fontSize(CommonConstants.FONT_SUBTITLE)
        .fontColor(Color.White)
        .backgroundColor(CommonConstants.COLOR_PRIMARY)
        .margin({ top: CommonConstants.SPACE_L })
        .onClick(() => {
          console.info('执行登录')   // 占位：后续接登录接口 + 跳转 MainPage
        })

      // 底部注册提示：Row 里两个 Text 并排，"立即注册"用主色引导点击
      Row() {
        Text('没有账号？')
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_TEXT_SUB)
        Text('立即注册')
          .fontSize(CommonConstants.FONT_CAPTION)
          .fontColor(CommonConstants.COLOR_PRIMARY)
      }
      .margin({ top: CommonConstants.SPACE_M })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    .justifyContent(FlexAlign.Center)       // 主轴（竖向）居中：整块内容垂直居中
    .alignItems(HorizontalAlign.Center)     // 交叉轴（横向）居中：子组件水平居中
  }
}
