// 登录/注册页（View 层）：零业务逻辑，全部委托 LoginViewModel
//
// 【分层说明】本文件位于 features/login/view/：它是"登录"feature 的页面，
//   由 pages/AppNavigation.ets 的 Navigation **内容区**按登录态承载（未登录时才是它），
//   页面根节点是 NavDestination。
// 【本页不再做任何跳转——2026-11-06 结构性改动】
//   旧写法在这里挂了 aboutToAppear + @Monitor('session.loggedIn') 两个出口去 replacePathByName(MAIN)。
//   那套是"边沿触发"：一旦本页是被返回键**露出来**的（组件没重建、loggedIn 也一直是 true），
//   两个出口同时失效，就出现"点了登录、hilog 打登录成功、界面卡在登录页"的死锁。
//   现在改由 AppNavigation 按 loggedIn **选内容**（电平触发）：登录成功 = 会话状态变了 = 内容区换成主页，
//   本页既不需要知道自己会"被替换"，也不需要持有根栈。
//   顺带删掉 pageStack / session 两个字段与 RouteConstants / AppStorageV2 / SessionUser / StateKeys 四个 import——
//   它们只服务于那段跳转代码，留着就是死引用。
// 【本实训的核心变化】页面从"自己管状态、自己写判断"变成**纯粹的渲染器**：
//   - 输入框 onChange 只做一件事：把值塞给 viewModel 的 @Trace 字段
//   - 按钮 onClick 只做一件事：调 viewModel.submit()，错误提示跟着 res 自动变
//   - 确认密码框、错误提示、按钮文案，全是"跟着 viewModel 状态自动变"的条件渲染
//   通读一遍你会发现：View 里找不到一个业务判断（没有 if 校验、没有 if 网络结果），
//   这就是 4.2.9 说的单一职责——业务归 ViewModel，渲染归 View。
import { CommonConstants } from '@zhititong/common'
import { LoginViewModel } from '../viewmodel/LoginViewModel'

@ComponentV2
export struct LoginPage {
  // 持有 ViewModel 实例：页面所有状态都在它身上（@Local 保证它变了页面会重绘）
  @Local viewModel: LoginViewModel = new LoginViewModel()

