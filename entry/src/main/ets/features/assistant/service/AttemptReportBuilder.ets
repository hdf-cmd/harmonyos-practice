/**
 * 成绩报告的纯逻辑：把后端的考试记录分页，拼成"给大模型读"的中文报告。
 *
 * 【为什么不写在执行器里】执行器（ExamIntentExecutor）继承 InsightIntentExecutor，
 *   拉起的是系统运行态，本地单测环境里 new 不出来。把钳位、文案拼装这些规则收在这个
 *   零依赖文件里，它们才能被 hypium 直接跑——而这两条恰恰是最容易写错的部分：
 *   参数是大模型传的（不可信），文案是大模型转述的（会被它改写）。
 * 【返回值的读者是大模型】除了结构化的 total/count，特意给一条已经把话说完整的
 *   message：大模型直接引用现成叙述，比让它自己从字段里拼句子可靠得多。
 * 【交卷方式文案不重复实现】submitTypeLabel 来自 @zhititong/common，与结果页、记录页
 *   同一口径；在这里再写一份三元判断，早晚出现"三处说法不一样"。
 */
import { submitTypeLabel } from '@zhititong/common'
import { AttemptPage, AttemptRecord } from '../../exam/service/ExamService'

/** 端插件 result 的业务字段：执行器把它塞进 ExecuteResult.result */
export interface AttemptReport {
  total: number
  count: number
  message: string
}

/** size 缺省与上限：大模型传什么都有可能，一律钳到 1~20 */
export const DEFAULT_SIZE: number = 10
export const MAX_SIZE: number = 20

/**
 * 解析大模型传来的 size。
 *
 * 判据写成 `!(raw >= 1)`：NaN、0、负数一个条件全拦住（NaN 参与比较恒为 false），
 *   再 Math.trunc 去掉小数并钳到 MAX_SIZE，避免"传 100000 条"把响应撑爆。
 */
export function parseSize(raw: Object | undefined): number {
  const value: number = Number(raw)
  if (!(value >= 1)) {
    return DEFAULT_SIZE
  }
  return Math.min(Math.trunc(value), MAX_SIZE)
}

/** 只有一句话结论的报告：未登录 / 无记录 / 查询失败三种场景共用 */
export function plainReport(message: string): AttemptReport {
  const report: AttemptReport = { total: 0, count: 0, message: message }
  return report
}

/** 把一页考试记录拼成倒序中文清单（后端已按时间倒序下发，这里不改顺序） */
export function formatAttemptPage(page: AttemptPage): AttemptReport {
  const lines: string[] = page.records.map((r: AttemptRecord, index: number): string => {
    const passText: string = r.passed ? '通过' : '未通过'
    return `${index + 1}. ${r.startTime} ${r.paperName}：${r.score}分（${passText}·${submitTypeLabel(r.submitType)}）`
  })
  // 结尾这句是"用返回值给大模型下指令"：明说只依据列出的记录，防它对没展示的场次脑补
  const message: string = `共有 ${page.total} 条考试记录，最近 ${page.records.length} 条（按时间倒序）：\n` +
    `${lines.join('\n')}\n请只依据以上记录作答，未列出的场次不要推测。`
  const report: AttemptReport = { total: page.total, count: page.records.length, message: message }
  return report
}
