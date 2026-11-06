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
- **卡片不得贴屏边**（Task 4 审查纠正）：spec §3.4 全局约束是"页面左右边距 16"，所以内容卡必须是 `width('100%')` **且父容器带 `padding({left: SPACE_M, right: SPACE_M})`**，或者直接 `width('92%')` 居中——二者选一，不能像 Task 4 初版那样"卡 `width('100%')` + 父容器无横向 padding"，那会让 `RADIUS_CARD=16` 的圆角和 Level 1 阴影被屏边切半。卡内子元素一律转 `width('100%')`，不许再留 80% 造成"卡满宽、内容悬空"的双层留白。
- **`LINE_*` 与 `WEIGHT_*` 的采用范围（controller 统一拍板，不要逐屏各自决定）**：Task 1 定义了 12 档行高与 4 档字重，但截至 Task 4 全仓仅 1 处引用——这是计划缺口，不是实施者的问题。裁决如下：
  - `fontWeight` **每处必配**：`Bold(700)`/`Semi(600)`/`Medium(500)`/`Regular(400)` 按 §3.3 档位表取，不写裸 `FontWeight.Bold`。零布局风险。
  - `lineHeight` **只在可能换行的文字上配**：题干、选项正文、解析正文、副文案行、签名。**单行短标签、胶囊、角标、数字配单位不配**——那些地方套行高只会造成裁切或撑高。既有先例见 `ExamDetailPage.ets:224`（题干配行高，注释写明"只放大字不动行高，五档下会越挤越近"）。
  - 若某屏按此规则套完仍有元素溢出，改布局不改规则，并把现象报给 controller。
- **死令牌终检（Task 13 必跑）**：换装全部落地后，逐个统计 `CommonConstants` 里每个令牌在视图层的引用数，**引用数为 0 的必须给出结论**——要么补上它的消费点，要么从常量表删掉。留着不消费也不删的令牌，等于把"这块活没干"伪装成"设计系统很完整"。
- **单测门禁必须跑两个模块**（Task 2 实测纠正，影响所有任务）：`-p module=entry@default` **完全不执行** `common` HAR 的 `src/test`。实测证据：entry 结果文件里 18 个 describe 全是 entry 模块的（`homeViewModelTest`、`examDetailViewModelTest` 等），`FontSettingTest`/`PaperUtilsTest` 零命中；common 的用例只出现在 `common/.test/default/intermediates/test/coverage_data/test_result.txt`。
  所以只跑 entry 一条命令，`common` 侧的改动（Task 1 的 8 个令牌断言、Task 2 的 2 个字号断言）在门禁里是**隐形的**。两条都要跑：

  ```bash
  rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt common/.test/default/intermediates/test/coverage_data/test_result.txt
  DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon
  DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=common@default --no-daemon
  ```

  然后分别读两个 `test_result.txt` 的尾行，**两个数字都要写进报告**。当前基线：entry 123 / common 32（Task 1 修复后 30，Task 3 后 entry 123）。
- **别名迁移门禁（每个视图任务都要跑一次）**：`grep -rnE "CommonConstants\.FONT_(TITLE|SUBTITLE|BODY|CAPTION)\b" entry/src/main/ets` 的命中数必须**逐任务递减**，Task 13 时必须为 0。
  这条不能省：四个旧别名与新档同值（`FONT_TITLE`=`FONT_HEADLINE_LG_MOBILE`=22、`FONT_SUBTITLE`=`FONT_BODY_SM`=18、`FONT_BODY`=`FONT_BODY_LG`=`FONT_HEADLINE_SM`=16、`FONT_CAPTION`=`FONT_BODY_MD`=`FONT_LABEL_MD`=14），漏改**渲染结果一模一样**，模拟器目检抓不出来，只有这条 grep 能抓。
  ⚠️ 模式必须带词边界。写成 `FONT_BODY:` 这种形式实测只命中 53 行，词边界版命中 92 行——漏掉 39 处引用。

- **简报沉默时该不该越出简报（Task 9 审查讲清，controller 升格为计划级判据，适用 Task 10-13 全部派单）**：
  - **conform 类必做** —— 代码里已有的字面量与 spec 声明的规范值直接冲突。典型：§3.4:98 那行「卡片圆角 | 新值 16 | 现值 12」
    的"现值 12"就是在指各屏残留的裸 `borderRadius(12)`；§3.3 档位表带"字重"列，采用该档即采用其配对字重。
    不做的后果不是"少做优化"，是**代码里留着一个令牌表已宣布作废的值**（且 12 不在任何令牌里）。
  - **extend 类不做、只登记** —— 引入该屏 §4 改动行没点名的新属性。判据是 §4 逐屏行：F01 明写了「圆角 16 + Level 1 阴影」，
    F07 逐项只列大分值/胶囊/分布图，不列卡面装饰——本计划的一贯做法是把卡面装饰在逐屏行里点名，未点名即不 invoke。
    依据是立身之本"只移植设计语言、不加新区块"(spec:11) 与 §6.4 克制原则。
  - 一句话：**简报沉默 ≠ 禁止（conform 照做）；沉默且属新增装饰（extend）不做**。
    越界或不动都必须在报告里点名**决定性的文档行**，不许只写"先例如此"或"简报未提"。
- **设备门禁是可执行项，不是环境死局（Task 8 审查核盘纠正，此前我判错过一次）**：6.1.1 镜像完整在
  `D:/system-image/HarmonyOS-6.1.1/phone_all_x86/`（`system.img` 3,670,016,000 B），AVD `hardware-qemu.ini` 正指过去；
  `devecocli`/`devecocli run --device` 报"系统镜像找不到"是它按 AVD `config.ini` 的 `sdkPath=D:/DevEco Studio/sdk` +
  `imageSubPath=…` 拼了一个不存在的位置。正解：直启 `D:/DevEco Studio/tools/emulator/Emulator.exe -start "Pura 90"`。
  唯一真实约束是内存——启前必须先量 free（本机实测 1.0 GB 时不起，会拖垮并行会话），并把读数写进报告。

