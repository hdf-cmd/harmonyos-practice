# 智题通 UI 换装（方案A 鸿蒙原生克制风）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 12 个页面的视觉语言对齐 Stitch 方案A，不新增任何后端没有数据的区块。

**Architecture:** 设计令牌集中在 `common/src/main/ets/constants/CommonConstants.ets`（现有模式，14 个 view 已引用），换装 = 扩令牌 + 把 24 处硬编码色值收编进令牌 + 逐屏调整卡片结构与状态底。不引入 `resources/element/color.json` 层。

**Tech Stack:** ArkTS / ArkUI（@ComponentV2 + @ObservedV2/@Trace）、hypium 本地单测、hvigor 构建、DevEco 模拟器目检。

**Spec:** `docs/superpowers/specs/2026-11-05-zhititong-ui-reskin-design.md`（本计划逐条实现它，执行时两份都读）

## Global Constraints

以下每一条对**所有任务**生效，值从 spec 与 DESIGN.md 逐字抄来：

- 权威色值源：`design/stitch/v2-final2/stitch_harmonyos_exam_client/restrained_native_precision/DESIGN.md`。**禁止**使用 `design/stitch/方案A-设计规范.md` 的色值（文件头已标失效）。
- 主色 `#0A59F7`，按下态 `#084ECC`；页面底 `#F1F3F5`；卡面 `#FFFFFF`。
- 文本三档 `#182431` / `#525F70` / `#8A95A5`；禁用 `#BAC2CE`。
- 语义色 成功 `#00B578` / 错误 `#E84026` / 警示 `#FA6400`。
- 浅色底一律 `#AARRGGBB` 形式（ArkTS 不吃 CSS `rgba()` 字符串），alpha = round(a×255) 转十六进制。
- 卡片圆角 16、按钮圆角 8、输入框圆角 10、复选框圆角 6、标签全圆胶囊。
- 按钮高 48；页面左右边距 16；卡片内边距 16（紧凑 12）；卡片纵向间距 12；分割线 0.5。
- **不加**任何后端没有的区块：统计指标卡、搜索框、筛选器、排序、下载 PDF、认证徽章、哈希防伪话术、版本号、科目属性标签（推荐/必考/高频/强化/专精/全真）。
- 页面文案保持现有中文，不得引入英文标题（HarmonyOS/ArkTS/Stage/UIAbility 等专有名词除外）。
- 未经用户明确要求，不 commit 到 master、不 push、不切分支覆盖写。本计划在 feature 分支 `feat/ui-reskin` 上逐任务提交，末任务再 ff 合并。
- 每个任务的验证**必须同时跑** `devecocli build` 与 `hvigorw test`：`hvigorw test` 不编译 view，只跑单测等于没验视图。

## 关于"测试"的说明（执行者先读这段）

这是纯视觉换装，ArkTS 的 hypium LocalUnit 跑在无 UI 环境，**断言不了布局、圆角、阴影**。所以本计划里只有三个任务带真正的单元测试（Task 2/3 是纯逻辑，Task 13 复核用例总数）；其余视图任务的门禁是：

1. `devecocli build` 0 ERROR —— 唯一能逼出视图编译错的手段；
2. `hvigorw test` 尾行 `Tests run: N, Failure: 0, Error: 0`，且 N 与上一任务相同（用例数变了就是回归）；
3. 静态 grep —— 该文件的硬编码色值计数必须降到 0；
4. 模拟器目检 —— 对 `design/stitch/v2-final2/stitch_harmonyos_exam_client/_<n>/screen.png` 逐屏比。

给视图硬写"断言字号等于 16"的单测是假测试，不要写。

---

### Task 1: 令牌层扩容

**Files:**
- Modify: `common/src/main/ets/constants/CommonConstants.ets`（全文重写，现 24 行）

**Interfaces:**
- Consumes: 无
- Produces: 全部令牌常量名。后续任务一律引用这些名字，**不得再写十六进制字面量**。色彩类常量类型均为 `string`，尺寸/字号为 `number`。

- [ ] **Step 1: 重写 CommonConstants.ets**

把整个文件替换为下面内容。注意：`GRADIENT_START` / `GRADIENT_END` **本任务保留**（答题页与结果页还在用，Task 7/9 停用、Task 13 删除）。

```ts
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
  static readonly SHADOW_CARD: ShadowOptions = {
    radius: 2, type: ShadowType.Color, color: '#08000000', offsetX: 0, offsetY: 1
  }
  static readonly SHADOW_BOTTOM_BAR: ShadowOptions = {
    radius: 8, type: ShadowType.Color, color: '#08000000', offsetX: 0, offsetY: -2
  }
  static readonly SHADOW_SHEET: ShadowOptions = {
    radius: 16, type: ShadowType.Color, color: '#14182431', offsetX: 0, offsetY: -8
  }
}
```

- [ ] **Step 2: 构建验证**

Run: `cd <工程> && devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，且日志尾行 `Build completed successfully`

若报 `Cannot find name 'ShadowOptions'`：ArkUI 全局类型，无需 import。若报 `has no exported member 'FONT_TITLE'` 之类，说明还有 view 引用旧常量名——旧名 `FONT_TITLE/FONT_SUBTITLE/FONT_BODY/FONT_CAPTION` 已被拆成十二档，**先记下报错文件清单**，那是后续任务的改动对象；本任务为让工程保持可编译，在类末尾临时补四行别名，Task 13 一并删除：

```ts
  // 旧字号别名：换装过渡期保留，各屏改完（Task 13）删除
  static readonly FONT_TITLE: number = 22
  static readonly FONT_SUBTITLE: number = 18
  static readonly FONT_BODY: number = 16
  static readonly FONT_CAPTION: number = 14
```

- [ ] **Step 3: 单测回归**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 121, Failure: 0, Error: 0, Pass: 121, Ignore: 0`

- [ ] **Step 4: Commit**

```bash
git add common/src/main/ets/constants/CommonConstants.ets
git commit -m "refactor: 换装令牌层扩容（方案A 色值/字阶/圆角/阴影）"
```

---

### Task 2: 极小档可读性下限

**Files:**
- Modify: `common/src/main/ets/model/FontSetting.ets:24-30`
- Test: `common/src/test/FontSetting.test.ets`

