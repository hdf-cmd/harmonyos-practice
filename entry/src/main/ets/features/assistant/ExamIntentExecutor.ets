/**
 * 意图执行器：小艺经意图框架调进 App 时，真正干活的入口（端插件的端侧一半）。
 *
 * 【三处同名】intentName 在本文件、insight_intent.json、平台端插件工具三处必须一字不差；
 *   intentVersion 同理。名字对不上，平台侧就找不到这个意图。
 * 【回调与执行模式一一对应】注册文件里 executeMode 写 background，这里实现的就是
 *   onExecuteInUIAbilityBackgroundMode（前台模式是另一个回调）。查成绩不需要界面，
 *   后台静默返回数据即可。
 * 【token 为什么一次都没出现】后台执行时 UIAbility 的 onCreate 照常跑，
 *   PreferencesUtil.init + SessionManager.loadFromDisk + setTokenProvider 那条链原样生效，
 *   所以这里直接 new ExamService() 就带上登录态，凭证从头到尾不出设备。
 * 【规则都写在 AttemptReportBuilder 里】钳位、文案拼装、失败话术都是可单测的纯函数，
 *   本文件只做"系统入口 → 纯逻辑 → ExecuteResult"的接线。
 */
import { InsightIntentExecutor, insightIntent } from '@kit.AbilityKit'
import { Logger, SessionManager } from '@zhititong/common'
import { ExamService, AttemptPage } from '../exam/service/ExamService'
import { AttemptReport, formatAttemptPage, parseSize, plainReport } from './service/AttemptReportBuilder'

const logger: Logger = new Logger('ExamIntentExecutor')

/** 本执行器支持的意图名：与 insight_intent.json、平台工具三处一致 */
const INTENT_QUERY_ATTEMPTS: string = 'QueryExamAttempts'

/**
 * 执行结果的具体类型。
 *
 * 【为什么不能用匿名对象字面量】ArkTS 严格模式不允许把对象字面量直接断言成接口类型
 *   （arkts-no-untyped-obj-literals），所以给 ExecuteResult 一个具名实现类。
 */
class IntentExecuteResult implements insightIntent.ExecuteResult {
  code: number
  result: Record<string, Object>

  constructor(code: number, result: Record<string, Object>) {
    this.code = code
    this.result = result
  }
}

/** 报告 → 200 结果：total/count 给结构化消费方（卡片绑定），message 给大模型读 */
function toResult(report: AttemptReport): insightIntent.ExecuteResult {
  const data: Record<string, Object> = {
    'total': report.total,
    'count': report.count,
    'message': report.message
  }
  return new IntentExecuteResult(200, data)
}

/** 只带一句话结论的结果（未登录 / 无记录 / 查询失败） */
function toMessageResult(message: string): insightIntent.ExecuteResult {
  const data: Record<string, Object> = { 'message': message }
  return new IntentExecuteResult(200, data)
}

export default class ExamIntentExecutor extends InsightIntentExecutor {
  /** 后台执行模式入口 */
  async onExecuteInUIAbilityBackgroundMode(intentName: string,
    param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
    logger.info(`收到意图调用：${intentName}，参数：${JSON.stringify(param)}`)
    if (intentName !== INTENT_QUERY_ATTEMPTS) {
      const data: Record<string, Object> = { 'message': `未知意图：${intentName}` }
      return new IntentExecuteResult(-1, data)
    }
    return this.queryAttempts(param)
  }

  /** 查询考试记录：复用 App 的登录态与网络层 */
  private async queryAttempts(param: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
    if (!SessionManager.isLoggedIn()) {
      // 话术里直接写"请提示用户……"：这是用返回值给大模型下指令，引导它如实转述
      return toMessageResult('用户还没有登录智题通，请提示用户先在 App 内登录后再查询成绩。')
    }
    const size: number = parseSize(param['size'])
    try {
      const service: ExamService = new ExamService()
      const pageData: AttemptPage = await service.getAttempts(1, size)
      if (pageData.records.length === 0) {
        return toMessageResult('当前账号还没有考试记录，可以提示用户先去考试中心考一场。')
      }
      const report: AttemptReport = formatAttemptPage(pageData)
      logger.info(`成绩查询成功：共 ${report.total} 条，本次返回 ${report.count} 条`)
      return toResult(report)
    } catch (e) {
      const message: string = (e as Error).message
      logger.error(`成绩查询失败：${message}`)
      return toMessageResult(`查询考试记录失败：${message}。请如实告知用户稍后再试，不要编造成绩。`)
    }
  }
}