## 关于"测试"的说明（执行者先读这段）

这是纯视觉换装，ArkTS 的 hypium LocalUnit 跑在无 UI 环境，**断言不了布局、圆角、阴影**。所以本计划里只有三个任务带真正的单元测试（Task 1 钉令牌值、Task 2/3 是纯逻辑），其余视图任务的门禁是：

1. `devecocli build` 0 ERROR —— 唯一能逼出视图编译错的手段；
2. `hvigorw test` 尾行 `Tests run: N, Failure: 0, Error: 0`，且 N 与上一任务相同（用例数变了就是回归）；
3. **别名迁移 grep**（见 Global Constraints）—— 旧字号别名与新档同值，漏改渲染不出来，只能靠 grep；
4. 静态 grep —— 该文件的硬编码色值计数必须降到 0；
5. 模拟器目检 —— 对 `design/stitch/v2-final2/stitch_harmonyos_exam_client/_<n>/screen.png` 逐屏比。

给视图硬写"断言字号等于 16"的单测是假测试，不要写。但**令牌值本身可以且必须钉**：69 个常量改错一个十六进制位，编译照过、回归照绿，只有装机才看得出来。

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

- [ ] **Step 2: 补回四个旧字号别名（必做，不是兜底）**

Step 1 替换掉的文件**必须**在类末尾带上这四行。12 个 view 此刻仍全部引用旧名 `FONT_TITLE` / `FONT_SUBTITLE` / `FONT_BODY` / `FONT_CAPTION`；不带上的话 Step 3 的构建门禁会当场挂在 12 个文件上，看起来像"令牌层写错了"，实际是过渡期别名没留。

```ts
  // 旧字号别名：换装过渡期保留，各屏改完（Task 13 Step 2）删除
  static readonly FONT_TITLE: number = 22
  static readonly FONT_SUBTITLE: number = 18
  static readonly FONT_BODY: number = 16
  static readonly FONT_CAPTION: number = 14
```

- [ ] **Step 3: 构建验证**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，且日志尾行 `Build completed successfully`

若报 `Cannot find name 'ShadowOptions'`（`common` 是 HAR；`session/SessionManager.ets` 已证明它能 import `@kit.ArkUI`，但全局类型仍可能不解析）：**不要卡住**，把三个 `SHADOW_*` 从 `CommonConstants` 移到各 view 调用点内联书写，`radius`/`type`/`color`/`offsetX`/`offsetY` 五个字段值照抄。在报告里写明走了这条分支——后续任务的 dispatch 会带上这个决定。

- [ ] **Step 5: 用单测把令牌表钉死**

69 个常量全是 `static readonly string/number`，hypium 不渲染也能断言。不钉的后果很具体：以后谁把 `#0A59F7` 手滑改成 `#0A59F6`，编译照过、121 例照绿、只有装机才看得出来，而肉眼几乎分不出这两档蓝。

新建 `common/src/test/CommonConstants.test.ets`：

