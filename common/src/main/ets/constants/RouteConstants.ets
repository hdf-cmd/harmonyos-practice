// 路由常量统一收敛，避免到处写魔法字符串
// 命名规范：应用级路由加 app. 前缀；域内路由直接用功能名
//
// 【为什么要有这个类】main_pages.json 里的页面路径、pushPathByName 的路由名都是字符串，
//   编译器不做校验——写错一个字母编译期不报错、运行时才白屏/静默失败。
//   收敛成常量后，"哪条路由、在哪个域"一目了然，且写错名字编译期就报错。
export class RouteConstants {
  // 应用级路由（根栈 RootDomain）
  static readonly LOGIN: string = 'app.Login'
  static readonly MAIN: string = 'app.Main'

  // 沉浸式详情页：统一注册到根栈（push 后盖住底部 Tab）
  static readonly EXAM_DETAIL: string = 'ExamDetail'
  static readonly ANSWER_RESULT: string = 'AnswerResult'

  // Exam 域内路由（examStack，push 后保留底部 Tab）
  static readonly EXAM_LIST: string = 'ExamList'
}