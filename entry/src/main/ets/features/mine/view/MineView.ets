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
import { CommonConstants, FONT_LEVELS, FontLevel, FontSetting, RouteConstants, StateKeys } from '@zhititong/common'
import { PageHeader } from '../../shell/PageHeader'
import { PersistenceV2 } from '@kit.ArkUI'
import { SettingItem } from './components/SettingItem'
import { MineViewModel } from '../viewmodel/MineViewModel'
import { AttemptHistoryPage } from '../../exam/view/AttemptHistoryPage'
import { CertificatePage } from '../../exam/view/CertificatePage'
import { AssistantEntry } from '../../assistant/AssistantEntry'

@ComponentV2
export struct MineView {
  // 三级导航：Mine 域自持子栈（预留，后续"考试记录""我的证书"等子页挂这里）
  @Provider('mineStack') mineStack: NavPathStack = new NavPathStack()
  // 根栈字段已删除（2026-11-06）：登出不再操作根栈，只调 vm.logout()——
  //   SessionManager.logout() 把 loggedIn 置假，AppNavigation 的内容区自己换成登录页。
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

  // Mine 域内路由注册：考试记录 / 我的证书都挂 mineStack（底部 Tab 保留）
  @Builder
  MineRouter(name: string, param: Object) {
    if (name === RouteConstants.HISTORY) {
      AttemptHistoryPage()
    } else if (name === RouteConstants.CERTIFICATE) {
      CertificatePage()
    }
  }

  // 菜单点击：下标与 vm.menuItems 顺序绑定（0 考试记录 / 1 我的证书 / 2 关于仅占位）
  private onMenuClick(index: number): void {
    if (index === 0) {
      this.mineStack.pushPathByName(RouteConstants.HISTORY, null)
    } else if (index === 1) {
      this.mineStack.pushPathByName(RouteConstants.CERTIFICATE, null)
    }
  }

  // 字号档位行：与 SettingItem 同宽同高同内边距，只是行尾的箭头换成 Select。
  //   左侧标签与 Select 文字都用固定字号——它们是设置控件本身，跟着字号一起变会让这一行自己抖。
  //   状态读取（levelIndex/levelLabel）发生在本 Builder 内部，所以档位一变这里就重绘。
  @Builder
  FontSettingRow() {
    Row() {
      Text('字号大小')
        .fontSize(CommonConstants.FONT_BODY_LG)
        .fontWeight(CommonConstants.WEIGHT_REGULAR)
        .fontColor(CommonConstants.COLOR_TEXT_MAIN)
      Blank()   // 弹性空隙：把 Select 推到行尾
      Select(this.fontOptions)
        .selected(this.font.levelIndex())
        .value(this.font.levelLabel())
        // 档位偏移由 FONT_LEVELS 单源驱动，这里只把当前值文字收进正文档；
        // weight 显式写 500 = SDK 给 Select 的默认字重（select.d.ts 的 font 默认值），声明不改观感
        .font({ size: CommonConstants.FONT_BODY_MD, weight: CommonConstants.WEIGHT_MEDIUM })
        .fontColor(CommonConstants.COLOR_TEXT_SUB)
        .onSelect((index: number) => {
          // View 不做判断：越界与"选了当前档"的去重都在 stepTo 里，改 @Trace 即刷新 + 自动落盘
          this.font.stepTo(index)
        })
    }
    .width('100%')
    .height(CommonConstants.BTN_HEIGHT)   // 与 SettingItem 的固定行高对齐（同为 48）
    .padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
    // 这一行是同一组菜单的一员（顶替原"字体大小"那一格），所以和内嵌发丝线同轨，
    //   否则它与相邻菜单项之间会凭空少一条分隔、读成同一行
    .border({ width: { bottom: CommonConstants.DIVIDER_WIDTH }, color: CommonConstants.COLOR_BORDER_HAIRLINE })
  }

  build() {
    // Navigation：Mine 域的子栈容器（当前无域内子页，先立架子）
    Navigation(this.mineStack) {
      Column() {
        PageHeader({ title: '我的' })
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
                .fontSize(this.font.sizeOf(CommonConstants.FONT_HEADLINE_SM))
                // headline-sm 档配对字重 600（§3.3 档位表），不是原来的裸 Bold
                .fontWeight(CommonConstants.WEIGHT_SEMI)
                .fontColor(CommonConstants.COLOR_TEXT_MAIN)

              Text(this.vm.signature)
                .fontSize(this.font.sizeOf(CommonConstants.FONT_BODY_SM))
                .fontWeight(CommonConstants.WEIGHT_REGULAR)
                // 签名是这页唯一长度不可控的文案（可折行），按全局裁决配配对行高；单行标签一律不配
                .lineHeight(CommonConstants.LINE_BODY_SM)
                .fontColor(CommonConstants.COLOR_TEXT_HINT)
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: CommonConstants.SPACE_M })
          }
          .width('100%')
          .padding(CommonConstants.SPACE_M)
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
          .borderRadius(CommonConstants.RADIUS_CARD)
          .shadow(CommonConstants.SHADOW_CARD)