```ts
import hilog from '@ohos.hilog';
import { describe, it, expect, assertContain } from '@ohos/hypium';
import { CommonConstants } from '../main/ets/constants/CommonConstants';

export default function commonConstantsTest() {
  describe('CommonConstantsTest', () => {
    // 每个值都对着 restrained_native_precision/DESIGN.md 断言一次。
    // 这里不测"看起来对不对"，只测"有没有被人改动"——换装后 12 个屏都引用这些名字，
    // 改错一个数字不会编译失败，也不会让现有 121 例变红。
    it('primary_and_surface_colors', 0, () => {
      expect(CommonConstants.COLOR_PRIMARY).assertEqual('#0A59F7');
      expect(CommonConstants.COLOR_PRIMARY_PRESSED).assertEqual('#084ECC');
      expect(CommonConstants.COLOR_BG_PAGE).assertEqual('#F1F3F5');
      expect(CommonConstants.COLOR_CARD_BG).assertEqual('#FFFFFF');
      expect(CommonConstants.COLOR_SUBTLE_BG).assertEqual('#F2F4F6');
    });

    it('text_hierarchy_colors', 0, () => {
      expect(CommonConstants.COLOR_TEXT_MAIN).assertEqual('#182431');
      expect(CommonConstants.COLOR_TEXT_SUB).assertEqual('#525F70');
      expect(CommonConstants.COLOR_TEXT_HINT).assertEqual('#8A95A5');
      expect(CommonConstants.COLOR_TEXT_DISABLED).assertEqual('#BAC2CE');
    });

    it('semantic_colors_and_tints', 0, () => {
      expect(CommonConstants.COLOR_SUCCESS).assertEqual('#00B578');
      expect(CommonConstants.COLOR_ERROR).assertEqual('#E84026');
      expect(CommonConstants.COLOR_WARN).assertEqual('#FA6400');
      // 浅色底必须是 #AARRGGBB，alpha = round(0.08 × 255) = 20 = 0x14
      expect(CommonConstants.COLOR_SUCCESS_BG).assertEqual('#1400B578');
      expect(CommonConstants.COLOR_ERROR_BG).assertEqual('#14E84026');
      expect(CommonConstants.COLOR_WARN_BG).assertEqual('#14FA6400');
      expect(CommonConstants.COLOR_PRIMARY_BG).assertEqual('#140A59F7');
    });

    it('hairline_and_focus_borders', 0, () => {
      expect(CommonConstants.COLOR_BORDER_HAIRLINE).assertEqual('#0A000000');
      expect(CommonConstants.COLOR_BORDER_FOCUS).assertEqual('#660A59F7');
      expect(CommonConstants.COLOR_OVERLAY).assertEqual('#66182431');
    });

    it('font_scale_matches_design_md', 0, () => {
      expect(CommonConstants.FONT_DISPLAY_SCORE).assertEqual(48);
      expect(CommonConstants.FONT_DISPLAY_SCORE_MOBILE).assertEqual(36);
      expect(CommonConstants.FONT_HEADLINE_LG).assertEqual(28);
      expect(CommonConstants.FONT_HEADLINE_LG_MOBILE).assertEqual(22);
      expect(CommonConstants.FONT_HEADLINE_MD).assertEqual(20);
      expect(CommonConstants.FONT_HEADLINE_SM).assertEqual(16);
      expect(CommonConstants.FONT_BODY_LG).assertEqual(16);
      expect(CommonConstants.FONT_BODY_MD).assertEqual(14);
      expect(CommonConstants.FONT_BODY_SM).assertEqual(12);
      expect(CommonConstants.FONT_LABEL_MD).assertEqual(14);
      expect(CommonConstants.FONT_LABEL_SM).assertEqual(12);
      expect(CommonConstants.FONT_CAPTION_UNIT).assertEqual(11);
    });

    it('line_heights_pair_with_their_font_tier', 0, () => {
      // 字号与行高成对写死：只改字号不改行高，五档下会越挤越近
      expect(CommonConstants.LINE_DISPLAY_SCORE).assertEqual(56);
      expect(CommonConstants.LINE_DISPLAY_SCORE_MOBILE).assertEqual(44);
      expect(CommonConstants.LINE_HEADLINE_LG).assertEqual(36);
      expect(CommonConstants.LINE_HEADLINE_LG_MOBILE).assertEqual(30);
      expect(CommonConstants.LINE_HEADLINE_MD).assertEqual(28);
      expect(CommonConstants.LINE_HEADLINE_SM).assertEqual(24);
      expect(CommonConstants.LINE_BODY_LG).assertEqual(26);
      expect(CommonConstants.LINE_BODY_MD).assertEqual(22);
      expect(CommonConstants.LINE_BODY_SM).assertEqual(18);
      expect(CommonConstants.LINE_LABEL_MD).assertEqual(20);
      expect(CommonConstants.LINE_LABEL_SM).assertEqual(16);
      expect(CommonConstants.LINE_CAPTION_UNIT).assertEqual(14);
    });

    it('shape_and_space_scale', 0, () => {
      expect(CommonConstants.BTN_HEIGHT).assertEqual(48);
      expect(CommonConstants.BTN_HEIGHT_SECONDARY).assertEqual(36);
      expect(CommonConstants.RADIUS_CARD).assertEqual(16);
      expect(CommonConstants.RADIUS_BUTTON).assertEqual(8);
      expect(CommonConstants.RADIUS_INPUT).assertEqual(10);
      expect(CommonConstants.RADIUS_CHECKBOX).assertEqual(6);
      expect(CommonConstants.SPACE_M).assertEqual(16);
      expect(CommonConstants.SPACE_L).assertEqual(24);
      expect(CommonConstants.SPACE_CARD_GAP).assertEqual(12);
    });

    it('legacy_aliases_stay_until_task_13', 0, () => {
      // 这四个是过渡期脚手架，Task 13 删除；此处断言它们的存在本身就是防误删
      expect(CommonConstants.FONT_TITLE).assertEqual(22);
      expect(CommonConstants.FONT_SUBTITLE).assertEqual(18);
      expect(CommonConstants.FONT_BODY).assertEqual(16);
      expect(CommonConstants.FONT_CAPTION).assertEqual(14);
    });
  });
}
```

在 `common/src/test/List.test.ets` 挂号（漏挂号等于一条不跑）：

```ts
import commonConstantsTest from './CommonConstants.test';
```
并在 `testsuite()` 内调用 `commonConstantsTest();`

- [ ] **Step 6: 单测回归**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt common/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 121（本任务不动 entry）；common 尾行 Tests run: 32（24 + 本步 8 例；复审时实测 common=32，此前写的 22 是 Task 2 落地前的旧基线）

若计数仍是 121，说明 `common/src/test` 没被 entry 轮跑到——先查 `common/src/test/List.test.ets` 的挂号，别把"没跑"当成"通过"。

- [ ] **Step 7: Commit**

```bash
git add common/src/main/ets/constants/CommonConstants.ets common/src/test/CommonConstants.test.ets common/src/test/List.test.ets
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
Expected: entry 尾行 Tests run: 121（不动）；common 尾行 Tests run: 24（22 + 本步 2 例）— 实测值，Task 2 已按此落地

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

在 `entry/src/test/ExamDetailViewModel.test.ets` 的 `describe` 内追加。**必须复用该文件 `beforeEach` 里已有的 mock `service` 注入**（`new ExamDetailViewModel(service)`）——VM 默认构造是 `service: ExamService = new ExamService()`，`selectSingleOption`/`toggleMultiOption` 会经 `persistAnswer` 真发 HTTP PUT，裸 `new` 会把网络打进单测。

```ts
    // 答题卡底部要显示"已答 x / y"。计数是纯逻辑，能单测。
    it('answered_count_zero_before_any_selection', 0, () => {
      const vm = new ExamDetailViewModel(service)
      vm.questions = [{ id: 'q1', type: 'SINGLE', content: 'c', options: [], score: 10 }]
      expect(vm.answeredCount()).assertEqual(0)
    })

    // 四种题型各答一题，末断言取 4 而不是 2：
    // 冒牌实现 radioSelected!==''?1:0 + checkboxSelected.size 在本夹具下会算出 1，
    // 只期望 2 或 3 都可能被它凑过去，期望 4 才同时杀掉"按全局单选态计数"和"按 Set 大小计数"两种写法。
    it('answered_count_accumulates_across_single_multi_and_judge', 0, () => {
      const vm = new ExamDetailViewModel(service)
      vm.questions = [
        { id: 'q1', type: 'SINGLE', content: 'c', options: [oA, oB], score: 10 },
        { id: 'q2', type: 'MULTI', content: 'c', options: [oA, oB, oC], score: 10 },
        { id: 'q3', type: 'JUDGE', content: 'c', options: [oA, oB], score: 10 },
        { id: 'q4', type: 'SINGLE', content: 'c', options: [oA, oB], score: 10 }
      ]
      vm.selectSingleOption('A')            // q1
      vm.jumpTo(1)
      vm.toggleMultiOption('A', true)
      vm.toggleMultiOption('C', true)       // q2 → 'AC'
      vm.jumpTo(2)
      vm.selectSingleOption('B')            // q3
      vm.jumpTo(3)
      vm.selectSingleOption('A')            // q4
      expect(vm.answeredCount()).assertEqual(4)
    })
