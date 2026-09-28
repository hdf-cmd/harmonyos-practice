// 我的页面：用户信息区 + 功能列表区 + 退出登录按钮
//
// 【分层说明】本文件位于 features/mine/view/：
//   MineView 是"我的"Tab 的内容组件——没加 @Entry，不是路由页，
//   由 pages/MainPage.ets 的 TabContent 直接嵌套使用，因此不需要注册到 main_pages.json。
//   本 feature 私有的子组件已抽到 ./components/SettingItem.ets。
// 【三级导航】Mine 域自持子栈（mineStack，本章先立空架子）；
//   退出登录要操作的是**根栈**——清空根栈后 Navigation 回落到内容区（登录页），登出闭环。
// 【MVVM】用户信息与退出登录业务全在 MineViewModel（@Trace），本页只渲染与转发事件；
//   菜单项由 vm.menuItems 驱动，点击行为（菜单跳转）后续阶段接。
import { CommonConstants, FONT_LEVELS, FontLevel, FontSetting, StateKeys } from '@zhititong/common'
import { PersistenceV2 } from '@kit.ArkUI'
import { SettingItem } from './components/SettingItem'
import { MineViewModel } from '../viewmodel/MineViewModel'

@ComponentV2
export struct MineView {
  // 三级导航：Mine 域自持子栈（预留，后续"考试记录""我的证书"等子页挂这里）
  @Provider('mineStack') mineStack: NavPathStack = new NavPathStack()
  // 登出要操作根栈
  @Consumer('pageStack') pageStack: NavPathStack = new NavPathStack()
  // MVVM：数据与业务归 ViewModel（Mock 三条铁律：Mock 只被 ViewModel 消费，view 不碰数据源）
  // @Local 持有 VM 实例；字段都是 @Trace，VM 加载完成后页面自动刷新
  @Local vm: MineViewModel = new MineViewModel()
  // 全局字号：PersistenceV2 按 key 寻址，同 key 多次 connect 拿到的是同一个实例，
  //   所以这里取到的就是 EntryAbility 在 loadContent 回调里建立的那个单例（@Trace 变更即刷新 + 自动落盘）。
  //   connect 只能在 UI 就绪后调，因此这一行留在 View 里而不是 ViewModel。
  @Local font: FontSetting = PersistenceV2.connect(FontSetting, StateKeys.FONT_SETTING,
    () => new FontSetting())!
  // Select 的选项由档位表派生：增减档位只改 FONT_LEVELS，这里零改动
  private fontOptions: SelectOption[] = FONT_LEVELS.map((level: FontLevel): SelectOption => {
    const option: SelectOption = { value: level.label }
    return option
  })

  // 页面创建时加载一次用户信息。返回的 Result 这里不处理——
  // 失败态由 vm.errorMessage 承载，静态 Demo 阶段占位数据不会失败
  aboutToAppear(): void {
    this.vm.loadUserInfo()
  }

  // Mine 域内路由注册（预留）
  @Builder
  MineRouter(name: string, param: Object) {
  }

  // 字号档位行：与 SettingItem 同宽同高同内边距，只是行尾的箭头换成 Select。
  //   左侧标签与 Select 文字都用固定字号——它们是设置控件本身，跟着字号一起变会让这一行自己抖。
  //   状态读取（levelIndex/levelLabel）发生在本 Builder 内部，所以档位一变这里就重绘。
  @Builder
  FontSettingRow() {
    Row() {
      Text('字号大小')
        .fontSize(CommonConstants.FONT_BODY)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
      Blank()   // 弹性空隙：把 Select 推到行尾
      Select(this.fontOptions)
        .selected(this.font.levelIndex())
        .value(this.font.levelLabel())
        .font({ size: CommonConstants.FONT_BODY })
        .fontColor(CommonConstants.COLOR_TEXT_HINT)
        .onSelect((index: number) => {
          // View 不做判断：越界与"选了当前档"的去重都在 stepTo 里，改 @Trace 即刷新 + 自动落盘
          this.font.stepTo(index)
        })
    }
    .width('100%')
    .height(52)   // 与 SettingItem 的固定行高对齐
    .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
  }

  build() {
    // Navigation：Mine 域的子栈容器（当前无域内子页，先立架子）
    Navigation(this.mineStack) {
      Column() {
        // 用户信息区：头像 + 名字签名，横排（Row 套 Column 的经典组合）
        Row() {
          // 头像：正方形图片 + borderRadius 一半边长 = 正圆
          Image($r('app.media.ic_app'))
            .width(60)
            .height(60)
            .borderRadius(30)

          // 用户名 + 签名：右侧纵向排两行（字号走 sizeOf：基准常量 + 全局偏移，层级关系保留）
          Column() {
            Text(this.vm.userName)
              .fontSize(this.font.sizeOf(CommonConstants.FONT_SUBTITLE))
              .fontWeight(FontWeight.Bold)
              .fontColor(CommonConstants.COLOR_TEXT_MAIN)

            Text(this.vm.signature)
              .fontSize(this.font.sizeOf(CommonConstants.FONT_CAPTION))
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

        // 功能列表区：菜单标题由 VM 驱动，ForEach 渲染（顺序即 vm.menuItems 顺序）
        Column() {
          ForEach(this.vm.menuItems, (title: string, index: number) => {
            SettingItem({ title: title })
            // 字号档位行插在"我的证书"之后：它顶替的是原"字体大小"那一格——
            //   菜单少一项、这里补一行，页面总行数与顺序都和改造前一致
            if (index === 1) {
              this.FontSettingRow()
            }
          }, (title: string) => title)
          // ↑ 键值生成器：菜单标题唯一，用它当 key
        }
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ top: CommonConstants.SPACE_M })

        // 退出登录按钮：Blank() 把它推到页面底部
        Blank()
        Button('退出登录')
          .type(ButtonType.Normal)
          .width('80%')
          .height(CommonConstants.BTN_HEIGHT)
          .fontSize(CommonConstants.FONT_BODY)
          .backgroundColor(Color.White)
          .fontColor(CommonConstants.COLOR_ERROR)   // 危险操作用错误色提示
          .borderRadius(8)
          .margin({ top: CommonConstants.SPACE_L })
          .onClick(async () => {
            // View 不做判断，只转发事件、消费结果：
            // 登出业务（清 session 等）在 VM 里，成功才清根栈
            const res = await this.vm.logout()
            if (res.ok) {
              // 清空根栈：栈空后 Navigation 回落到内容区，也就是登录页——登出闭环。
              // 注意清的是根栈而不是 mineStack：要退出的是整个应用，不只是"我的"域
              this.pageStack.clear()
            }
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
      .padding(CommonConstants.SPACE_M)
    }
    .navDestination(this.MineRouter)   // 域内路由表（本章为空）
    .hideTitleBar(true)                // 不要系统标题栏：Tab 页有自己的排版
    .mode(NavigationMode.Stack)        // 栈模式
  }
}