**Interfaces:**
- Consumes: 无
- Produces: `FONT_LEVELS` 五档偏移改为 `-2 / -1 / 0 / 1 / 2`；`sizeOf()` 行为不变。

- [ ] **Step 1: 写失败测试**

在 `common/src/test/FontSetting.test.ets` 的 `describe` 块内追加：

```ts
    // 换装后基准字号最小是 11（FONT_CAPTION_UNIT），极小档若仍是 -4 会算出 7fp，
    // 中文辅助文字基本看不清。下限收到 -2 后最小 9fp。
    it('polar_min_keeps_caption_unit_legible', 0, () => {
      const fs = new FontSetting()
      fs.stepTo(0)                       // 极小档
      expect(fs.sizeOf(11)).assertEqual(9)
    })

    it('polar_max_does_not_exceed_display_mobile_base', 0, () => {
      const fs = new FontSetting()
      fs.stepTo(4)                       // 极大档
      expect(fs.sizeOf(11)).assertEqual(13)
    })
```

- [ ] **Step 2: 跑测试确认失败**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt common/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行出现 `Failure: 1`，失败用例名 `polar_min_keeps_caption_unit_legible`，断言信息含 `7` 与 `9`

- [ ] **Step 3: 改档位表**

`FontSetting.ets` 第 23-30 行替换为：

```ts
// 五档字号偏移档位。增减档位只改这一处
// 上限取 ±2 而不是原来的 ±4：换装后最小基准字号降到 11（辅助标签），
// ±4 会让它掉到 7fp、中文看不清；±2 时极小档 9fp 仍在可读线以上。
export const FONT_LEVELS: FontLevel[] = [
  { label: '极小', size: -2 },
  { label: '小', size: -1 },
  { label: '标准', size: 0 },
  { label: '大', size: 1 },
  { label: '极大', size: 2 }
]
```

- [ ] **Step 4: 跑测试确认通过**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt common/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Tests run: 123, Failure: 0, Error: 0, Pass: 123`（121 + 新增 2）

- [ ] **Step 5: Commit**

```bash
git add common/src/main/ets/model/FontSetting.ets common/src/test/FontSetting.test.ets
git commit -m "fix: 极小档偏移收到 -2，避免辅助文字掉到 7fp"
```

---

### Task 3: 答题进度 getter（答题卡要显示"已答 x / y"）

**Files:**
- Modify: `entry/src/main/ets/features/exam/viewmodel/ExamDetailViewModel.ets`（在 `isQuestionFlagged` 之后插入）
- Test: `entry/src/test/ExamDetailViewModel.test.ets`

**Interfaces:**
- Consumes: 已有 `questions: QuestionItem[]`、`isQuestionAnswered(id): boolean`
- Produces: `answeredCount(): number` —— 无参，返回已答题数。Task 8 的答题卡底部要用。

- [ ] **Step 1: 写失败测试**

在 `entry/src/test/ExamDetailViewModel.test.ets` 的 `describe` 内追加（沿用该文件已有的 VM 构造方式；若文件里已有构造 helper 就复用它，别新建 service）：

```ts
    // 答题卡底部要显示"已答 x / y"。计数是纯逻辑，能单测。
    it('answered_count_zero_before_any_selection', 0, () => {
      const vm = new ExamDetailViewModel()
      vm.questions = [{ id: 'q1', type: 'SINGLE', content: 'c', options: [] }]
      expect(vm.answeredCount()).assertEqual(0)
    })

    it('answered_count_counts_single_and_multi_and_true_false', 0, () => {
      const vm = new ExamDetailViewModel()
      vm.questions = [
        { id: 'q1', type: 'SINGLE', content: 'c', options: [] },
        { id: 'q2', type: 'MULTI', content: 'c', options: [] },
        { id: 'q3', type: 'TRUE_FALSE', content: 'c', options: [] },
        { id: 'q4', type: 'SINGLE', content: 'c', options: [] }
      ]
      vm.radioSelected = 'A'
      vm.checkboxSelected = new Set<string>(['A', 'C'])
      expect(vm.answeredCount()).assertEqual(2)
    })
```

- [ ] **Step 2: 跑测试确认失败**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Failure` 或编译错误 `Property 'answeredCount' does not exist`——两者都算失败成立

- [ ] **Step 3: 实现 getter**

在 `ExamDetailViewModel.ets` 的 `isQuestionFlagged` 方法之后插入。注意：`radioSelected` 是单选取值、`checkboxSelected` 是多选取值，两者互斥使用，所以按题型分流数：

```ts
  // 已答题数：答题卡底部"已答 x / y"与提交前确认都用它。
  // 按题型分流而不是统一查一张 answerMap——单选存 radioSelected（全局一个），
  // 多选存 checkboxSelected（Set），两者的"是否作答"判法不同。
  answeredCount(): number {
    let count: number = 0
    for (let i = 0; i < this.questions.length; i++) {
      if (this.isQuestionAnswered(this.questions[i].id)) {
        count++
      }
    }
    return count
  }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Tests run: 125, Failure: 0, Error: 0, Pass: 125`（123 + 新增 2）