```

三处原稿写错、已由实施者实测纠正，此处为最终形态：
1. 题型枚举是 `SINGLE`/`MULTI`/`JUDGE`，**没有 `TRUE_FALSE`**（`QuestionModel.ets:7`）。
2. `QuestionItem.score` 是必填字段，夹具不写会编译不过。
3. **不能用 `vm.radioSelected = 'A'` / `vm.checkboxSelected = new Set(...)` 直接灌状态**——`isQuestionAnswered()` 读的是私有 `answers: Map`（`ExamDetailViewModel.ets:227-230`），那两个字段只是当前题的渲染态。原稿这样写实测得 0。必须走 `selectSingleOption` / `toggleMultiOption` / `jumpTo` 这些公开方法让答案真正落进 `answers`。

- [ ] **Step 2: 跑测试确认失败**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: `Failure` 或编译错误 `Property 'answeredCount' does not exist`——两者都算失败成立

- [ ] **Step 3: 实现 getter**

在 `ExamDetailViewModel.ets` 的 `isQuestionFlagged` 方法之后插入。计数只委托 `isQuestionAnswered`（它读 `answers` Map），**不按题型分流**——`radioSelected`/`checkboxSelected` 是当前题的渲染态，不承载"已答"语义。

```ts
  // 已答题数：答题卡底部"已答 x / y"用它。
  // 统一以 answers 表为判据（委托 isQuestionAnswered），不按题型分流——
  // radioSelected / checkboxSelected 只是"当前题"的渲染态，不承载"已答"语义；
  // 跨题累计只认 answers（见本类第 53 行"唯一事实源"）。
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

⚠️ 本步原稿的注释写反了（"单选存 radioSelected、多选存 checkboxSelected，两者判法不同"），
Task 3 审查按 `ExamDetailViewModel.ets:53` 的"唯一事实源"注释判为 materially false 并要求改正。
以上面这版为准。

- [ ] **Step 4: 跑测试确认通过**

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123（121 + 本步 2 例）；common 尾行 Tests run: 32

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

- [ ] **Step 1: 表单收进单张白卡（卡不能贴屏边）**

把 Logo 以下的表单区外层包一个 `Column`，属性固定为：

```ts
.width('100%')
.padding(CommonConstants.SPACE_M)
.borderRadius(CommonConstants.RADIUS_CARD)
.backgroundColor(CommonConstants.COLOR_CARD_BG)
.shadow(CommonConstants.SHADOW_CARD)
```

**并且**该卡的父容器必须带横向内边距，否则卡贴屏边、16 圆角与阴影被切半（Task 4 初版就栽在这里）：

```ts
.padding({ left: CommonConstants.SPACE_M, right: CommonConstants.SPACE_M })
```

卡内原本写 `width('80%')` 的子元素一律转 `width('100%')`——卡已是满宽带 16 内边距，再套 80% 会变成"卡满宽、输入框悬空"的双层留白。

- [ ] **Step 2: 输入框按令牌重排（含聚焦态）**

每个 `TextInput` 的静息链改为：

```ts
.backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
.borderRadius(CommonConstants.RADIUS_INPUT)
.border({ width: CommonConstants.DIVIDER_WIDTH, color: CommonConstants.COLOR_BORDER_HAIRLINE })
.fontSize(CommonConstants.FONT_BODY_LG)
.fontColor(CommonConstants.COLOR_TEXT_MAIN)
.placeholderColor(CommonConstants.COLOR_TEXT_DISABLED)
.placeholderFont({ size: CommonConstants.FONT_BODY_MD })
```

再加聚焦链。spec §4 F01 要求"静息灰底 → 聚焦转白 + 1.5 主色描边"，这**不是加行为**：`stateStyles` 有 `focused` 键（SDK `component/common.d.ts` 的 `StateStyles` 接口），与本页按钮已在用的 `pressed` 同一机制，零新增状态、零行为改动：

```ts
.stateStyles({
  focused: {
    .backgroundColor(CommonConstants.COLOR_CARD_BG)
    .border({ width: 1.5, color: CommonConstants.COLOR_BORDER_FOCUS })
  }
})
```

漏掉这一条，`COLOR_BORDER_FOCUS` 就是全仓零视图引用的死令牌。

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
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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

科目名 `FONT_HEADLINE_SM` + `COLOR_TEXT_MAIN`；`共 N 套` `FONT_BODY_SM` + `COLOR_TEXT_SUB`；卡面 `COLOR_CARD_BG` + `RADIUS_CARD` + `SHADOW_CARD` + 0.5 发丝边框。

Grid 的 gap 按 spec §3.4 的间距模型拆开——**横向沟 16、纵向节奏 12**，不是两个都 16：

```ts
.columnsGap(CommonConstants.SPACE_M)          // 16，横向沟
.rowsGap(CommonConstants.SPACE_CARD_GAP)      // 12，纵向节奏，与列表同轨
```

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

行间距必须与首页同轨（spec §3.4 纵向节奏 12，F04 要求行结构与 F02 统一）：

```ts
List({ space: CommonConstants.SPACE_CARD_GAP })   // 12
```

并**删掉** `ListItem` 上的 `.margin({ bottom: CommonConstants.SPACE_M })`。两处叠加会变成 28，
`HomeView.ets` 里已踩过并留了注释说明。

- [ ] **Step 4: 不加筛选器与排序**

DESIGN.md F04 的状态胶囊筛选器（全部/未考/已及格）与"综合排序"按钮**不做**。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#FFFFFF'" entry/src/main/ets/features/exam/view/ExamSubjectView.ets entry/src/main/ets/features/exam/view/components/ExamSubjectCard.ets entry/src/main/ets/features/exam/view/ExamListPage.ets`
Expected: 三个文件都 `0`

- [ ] **Step 6: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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

