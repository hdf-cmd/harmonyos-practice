/**
 * ExamService：考试链路接口声明（契约 3.2~3.8）
 *
 * 【请求体为什么都立 interface】ArkTS 红线 arkts-no-untyped-obj-literals——
 *   裸对象字面量塞给 object 形参会编译报错。给每个请求体一个具名接口，
 *   顺手把契约写进类型系统，一举两得。
 * 【作答面不下发 correctAnswer】开考(3.2)的题目只有 myAnswer，判分/逐题对错在交卷后的
 *   result(3.5)与 review(3.8)才出现——防作弊从契约层就开始。
 */
import { BaseService, QuestionItem, OptionItem } from '@zhititong/common'

/** 开考响应（契约 3.2）：场次信息 + 整卷题目（含 myAnswer 回填、无 correctAnswer） */
export interface AttemptInfo {
  attemptId: string
  paperName: string
  totalScore: number
  passScore: number
  duration: number
  remainingSeconds: number          // 时间权威在服务端
  questions: QuestionItem[]
}

/** 交卷/成绩响应（契约 3.5）：判分结果（无逐题对错） */
export interface SubmitResult {
  score: number
  totalScore: number
  passScore: number
  passed: boolean
  usedTime: number                  // 秒
  submitType: string                // MANUAL / TIMEOUT / TAB_SWITCH
  certificateGenerated: boolean
}

/** 逐题回顾的单题（契约 3.8）：交卷后才下发 isCorrect/userAnswer */
export interface ReviewQuestion {
  questionId: string
  type: string
  content: string
  correctAnswer: string
  userAnswer: string
  isCorrect: boolean
  earnedScore: number
  maxScore: number
  options: OptionItem[]
}

/** 逐题回顾响应（契约 3.8）：结果页答题卡数据源 */
export interface ReviewInfo {
  attemptId: string
  paperName: string
  score: number
  totalScore: number
  isPassed: number                  // 数字 1/0，不是布尔
  questions: ReviewQuestion[]
}

/** 逐题回顾·全量（契约 3.8）——回顾页精讲的数据源 */
export interface ReviewQuestionDetail {
  questionId: string
  type: string
  content: string
  correctAnswer: string
  userAnswer: string | null         // 未作答时后端下发 null
  isCorrect: boolean
  earnedScore: number
  maxScore: number
  analysis: string                  // 可为空串（该题无解析）
  options: OptionItem[]
}

export interface ReviewDetail {
  attemptId: string
  paperName: string
  score: number
  totalScore: number
  isPassed: number                  // 契约注意：数字 1/0，不是布尔
  questions: ReviewQuestionDetail[]
}

/** 考试记录（契约 3.6，分页壳见契约 §一） */
export interface AttemptRecord {
  id: string
  startTime: string
  score: number
  passed: boolean
  usedTime: number
  submitType: string
  paperId: string
  paperName: string
}

export interface AttemptPage {
  records: AttemptRecord[]
  total: number
  page: number
  size: number
}

/** 证书（契约 §四·列表接口；注意列表与详情字段名、状态值不同） */
export interface CertificateItem {
  id: string
  certificateNo: string
  name: string
  issueDate: string
  expiryDate: string
  status: string                    // VALID | EXPIRED
}

// ---- 请求体接口 ----

export interface StartExamRequest {
  paperId: string
}

export interface SaveAnswerRequest {
  questionId: string
  answer: string
  isFlagged: boolean
}

export interface SubmitRequest {
  submitType: string
  tabSwitchCount: number
}

/** 切屏上报请求（契约 3.4） */
interface TabSwitchRequest {
  tabSwitchCount: number
}

/** 切屏上报响应（契约 3.4）：服务端裁决是否强制交卷 */
export interface TabSwitchResult {
  tabSwitchCount: number
  tabSwitchLimit: number
  shouldAutoSubmit: boolean
}

export class ExamService extends BaseService {
  /** 开考（或断点续考：后端对进行中的同卷场次幂等返回） */
  startExam(paperId: string): Promise<AttemptInfo> {
    const req: StartExamRequest = { paperId: paperId }
    return this.postJson<AttemptInfo>('/api/exam/attempts', req)
  }

  /** 实时保存单题答案。isFlagged 由调用方给当前值：后端缺该字段即按 false 覆盖 */
  saveAnswer(attemptId: string, questionId: string, answer: string, isFlagged: boolean): Promise<void> {
    const req: SaveAnswerRequest = { questionId: questionId, answer: answer, isFlagged: isFlagged }
    return this.putJson<void>(`/api/exam/attempts/${attemptId}/answer`, req)
  }

  /** 交卷判分：MANUAL 手动 / TIMEOUT 超时 / TAB_SWITCH 切屏超限 */
  submit(attemptId: string, submitType: string, tabSwitchCount: number = 0): Promise<SubmitResult> {
    const req: SubmitRequest = { submitType: submitType, tabSwitchCount: tabSwitchCount }
    return this.postJson<SubmitResult>(`/api/exam/attempts/${attemptId}/submit`, req)
  }

  /** 切屏上报：客户端如实报数，裁决权在服务端（shouldAutoSubmit） */
  reportTabSwitch(attemptId: string, count: number): Promise<TabSwitchResult> {
    const req: TabSwitchRequest = { tabSwitchCount: count }
    return this.putJson<TabSwitchResult>(`/api/exam/attempts/${attemptId}/tab-switch`, req)
  }

  /** 拉取成绩结构（契约 3.7 result：始终返回成绩，用于结果页判分卡） */
  getResult(attemptId: string): Promise<SubmitResult> {
    return this.getJson<SubmitResult>(`/api/exam/attempts/${attemptId}/result`)
  }

  /** 拉取逐题回顾（契约 3.8：用于结果页答题卡的对错着色） */
  getReview(attemptId: string): Promise<ReviewInfo> {
    return this.getJson<ReviewInfo>(`/api/exam/attempts/${attemptId}/review`)
  }

  /** 逐题回顾全量（契约 3.8）：回顾页精讲数据源 */
  getFullReview(attemptId: string): Promise<ReviewDetail> {
    return this.getJson<ReviewDetail>(`/api/exam/attempts/${attemptId}/review?wrongOnly=false`)
  }

  /** 考试记录分页（契约 3.6） */
  getAttempts(page: number, size: number): Promise<AttemptPage> {
    return this.getJson<AttemptPage>(`/api/exam/attempts?page=${page}&size=${size}`)
  }

  /** 我的证书列表（契约 §四） */
  getCertificates(): Promise<CertificateItem[]> {
    return this.getJson<CertificateItem[]>('/api/exam/certificates')
  }
}
