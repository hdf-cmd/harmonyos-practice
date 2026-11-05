/**
 * 助教入口真身：本 feature 里唯一静态导入 @kit.AgentFrameworkKit 的文件。
 *
 * 【为什么单独一个文件】把 kit 依赖收在这一个文件里，宿主（AssistantEntry）才能靠动态
 *   import 实现"不支持的设备不加载原生库"。一旦别的页面也直接 import 这个 kit，
 *   隔离就失效了——模拟器和低版本设备会退化成整页出问题。
 * 【先预检再渲染】FunctionController.isAgentSupport() 问的是"这台设备当前能不能用这个
 *   智能体"（账号是否在白名单、智能体是否已发布真机测试、应用是否被关联），
 *   和宿主的三道检查不重复：宿主查的是框架能力，这里查的是授权与发布状态。
 * 【参数只在创建时生效】agentId/options（含 queryText）由 FunctionComponent 在创建时读一次，
 *   之后改 @Param 不会更新已创建的组件。所以带上下文的入口要么等数据就绪再创建，
 *   要么靠 ForEach 键值变化重建（回顾页就是这么做的）。
 */
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { FunctionComponent, FunctionController, FunctionOptions, ButtonType as AgentButtonType }
  from '@kit.AgentFrameworkKit'
import { Logger } from '@zhititong/common'
import { ASSISTANT_AGENT_ID } from './AssistantConstants'

@ComponentV2
struct SupportedAssistantEntry {
  @Param @Once title: string = ''
  @Param @Once queryText: string = ''
  @Local supported: boolean = false
  private controller: FunctionController | undefined = undefined
  private logger: Logger = new Logger('AssistantEntry')
  // 对话开/关各打一条：真机验收"入口到底拉起了什么"就靠这两行 HiLog
  private onOpened: () => void = () => this.logger.info('agentDialogOpened')
  private onClosed: () => void = () => this.logger.info('agentDialogClosed')

  aboutToAppear(): void {
    void this.checkSupport()
  }

  private async checkSupport(): Promise<void> {
    try {
      const context: common.UIAbilityContext | undefined =
        this.getUIContext().getHostContext() as common.UIAbilityContext | undefined
      if (!context) {
        // 拿不到宿主上下文（例如被 @Preview 直接渲染）：不预检也不渲染，宁缺毋滥
        this.logger.info('取不到 UIAbilityContext，助教入口不渲染')
        return
      }
      const controller: FunctionController = new FunctionController()
      this.controller = controller
      controller.on('agentDialogOpened', this.onOpened)
      controller.on('agentDialogClosed', this.onClosed)
      this.supported = await controller.isAgentSupport(context, ASSISTANT_AGENT_ID)
      this.logger.info(`isAgentSupport=${this.supported}`)
    } catch (error) {
      const err: BusinessError = error as BusinessError
      this.logger.error(`isAgentSupport 失败，code=${err.code}，message=${err.message}`)
    }
  }

  aboutToDisappear(): void {
    // 事件订阅必须成对取消，否则组件销毁后回调仍持有 this
    this.supported = false
    if (this.controller) {
      this.controller.off('agentDialogOpened', this.onOpened)
      this.controller.off('agentDialogClosed', this.onClosed)
      this.controller = undefined
    }
  }

  private getOptions(): FunctionOptions {
    const options: FunctionOptions = {
      title: this.title,
      // 有标题用胶囊按钮，无标题用圆形图标（圆形那枚要叠在列表右下角）
      buttonType: this.title === '' ? AgentButtonType.CIRCLE : AgentButtonType.CAPSULE
    }
    if (this.queryText !== '') {
      // 空串就别塞：留空表示"打开对话让用户自己问"，而不是自动发一条空消息
      options.queryText = this.queryText
    }
    return options
  }

  build() {
    if (this.supported) {
      FunctionComponent({
        agentId: ASSISTANT_AGENT_ID,
        controller: this.controller,
        options: this.getOptions(),
        onError: (err: BusinessError): void => {
          // 常见码：1022400010 参数错、1022400014 内部错；未授权/未发布多落在这里
          this.logger.error(`FunctionComponent 失败，code=${err.code}，message=${err.message}`)
        }
      })
    }
  }
}

@Builder
function assistantEntryBuilder(title: string, queryText: string) {
  SupportedAssistantEntry({ title: title, queryText: queryText })
}

/** 给宿主组件的工厂：返回 WrappedBuilder，宿主在 build() 里调用它渲染真身 */
export function createAssistantBuilder(): WrappedBuilder<[string, string]> {
  return wrapBuilder(assistantEntryBuilder)
}
