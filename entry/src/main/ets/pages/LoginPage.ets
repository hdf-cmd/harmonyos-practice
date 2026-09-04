// 登录页：上部 Logo 区 + 下部表单区
import { CommonConstants } from '../constants/CommomConstants'

@Preview
@Entry
@ComponentV2
struct LoginPage {
  @Local username: string = ''
  @Local password: string = ''

  build() {
    Column() {
      // ===== 上部 Logo 区 =====
      Image($r('app.media.ic_app'))
        .width(80)
        .height(80)
        .objectFit(ImageFit.Contain)
      Text('欢迎使用智题通')
        .fontSize(CommonConstants.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
        .margin({ top: CommonConstants.SPACE_M })

      // ===== 下部表单区 =====
      TextInput({ placeholder: '请输入用户名' })
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .onChange((value: string) => {
          this.username = value
        })
        .margin({ top: CommonConstants.SPACE_L })

      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .onChange((value: string) => {
          this.password = value
        })
        .margin({ top: CommonConstants.SPACE_M })

      Button('登录')
        .type(ButtonType.Capsule)
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .fontSize(CommonConstants.FONT_SUBTITLE)
        .fontColor(Color.White)
        .backgroundColor(CommonConstants.COLOR_PRIMARY)
        .margin({ top: CommonConstants.SPACE_L })
        .onClick(() => {
          console.info('执行登录')
        })

      // 底部注册提示
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
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
