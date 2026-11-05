// AttemptReportBuilder 单元测试：端插件返回给大模型的那段话，规则在这里钉死
//
// 【被测规则】size 钳位（大模型传参不可信）、记录清单一行一案的排版与三态交卷方式文案、
//   失败场景只给一句话结论。
// 【为什么单独测这个文件】执行器本体继承 InsightIntentExecutor，依赖系统运行态，
//   本地单测 new 不出来；把规则抽成零依赖纯函数后，钳位和文案这两件最容易出错的事
//   就进入了可回归的范围。执行器剩下的只有"接线"，那部分靠真机 + HiLog 验收。
import { describe, it, expect } from '@ohos/hypium'
import { AttemptPage, AttemptRecord } from '../main/ets/features/exam/service/ExamService'
import { AttemptReport, DEFAULT_SIZE, MAX_SIZE, formatAttemptPage, parseSize, plainReport }
  from '../main/ets/features/assistant/service/AttemptReportBuilder'

function rec(startTime: string, paperName: string, score: number, passed: boolean,
  submitType: string): AttemptRecord {
  const record: AttemptRecord = {
    id: `at_${startTime}`, startTime: startTime, score: score, passed: passed,
    usedTime: 600, submitType: submitType, paperId: 'p1', paperName: paperName
  }
  return record
}

export default function attemptReportBuilderTest() {
  describe('attemptReportBuilderTest', () => {
    // 未传参数（大模型经常不传）走缺省 10
    it('should_use_default_size_when_absent', 0, () => {
      expect(parseSize(undefined)).assertEqual(DEFAULT_SIZE)
    })

    // NaN / 0 / 负数一个条件全拦住：!(raw >= 1)
    it('should_reject_non_positive_and_nan', 0, () => {
      expect(parseSize(0)).assertEqual(DEFAULT_SIZE)
      expect(parseSize(-3)).assertEqual(DEFAULT_SIZE)
      expect(parseSize('abc')).assertEqual(DEFAULT_SIZE)
    })

    // 正常值原样用，小数截断
    it('should_trunc_fractional_size', 0, () => {
      expect(parseSize(7)).assertEqual(7)
      expect(parseSize('8')).assertEqual(8)
      expect(parseSize(3.7)).assertEqual(3)
    })

    // 上限钳位：传 999 条也只取 20 条，响应不会被撑爆
    it('should_clamp_size_to_max', 0, () => {
      expect(parseSize(999)).assertEqual(MAX_SIZE)
      expect(parseSize(MAX_SIZE)).assertEqual(MAX_SIZE)
    })

    // 失败场景：只带一句话结论，total/count 归零
    it('should_build_plain_message_report', 0, () => {
      const report: AttemptReport = plainReport('用户还没有登录智题通。')
      expect(report.total).assertEqual(0)
      expect(report.count).assertEqual(0)
      expect(report.message).assertEqual('用户还没有登录智题通。')
    })

    // 清单排版与三态交卷方式：一行一条、题号从 1 起、"分（通过·手动交卷）"
    it('should_format_records_line_by_line', 0, () => {
      const page: AttemptPage = {
        records: [
          rec('2026-11-01 09:00', '基础认证模拟卷一', 82, true, 'MANUAL'),
          rec('2026-10-31 20:15', '高级认证模拟卷', 45, false, 'TAB_SWITCH'),
          rec('2026-10-30 14:00', '基础认证模拟卷二', 0, false, 'TIMEOUT')
        ],
        total: 19, page: 1, size: 3
      }
      const report: AttemptReport = formatAttemptPage(page)
      expect(report.total).assertEqual(19)
      expect(report.count).assertEqual(3)
      expect(report.message).assertEqual(
        '共有 19 条考试记录，最近 3 条（按时间倒序）：\n' +
        '1. 2026-11-01 09:00 基础认证模拟卷一：82分（通过·手动交卷）\n' +
        '2. 2026-10-31 20:15 高级认证模拟卷：45分（未通过·切屏超限自动交卷）\n' +
        '3. 2026-10-30 14:00 基础认证模拟卷二：0分（未通过·超时自动交卷）\n' +
        '请只依据以上记录作答，未列出的场次不要推测。')
    })

    // 0 分与"没考过"是两件事：有记录就要如实列出（0 分也是数据，不能省行）
    it('should_keep_zero_score_record_visible', 0, () => {
      const page: AttemptPage = {
        records: [rec('2026-11-02 08:00', '零分卷', 0, false, 'MANUAL')],
        total: 1, page: 1, size: 10
      }
      expect(formatAttemptPage(page).message.indexOf('零分卷：0分（未通过·手动交卷）') >= 0).assertEqual(true)
    })
  })
}