若第二条用例失败，先读 `isQuestionAnswered()` 的实现确认它对 `TRUE_FALSE` 走的是哪条分支——判断题的正确答案以选项 `A`/`B` 提交（见 AGENTS.md 硬约束），不要为了过测试改判据。

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/features/exam/viewmodel/ExamDetailViewModel.ets entry/src/test/ExamDetailViewModel.test.ets
git commit -m "feat: 答题页 VM 增加 answeredCount 计数（答题卡进度用）"
```

---

### Task 4: 登录页

**Files:**
- Modify: `entry/src/main/ets/features/login/view/LoginPage.ets`

**Interfaces:**
- Consumes: Task 1 的 `COLOR_CARD_BG` / `RADIUS_CARD` / `SHADOW_CARD` / `RADIUS_INPUT` / `COLOR_BORDER_FOCUS` / `COLOR_SUBTLE_BG` / `BTN_HEIGHT` / `RADIUS_BUTTON`
- Produces: 无（叶子任务）

- [ ] **Step 1: 表单收进单张白卡**

把 Logo 以下的表单区外层包一个 `Column`，属性固定为：

```ts
.width('100%')
.padding(CommonConstants.SPACE_M)
.borderRadius(CommonConstants.RADIUS_CARD)
.backgroundColor(CommonConstants.COLOR_CARD_BG)
.shadow(CommonConstants.SHADOW_CARD)
```

- [ ] **Step 2: 输入框按令牌重排**

每个 `TextInput` 的修饰链改为：

```ts
.backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
.borderRadius(CommonConstants.RADIUS_INPUT)
.border({ width: 0.5, color: CommonConstants.COLOR_BORDER_HAIRLINE })
.fontSize(CommonConstants.FONT_BODY_LG)
.fontColor(CommonConstants.COLOR_TEXT_MAIN)
.placeholderColor(CommonConstants.COLOR_TEXT_DISABLED)
.placeholderFont({ size: CommonConstants.FONT_BODY_MD })
```

- [ ] **Step 3: 主按钮去 `Color.White`**

登录/注册按钮链改为（`Color.White` → `COLOR_CARD_BG`，这是本文件的硬编码清零点）：

```ts
.height(CommonConstants.BTN_HEIGHT)
.borderRadius(CommonConstants.RADIUS_BUTTON)
.fontSize(CommonConstants.FONT_BODY_LG)
.fontWeight(CommonConstants.WEIGHT_MEDIUM)
.fontColor(CommonConstants.COLOR_CARD_BG)
.backgroundColor(this.vm.busy ? CommonConstants.COLOR_TEXT_DISABLED : CommonConstants.COLOR_PRIMARY)
```

按下态用 `.stateStyles({ pressed: { .backgroundColor(CommonConstants.COLOR_PRIMARY_PRESSED) } })`。三态文案（登录/注册/请稍候...）与 `AuthExpiredError` 分流逻辑**不动**。

- [ ] **Step 4: 切换行与错误行字阶**

「没有账号？/立即注册」用 `FONT_BODY_MD` + `COLOR_TEXT_SUB`，链接部分 `COLOR_PRIMARY`；错误行 `FONT_BODY_SM` + `COLOR_ERROR`。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#FFFFFF'" entry/src/main/ets/features/login/view/LoginPage.ets`
Expected: `0`

- [ ] **Step 6: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR` → `0`
Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Tests run: 125, Failure: 0, Error: 0`

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/features/login/view/LoginPage.ets
git commit -m "style: 登录页对齐方案A（单卡表单 + 令牌化输入框与按钮）"
```

---

### Task 5: 首页与试卷卡片

**Files:**
- Modify: `entry/src/main/ets/features/home/view/HomeView.ets`
- Modify: `entry/src/main/ets/features/home/view/components/PaperCard.ets`

**Interfaces:**
- Consumes: Task 1 令牌
- Produces: `PaperCard` 的新内部结构（Task 6 的 `ExamListPage` 行结构与之同构，要照同一套属性链写）

- [ ] **Step 1: PaperCard 等级标签改浅蓝底全圆胶囊**

现有是"透明底 + 主色 1vp 描边 + 圆角 4"。替换为：

```ts
Text(this.paper.levelName)
  .fontSize(CommonConstants.FONT_LABEL_SM)
  .fontWeight(CommonConstants.WEIGHT_MEDIUM)
  .fontColor(CommonConstants.COLOR_PRIMARY)
  .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
  .borderRadius(CommonConstants.RADIUS_TAG)
  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
  .height(24)
```

- [ ] **Step 2: 成绩角标同改为胶囊**

`最好 X 分` / `未考` 两处 `Text` 均改为：

```ts
.fontSize(CommonConstants.FONT_LABEL_SM)
.fontWeight(CommonConstants.WEIGHT_MEDIUM)
.fontColor(this.paper.bestScore > 0 ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_HINT)
.backgroundColor(this.paper.bestScore > 0 ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_SUBTLE_BG)
.borderRadius(CommonConstants.RADIUS_TAG)
.height(24)
.padding({ left: 10, right: 10, top: 4, bottom: 4 })
.margin({ top: 6 })
```

- [ ] **Step 3: 卡面与副文案令牌化**

副行 `共 X 题 · Y 分钟 · 及格 Z 分` 用 `FONT_BODY_SM` + `COLOR_TEXT_SUB`。卡片根 `Row` 的 `'#FFFFFF'` → `CommonConstants.COLOR_CARD_BG`，`borderRadius(12)` → `CommonConstants.RADIUS_CARD`，`padding(SPACE_M)` 保持，追加 `.border({ width: 0.5, color: CommonConstants.COLOR_BORDER_HAIRLINE })` 与 `.shadow(CommonConstants.SHADOW_CARD)`。

- [ ] **Step 4: HomeView 轮播与分区标题**

轮播 `Swiper` 高度保持 160，圆角改 `RADIUS_CARD`；分区标题「推荐试卷」用 `FONT_HEADLINE_MD` + `COLOR_TEXT_MAIN`，与列表间距 `SPACE_CARD_GAP`。列表 `List` 的 `space` 设 12。错误态按钮链同 Task 4 Step 3 的次级按钮形态（`BTN_HEIGHT_SECONDARY` + `COLOR_PRIMARY_BG` 底 + `COLOR_PRIMARY` 字），文案「重新登录」/「重试」的分流逻辑不动。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#FFFFFF'" entry/src/main/ets/features/home/view/HomeView.ets entry/src/main/ets/features/home/view/components/PaperCard.ets`
Expected: 两个文件都 `0`

- [ ] **Step 6: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR` → `0`
Run: `rm -f entry/.test/.../test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Tests run: 125, Failure: 0, Error: 0`

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/features/home
git commit -m "style: 首页与试卷卡片对齐方案A（胶囊标签 + 令牌化卡面）"
```

---

