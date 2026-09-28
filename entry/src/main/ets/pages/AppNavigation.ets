// 应用唯一入口（全应用只有一个 @Entry）
//
// 【三级导航 · 第一级】根栈 RootDomain：AppNavigation 只负责三件事——
//   创建根栈 pageStack、注册根路由、首屏放内容。
//   - EntryAbility 的 loadContent 加载的就是它（pages/AppNavigation）
//   - 根栈上挂两类页面：①应用级页面（登录 app.Login / 主页面 app.Main）
//     ②"沉浸式详情页"（答题 ExamDetail / 结果 AnswerResult）——这类页面 push 后盖住底部 Tab
//   - @Provider('pageStack') 把根栈实例递到组件树下方，任意层级（哪怕嵌在卡片深处）都能用
//     @Consumer('pageStack') 直接取到，不必层层传参
import { RouteConstants } from '@zhititong/common'
import { MainPage } from './MainPage'
import { LoginPage } from '../features/login/view/LoginPage'
import { ExamDetailPage } from '../features/exam/view/ExamDetailPage'
import { AnswerResultPage } from '../features/exam/view/AnswerResultPage'

@Entry
@ComponentV2
struct AppNavigation {
  // 一级导航：根栈。@Provider 提供给全局，任意层级用 @Consumer('pageStack') 直接消费
  @Provider('pageStack') pageStack: NavPathStack = new NavPathStack()

  // 根路由注册：应用级页面 + 挂根栈的沉浸式详情页
  // name 全部来自 RouteConstants，写错一个字母编译期就报错（不用记字符串）
  @Builder
  RootRouter(name: string, param: Object) {
    if (name === RouteConstants.MAIN) {
      MainPage()
    } else if (name === RouteConstants.LOGIN) {
      LoginPage()
    } else if (name === RouteConstants.EXAM_DETAIL) {
      ExamDetailPage()
    } else if (name === RouteConstants.ANSWER_RESULT) {
      AnswerResultPage()
    }
  }

  build() {
    // Navigation 的内容区（首屏）：放登录页——栈空时就显示它。
    // 登录成功后用 replacePathByName 换成 MainPage，登录页不进返回历史。
    Navigation(this.pageStack) {
      LoginPage()
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.RootRouter)
    .hideTitleBar(true)
  }
}