- [ ] **Step 7b: 中部加滚动容器（换装引入的回归，必修）**

Step 4 给选项行加了 `padding({top:10,bottom:10})` + 1vp 描边，每行 +22vp、四行 +88vp；告警条在场时再吃约 56vp。
而中部是 `layoutWeight(1)` 的 `Column`，全文件没有任何滚动能力——长题干 + 四选项在中小屏会被裁掉且无法滚。
**这是本次换装自己造成的回归**，不是存量问题，必须在本任务修。

正解是把中部卡的内容整体包进 `Scroll`（单子 `Column` 作内容体，卡壳的圆角/阴影留在外层）：

```ts
Scroll() {
  Column() {
    // 题型标签、题干、选项列表原样搬进来
  }
  .width('100%')
  .alignItems(HorizontalAlign.Start)
}
.layoutWeight(1)
.scrollBar(BarState.Auto)
.width('100%')
```

不要用"选项 `Column` 换 `List`"——那只救选项，救不了长题干和极大字号档。
也不要包页级 `Scroll`——会破坏三段式 `layoutWeight` 结构。

同时改写 `:272` 那句注释「题目最多 4 个选项，够短，没必要上 List」：它的前提已被本轮改动打破。

- [ ] **Step 7c: 补 spec 明文但简报漏写的两处元素**

两处都是"spec 要求、简报没写、目前无人认领"，与 Task 4 的聚焦态、Task 7 的滚动同类。

**① F05 纤细进度条**（顶部标题区，`currentIndex+1 / questions.length` 全在 VM，不新增数据通路）：

```ts
Row()
  .width('100%')
  .height(3)
  .borderRadius(2)
  .backgroundColor(CommonConstants.COLOR_SUBTLE_BG)
  .margin({ top: CommonConstants.SPACE_CARD_GAP })

Row()
  .width(`${Math.round((this.vm.currentIndex + 1) / this.vm.questions.length * 100)}%`)
  .height(3)
  .borderRadius(2)
  .backgroundColor(CommonConstants.COLOR_PRIMARY)
```

外层用 `Stack(Alignment.Start)` 叠放，或直接把第二条放在第一条内部——取可读的那种。

**② F06 存疑格右上实心点**（`isQuestionFlagged` 现成可用）：`GridItem` 内套 `Stack(Alignment.TopEnd)`，
数字 `Text` 保持原链，右上角叠一个点：

```ts
Text('')
  .width(8)
  .height(8)
  .borderRadius(4)
  .backgroundColor(CommonConstants.COLOR_WARN)
  .position({ x: 30, y: 2 })
```

存疑与"当前题"是**复合态**（第 7 题同时具备）：底色走 tint、描边走主色，圆点独立叠加，三者互不覆盖。

- [ ] **Step 8: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#EEEEEE'\|'#FFF3E0'" entry/src/main/ets/features/exam/view/ExamDetailPage.ets`
Expected: `0`

- [ ] **Step 9: 构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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

- [ ] **Step 0: 先把 answers 变成可追踪的（否则 x 不会跳）**

Task 3 审查确认的刷新风险，本任务必须一并解决：`ExamDetailViewModel.ets:54` 的
`private answers: Map<string, string>` **没有 `@Trace`**。ArkUI V2 的渲染依赖是在 build 期读 `@Trace` 时建立的，
而 `answeredCount()` 只读 `questions`（长度不变）和这个未追踪的 Map——抽屉里 `已答 ${vm.answeredCount()}`
因此对"答了另一道题"这件事**没有任何失效来源**，数字不会跳。

改法就一个词，与本类既有的 `@Trace checkboxSelected: Set<string>`（:51）同形态，V2 支持集合：

```ts
  // 唯一事实源：questionId → 已选答案（字母拼接，如 'AC'）
  // 必须 @Trace：答题卡抽屉的"已答 x / y"与逐格状态都靠它失效，
  //   没有 @Trace 时答完一题抽屉数字不动，且不会报错——是最难发现的一类缺陷。
  @Trace private answers: Map<string, string> = new Map<string, string>()
```

同一处改动顺带修掉一个**换装前就存在**的隐患：抽屉网格里每格调 `isQuestionAnswered(q.id)`，
读的也是这个未追踪 Map，所以格子态同样不会实时更新（此前没人发现是因为答完题抽屉就关了）。

不要选 `@Computed`：本仓库零 `@Computed` 用例，为一个计数引入新模式不值；`@Trace` 是一词改动且与邻行一致。

- [x] **Step 1: 抽屉加手柄条与标题行**（**已被 Task 8 修复轮作废**，见 ledger Ruling T8-1）

> ⚠️ 本步的手绘手柄条已在 `79751a6` **整块删除**，改吃平台默认拖拽条
> （`SheetOptions.dragBar` **`@default true`**，SDK `common.d.ts:11766-11775`；本仓 `grep dragBar` 零命中，
> 即从没关过 ⇒ 手绘那条与系统条叠成两层，且其色合成后对比度仅 1.09:1 属隐形装饰）。
> 标题行的"左标题**右关闭**"同期裁为不做：`showClose: true` 已给系统 X，同一抽屉不该有两个关闭入口。
> **下轮 conform 巡检不要把这一条当缺口报**——缺口在 spec §4 F06 行，已同步改为"平台系统拖拽条"。

原文（存档，勿实施）：

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