### Task 6: 刷题域（科目网格 + 考卷列表）

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/ExamSubjectView.ets`
- Modify: `entry/src/main/ets/features/exam/view/components/ExamSubjectCard.ets`
- Modify: `entry/src/main/ets/features/exam/view/ExamListPage.ets`

**Interfaces:**
- Consumes: Task 5 的胶囊标签写法（`ExamListPage` 行结构与 `PaperCard` 同构）
- Produces: 无

- [ ] **Step 1: ExamSubjectCard 令牌化**

科目名 `FONT_HEADLINE_SM` + `COLOR_TEXT_MAIN`；`共 N 套` `FONT_BODY_SM` + `COLOR_TEXT_SUB`；卡面 `COLOR_CARD_BG` + `RADIUS_CARD` + `SHADOW_CARD` + 0.5 发丝边框。Grid 的 `columnsGap`/`rowsGap` 保持 16。

- [ ] **Step 2: 明确不加的东西**

DESIGN.md F03 提到图标容器、属性标签（推荐/必考/高频/强化/专精/全真）、"进入练习 →"链接、搜索框、底部同步提醒条。**全部不做**——`categoryName` 之外没有可填字段。这一步是防止执行者照稿子"补齐"。

- [ ] **Step 3: ExamListPage 行结构对齐 PaperCard**

该页每行字段顺序：卷名 / `共 X 题 · Y 分钟 · 及格 Z 分` / `已考 x/y 次` / 等级胶囊 / 成绩角标。

等级胶囊逐字写成（与 Task 5 Step 1 同形，此处自带完整代码，不依赖阅读顺序）：

```ts
Text(paper.levelName)
  .fontSize(CommonConstants.FONT_LABEL_SM)
  .fontWeight(CommonConstants.WEIGHT_MEDIUM)
  .fontColor(CommonConstants.COLOR_PRIMARY)
  .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
  .borderRadius(CommonConstants.RADIUS_TAG)
  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
  .height(24)
```

成绩角标逐字写成：

```ts
Text(paper.bestScore > 0 ? `最好 ${paper.bestScore} 分` : '未考')
  .fontSize(CommonConstants.FONT_LABEL_SM)
  .fontWeight(CommonConstants.WEIGHT_MEDIUM)
  .fontColor(paper.bestScore > 0 ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_HINT)
  .backgroundColor(paper.bestScore > 0 ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_SUBTLE_BG)
  .borderRadius(CommonConstants.RADIUS_TAG)
  .height(24)
  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
  .margin({ top: 6 })
```

`已考 x/y 次` 用 `FONT_BODY_SM` + `COLOR_TEXT_SUB`。空态「该科目暂无考卷」`FONT_BODY_MD` + `COLOR_TEXT_HINT`。

- [ ] **Step 4: 不加筛选器与排序**

DESIGN.md F04 的状态胶囊筛选器（全部/未考/已及格）与"综合排序"按钮**不做**。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#FFFFFF'" entry/src/main/ets/features/exam/view/ExamSubjectView.ets entry/src/main/ets/features/exam/view/components/ExamSubjectCard.ets entry/src/main/ets/features/exam/view/ExamListPage.ets`
Expected: 三个文件都 `0`

- [ ] **Step 6: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

- [ ] **Step 7: Commit**

```bash
git add entry/src/main/ets/features/exam/view/ExamSubjectView.ets entry/src/main/ets/features/exam/view/components/ExamSubjectCard.ets entry/src/main/ets/features/exam/view/ExamListPage.ets
git commit -m "style: 刷题域（科目网格与考卷列表）对齐方案A"
```

---

### Task 7: 答题页

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/ExamDetailPage.ets:101-148`（答题卡 Builder）、`:168-274`（顶部/中部）、`:338-354`（提交按钮）

**Interfaces:**
- Consumes: Task 1 全部令牌、Task 3 `vm.answeredCount()`
- Produces: 答题卡抽屉结构（Task 8 在此基础上补底部按钮行）

- [ ] **Step 1: 提交按钮去渐变**

第 338-348 行的 `.linearGradient({...})` 整块删除，替换为：

```ts
.height(CommonConstants.BTN_HEIGHT)
.borderRadius(CommonConstants.RADIUS_BUTTON)
.fontSize(CommonConstants.FONT_BODY_LG)
.fontWeight(CommonConstants.WEIGHT_MEDIUM)
.fontColor(CommonConstants.COLOR_CARD_BG)
.backgroundColor(CommonConstants.COLOR_PRIMARY)
.stateStyles({ pressed: { backgroundColor: CommonConstants.COLOR_PRIMARY_PRESSED } })
```

这是本计划视觉变化最大的一处，spec §6.1 已拍板。

- [ ] **Step 2: 顶部/中部卡片令牌化**

两处 `Column` 的 `.backgroundColor(Color.White)` → `CommonConstants.COLOR_CARD_BG`，`.borderRadius(8)` → `CommonConstants.RADIUS_CARD`，各追加 `.shadow(CommonConstants.SHADOW_CARD)`。中部与顶部的 `margin({top: SPACE_M})` → `SPACE_CARD_GAP`。

- [ ] **Step 3: 题型标签改胶囊**

第 213-217 行改为与 Task 5 Step 1 同构的浅蓝底全圆胶囊（`COLOR_PRIMARY_BG` 底 + `COLOR_PRIMARY` 字 + `RADIUS_TAG`）。

- [ ] **Step 4: 选项行加选中态描边**

第 231-259 行的选项 `Row` 追加：

```ts
.padding({ left: 12, right: 12, top: 10, bottom: 10 })
.borderRadius(CommonConstants.RADIUS_INPUT)
.backgroundColor(this.isOptionActive(option) ? CommonConstants.COLOR_PRIMARY_BG : CommonConstants.COLOR_CARD_BG)
.border({
  width: 1,
  color: this.isOptionActive(option) ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_BORDER_HAIRLINE
})
```

并在类内新增判定方法（多选取 `checkboxSelected`、单选取 `radioSelected`，与 VM 现有存储一致）：

```ts
  // 选项行是否处于选中态：多选取 checkboxSelected、单选/判断取 radioSelected。
  // 判据住在 view 是因为它只为高亮服务，不参与提交数据（提交流转在 VM）。
  private isOptionActive(option: OptionItem): boolean {
    const q: QuestionItem = this.vm.getCurrentQuestion()
    return q.type === 'MULTI' ? this.vm.checkboxSelected.has(option.label) : this.vm.radioSelected === option.label
  }
