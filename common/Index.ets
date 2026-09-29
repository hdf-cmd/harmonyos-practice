/**
 * @zhititong/common 对外能力总出口。
 *
 * 【为什么只能从这里导出】HAR 是包级依赖：entry 只能 import 本文件导出的符号，
 *   模块内部的目录结构（base/、utils/ 等）对外不可见，内部实现可自由调整而不波及调用方。
 */
// base：ViewModel 基座与统一结果封装
export { BaseViewModel } from './src/main/ets/base/BaseViewModel';
export { Result } from './src/main/ets/base/Result';
// constants：样式常量、路由常量与应用级状态 key
export { CommonConstants } from './src/main/ets/constants/CommonConstants';
export { RouteConstants } from './src/main/ets/constants/RouteConstants';
export { StateKeys } from './src/main/ets/constants/StateKeys';
// log：hilog 薄封装
export { Logger } from './src/main/ets/log/Logger';
// model：跨 feature 共享的数据契约
export { OptionItem, QuestionItem, PaperInfo, AnswerItem, ExamResult } from './src/main/ets/model/QuestionModel';
// 状态模型：字号设置（应用级持久化状态，落盘由 PersistenceV2 接管）
export { FontSetting, FONT_LEVELS, FontLevel } from './src/main/ets/model/FontSetting';
// 状态模型：切后台监视器（应用级运行状态，AppStorageV2 共享，不落盘）
export { BackgroundMonitor } from './src/main/ets/model/BackgroundMonitor';
// mock：多 feature 共用的假数据
export { MOCK_PAPER, MOCK_PAPERS, MOCK_QUESTIONS } from './src/main/ets/mock/MockExamData';
export { MOCK_RESULT } from './src/main/ets/mock/MockResultData';
// utils：纯函数工具
export { CategoryGroup, getRandomPapers, filterByCategory, groupByCategory } from './src/main/ets/utils/PaperUtils';
export { formatDuration } from './src/main/ets/utils/TimeUtils';
export { ValidationResult, ValidationUtil } from './src/main/ets/utils/ValidationUtil';
