// 我的页面：用户信息区 + 功能列表区 + 退出登录按钮
import { CommonConstants } from '../constants/CommomConstants'

// 设置项行组件：标题 + 右箭头，一次封装四处复用（DRY）
@ComponentV2
struct SettingItem {
  @Param @Require title: string

  build() {
    Row() {
      Text(this.title)
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
      Blank()
      Text('>')
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_HINT)
    }
    .width('100%')
    .height(52)
    .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
  }
}

@Preview
@Entry
@ComponentV2
struct MinePage {
  build() {
    Column() {
      // 用户信息区
      Row() {
        // 头像
        Image($r('app.media.ic_app'))
          .width(60)
          .height(60)
          .borderRadius(30)

        // 用户名 + 签名
        Column() {
          Text('用户名')
            .fontSize(CommonConstants.FONT_SUBTITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)

          Text('这个人很懒，什么都没写')
            .fontSize(CommonConstants.FONT_CAPTION)
            .fontColor(CommonConstants.COLOR_TEXT_HINT)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: CommonConstants.SPACE_M })
      }
      .width('100%')
      .padding(CommonConstants.SPACE_M)
      .backgroundColor(Color.White)
      .borderRadius(12)

      // 功能列表区
      Column() {
        SettingItem({ title: '考试记录' })
        SettingItem({ title: '我的证书' })
        SettingItem({ title: '字体大小' })
        SettingItem({ title: '关于智题通' })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ top: CommonConstants.SPACE_M })

      // 退出登录按钮
      Blank()
      Button('退出登录')
        .type(ButtonType.Normal)
        .width('80%')
        .height(CommonConstants.BTN_HEIGHT)
        .fontSize(CommonConstants.FONT_BODY)
        .backgroundColor(Color.White)
        .fontColor(CommonConstants.COLOR_ERROR)
        .borderRadius(8)
        .margin({ top: CommonConstants.SPACE_L })
        .onClick(() => {
          console.info('退出登录')
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    .padding(CommonConstants.SPACE_M)
  }
}