```

- [ ] **Step 5: 存疑按钮与答题卡按钮令牌化**

第 310 行 `'#FFF3E0'` → `CommonConstants.COLOR_WARN_BG`。第 321-323 行答题卡按钮 `Color.White` → `COLOR_CARD_BG`、描边 `COLOR_TEXT_HINT` → `COLOR_BORDER_HAIRLINE`。上一题/下一题按钮 `backgroundColor(COLOR_TEXT_HINT)` → `COLOR_SUBTLE_BG`，`fontColor(Color.White)` → `COLOR_TEXT_MAIN`。

- [ ] **Step 6: 切屏提醒改为常驻告警条**

现状是 Toast（`showBackgroundHint()`）。DESIGN.md F05 要求常驻条。在顶部卡片**之上**插入，仅在场次进行中且计数 > 0 时出现：

```ts
if (this.monitor.monitoring && this.monitor.count > 0) {
  Row({ space: 8 }) {
    Text('检测到切出应用，已记录 ' + this.monitor.count + ' 次，请专心作答')
      .fontSize(CommonConstants.FONT_BODY_SM)
      .fontColor(CommonConstants.COLOR_ERROR)
      .layoutWeight(1)
  }
  .width('100%')
  .padding({ left: 12, right: 12, top: 10, bottom: 10 })
  .borderRadius(CommonConstants.RADIUS_INPUT)
  .backgroundColor(CommonConstants.COLOR_ERROR_BG)
  .margin({ bottom: CommonConstants.SPACE_CARD_GAP })
}
```

**Toast 保留不删**：告警条只在页面内可见，回前台那一刻用户可能正看着别处，Toast 负责"及时告知"，条负责"持续留痕"。`hintPending` 机制不动。

- [ ] **Step 7: 答题卡格子态换 tint 底**

第 116-143 行的格子链改为（`'#EEEEEE'` 清零）：

```ts
Text(`${index + 1}`)
  .fontSize(CommonConstants.FONT_BODY_MD)
  .fontColor(this.vm.isQuestionAnswered(q.id) && !this.vm.isQuestionFlagged(q.id)
    ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_TEXT_MAIN)
  .width(40)
  .height(40)
  .textAlign(TextAlign.Center)
  .backgroundColor(
    this.vm.isQuestionFlagged(q.id) ? CommonConstants.COLOR_WARN_BG
      : (this.vm.isQuestionAnswered(q.id) ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_SUBTLE_BG))
  .borderRadius(CommonConstants.RADIUS_BUTTON)
  .border({
    width: index === this.vm.currentIndex ? 2 : 0.5,
    color: index === this.vm.currentIndex ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_BORDER_HAIRLINE
  })
```

图例文案改为 `已答 · 存疑 · 当前题 · 点击跳转`（去掉"绿色/橙色/蓝框"三个颜色词——换 tint 底后色名与观感不再一一对应）。

- [ ] **Step 8: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#EEEEEE'\|'#FFF3E0'" entry/src/main/ets/features/exam/view/ExamDetailPage.ets`
Expected: `0`

- [ ] **Step 9: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

- [ ] **Step 10: Commit**

```bash
git add entry/src/main/ets/features/exam/view/ExamDetailPage.ets
git commit -m "style: 答题页对齐方案A（去渐变、选项选中态、常驻切屏告警条）"
```

---

### Task 8: 答题卡抽屉底部按钮行

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/ExamDetailPage.ets:101-148`（`AnswerCardSheet` Builder）

**Interfaces:**
- Consumes: Task 3 `vm.answeredCount()`、`vm.getRemainingText()`、`vm.questions.length`
- Produces: 无

- [ ] **Step 1: 抽屉加手柄条与标题行**

`AnswerCardSheet` 顶部 `Column` 前插入手柄条，标题行改为左标题右关闭：

```ts
Column() {
  Column()
    .width(36).height(4).borderRadius(2)
    .backgroundColor(CommonConstants.COLOR_BORDER_HAIRLINE)
    .margin({ bottom: CommonConstants.SPACE_COMPACT })
}
.width('100%').alignItems(HorizontalAlign.Center)
```

- [ ] **Step 2: 底部状态汇总行 + 双按钮**

在 `Grid` 之后、`Column` 结束之前追加（这是 DESIGN.md F06 要求的、当前工程完全没有的一块）：

```ts
Row() {
  Text('已答 ' + this.vm.answeredCount() + ' / ' + this.vm.questions.length)
    .fontSize(CommonConstants.FONT_BODY_SM)
    .fontColor(CommonConstants.COLOR_TEXT_SUB)
  Blank()
  Text('剩余 ' + this.vm.getRemainingText())
    .fontSize(CommonConstants.FONT_BODY_SM)
    .fontColor(CommonConstants.COLOR_WARN)
    .fontWeight(CommonConstants.WEIGHT_MEDIUM)
}
.width('100%')

Row({ space: CommonConstants.SPACE_M }) {
  Button('继续作答')
    .type(ButtonType.Normal)
    .layoutWeight(2)
    .height(CommonConstants.BTN_HEIGHT)
    .borderRadius(CommonConstants.RADIUS_BUTTON)
    .fontSize(CommonConstants.FONT_BODY_LG)
    .fontColor(CommonConstants.COLOR_TEXT_MAIN)
    .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
    .onClick(() => {
      this.showAnswerCard = false
    })

  Button('提交试卷')
    .type(ButtonType.Normal)
    .layoutWeight(3)
    .height(CommonConstants.BTN_HEIGHT)
    .borderRadius(CommonConstants.RADIUS_BUTTON)
    .fontSize(CommonConstants.FONT_BODY_LG)
    .fontWeight(CommonConstants.WEIGHT_MEDIUM)
    .fontColor(CommonConstants.COLOR_CARD_BG)
    .backgroundColor(CommonConstants.COLOR_PRIMARY)
    .onClick(() => {
      this.showAnswerCard = false
      this.vm.submit('MANUAL')
    })
}
.width('100%')
```

`layoutWeight(2)` / `(3)` 即 DESIGN.md 的 40% / 60%。提交走 `vm.submit('MANUAL')`，与页内主按钮同一个出口，跳转仍由 `@Monitor('vm.finishedAttemptId')` 单点负责——**不要在按钮里直接 push/replace**。

- [ ] **Step 3: 抽屉高度与圆角**

`bindSheet` 的 `height: 440` 改为 `height: 520`（多出一行汇总 + 一行按钮），追加 `radius: { topLeft: CommonConstants.RADIUS_CARD, topRight: CommonConstants.RADIUS_CARD }`、`backgroundColor: CommonConstants.COLOR_CARD_BG`、`maskColor: CommonConstants.COLOR_OVERLAY`、`detents: [520, 300]`。`showClose: true` 保持。

- [ ] **Step 4: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/features/exam/view/ExamDetailPage.ets
git commit -m "feat: 答题卡抽屉补进度汇总与继续作答/提交试卷双按钮"
```