在 `Grid` 之后、`Column` 结束之前追加（本步要求的出处是**本简报自己**——
Task 8 审查核出 `DESIGN.md` 全文无逐屏章节、无 F06 标识、无已答计数要求，原句"DESIGN.md F06 要求的"是错引，已改；
半模态形态的真实证据在导出的第 11 屏 HTML：`fixed bottom` + `rounded-t-2xl`）：

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

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt common/.test/default/intermediates/test/coverage_data/test_result.txt`
Run: `DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Run: `DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=common@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

- [ ] **Step 4b: 刷新验收（模拟器，改口径）**

~~打开答题卡抽屉、**不关抽屉**直接答下一题，看 x 是否当场跳~~ —— 这条验收动作在原计划里就写错了，
Task 8 审查核 SDK 判出：`SheetOptions.enableOutsideInteractive` **默认 false**（`common.d.ts:11877 @default false`），
遮罩吃掉抽屉外的一切触点，抽屉开着时根本答不了题，"当场跳"这个症状在现交互里**不可能发生**。
本页的交互模型是"开抽屉 → 看 → 点继续作答关闭 → 答题"，逐题作答与抽屉互斥，不存在实时刷新需求。

上机真正要验的是另外三件（都在本交互内可执行）：
1. **关掉抽屉、答一题、再开抽屉**，`已答 x / y` 与逐格底色是不是新值。这验的是 `bindSheet` 内容
   关闭即销毁还是被复用——被复用时靠 `@Trace answers` + 整体替换失效，销毁重建时靠 build 现值，
   两条都成立才算过。SDK 声明层没有这一条，只能上机。
2. **抽屉顶部是不是只有系统一条拖拽条**（手绘条按 Ruling T8-1 删除后，验证没有双层条、也没有空白）。
3. `detents: [520, 300]` 拖到 300 档时汇总行与双按钮是否被裁。

模拟器入口按 Ruling T8-3 更正：`devecocli run --device` 会因 AVD `config.ini` 的 `sdkPath` 拼错而报"镜像找不到"，
正解是直启 `D:/DevEco Studio/tools/emulator/Emulator.exe -start "Pura 90"`（镜像完整在 `D:/system-image/`，见 spec §8.3）。
起之前先量内存（本机实测 free 仅 1.0 GB 时不起，会拖垮并行会话）。

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
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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

`第 N 题` + 题型标签 + `x / y 分` 用 **`FONT_LABEL_SM`**（12/500，见 spec §3.3 的 badging 许可条与设计源
§Application Rules 原文"Status pills, chapter identifiers, and time stamps employ `label-sm` or `caption-unit`"——
**原计划钉的 `FONT_LABEL_MD` 是计划相对设计源的错，Task 10 审查后由 Ruling T10-A 作废**；
`label-md`(14) 只留给按钮文字）；题干 `FONT_BODY_LG` + `LINE_BODY_LG`；`我的答案 A`（`COLOR_WARN`）/
`正确答案 B`（`COLOR_SUCCESS`）用 `FONT_BODY_MD`；解析正文 `FONT_BODY_MD` + `COLOR_TEXT_SUB`。

- [ ] **Step 4: ReviewPage 摘要卡与开关行**

摘要卡得分用 `FONT_DISPLAY_SCORE_MOBILE` + `COLOR_PRIMARY`；`/ 100 分` 与 `答对 x / y` 用 `FONT_CAPTION_UNIT` + `COLOR_TEXT_SUB`。「只看错题」行 `Switch` 保留，行高 52 → `BTN_HEIGHT`（48），文字 `FONT_BODY_LG`。`Color.White` 两处清零。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White\|'#E8F5E9'\|'#FFF3E0'\|'#F5F5F5'\|'#E0E0E0'\|'#FFFFFF'" entry/src/main/ets/features/exam/view/ReviewQuestionCard.ets entry/src/main/ets/features/exam/view/ReviewPage.ets`
Expected: 两个文件都 `0`

- [ ] **Step 6: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

```bash
git add entry/src/main/ets/features/exam/view/ReviewQuestionCard.ets entry/src/main/ets/features/exam/view/ReviewPage.ets
git commit -m "style: 逐题回顾对齐方案A（状态轨 + tint 选项底 + 令牌化解析盒）"
```

---

### Task 11: 我的 + 底部 Tab 条

**Files:**
- Modify: `entry/src/main/ets/features/mine/view/MineView.ets`
- Modify: `entry/src/main/ets/features/mine/view/components/SettingItem.ets`
- Modify: `entry/src/main/ets/pages/MainPage.ets`

**Interfaces:**
- Consumes: Task 1 令牌、Task 2 的新 `FONT_LEVELS`
- Produces: 无

- [ ] **Step 0: 底部 Tab 条（Task 5 实施时发现整份计划无人认领，补上）**

`MainPage.ets:36` 是全仓最后一处仍在用 `CommonConstants.FONT_BODY` 旧别名的地方，而原计划 13 个任务没有一个碰这个文件——Task 13 的别名门禁会把它逼出来，但没人定它该改成什么。`SHADOW_BOTTOM_BAR` 也因此一直是死令牌。

设计稿（导出 HTML `_6/_7/_8/_9`）的导航条是：`h-16`（64vp）+ 24px Material 图标 + `font-label-sm` 文字，选中态 `text-primary-container` + `font-semibold`，容器带 `bg-surface/90` + `backdrop-blur-xl` + `shadow-[0_-2px_12px_rgba(0,0,0,0.03)]`。

**两条裁决，按此实现，不要自行扩展：**

1. **不加图标。** 稿子的图标是 Material Symbols 字体连字（`menu_book` 等），ArkUI 没有这套字体，加图标等于引一条素材管道，而计划从未预算过图标资源。保持现状的纯文字标签。代价：与稿子有一处可见差异，终审或装机目检时若判定必须补，属新增范围另立任务。
2. **不做毛玻璃。** 导出 HTML 用了 `backdrop-blur-xl`，但 DESIGN.md 正文明令"杜绝毛玻璃模糊"（Zero Decorative Bloat 段）——**设计源自己矛盾**。以设计系统规则为准：平面 `COLOR_CARD_BG` + Level 3 阴影。这同时避开 ArkUI 模糊的渲染代价。

实现（`tabBarBuilder` 内）：

```ts
Text(title)
  .fontSize(CommonConstants.FONT_LABEL_SM)
  .fontWeight(this.currentIndex === index ? CommonConstants.WEIGHT_SEMI : CommonConstants.WEIGHT_REGULAR)
  .fontColor(this.currentIndex === index
    ? CommonConstants.COLOR_PRIMARY
    : CommonConstants.COLOR_TEXT_HINT)
```