          // 功能列表区：菜单标题由 VM 驱动，ForEach 渲染（顺序即 vm.menuItems 顺序）
          Column() {
            ForEach(this.vm.menuItems, (title: string, index: number) => {
              SettingItem({
                title: title,
                onTap: () => {
                  this.onMenuClick(index)
                }
              })
              // 字号档位行插在"我的证书"之后：它顶替的是原"字体大小"那一格——
              //   菜单少一项、这里补一行，页面总行数与顺序都和改造前一致
              if (index === 1) {
                this.FontSettingRow()
              }
            }, (title: string) => title)
            // ↑ 键值生成器：菜单标题唯一，用它当 key
          }
          .width('100%')
          .backgroundColor(CommonConstants.COLOR_CARD_BG)
          .borderRadius(CommonConstants.RADIUS_CARD)
          // 卡面配方（§6.6）：白底 + 圆角 16 + Level 1 阴影，与同页用户卡同档。
          //   之前这半套缺阴影，是"同屏两套卡面"被 Task 11 审查点名后补上的。
          //   clip 与 shadow 不冲突——SDK 把 clip 的语义写死了：裁的是**超出本组件边界的子组件**
          //   （common.d.ts:21150），不涉及节点自身投影，全文件也没有 clip 与 shadow 并举的条款。
          .shadow(CommonConstants.SHADOW_CARD)
          // 卡内是贴边的整行（行宽 100%，发丝线画在行的左右满宽处），不像别的卡那样有 16 内边距挡着，
          //   所以必须 clip：ArkUI 的容器圆角默认不裁剪子节点，末行的线会从圆角外头直着穿出去，
          //   圆角等于没落地（同 F02 轮播卡加 clip 的理由）
          .clip(true)
          // 卡与卡的纵向节奏 12（§3.4），不是页面左右边距那个 16
          .margin({ top: CommonConstants.SPACE_CARD_GAP })

          // 助教入口（通用问答）：只给标题，不带考试上下文——这里没有"当前这场考试"可带。
          //   设备不具备 AgentKit 或在模拟器上时，组件内部整体不渲染，页面其余部分不受影响。
          AssistantEntry({ title: 'AI 备考助教' })
            .margin({ top: CommonConstants.SPACE_CARD_GAP })

          // 退出登录按钮：Blank() 把它推到页面底部
          Blank()
          Button('退出登录')
            .type(ButtonType.Normal)
            .width('80%')
            .height(CommonConstants.BTN_HEIGHT)
            .fontSize(CommonConstants.FONT_BODY_LG)
            .fontWeight(CommonConstants.WEIGHT_MEDIUM)   // Button 默认字重即 500（SDK button.d.ts），声明不改观感
            .backgroundColor(CommonConstants.COLOR_CARD_BG)
            .fontColor(CommonConstants.COLOR_ERROR)   // 危险操作用错误色提示
            .borderRadius(CommonConstants.RADIUS_BUTTON)
            .margin({ top: CommonConstants.SPACE_L })
            .onClick(() => {
              // View 只转发事件：登出业务（清内存 token、清运行态用户、异步清盘）全收在 VM 里。
              //   旧写法是 `const res = await this.vm.logout(); if (res.ok) this.pageStack.clear()`，
              //   那句 clear 属于"主页是根栈栈项"的时代——靠清空栈让 Navigation 回落到登录页内容区。
              //   现在 AppNavigation 按 loggedIn 选内容，SessionManager.logout() 一置假界面就换，
              //   根栈上本来就没有主页，clear() 成了空操作；留着会让下一位以为登出的机制是清栈。
              this.vm.logout()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(CommonConstants.COLOR_BG_PAGE)
        .padding(CommonConstants.SPACE_M)
      }
      .width('100%')
      .height('100%')
      // 大底由外层 Column 承担：顶栏与内容区同色，不会在顶栏下沿露出一道色差。
      //   内层 Column 仍保留原来的四边 16（顶栏之下的那 16 是页面自己的留白，不是顶栏的一部分）
      .backgroundColor(CommonConstants.COLOR_BG_PAGE)
    }
    .navDestination(this.MineRouter)   // 域内路由表（本章为空）
    .hideTitleBar(true)                // 不要系统标题栏：Tab 页有自己的排版
    .mode(NavigationMode.Stack)        // 栈模式
  }
}