---

### Task 9: 答题结果页

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/AnswerResultPage.ets`

**Interfaces:**
- Consumes: Task 1 令牌
- Produces: 无

- [ ] **Step 1: 大分值改主色 + 弱化单位**

现有 48 号数字 + 小号"分"。改为：

```ts
Text() {
  Span(`${this.vm.result.score}`)
    .fontSize(this.font.sizeOf(CommonConstants.FONT_DISPLAY_SCORE_MOBILE))
    .fontWeight(CommonConstants.WEIGHT_BOLD)
    .fontColor(this.vm.result.passed ? CommonConstants.COLOR_PRIMARY : CommonConstants.COLOR_ERROR)
  Span(' 分')
    .fontSize(this.font.sizeOf(CommonConstants.FONT_CAPTION_UNIT))
    .fontWeight(CommonConstants.WEIGHT_REGULAR)
    .fontColor(CommonConstants.COLOR_TEXT_SUB)
}
```

取值路径是 `this.vm.result.passed`（布尔）。**不要写成 `isPassed === 1`**——`isPassed` 的 `1`/`0` 数字口径是后端接口线上字段（AGENTS.md 硬约束），客户端 `ExamResult` 模型已转成 `passed: boolean`（`common/src/main/ets/model/QuestionModel.ets:50`），view 层拿到的就是布尔。

本文件当前**没有** `@Local font: FontSetting`，用 `sizeOf` 需先按 Task 11 Step 3 的方式 connect；见「未决项」第 5 条——字号设置目前只作用于答题页与我的两页，本任务不擅自扩大覆盖范围，若维持现状则把上面两处 `this.font.sizeOf(x)` 直接写成 `x`。

- [ ] **Step 2: 通过/未通过改胶囊**

描边胶囊 → `COLOR_SUCCESS_BG`/`COLOR_ERROR_BG` 底 + `COLOR_SUCCESS`/`COLOR_ERROR` 字 + `RADIUS_TAG` + `height 28` + `padding {left:10,right:10,top:4,bottom:4}`。

- [ ] **Step 3: 迷你分布图换 tint 色**

答对 `COLOR_SUCCESS_BG`、答错 `COLOR_ERROR_BG`、未答 `COLOR_SUBTLE_BG`，格子圆角 `RADIUS_BUTTON`，0.5 发丝边框。

- [ ] **Step 4: 底部双按钮 + 去渐变**

「查看回顾」= 白底主色描边（`COLOR_CARD_BG` + `border 1 COLOR_PRIMARY` + `COLOR_PRIMARY` 字）；「重新刷题」= 实心主色。两者均 `BTN_HEIGHT` + `RADIUS_BUTTON`，各 `layoutWeight(1)`。`.linearGradient` 整块删除（本文件最后一处渐变）。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#E8F5E9'" entry/src/main/ets/features/exam/view/AnswerResultPage.ets`
Expected: `0`

- [ ] **Step 6: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

```bash
git add entry/src/main/ets/features/exam/view/AnswerResultPage.ets
git commit -m "style: 答题结果页对齐方案A（主色大分值 + 胶囊徽章 + 去渐变）"
```

---

### Task 10: 逐题回顾

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/ReviewPage.ets`
- Modify: `entry/src/main/ets/features/exam/view/ReviewQuestionCard.ets`

**Interfaces:**
- Consumes: Task 1 令牌
- Produces: 无

- [ ] **Step 1: ReviewQuestionCard 五处硬编码清零**

这是全工程硬编码最集中的文件。逐处替换：

| 现值 | 改为 |
|---|---|
| `'#E8F5E9'`（正确项底） | `CommonConstants.COLOR_SUCCESS_BG` |
| `'#FFF3E0'`（我的错选底） | `CommonConstants.COLOR_WARN_BG` |
| `'#F5F5F5'`（解析盒） | `CommonConstants.COLOR_SUBTLE_BG` |
| `'#E0E0E0'`（描边） | `CommonConstants.COLOR_BORDER_HAIRLINE` |
| `'#FFFFFF'` / `Color.White` | `CommonConstants.COLOR_CARD_BG` |

- [ ] **Step 2: 左侧状态轨换语义色**

4vp 色条保留宽度，颜色 `#4CAF50`/`#F44336` 类旧值 → `COLOR_SUCCESS` / `COLOR_ERROR`。卡片圆角 `RADIUS_CARD`，追加 `SHADOW_CARD`。

- [ ] **Step 3: 卡头与答案对照行字阶**

`第 N 题` + 题型标签 + `x / y 分` 用 `FONT_LABEL_MD`；题干 `FONT_BODY_LG` + `LINE_BODY_LG`；`我的答案 A`（`COLOR_WARN`）/ `正确答案 B`（`COLOR_SUCCESS`）用 `FONT_BODY_MD`；解析正文 `FONT_BODY_MD` + `COLOR_TEXT_SUB`。

- [ ] **Step 4: ReviewPage 摘要卡与开关行**

摘要卡得分用 `FONT_DISPLAY_SCORE_MOBILE` + `COLOR_PRIMARY`；`/ 100 分` 与 `答对 x / y` 用 `FONT_CAPTION_UNIT` + `COLOR_TEXT_SUB`。「只看错题」行 `Switch` 保留，行高 52 → `BTN_HEIGHT`（48），文字 `FONT_BODY_LG`。`Color.White` 两处清零。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#E8F5E9'\|'#FFF3E0'\|'#F5F5F5'\|'#E0E0E0'\|'#FFFFFF'" entry/src/main/ets/features/exam/view/ReviewQuestionCard.ets entry/src/main/ets/features/exam/view/ReviewPage.ets`
Expected: 两个文件都 `0`

- [ ] **Step 6: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

```bash
git add entry/src/main/ets/features/exam/view/ReviewQuestionCard.ets entry/src/main/ets/features/exam/view/ReviewPage.ets
git commit -m "style: 逐题回顾对齐方案A（状态轨 + tint 选项底 + 令牌化解析盒）"
```

---

### Task 11: 我的

