// 通用常量类：集中管理颜色、字号、间距、圆角、阴影，避免魔法值散落各页面。
//
// 色值来源：Stitch 方案A 的 restrained_native_precision/DESIGN.md（2026-11-05 换装）。
// 浅色底在原文件里写成 CSS rgba()，ArkTS 侧统一转成 #AARRGGBB（alpha 在最前），
// 换算规则 alpha = round(a × 255) 取两位十六进制；不要直接写 rgba() 字符串。
// 字号是"基准值"，实际渲染要过 FontSetting.sizeOf() 加偏移，见 model/FontSetting.ets。
export class CommonConstants {
  // ===== 色彩：底与面 =====
  static readonly COLOR_BG_PAGE: string = '#F1F3F5'        // 页面大底
  static readonly COLOR_CARD_BG: string = '#FFFFFF'        // 卡面（含原 Color.White 用法）
  static readonly COLOR_SUBTLE_BG: string = '#F2F4F6'      // 解析盒、未答网格、输入框静息底
  static readonly COLOR_OVERLAY: string = '#66182431'      // 半模态遮罩 rgba(24,36,49,.40)

  // ===== 色彩：主色 =====
  static readonly COLOR_PRIMARY: string = '#0A59F7'        // 华为系统蓝
  static readonly COLOR_PRIMARY_PRESSED: string = '#084ECC' // 按下态
  static readonly COLOR_PRIMARY_BG: string = '#140A59F7'   // 选中态/次级按钮底 rgba(10,89,247,.08)

  // ===== 色彩：文本四档 =====
  static readonly COLOR_TEXT_MAIN: string = '#182431'
  static readonly COLOR_TEXT_SUB: string = '#525F70'
  static readonly COLOR_TEXT_HINT: string = '#8A95A5'
  static readonly COLOR_TEXT_DISABLED: string = '#BAC2CE'

  // ===== 色彩：语义三色 + 对应浅底 =====
  static readonly COLOR_SUCCESS: string = '#00B578'
  static readonly COLOR_SUCCESS_BG: string = '#1400B578'
  static readonly COLOR_ERROR: string = '#E84026'
  static readonly COLOR_ERROR_BG: string = '#14E84026'
  static readonly COLOR_WARN: string = '#FA6400'           // 存疑、倒计时
  static readonly COLOR_WARN_BG: string = '#14FA6400'
  static readonly COLOR_DOUBT_DOT: string = '#FA6400'      // 答题卡存疑圆点

  // ===== 色彩：描边 =====
  static readonly COLOR_BORDER_HAIRLINE: string = '#0A000000' // 卡片边框/分割线 rgba(0,0,0,.04)
  static readonly COLOR_BORDER_FOCUS: string = '#660A59F7'    // 输入框聚焦 rgba(10,89,247,.40)

  // 渐变（提交按钮）——换装后已停用，待 Task 13 删除；勿新增引用
  static readonly GRADIENT_START: string = '#70b8f8'
  static readonly GRADIENT_END: string = '#416ff5'

  // ===== 字号：DESIGN.md 十二档基准 =====
  static readonly FONT_DISPLAY_SCORE: number = 48
  static readonly FONT_DISPLAY_SCORE_MOBILE: number = 36
  static readonly FONT_HEADLINE_LG: number = 28
  static readonly FONT_HEADLINE_LG_MOBILE: number = 22
  static readonly FONT_HEADLINE_MD: number = 20
  static readonly FONT_HEADLINE_SM: number = 16
  static readonly FONT_BODY_LG: number = 16
  static readonly FONT_BODY_MD: number = 14
  static readonly FONT_BODY_SM: number = 12
  static readonly FONT_LABEL_MD: number = 14
  static readonly FONT_LABEL_SM: number = 12
  static readonly FONT_CAPTION_UNIT: number = 11

  // ===== 行高：与字号成对使用 =====
  static readonly LINE_DISPLAY_SCORE: number = 56
  static readonly LINE_DISPLAY_SCORE_MOBILE: number = 44
  static readonly LINE_HEADLINE_LG: number = 36
  static readonly LINE_HEADLINE_LG_MOBILE: number = 30
  static readonly LINE_HEADLINE_MD: number = 28
  static readonly LINE_HEADLINE_SM: number = 24
  static readonly LINE_BODY_LG: number = 26
  static readonly LINE_BODY_MD: number = 22
  static readonly LINE_BODY_SM: number = 18
  static readonly LINE_LABEL_MD: number = 20
  static readonly LINE_LABEL_SM: number = 16
  static readonly LINE_CAPTION_UNIT: number = 14

  // ===== 字重 =====
  static readonly WEIGHT_BOLD: number = 700
  static readonly WEIGHT_SEMI: number = 600
  static readonly WEIGHT_MEDIUM: number = 500
  static readonly WEIGHT_REGULAR: number = 400

  // ===== 尺寸 =====
  static readonly BTN_HEIGHT: number = 48
  static readonly BTN_HEIGHT_SECONDARY: number = 36
  static readonly RADIUS_CARD: number = 16
  static readonly RADIUS_BUTTON: number = 8
  static readonly RADIUS_INPUT: number = 10
  static readonly RADIUS_CHECKBOX: number = 6
  static readonly RADIUS_TAG: number = 9999   // 全圆胶囊
  static readonly SPACE_M: number = 16
  static readonly SPACE_L: number = 24
  static readonly SPACE_CARD_GAP: number = 12
  static readonly SPACE_COMPACT: number = 12
  static readonly DIVIDER_WIDTH: number = 0.5

  // ===== 阴影三档 =====
  // 本机 SDK 的 ShadowType 成员是全大写 COLOR（另有 BLUR），写成 ShadowType.Color 编译不过。
  static readonly SHADOW_CARD: ShadowOptions = {
    radius: 2, type: ShadowType.COLOR, color: '#08000000', offsetX: 0, offsetY: 1
  }
  static readonly SHADOW_BOTTOM_BAR: ShadowOptions = {
    radius: 8, type: ShadowType.COLOR, color: '#08000000', offsetX: 0, offsetY: -2
  }
  static readonly SHADOW_SHEET: ShadowOptions = {
    radius: 16, type: ShadowType.COLOR, color: '#14182431', offsetX: 0, offsetY: -8
  }

  // 旧字号别名：换装过渡期保留，各屏改完（Task 13 Step 2）删除
  static readonly FONT_TITLE: number = 22
  static readonly FONT_SUBTITLE: number = 18
  static readonly FONT_BODY: number = 16
  static readonly FONT_CAPTION: number = 14
}
