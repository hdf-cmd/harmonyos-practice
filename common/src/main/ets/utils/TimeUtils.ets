// 时长格式化工具：将秒数换算为 "X 分 X 秒" 文本

// 将秒数换算为 "X 分 X 秒" 形式，如 formatDuration(754) => "12 分 34 秒"
// 纯函数：不修改入参、不依赖任何状态，后续便于补单元测试
export function formatDuration(seconds: number): string {
  const minutes: number = Math.floor(seconds / 60)
  const restSeconds: number = seconds % 60
  return `${minutes} 分 ${restSeconds} 秒`
}
