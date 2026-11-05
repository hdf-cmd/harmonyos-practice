/**
 * 助教的唯一配置源：AgentID 全工程只写这一处。
 *
 * 【为什么单独一个文件】AgentID 同时被三处需要——入口组件拉起、能力预检、日志定位。
 *   散在各页面里写死字符串，改一次要翻三个页面，漏一处就出现"半屏对话拉起了别的智能体"。
 * 【AgentID 从哪来】小艺开放平台 → Agent → 本智能体的配置页 AgentCard。每人的智能体不同，
 *   不能沿用教材示例值；填错会拉起别人的智能体或提示未授权。
 * 【留空时的行为】宿主组件直接把入口关掉（见 AssistantEntry），表现为"页面上没有助教按钮"，
 *   而不是点下去报未授权——这是缺配置时最省事的自检。
 * 【填了还要做两件事】① 平台侧把包名 com.hdf.zhititong（AGC APP ID 6917620886067339507）的应用关联到该智能体；
 *   ② 用基于该 AGC 应用的手动签名重装，并点"重新发布真机测试"。少任一步，真机上拉不起来。
 */

/** 智题通备考助教的 AgentID；填入后入口才会出现 */
export const ASSISTANT_AGENT_ID: string = 'agentec877f4d82a4426abd47dab040749606'

/**
 * 调试开关：允许模拟器也尝试加载 AgentKit 入口。**只能是 false，别改 true。**
 *
 * 【为什么留着这个开关】11-04 实测过一次，结论是硬的：模拟器上
 *   `canIUse('SystemCapability.AI.Agent.AgentKit')` 返回 **true**（能力声明在，
 *   `param get const.SystemCapability.AI.Agent.AgentKit` 同样回 true），
 *   但 AgentKit 的实现体是一个 HSP 共享模块 `agentKitHsp`，宿主在 `com.huawei.hmsapp.hiai.hsp`。
 *   模拟器镜像里的 HiAI 引擎只装了 `commonBaseHsp`（hapPath 带 ideX86 字样，是裁剪过的 x86 版），
 *   没有 agentKitHsp，于是动态 import 一执行就是：
 *   `[LoadJSPandaFile] load hsp failed ... Get shared HspPath failed` →
 *   `DfxFaultLogger LastFatalMessage` → `PARAM_WATCHER Agent died <pid>`，**整个应用直接死**。
 * 【由此纠正一条设计假设】"用动态 import 把 kit 依赖隔开就不崩"是不成立的：
 *   崩在模块加载期的 Fatal，catch 不住。所以模拟器必须在 import 之前用机型判断拦下，
 *   这道检查没有替代方案。
 */
export const ASSISTANT_ALLOW_EMULATOR: boolean = false

/**
 * 成绩页/回顾页带给助手的错题线索条数上限。
 *
 * 【为什么要限】queryText 是整段拼好发给云端的，错题越多上下文越长，
 *   既有请求体风险，也会把助教的答案稀释成"逐题复述"。前 5 道足够它给出针对性建议。
 */
export const ASSISTANT_WRONG_TITLE_LIMIT: number = 5
