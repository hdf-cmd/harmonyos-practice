/**
 * 考试文案工具：交卷方式的唯一翻译口径
 *
 * 【为什么抽到 common】结果页与考试记录页都要显示交卷方式，两处各写一份三元判断，
 * 迟早会出现"一处改了另一处没改"的文案漂移。翻译规则收在这里，两个 ViewModel 共用。
 */

/** 交卷方式 → 中文：MANUAL 手动 / TIMEOUT 超时 / TAB_SWITCH 切屏超限 */
export function submitTypeLabel(submitType: string): string {
  if (submitType === 'MANUAL') {
    return '手动交卷'
  }
  if (submitType === 'TAB_SWITCH') {
    return '切屏超限自动交卷'
  }
  return '超时自动交卷'
}

/** 题型码 → 中文：后端存 JUDGE/SINGLE/MULTI，展示翻成中文；未知题型兜底 */
export function questionTypeLabel(type: string): string {
  if (type === 'JUDGE') {
    return '判断题'
  }
  if (type === 'SINGLE') {
    return '单选题'
  }
  if (type === 'MULTI') {
    return '多选题'
  }
  return '未知题型'
}