  build() {
    NavDestination() {
      Column() {
        // 上部 Logo 区
        Column() {
          Image($r('app.media.ic_app'))
            .width(80)
            .height(80)
            .objectFit(ImageFit.Cover)

          // 标题跟着 isReg 变：登录态"欢迎使用智题通"、注册态"注册智题通账号"
          // FONT_HEADLINE_LG_MOBILE（22）是方案A 该屏 h1 的字阶：导出屏 _2 的 h1 类名就是
          // `text-headline-lg-mobile`，全 12 屏里唯一不用 headline-sm(16) 起标题的一屏。
          // 旧字号别名已于换装收尾删除，本行的 22 直接取自 §3.3 档位表，不再经别名中转。
          // 字重按 spec §3.3 该档＝600（WEIGHT_SEMI），不再用系统枚举的 Bold(700)。
          // 行高按 controller 裁决"只给可能换行的文字配"：标题是整句文案，窄窗/折叠屏分屏下
          // 会折行，且父容器是自适应高度（不裁切），故配 LINE_HEADLINE_LG_MOBILE(30)。
          Text(this.viewModel.isReg ? '注册智题通账号' : '欢迎使用智题通')
            .fontSize(CommonConstants.FONT_HEADLINE_LG_MOBILE)
            .fontWeight(CommonConstants.WEIGHT_SEMI)
            .lineHeight(CommonConstants.LINE_HEADLINE_LG_MOBILE)
            .fontColor(CommonConstants.COLOR_TEXT_MAIN)
            .margin({ top: CommonConstants.SPACE_M })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: CommonConstants.SPACE_L })

        // 下部表单区：方案A 把 Logo 以下的表单整体收进一张白卡
        // 卡面令牌：圆角 RADIUS_CARD + 内边距 SPACE_M + Level 1 阴影
        // 卡内子元素一律 width('100%')：卡本身已满宽且带 16 内边距，再套 80% 会变成
        // "卡满宽、输入框悬空"的双层留白（计划 Task 4 修订条）。
        Column() {
          Column({ space: CommonConstants.SPACE_M }) {
            // 输入框：静息灰底 + 发丝描边 → 聚焦转白底 + 1.5 主色描边（spec §4 F01）。
            // 聚焦态走 stateStyles 的 focused 键，和下面按钮的 pressed 同一机制：
            // 纯声明式样式，不加 onFocus/onBlur、不加页面状态、不改行为。
            TextInput({ placeholder: '请输入用户名', text: this.viewModel.username })
              .width('100%')
              .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
              .borderRadius(CommonConstants.RADIUS_INPUT)
              .border({ width: CommonConstants.DIVIDER_WIDTH, color: CommonConstants.COLOR_BORDER_HAIRLINE })
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .placeholderColor(CommonConstants.COLOR_TEXT_DISABLED)
              .placeholderFont({ size: CommonConstants.FONT_BODY_MD })
              .stateStyles({
                focused: {
                  .backgroundColor(CommonConstants.COLOR_CARD_BG)
                  .border({ width: 1.5, color: CommonConstants.COLOR_BORDER_FOCUS })
                }
              })
              .onChange((value: string) => {
                this.viewModel.username = value
              })

            TextInput({ placeholder: '请输入密码', text: this.viewModel.password })
              .width('100%')
              .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
              .borderRadius(CommonConstants.RADIUS_INPUT)
              .border({ width: CommonConstants.DIVIDER_WIDTH, color: CommonConstants.COLOR_BORDER_HAIRLINE })
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_REGULAR)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)
              .placeholderColor(CommonConstants.COLOR_TEXT_DISABLED)
              .placeholderFont({ size: CommonConstants.FONT_BODY_MD })
              .type(InputType.Password)
              .stateStyles({
                focused: {
                  .backgroundColor(CommonConstants.COLOR_CARD_BG)
                  .border({ width: 1.5, color: CommonConstants.COLOR_BORDER_FOCUS })
                }
              })
              .onChange((value: string) => {
                this.viewModel.password = value
              })

            // 注册态才出现的确认密码框（条件渲染由 isReg 驱动）
            if (this.viewModel.isReg) {
              TextInput({ placeholder: '请再次输入密码', text: this.viewModel.confirmPwd })
                .width('100%')
                .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
                .borderRadius(CommonConstants.RADIUS_INPUT)
                .border({ width: CommonConstants.DIVIDER_WIDTH, color: CommonConstants.COLOR_BORDER_HAIRLINE })
                .fontSize(CommonConstants.FONT_BODY_LG)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .fontColor(CommonConstants.COLOR_TEXT_MAIN)
                .placeholderColor(CommonConstants.COLOR_TEXT_DISABLED)
                .placeholderFont({ size: CommonConstants.FONT_BODY_MD })
                .type(InputType.Password)
                .stateStyles({
                  focused: {
                    .backgroundColor(CommonConstants.COLOR_CARD_BG)
                    .border({ width: 1.5, color: CommonConstants.COLOR_BORDER_FOCUS })
                  }
                })
                .onChange((value: string) => {
                  this.viewModel.confirmPwd = value
                })
            }

            // 错误提示区（errorMessage 非空才渲染）
            // 服务端/VM 下发的变长文案，会折行 → 属"可换行文字"，配 LINE_BODY_SM；
            // 权重按字阶表 BODY_SM＝400。
            if (this.viewModel.errorMessage !== '') {
              Text(this.viewModel.errorMessage)
                .fontSize(CommonConstants.FONT_BODY_SM)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .lineHeight(CommonConstants.LINE_BODY_SM)
                .fontColor(CommonConstants.COLOR_ERROR)
                .width('100%')
            }

            // 按钮文案三态：加载中 / 注册 / 登录；加载中禁用点击，防重复提交
            Button(this.viewModel.loading
              ? '请稍候...'
              : (this.viewModel.isReg ? '注册' : '登录'))
              // ButtonType.Normal 不是装饰：Capsule 形态由组件自己定圆角，会把 .borderRadius() 吃掉，
              // 令牌里的 RADIUS_BUTTON(8) 落不了地。改 Normal 才让 8vp 圆角真正生效。
              .type(ButtonType.Normal)
              .width('100%')
              .height(CommonConstants.BTN_HEIGHT)
              .borderRadius(CommonConstants.RADIUS_BUTTON)
              .fontSize(CommonConstants.FONT_BODY_LG)
              .fontWeight(CommonConstants.WEIGHT_MEDIUM)
              // 卡面白（COLOR_CARD_BG）顶掉原先写死的白色枚举——本文件的硬编码色值清零点
              .fontColor(CommonConstants.COLOR_CARD_BG)
              .backgroundColor(this.viewModel.loading
                ? CommonConstants.COLOR_TEXT_DISABLED
                : CommonConstants.COLOR_PRIMARY)
              // 按下态：stateStyles 的内联对象是 ArkUI 文档给的写法，只支持通用属性
              .stateStyles({
                pressed: {
                  .backgroundColor(CommonConstants.COLOR_PRIMARY_PRESSED)
                }
              })
              .enabled(!this.viewModel.loading)
              .onClick(() => {
                // View 不做任何判断，只转发事件。跳转不在这做——
                // 登录成功会点亮 session.loggedIn，由上面的 @Monitor 统一接管（导航单一出口）
                this.viewModel.submit()
              })

            // 登录/注册切换
            // 两段都是单行短标签（最多 5 字，Row 内不折行）→ 按裁决只配字重、不配行高，
            // 套行高会把 Row 撑高并造成基线错位；字阶 BODY_MD 对应字重 400。
            Row() {
              Text(this.viewModel.isReg ? '已有账号？' : '没有账号？')
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .fontColor(CommonConstants.COLOR_TEXT_SUB)
              Text(this.viewModel.isReg ? '返回登录' : '立即注册')
                .fontSize(CommonConstants.FONT_BODY_MD)
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                .fontColor(CommonConstants.COLOR_PRIMARY)
                .onClick(() => {
                  this.viewModel.isReg = !this.viewModel.isReg
                  this.viewModel.errorMessage = ''
                })
            }
            .margin({ top: CommonConstants.SPACE_M })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding(CommonConstants.SPACE_M)
        .borderRadius(CommonConstants.RADIUS_CARD)
        .backgroundColor(CommonConstants.COLOR_CARD_BG)
        .shadow(CommonConstants.SHADOW_CARD)
        // .margin 从原来的表单 Column 上移到卡片：卡片贴住 Logo 底会显得没有呼吸，
        // 留在子节点上则变成"卡内多 24vp 空白"。间距语义（Logo 与表单之间 24）不变。
        .margin({ top: CommonConstants.SPACE_L })
      }
      .width('100%')
      .height('100%')
      // 页面左右边距 16（spec §3.4）。这层 padding 是白卡不贴屏边的前提：
      // 卡自身是 width('100%')，父容器不给横向内边距的话，RADIUS_CARD 的圆角和
      // Level 1 阴影会被屏边切半。ArkUI 的百分比宽度按父容器"减去 padding 后的内容区"
      // 解析（子组件拿到的是收缩后的约束），所以卡不会被这 32vp 顶出屏外。
      .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .hideTitleBar(true)
  }
}