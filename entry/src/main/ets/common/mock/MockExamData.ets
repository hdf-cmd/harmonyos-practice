import { PaperInfo, QuestionItem } from '../model/QuestionModel'

// Mock 试卷 (字段与契约对齐)
export const MOCK_PAPER: PaperInfo = {
  id: '1953001000000000001',
  paperName: 'HarmonyOS 应用开发基础模拟卷（一）',
  categoryName: '鸿蒙认证',
  levelName: '基础认证',
  totalScore: 100,
  passScore: 60,
  duration: 30,
  questionCount: 6,
  maxAttempts: 3,    // 补：契约字段
  attemptCount: 1,  // 补：已考次数
  bestScore: 80     // 补：最好成绩
}
// 多试卷 Mock：覆盖 3 个类别，字段与契约对齐
export const MOCK_PAPERS: PaperInfo[] = [
  { id: '1953001000000000001', paperName: 'HarmonyOS 应用开发基础模拟卷（一）', categoryName: '鸿蒙认证', levelName: '基础认证', totalScore: 100, passScore: 60, duration: 30, questionCount: 6, maxAttempts: 3, attemptCount: 1, bestScore: 80 },
  { id: '1953001000000000002', paperName: 'HarmonyOS 应用开发基础模拟卷（二）', categoryName: '鸿蒙认证', levelName: '基础认证', totalScore: 100, passScore: 60, duration: 30, questionCount: 6, maxAttempts: 3, attemptCount: 0, bestScore: 0 },
  { id: '1953001000000000003', paperName: 'HarmonyOS 应用开发高级模拟卷（一）', categoryName: '鸿蒙认证', levelName: '高级认证', totalScore: 100, passScore: 70, duration: 45, questionCount: 6, maxAttempts: 2, attemptCount: 0, bestScore: 0 },
  { id: '1953001000000000004', paperName: 'Java 程序设计期末模拟卷 A', categoryName: 'Java 程序设计', levelName: '期末考试', totalScore: 100, passScore: 60, duration: 60, questionCount: 6, maxAttempts: 3, attemptCount: 2, bestScore: 72 },
  { id: '1953001000000000005', paperName: 'Java 程序设计期末模拟卷 B', categoryName: 'Java 程序设计', levelName: '期末考试', totalScore: 100, passScore: 60, duration: 60, questionCount: 6, maxAttempts: 3, attemptCount: 0, bestScore: 0 },
  { id: '1953001000000000006', paperName: '计算机网络单元测验（一）', categoryName: '计算机网络', levelName: '单元测验', totalScore: 100, passScore: 60, duration: 20, questionCount: 6, maxAttempts: 5, attemptCount: 3, bestScore: 95 },
  { id: '1953001000000000007', paperName: '计算机网络单元测验（二）', categoryName: '计算机网络', levelName: '单元测验', totalScore: 100, passScore: 60, duration: 20, questionCount: 6, maxAttempts: 5, attemptCount: 0, bestScore: 0 },
  { id: '1953001000000000008', paperName: 'HarmonyOS 应用开发基础模拟卷（三）', categoryName: '鸿蒙认证', levelName: '基础认证', totalScore: 100, passScore: 60, duration: 30, questionCount: 6, maxAttempts: 3, attemptCount: 0, bestScore: 0 }
]

// Mock 题目列表：6 道题，总分 100，与 MOCK_PAPER 对齐
export const MOCK_QUESTIONS: QuestionItem[] = [
  {
    id: '1953001000000000101',
    type: 'JUDGE',
    content: 'HarmonyOS 的分布式软总线是系统底层的通信基础设施。',
    options: [
      { label: 'A', content: '正确' },
      { label: 'B', content: '错误' }
    ],
    score: 10
  },
  {
    id: '1953001000000000102',
    type: 'JUDGE',
    content: 'ArkTS 是 TypeScript 的超集，完全兼容所有 TypeScript 语法。',
    options: [
      { label: 'A', content: '正确' },
      { label: 'B', content: '错误' }
    ],
    score: 10
  },
  {
    id: '1953001000000000103',
    type: 'SINGLE',
    content: '以下哪个是 ArkUI 的装饰器，用于标记自定义组件？',
    options: [
      { label: 'A', content: '@Entry' },
      { label: 'B', content: '@Component' },
      { label: 'C', content: '@State' },
      { label: 'D', content: '@Builder' }
    ],
    score: 20
  },
  {
    id: '1953001000000000104',
    type: 'SINGLE',
    content: '在 HarmonyOS 中，用于页面路由跳转的 API 是哪个？',
    options: [
      { label: 'A', content: 'router.pushUrl()' },
      { label: 'B', content: 'navigator.navigate()' },
      { label: 'C', content: 'page.goto()' },
      { label: 'D', content: 'window.open()' }
    ],
    score: 20
  },
  {
    id: '1953001000000000105',
    type: 'MULTI',
    content: '以下哪些是 HarmonyOS 的 Ability 类型？',
    options: [
      { label: 'A', content: 'UIAbility' },
      { label: 'B', content: 'ExtensionAbility' },
      { label: 'C', content: 'ServiceAbility' },
      { label: 'D', content: 'PageAbility' }
    ],
    score: 20
  },
  {
    id: '1953001000000000106',
    type: 'MULTI',
    content: '以下哪些属于 ArkUI 的状态管理装饰器？',
    options: [
      { label: 'A', content: '@State' },
      { label: 'B', content: '@Prop' },
      { label: 'C', content: '@Link' },
      { label: 'D', content: '@Provide' }
    ],
    score: 20
  }
]