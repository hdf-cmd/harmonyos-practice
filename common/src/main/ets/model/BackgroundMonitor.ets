/**
 * 切后台监视器（防作弊）：考试进行中，应用每切到后台一次就累计一次。
 *
 * 【为什么"要不要计数"写在类里，而不是让调用方判断】切后台是否算作弊，取决于"此刻是不是在考试中"，
 *   这是业务规则，不是调用方的现场判断。把判断收进 increase() 之后，EntryAbility.onBackground
 *   只管无脑调用，不需要自己读 monitoring 加分支；规则将来要改（比如允许切出去一次）只动这一处，
 *   也不会出现"某个调用方漏了判断"这种分散性错误。
 * 【为什么运行期状态不落盘】切后台次数只对本场考试有意义，跨场累计反而失真，
 *   所以用 AppStorageV2 全局共享、进程结束即清零。这与字号设置走 PersistenceV2 落盘
 *   正好构成应用级状态的两种用法对照：一个跟着进程走，一个跟着用户走。
 * 【为什么 stop() 不清零】交卷后结果页还要读这一场的次数，清零等于把刚产生的数据丢掉。
 *   归零时机只有 start() 一个——"开考"这个动作自带重置语义。
 */
@ObservedV2
export class BackgroundMonitor {
  // 本场考试切到后台的次数
  @Trace count: number = 0
  // 是否处于监视中：true = 考试进行中
  @Trace monitoring: boolean = false

  // 开考调用：进入监视并清零计数
  start(): void {
    this.count = 0
    this.monitoring = true
  }

  // 交卷/离场调用：停止监视，计数保留供结果页读取
  stop(): void {
    this.monitoring = false
  }

  // 累计一次切后台（由 EntryAbility.onBackground 调用）：非监视中一律不计
  increase(): void {
    if (this.monitoring) {
      this.count++
    }
  }
}
