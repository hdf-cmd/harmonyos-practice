import { ExamResult } from '../model/QuestionModel'

// Mock 交卷结果：字段与后端契约对齐
// 得分自洽说明：MOCK_QUESTIONS 分值为 10/10/20/20/20/20，
// 4 道答对的题取 4 道 20 分题（…103~106），故 score = 20 × 4 = 80 ≥ 及格线 60，passed 为 true
export const MOCK_RESULT: ExamResult = {
  score: 80,
  totalScore: 100,
  passScore: 60,
  passed: true,
  usedTime: 754,            // 12 分 34 秒
  submitType: 'MANUAL',     // 手动交卷
  // 与 MOCK_QUESTIONS 六道题一一对应：4 对 1 错 1 未答
  answers: [
    { questionId: '1953001000000000101', correct: false, answered: true },   // 判断题：答错
    { questionId: '1953001000000000102', correct: false, answered: false },  // 判断题：未答
    { questionId: '1953001000000000103', correct: true, answered: true },    // 单选题：答对
    { questionId: '1953001000000000104', correct: true, answered: true },    // 单选题：答对
    { questionId: '1953001000000000105', correct: true, answered: true },    // 多选题：答对
    { questionId: '1953001000000000106', correct: true, answered: true }     // 多选题：答对
  ]
}