容器：`.height(64)`（原 52，对齐稿子 `h-16`），`Tabs` 的 `barHeight(64)` 同步改；`tabBar` 背景 `CommonConstants.COLOR_CARD_BG`，并在 `MainPage` 的 `build()` 根节点上给导航条挂 `CommonConstants.SHADOW_BOTTOM_BAR`。

`fontWeight` 每处必配、`lineHeight` 不配（单行标签，配了会裁切）——同 Global Constraints 裁决。

验收：`grep -cE "CommonConstants\.FONT_(TITLE|SUBTITLE|BODY|CAPTION)\b" entry/src/main/ets/pages/MainPage.ets` → `0`；`grep -rc "CommonConstants\.SHADOW_BOTTOM_BAR" entry/src/main/ets` → 至少 1。

- [ ] **Step 1: 分组菜单卡改内嵌发丝分割线**

DESIGN.md 要求组内用内嵌细线而不是间距分隔。`SettingItem` 追加底边：

```ts
.border({ width: { bottom: CommonConstants.DIVIDER_WIDTH }, color: CommonConstants.COLOR_BORDER_HAIRLINE })
```

行高 52 → `BTN_HEIGHT`（48）。右侧箭头 `>` 保持文字形态，颜色 `COLOR_TEXT_HINT`。

- [ ] **Step 2: 用户卡令牌化**

头像 60 保持；用户名 `FONT_HEADLINE_SM` + `COLOR_TEXT_MAIN`；签名「这个人很懒，什么都没写」`FONT_BODY_SM` + `COLOR_TEXT_HINT`。卡面 `COLOR_CARD_BG` + `RADIUS_CARD` + `SHADOW_CARD`。**不加**认证徽章、编辑笔、学习指标栏。

- [ ] **Step 3: 字号行保持 Select 形态**

~~DESIGN.md F09 建议分段控制器~~ —— 出处是虚构的（本计划第四次犯同一类错，见 ledger 的"虚构逐屏出处"条目）：
`DESIGN.md` 无逐屏章节、无 F09 标识。Task 11 实测导出屏 `_7`：无 `<select>`、无 `role="tablist"`、无 `type="radio"`，
字号那一行只有一个 `shrink-0` 的「标准」span ⇒ **设计源画的就是"设置行 + 行尾当前值"，不是分段控制器**。
结论不变、理由换成实测：现有 `Select` 已实现且 `FONT_LEVELS` 单源驱动，**不换控件**，
只把行尾当前值文字改 `FONT_BODY_MD` + `COLOR_TEXT_SUB`。Task 2 改了档位偏移，这里要确认 Select 选项文案仍是极小/小/标准/大/极大（由 `FONT_LEVELS` 推导，无需改动）。

- [ ] **Step 4: 退出登录按钮**

白底红字 → `COLOR_CARD_BG` + `COLOR_ERROR` 字 + `RADIUS_BUTTON` + `BTN_HEIGHT`，宽度 80% 保持。三处 `Color.White` 清零。

- [ ] **Step 5: 硬编码清零检查**

Run: `grep -c "Color\.White" entry/src/main/ets/features/mine/view/MineView.ets`
Expected: `0`

- [ ] **Step 6: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

```bash
git add entry/src/main/ets/features/mine
git commit -m "style: 我的页对齐方案A（发丝分割线 + 令牌化行高）"
```

---

### Task 12: 考试记录与我的证书

**Files:**
- Modify: `entry/src/main/ets/features/exam/view/AttemptHistoryPage.ets`
- Modify: `entry/src/main/ets/features/exam/view/CertificatePage.ets`
- Modify: `entry/src/main/ets/features/exam/view/ExamSubjectView.ets`（Step 1b 的会话失效块要覆盖各页错误态，而 Task 6 只做了同值迁移没动形态；不列进来这个文件就会漏到终审之后）

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

- [ ] **Step 1c: 分区标题间距归一**

`ExamSubjectView.ets:107` 的页内标题「考试科目」目前 `margin({ bottom: SPACE_M })` = 16，
而同域的首页「推荐试卷」（`HomeView.ets:156`）已是 12。spec §3.4 已把"分区标题→下方内容"定死 12，
两屏不对称会被装机目检抓出来。改为：

```ts
.margin({ bottom: CommonConstants.SPACE_CARD_GAP })   // 12，与首页同轨
```

同一条还覆盖 `AnswerResultPage.ets:120` 的「答题卡」分区标题——Task 9 审查登记：它写的是
`margin({ top: SPACE_L, bottom: SPACE_M })`，其中 **bottom 16 与 §3.4 的 12 冲突**，bottom 改为
`SPACE_CARD_GAP`；`top` 是"上一区块到本标题"的容器间距，阶梯上有现成的 `SPACE_L`，保留不动。

注意 §3.4 的边界条款：这条只管**分区标题到其下方内容**，不要顺手去改胶囊 `margin({top: 6})`
或卡片内标题到副行的 `margin({top: 8})`——那些是组件内部构造，由各自简报逐字规定。

- [ ] **Step 1d: 结果页主按钮补按压态**（Task 9 审查 → Ruling T9-B）

`AnswerResultPage.ets:184` 的「重新刷题」是全 App 唯一没有按压反馈的实心主色钮——其余四颗
（登录、交卷、抽屉提交、`ExamDetailPage:248/:569`）都挂 `stateStyles.pressed` → `COLOR_PRIMARY_PRESSED`。
§3.1 那枚 token 存在的唯一用途就是它，且 Ruling T4-D 已裁过"stateStyles 是声明式样式不是行为"。
补两行，与页内既有那颗同写法：

```ts
            .stateStyles({ pressed: { .backgroundColor(CommonConstants.COLOR_PRIMARY_PRESSED) } })
```

同屏**不做**的两条（Ruling T9-C/T9-D，已裁，勿再翻）：白卡不加 hairline + Level 1 阴影（extend 类，
§4 F07 行未点名，§6.4 取克制读法，张力已交终审）；分布图网格 gap 双轴 8 豁免两轴模型（与
`AnswerResultViewModel:124-127` 高度公式同源且被单测钉死）。

