// 登录页：上部 Logo 区 + 下部表单区
//
// 【分层说明】本文件位于 features/login/view/：它是"登录"feature 的页面。
//   实训 4-2 改造后它不再是自己 @Entry 的独立页面，而是**根栈（RootDomain）里的一个路由页**：
//   由 pages/AppNavigation.ets 的 Navigation 内容区承载首屏、并在 RootRouter 注册为 app.Login。
//   页面内容的根节点相应从 Column 换成 NavDestination——这是 Navigation 体系对"页面"的要求。
// 目前是纯静态表单：输入只存进 @Local，登录按钮只做跳转、未做校验/请求；
// 登录态持久化、防返回拦截留待项目 5/6 完善。
// 布局要点：Column 用 justifyContent(FlexAlign.Center) 让整体在屏幕垂直居中。
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { RouteConstants } from '../../../common/constants/RouteConstants'

@Preview
@ComponentV2
export struct LoginPage {
  // 跨层级直取根栈：@Consumer 按 key 拿到 AppNavigation 用 @Provider('pageStack') 提供的实例，
  // 中间隔多少层组件都能取到（这就是"任意层级都能跳路由"的实现方式）
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // 输入框内容：onChange 里同步进来，点登录时即可拿到（目前只存不用）
  @Local username: string = ''
  @Local password: string = ''

  build() {
    // NavDestination：Navigation 体系里"一个页面"的根节点，相当于 @Entry 页面在新体系中的角色
    NavDestination() {
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
            // 登录成功进入主页面：用 replace 而不是 push——
            // 登录页不该留在返回历史里（真正的防返回拦截项目 5/6 用路由拦截完善）
            this.pageStack.replacePathByName(RouteConstants.MAIN, null)
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
    .hideTitleBar(true)   // 隐藏系统标题栏：本页有自带的 Logo 区，不需要再加标题
  }
}