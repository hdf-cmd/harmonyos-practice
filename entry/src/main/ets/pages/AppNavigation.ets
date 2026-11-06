// 应用唯一入口（全应用只有一个 @Entry）
//
// 【三级导航 · 第一级】根栈 RootDomain：AppNavigation 只负责三件事——
//   创建根栈 pageStack、注册根路由、按登录态给首屏内容。
//   - EntryAbility 的 loadContent 加载的就是它（pages/AppNavigation）
//   - 根栈上只挂"需要盖住底部 Tab 的页面"：沉浸式详情页（答题 ExamDetail / 结果 AnswerResult / 回顾 Review）
//   - @Provider('pageStack') 把根栈实例递到组件树下方，任意层级（哪怕嵌在卡片深处）都能用
//     @Consumer('pageStack') 直接取到，不必层层传参
//
// 【2026-11-06 结构性改动：登录页与主页面从"栈项"改成"内容区二选一"】
//   旧写法是 Navigation 内容区固定放 LoginPage，登录成功后 replacePathByName(MAIN) 把主页压上去。
//   代价是主页永远是一个**盖在登录页之上的栈项**，于是：
//     ① 用户在主页按系统返回键 ⇒ 栈被弹空 ⇒ 底下那张登录页露出来，而 session.loggedIn 仍是 true；
//     ② 此时再点登录，@Monitor 等的是 false→true 的边沿、aboutToAppear 又只在创建时跑一次，
//        两个出口同时失效 ⇒ 卡在登录页（hilog 连着打"登录成功"，界面哪儿也不去）。
//   曾试过给登录页补 onShown 再查一次——**装机实测证伪**：内容区那一层 NavDestination 不触发 onShown
//   （SDK 的 onShown 语义讲的是"栈顶 NavDestination"），补丁无效后已撤回，不留假修复。
//   现在按状态选内容：已登录就是主页、未登录就是登录页，两者都不是栈项，
//   于是"已登录却露出登录页"这个不一致状态**在结构上不可表示**，返回键回到的是"退出应用"而不是登录页。
//   登录/401/登出三条链路从此只改 session.loggedIn，不再做任何路由操作。
import { RouteConstants, SessionManager, SessionUser } from '@zhititong/common'
import { MainPage } from './MainPage'
import { LoginPage } from '../features/login/view/LoginPage'
import { ExamDetailPage } from '../features/exam/view/ExamDetailPage'
import { AnswerResultPage } from '../features/exam/view/AnswerResultPage'
import { ReviewPage } from '../features/exam/view/ReviewPage'

@Entry
@ComponentV2
struct AppNavigation {
  // 一级导航：根栈。@Provider 提供给全局，任意层级用 @Consumer('pageStack') 直接消费
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack()

  // 会话运行态：内容区二选一读的就是它（@Trace loggedIn 一变，下面的 if 自动重绘）。
  //   取法必须走 SessionManager.getUser()——那行 AppStorageV2.connect 的唯一归属地就是它，
  //   在 shell 里自己 connect 一遍等于把会话入口复制成两处，以后改 key/改类型必漏一处。
  //   这与旧写法靠 @Monitor 边沿触发是本质区别：**这里是电平触发**，状态对，界面就对，
  //   不依赖"谁在什么时机被创建/被显示"。
  @Local session: SessionUser = SessionManager.getUser()

  // 根路由注册：只剩沉浸式详情页。
  //   MAIN / LOGIN 两个分支已随上面的改动删除——它们不再被 push，留着就是死分支；
  //   RouteConstants 里对应的常量也一并清掉，避免以后有人照着常量再 push 回旧模型。
  @Builder
  RootRouter(name: string, param: Object) {
    if (name === RouteConstants.EXAM_DETAIL) {
      ExamDetailPage()
    } else if (name === RouteConstants.ANSWER_RESULT) {
      AnswerResultPage()
    } else if (name === RouteConstants.REVIEW) {
      ReviewPage()
    }
  }

  build() {
    Navigation(this.pageStack) {
      if (this.session.loggedIn) {
        MainPage()
      } else {
        LoginPage()
      }
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.RootRouter)
    .hideTitleBar(true)
  }
}