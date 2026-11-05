/**
 * 助教入口宿主组件：只负责"能不能用"，不负责长什么样。
 *
 * 【为什么要有这一层】@kit.AgentFrameworkKit 是带原生库的 kit。模拟器和不具备
 *   AgentKit 能力的设备上，只要静态 import 到它，模块加载阶段就可能直接出错——表现为
 *   "整页白屏"，而不是"这个按钮没了"。所以本文件一个 kit 符号都不 import，
 *   三道检查全过之后，才用动态 import 把真正依赖 AgentKit 的模块拉进来。
 * 【三道检查的次序】① AgentID 是否填了（没填=没配好，别费劲加载）② 是否模拟器
 *   ③ 系统能力是否具备。前两道是纯字符串判断，便宜；`canIUse` 最贵，放最后。
 * 【generation 用来挡异步竞争】动态 import 是异步的：加载回来的那一刻，页面可能已经被
 *   销毁或重建（回顾页切题会销毁重建入口）。用自增序号比对，序号不一致就丢弃结果，
 *   避免把 builder 塞回一个已经不该再渲染的实例。
 */
import { deviceInfo } from '@kit.BasicServicesKit'
import { Logger } from '@zhititong/common'
import { ASSISTANT_AGENT_ID, ASSISTANT_ALLOW_EMULATOR } from './AssistantConstants'

/** 动态加载回来的模块形状：只需要工厂函数这一个入口 */
interface AssistantEntryModule {
  createAssistantBuilder(): WrappedBuilder<[string, string]>
}

@ComponentV2
export struct AssistantEntry {
  // 按钮文字；留空则渲染为圆形图标（形态选择见 SupportedAssistantEntry）
  @Param @Once title: string = ''
  // 拉起对话后自动发送的问题文本
  @Param @Once queryText: string = ''
  @Local loaded: boolean = false
  private assistantBuilder: WrappedBuilder<[string, string]> | undefined = undefined
  private generation: number = 0
  private logger: Logger = new Logger('AssistantEntry')

  aboutToAppear(): void {
    const generation: number = ++this.generation
    if (ASSISTANT_AGENT_ID.length === 0) {
      this.logger.info('未配置 AgentID，助教入口关闭')
      return
    }
    // 模拟器必须在动态导入之前拦下。11-04 实测：模拟器上 canIUse 回 true，但缺 agentKitHsp
    //   这个共享模块，import 一执行就是 LoadJSPandaFile 失败 → 进程 Fatal 死亡，catch 不住。
    //   所以这道判断没有替代方案，ASSISTANT_ALLOW_EMULATOR 请保持 false（详见 AssistantConstants）。
    const isEmulator: boolean = deviceInfo.productModel.toLowerCase().includes('emulator')
    if (isEmulator && !ASSISTANT_ALLOW_EMULATOR) {
      this.logger.info('模拟器缺 agentKitHsp，助教入口关闭')
      return
    }
    if (!canIUse('SystemCapability.AI.Agent.AgentKit')) {
      this.logger.info('系统不具备 AgentKit 能力，助教入口关闭')
      return
    }
    void this.loadAssistant(generation)
  }

  private async loadAssistant(generation: number): Promise<void> {
    try {
      const assistantModule: AssistantEntryModule = await import('./SupportedAssistantEntry')
      if (this.generation === generation) {
        // 页面还在：拿到 builder 才允许渲染
        this.assistantBuilder = assistantModule.createAssistantBuilder()
        this.loaded = true
      }
    } catch (error) {
      this.logger.error(`助教组件加载失败：${(error as Error).message}`)
    }
  }

  aboutToDisappear(): void {
    // 让在途的加载结果作废，并交还 builder 引用
    this.generation++
    this.loaded = false
    this.assistantBuilder = undefined
  }

  build() {
    if (this.loaded && this.assistantBuilder) {
      this.assistantBuilder.builder(this.title, this.queryText)
    }
  }
}