- [ ] **Step 2: 证书卡**

证书名 `FONT_HEADLINE_SM`；状态胶囊 有效=`COLOR_SUCCESS`/`COLOR_SUCCESS_BG`、已过期=`COLOR_TEXT_HINT`/`COLOR_SUBTLE_BG`；编号与两个日期用 `Grid`/`Row` 两列网格排布，标签 `FONT_CAPTION_UNIT` + `COLOR_TEXT_HINT`、值 `FONT_BODY_MD` + `COLOR_TEXT_MAIN`。`status` 判等用英文枚举 `VALID`/`EXPIRED`（列表接口是英文，详情接口是中文，不可混用——AGENTS.md 硬约束）。**不加**下载按钮、重新认证、哈希防伪说明。

- [ ] **Step 3: 硬编码清零检查**

Run: `grep -c "Color\.White" entry/src/main/ets/features/exam/view/AttemptHistoryPage.ets entry/src/main/ets/features/exam/view/CertificatePage.ets`
Expected: 两个文件都 `0`

- [ ] **Step 4: 构建 + 单测 + Commit**

Run: `devecocli build 2>&1 | grep -c ERROR`
Expected: `0`，日志尾行 `Build completed successfully`

Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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

- [ ] **Step 1: 确认旧别名与渐变已无引用**

Run: `grep -rnE "CommonConstants\.(FONT_(TITLE|SUBTITLE|BODY|CAPTION)|GRADIENT_(START|END))\b" entry/src common/src --include=*.ets | grep -v "constants/CommonConstants.ets" | grep -v "test/CommonConstants.test.ets"`
Expected: 空输出。

注意两条：
- 模式必须带词边界 `\b`。`grep "FONT_BODY:"` 这种写法实测只命中 53 行、词边界版命中 92 行，会漏掉 39 处引用。
- Task 1 新增的 `CommonConstants.test.ets` 里有一组 `legacy_aliases_stay_until_task_13` 断言，是**故意**引用这四个别名的；本步删除别名时必须连同那个 `it()` 一起删，否则编译不过。

若仍有其它引用，先改完那些文件再删别名，不要跳过。

- [ ] **Step 2: 删别名与渐变**

从 `CommonConstants.ets` 删除这四行旧别名和两行渐变常量及其注释块。

- [ ] **Step 3: 全工程硬编码清零门禁**

Run: `grep -rn "Color\.White\|'#FFFFFF'\|'#EEEEEE'\|'#FFF3E0'\|'#E8F5E9'\|'#F5F5F5'\|'#E0E0E0'\|'#70b8f8'\|'#416ff5'" entry/src/main/ets/features --include=*.ets`
Expected: 空输出（基线是 24 处，此处必须归零）

- [ ] **Step 3b: 死令牌清点**

逐个统计 `CommonConstants` 每个令牌在视图层的引用数，引用为 0 的必须给出结论——补消费点，或从常量表删掉：

```bash
grep -oE "static readonly [A-Z_0-9]+" common/src/main/ets/constants/CommonConstants.ets \
  | sed 's/static readonly //' | while read t; do
  n=$(grep -rlo "CommonConstants\.$t\b" entry/src/main/ets common/src/main/ets --include=*.ets 2>/dev/null | wc -l)
  [ "$n" -eq 0 ] && echo "UNUSED $t"
done
```

Expected: 空输出。非空则逐个处置，并把处置结果写进报告。

判据的理由：Task 4 审查发现 `COLOR_BORDER_FOCUS` 只在定义和 Task 1 的断言里出现、没有任何视图引用，
顺藤摸出"spec 要求的聚焦态整条没做"。一个不被消费的令牌往往就是漏掉的那块活——
留着它不删也不接，等于把"没干完"伪装成"设计系统很完整"。

注意 `LINE_*`/`WEIGHT_*` 按 Global Constraints 的采用范围裁决：`fontWeight` 每处必配，
`lineHeight` 只配可能换行的文字。所以这两族允许有合理数量的零引用（单行标签档），
但每个零引用都要在报告里点名说明为什么合理，不许笼统带过。

- [ ] **Step 4: 全量构建 + 单测**

Run: `devecocli build 2>&1 | grep -c ERROR` → `0`
Run: `rm -f entry/.test/default/intermediates/test/coverage_data/test_result.txt && DEVECO_SDK_HOME="D:/DevEco Studio/sdk" node "D:/DevEco Studio/tools/hvigor/bin/hvigorw.js" test --mode module -p module=entry@default --no-daemon`
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

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
Expected: entry 尾行 Tests run: 123；common 尾行 Tests run: 32（两个模块都要报）

---

## 未决项（开工前需用户确认，不阻塞 Task 1-3）

1. **AGENTS.md 未入库**：它让读者"先读 `knowledge/harmonyos-textbook/`"，而该目录已被 `.gitignore` 忽略，干净克隆下引用悬空。改一行说明还是先不入库，待定。
2. **`graph/`(11M)、`docs/emulator_audit_report.md`、`docs/verify/` 未跟踪**，按约定不动。
3. **`chapter05-end` 标签**仍指向 `9ec48d7`，本次新提交未打标签。
4. **应用图标与商店截图**仍是 `#007AFF` 蓝，与新界面 `#0A59F7` 不一致（spec §6.3）。
5. **push**：master 已 ahead 11 未推送，本计划不含推送动作。
6. **字号设置实际只覆盖两页**：全工程只有 `ExamDetailPage.ets` 与 `MineView.ets` connect 了 `FontSetting` 并调 `sizeOf()`（各 3 处 / 2 处）。首页、刷题、结果、回顾、记录、证书、登录七类页面的文字是裸 `fontSize`，拨档位对它们没反应。这是换装前就存在的缺口，不是换装引入的。本计划**不擅自扩大覆盖**（Task 9 里那段 `sizeOf` 因此标了条件注释）。要不要顺带补齐，请单独拍板——补齐会给每个 view 增加一行 `@Local font` 连接与一处偏移，属于独立改动。