**Files:**
- Modify: `entry/src/main/ets/features/mine/view/MineView.ets`
- Modify: `entry/src/main/ets/features/mine/view/components/SettingItem.ets`

**Interfaces:**
- Consumes: Task 1 令牌、Task 2 的新 `FONT_LEVELS`
- Produces: 无

- [ ] **Step 1: 分组菜单卡改内嵌发丝分割线**

DESIGN.md 要求组内用内嵌细线而不是间距分隔。`SettingItem` 追加底边：

```ts
.border({ width: { bottom: CommonConstants.DIVIDER_WIDTH }, color: CommonConstants.COLOR_BORDER_HAIRLINE })
```

行高 52 → `BTN_HEIGHT`（48）。右侧箭头 `>` 保持文字形态，颜色 `COLOR_TEXT_HINT`。

- [ ] **Step 2: 用户卡令牌化**

头像 60 保持；用户名 `FONT_HEADLINE_SM` + `COLOR_TEXT_MAIN`；签名「这个人很懒，什么都没写」`FONT_BODY_SM` + `COLOR_TEXT_HINT`。卡面 `COLOR_CARD_BG` + `RADIUS_CARD` + `SHADOW_CARD`。**不加**认证徽章、编辑笔、学习指标栏。

- [ ] **Step 3: 字号行保持 Select 形态**

DESIGN.md F09 建议分段控制器，但现有 `Select` 已实现且 `FONT_LEVELS` 单源驱动。**不换控件**，只把行尾当前值文字改 `FONT_BODY_MD` + `COLOR_TEXT_SUB`。Task 2 改了档位偏移，这里要确认 Select 选项文案仍是极小/小/标准/大/极大（由 `FONT_LEVELS` 推导，无需改动）。

- [ ] **Step 4: 退出登录按钮**

白底红字 → `COLOR_CARD_BG` + `COLOR_ERROR` 字 + `RADIUS_BUTTON` + `BTN_HEIGHT`，宽度 80% 保持。三处 `Color.White` 清零。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White" entry/src/main/ets/features/mine/view/MineView.ets`
Expected: `0`

- [ ] **Step 6: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

```bash
git add entry/src/main/ets/features/mine
git commit -m "style: 我的页对齐方案A（发丝分割线 + 令牌化行高）"
```

---

### Task 12: 考试记录与我的证书

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/AttemptHistoryPage.ets`
- Modify: `entry/src/main/ets/features/exam/view/CertificatePage.ets`

**Interfaces:**
- Consumes: Task 1 令牌、Task 5 的胶囊写法
- Produces: 无

- [ ] **Step 1: 考试记录行**

卷名 `FONT_HEADLINE_SM` + `COLOR_TEXT_MAIN`；时间 `FONT_BODY_SM` + `COLOR_TEXT_HINT`；`手动交卷 · 用时 X 分 Y 秒` 同色；得分 `FONT_HEADLINE_MD` + `COLOR_TEXT_MAIN`。分页哨兵「加载更多…」`FONT_BODY_SM` + `COLOR_TEXT_HINT`。**不加**汇总对比卡。

通过/未通过胶囊逐字写成（沿用该文件现有的 `record.passed`，不要改成 `isPassed`）：

```ts
Text(record.passed ? '通过' : '未通过')
  .fontSize(CommonConstants.FONT_LABEL_SM)
  .fontWeight(CommonConstants.WEIGHT_MEDIUM)
  .fontColor(record.passed ? CommonConstants.COLOR_SUCCESS : CommonConstants.COLOR_ERROR)
  .backgroundColor(record.passed ? CommonConstants.COLOR_SUCCESS_BG : CommonConstants.COLOR_ERROR_BG)
  .borderRadius(CommonConstants.RADIUS_TAG)
  .height(24)
  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
```

**口径说明（别改错）**：后端接口线上的是 `isPassed`，数字 `1`/`0`（AGENTS.md 硬约束）；但客户端模型在 Service 层已归一化成布尔 `passed`（`AttemptHistoryPage.ets:123`、`AnswerResultPage.ets:39` 都是 `record.passed` / `result.passed`）。view 层一律用布尔，`=== 1` 只出现在 Service 的字段转换处。本任务不碰转换层。

- [ ] **Step 1b: 状态三态令牌化（spec §4 F12）**

F12 不是一屏，是三种跨页状态。逐处按下面三条链改，改完 grep 确认这三个文件的旧色值归零：

未通过结果块（`AnswerResultPage.ets` 已有分支，确认用 tint 底）：

```ts
.fontColor(CommonConstants.COLOR_ERROR)
.backgroundColor(CommonConstants.COLOR_ERROR_BG)
.borderRadius(CommonConstants.RADIUS_CARD)
```

空态块（`ExamListPage.ets` / `CertificatePage.ets`）：

```ts
Column({ space: CommonConstants.SPACE_COMPACT }) {
  Text('该科目暂无考卷')
    .fontSize(CommonConstants.FONT_BODY_LG)
    .fontWeight(CommonConstants.WEIGHT_MEDIUM)
    .fontColor(CommonConstants.COLOR_TEXT_MAIN)
  Text('通过考试即可获得证书')
    .fontSize(CommonConstants.FONT_BODY_SM)
    .fontColor(CommonConstants.COLOR_TEXT_HINT)
}
.width('100%')
.padding(CommonConstants.SPACE_L)
.borderRadius(CommonConstants.RADIUS_CARD)
.backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
```

会话失效块（各页错误态里 `AuthExpiredError` 分流出的「重新登录」按钮 + 文案）：

```ts
Text('登录已过期，请重新登录')
  .fontSize(CommonConstants.FONT_BODY_MD)
  .fontColor(CommonConstants.COLOR_ERROR)
Button('重新登录')
  .height(CommonConstants.BTN_HEIGHT_SECONDARY)
  .borderRadius(CommonConstants.RADIUS_BUTTON)
  .fontSize(CommonConstants.FONT_LABEL_MD)
  .fontColor(CommonConstants.COLOR_PRIMARY)
  .backgroundColor(CommonConstants.COLOR_PRIMARY_BG)
