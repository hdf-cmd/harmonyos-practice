// 选项：与后端契约一致，label 为 A/B/C/D，content 为选项文字
export interface OptionItem {
  label: string
  content: string
}

// 题目：id 用 string 模拟雪花 ID；type 为 JUDGE | SINGLE | MULTI
export interface QuestionItem {
  id: string
  type: string
  content: string
  options: OptionItem[]
  score: number
  // 断点续考回填：开考时后端随题目下发我已答的内容（未答为 null/undefined）。
  // 作答面不下发 correctAnswer——判分与逐题对错只在交卷后的 result/review 接口出现。
  myAnswer?: string
  // 存疑标记。后端开考响应随题目下发，且 PUT answer 缺这个字段时按 false 覆盖写（本机实测），
  // 所以实时保存必须原样带回——否则一标记存疑、再答一次题，标记就被悄悄抹掉。
  isFlagged?: boolean
}

// 试卷信息：字段名与契约对齐，项目 6 接入真实接口时只换数据源
export interface PaperInfo {
  id: string
  paperName: string
  categoryName: string
  levelName: string
  totalScore: number
  passScore: number
  duration: number        // 分钟
  questionCount: number

  maxAttempts: number     // 最大可考次数（契约字段）
  attemptCount: number    // 已考次数（卡片角标用）
  bestScore: number       // 最好成绩（0 表示未考过）
}

// 单题作答结果：与后端交卷接口契约对齐
export interface AnswerItem {
  questionId: string
  correct: boolean        // 该题是否答对
  answered: boolean       // 该题是否作答
}

// 交卷结果：字段与后端契约对齐，项目 6 接入真实接口时只换数据源
export interface ExamResult {
  score: number           // 得分
  totalScore: number      // 总分
  passScore: number       // 及格线
  passed: boolean         // 是否通过
  usedTime: number        // 用时（秒）
  submitType: string      // 交卷方式：MANUAL 手动 / TIMEOUT 超时自动
  answers: AnswerItem[]   // 逐题作答结果
}
