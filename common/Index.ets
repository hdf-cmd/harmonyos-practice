/**
 * @zhititong/common 对外能力总出口。
 *
 * 【为什么只能从这里导出】HAR 是包级依赖：entry 只能 import 本文件导出的符号，
 *   模块内部的目录结构（base/、utils/ 等）对外不可见，内部实现可自由调整而不波及调用方。
 */
// base：ViewModel 基座、统一结果封装、Service 两层拆包基类
export { BaseViewModel } from './src/main/ets/base/BaseViewModel';
export { Result } from './src/main/ets/base/Result';
export { ApiResponse, BaseService } from './src/main/ets/base/BaseService';
// config：会变的运行参数（后端地址、超时、日志开关）集中一处
export { AppConfig } from './src/main/ets/config/AppConfig';
// network：HTTP 客户端与拦截器链。业务侧通常只用 httpClient（或继承 BaseService），
//   四个类型与拦截器一并导出，是为了单测与自定义拦截器可寻址。
export { RequestConfig, HttpResult, Interceptor } from './src/main/ets/network/types';
export { HttpClient } from './src/main/ets/network/HttpClient';
export { TokenProvider, TokenInterceptor, LoggingInterceptor } from './src/main/ets/network/interceptors';
export { httpClient, setTokenProvider } from './src/main/ets/network/http';
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