```

三态的**触发逻辑**（`AuthExpiredError` 分流、空数据判定）在 `427029c` 已入库，本步只改呈现，不碰 VM 分支。

- [ ] **Step 2: 证书卡**

证书名 `FONT_HEADLINE_SM`；状态胶囊 有效=`COLOR_SUCCESS`/`COLOR_SUCCESS_BG`、已过期=`COLOR_TEXT_HINT`/`COLOR_SUBTLE_BG`；编号与两个日期用 `Grid`/`Row` 两列网格排布，标签 `FONT_CAPTION_UNIT` + `COLOR_TEXT_HINT`、值 `FONT_BODY_MD` + `COLOR_TEXT_MAIN`。`status` 判等用英文枚举 `VALID`/`EXPIRED`（列表接口是英文，详情接口是中文，不可混用——AGENTS.md 硬约束）。**不加**下载按钮、重新认证、哈希防伪说明。

- [ ] **Step 3: 硬编码清零检查**

Run: `grep -c "Color\.White" entry/src/main/ets/features/exam/view/AttemptHistoryPage.ets entry/src/main/ets/features/exam/view/CertificatePage.ets`
Expected: 两个文件都 `0`

- [ ] **Step 4: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: 尾行 `Tests run: 125, Failure: 0, Error: 0, Pass: 125`

```bash
git add entry/src/main/ets/features/exam/view/AttemptHistoryPage.ets entry/src/main/ets/features/exam/view/CertificatePage.ets
git commit -m "style: 考试记录与我的证书对齐方案A"
```

---

### Task 13: 收官——清尾、目检、合并

**Files:**
- Modify: `common/src/main/ets/constants/CommonConstants.ets`（删别名与渐变）
- Modify: 目检发现问题的任意 view 文件

**Interfaces:**
- Consumes: 前 12 个任务全部完成
- Produces: 可合并的 master

- [ ] **Step 1: 确认旧别名无引用**

Run: `grep -rn "FONT_TITLE\|FONT_SUBTITLE\|FONT_BODY:\|FONT_CAPTION\|GRADIENT_START\|GRADIENT_END" entry/src common/src --include=*.ets | grep -v "CommonConstants.ets"`
Expected: 空输出。若非空，先改完那些引用再删。

- [ ] **Step 2: 删别名与渐变**

从 `CommonConstants.ets` 删除这四行旧别名和两行渐变常量及其注释块。

- [ ] **Step 3: 全工程硬编码清零门禁**

Run: `grep -rn "Color\.White\|'#FFFFFF'\|'#EEEEEE'\|'#FFF3E0'\|'#E8F5E9'\|'#F5F5F5'\|'#E0E0E0'\|'#70b8f8'\|'#416ff5'" entry/src/main/ets/features --include=*.ets`
Expected: 空输出（基线是 24 处，此处必须归零）

- [ ] **Step 4: 全量构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR` → `0`
Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Tests run: 125, Failure: 0, Error: 0, Pass: 125`（基线 121 + Task 2 的 2 + Task 3 的 2）

- [ ] **Step 5: 模拟器逐屏目检**

Run: `devecocli run --module entry --device "Pura 90"`（构建成功后 App 冷启动回登录页，坐标需重新 dump）

逐屏截图，与 `design/stitch/v2-final2/stitch_harmonyos_exam_client/_<n>/screen.png` 对比。检查清单：

| 屏 | 必看 |
|---|---|
| 登录 | 输入框静息灰底、聚焦转白 + 主色描边；按钮无渐变 |
| 首页 | 等级胶囊浅蓝底、角标 tint 底；卡片 16 圆角 + 微阴影 |
| 答题页 | 切屏告警条在场次进行中是否常驻；选项选中态描边 |
| 答题卡 | 已答 x/y 数字与实答一致；双按钮 40/60 比例；存疑格 tint 底 + 当前题描边复合态 |
| 结果页 | 大分值主色、"分"字弱化；通过胶囊 |
| 回顾 | 状态轨颜色；正确/错选 tint 底区分度 |
| 我的 | 发丝分割线可见但不抢眼 |
| 证书 | 有效/已过期两态区分度（色弱场景下不能只靠颜色） |

- [ ] **Step 6: 五档字号巡检**

在「我的 → 字号大小」依次切 极小/小/标准/大/极大，每档回答题页与回顾页看：辅助文字（11 基准）在极小档是否仍可读（应为 9fp）、极大档下题干与选项是否溢出卡片。发现问题回到对应任务修，不要在本步堆补丁。

- [ ] **Step 7: 提交并 ff 合并**

```bash
git branch --show-current
git add common/src/main/ets/constants/CommonConstants.ets
git commit -m "refactor: 换装收尾，删除过渡期字号别名与渐变常量"
git branch --show-current
git switch master
git branch --show-current
git merge --ff-only feat/ui-reskin
git branch -d feat/ui-reskin
```

`--ff-only` 报错就停下问，不要改成 `-X ours` 或 `reset --hard`。

- [ ] **Step 8: 合并态复跑**

Run: 同 Step 4
Expected: `Tests run: 125, Failure: 0, Error: 0`，且 `test_result.txt` 的 mtime 晚于本轮起跑时刻

---

## 未决项（开工前需用户确认，不阻塞 Task 1-3）

1. **AGENTS.md 未入库**：它让读者"先读 `knowledge/harmonyos-textbook/`"，而该目录已被 `.gitignore` 忽略，干净克隆下引用悬空。改一行说明还是先不入库，待定。
2. **`graph/`(11M)、`docs/emulator_audit_report.md`、`docs/verify/` 未跟踪**，按约定不动。
3. **`chapter05-end` 标签**仍指向 `9ec48d7`，本次新提交未打标签。
4. **应用图标与商店截图**仍是 `#007AFF` 蓝，与新界面 `#0A59F7` 不一致（spec §6.3）。
5. **push**：master 已 ahead 11 未推送，本计划不含推送动作。
6. **字号设置实际只覆盖两页**：全工程只有 `ExamDetailPage.ets` 与 `MineView.ets` connect 了 `FontSetting` 并调 `sizeOf()`（各 3 处 / 2 处）。首页、刷题、结果、回顾、记录、证书、登录七类页面的文字是裸 `fontSize`，拨档位对它们没反应。这是换装前就存在的缺口，不是换装引入的。本计划**不擅自扩大覆盖**（Task 9 里那段 `sizeOf` 因此标了条件注释）。要不要顺带补齐，请单独拍板——补齐会给每个 view 增加一行 `@Local font` 连接与一处偏移，属于独立改动。
