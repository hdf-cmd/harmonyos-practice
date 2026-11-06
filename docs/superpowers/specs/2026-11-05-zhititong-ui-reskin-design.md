# 智题通 UI 换装：方案A「鸿蒙原生克制风」移植设计

日期：2026-11-05
状态：待评审
关联：`design/stitch/v2-final2/`（12 屏 HTML + PNG + DESIGN.md）、`design/figma/内容规格.md`

## 1. 目标与范围边界

把 Stitch 方案A 的设计语言落到真实 ArkTS 工程，让 12 个页面在**配色、字阶、圆角、间距、阴影、卡片内部结构**上与稿子一致。

明确**不做**（上一轮已拍板"只移植设计语言，不加新区块"）：

- 不加稿子里出现但后端没有的区块：统计指标卡、搜索框、筛选器、排序、下载 PDF、认证徽章、哈希防伪话术、版本号
- 不做暗色模式适配（现状本来也没有，`entry/src/main/resources/dark/` 只有一个启动窗背景色）
- 不换应用图标与启动页
- 不把令牌迁到 `resources/base/element/color.json`

理由：`$r()` 返回 `Resource` 不是 `string`，迁移会连带改掉 12 个 view 的所有 `.fontColor()` 调用签名和颜色断言类单测。那是独立的重构，不该塞进换装。

## 2. 权威设计源

`design/stitch/v2-final2/stitch_harmonyos_exam_client/restrained_native_precision/DESIGN.md`。

⚠️ `design/stitch/方案A-设计规范.md`（从 Stitch 聊天里扒的那份）**色值不可用**，两者不一致：

| | 聊天版（作废） | DESIGN.md（权威） |
|---|---|---|
| 主文本 | `#111827` | `#182431` |
| 成功色 | `#059669` | `#00B578` |
| 按钮圆角 | 12 | 8 |

DESIGN.md 的 `#00B578 / #FA6400 / #E84026` 正好是 HarmonyOS 官方语义色，可信度更高，以它为准。

## 3. 令牌层方案

沿用现有模式：扩 `common/src/main/ets/constants/CommonConstants.ets`，不引入新层。view 层已有 14 个文件引用它，只有 10 处硬编码色值需要一并收编。

### 3.1 色彩（改值）

| 现有常量 | 现值 | 新值 | 备注 |
|---|---|---|---|
| `COLOR_PRIMARY` | `#007AFF` | `#0A59F7` | 按下态另加 `COLOR_PRIMARY_PRESSED = #084ECC` |
| `COLOR_TEXT_MAIN` | `#333333` | `#182431` | |
| `COLOR_TEXT_SUB` | `#666666` | `#525F70` | |
| `COLOR_TEXT_HINT` | `#999999` | `#8A95A5` | |
| `COLOR_BG_PAGE` | `#F5F6FA` | `#F1F3F5` | |
| `COLOR_SUCCESS` | `#4CAF50` | `#00B578` | |
| `COLOR_ERROR` | `#F44336` | `#E84026` | |
| `COLOR_WARN` | `#FF6600` | `#FA6400` | |
| `GRADIENT_START/END` | `#70b8f8/#416ff5` | **删除** | 见 §6.1 |

### 3.2 色彩（新增）

DESIGN.md 的浅色底用 CSS `rgba()` 写。ArkUI 侧统一转成 `#AARRGGBB`（alpha 在最前），因为部分属性不吃 `rgba()` 字符串。换算 `alpha = round(a × 255)` 取十六进制：

| 新常量 | DESIGN.md 原值 | ArkTS 用值 | 用途 |
|---|---|---|---|
| `COLOR_CARD_BG` | `#FFFFFF` | `#FFFFFF` | 卡面 |
| `COLOR_TEXT_DISABLED` | `#BAC2CE` | `#BAC2CE` | 占位符、禁用 |
| `COLOR_PRIMARY_BG` | `rgba(10,89,247,.08)` | `#140A59F7` | 选中态底、次级按钮底 |
| `COLOR_SUCCESS_BG` | `rgba(0,181,120,.08)` | `#1400B578` | 答对选项、已答网格 |
| `COLOR_ERROR_BG` | `rgba(232,64,38,.08)` | `#14E84026` | 错选选项、未通过徽章 |
| `COLOR_WARN_BG` | `rgba(250,100,0,.08)` | `#14FA6400` | 存疑态底 |
| `COLOR_SUBTLE_BG` | `surface-container-low` | `#F2F4F6` | 解析盒、未答网格、静息胶囊底 |
| `COLOR_BORDER_HAIRLINE` | `rgba(0,0,0,.04)` | `#0A000000` | 卡片描边、分割线 |
| `COLOR_BORDER_FOCUS` | `rgba(10,89,247,.40)` | `#660A59F7` | 输入框聚焦 |
| `COLOR_OVERLAY` | `rgba(24,36,49,.40)` | `#66182431` | 答题卡抽屉遮罩 |

### 3.3 字阶

DESIGN.md 给 12 档。现有 4 档（24/18/16/14）+ 散落裸值（12/28/48）。

| 常量 | 新值 | 字重 | 行高 |
|---|---|---|---|
| `FONT_DISPLAY_SCORE` | 48 | 700 | 56 |
| `FONT_DISPLAY_SCORE_MOBILE` | 36 | 700 | 44 |
| `FONT_HEADLINE_LG` | 28 | 600 | 36 |
| `FONT_HEADLINE_LG_MOBILE` | 22 | 600 | 30 |
| `FONT_HEADLINE_MD` | 20 | 600 | 28 |
| `FONT_HEADLINE_SM` | 16 | 600 | 24 |
| `FONT_BODY_LG` | 16 | 400 | 26 |
| `FONT_BODY_MD` | 14 | 400 | 22 |
| `FONT_BODY_SM` | 12 | 400 | 18 |
| `FONT_LABEL_MD` | 14 | 500 | 20 |
| `FONT_LABEL_SM` | 12 | 500 | 16 |
| `FONT_CAPTION_UNIT` | 11 | 500 | 14 |

**字号设置不受影响**：`FontSetting` 存的是偏移量（`common/src/main/ets/model/FontSetting.ets:26-32`），
实际字号 = 基准 + 偏移。换基准值不动这套机制，五档照常工作。
⚠️ 但"**照常工作**"只覆盖了会调 `sizeOf()` 的屏——Task 10 审查实测出**跨屏机制分叉**：
答题页题干/选项走 `font.sizeOf(...)`（`ExamDetailPage.ets:392/396/429/434`，注释还写明"不写死值，
否则放大档位下行距会被压回原尺寸"），而回顾页同一道题的同一批文字走裸令牌
（`ReviewQuestionCard.ets:85-87/:97-100`）、结果页同样如此 ⇒ **回顾页与结果页对用户的字号档完全没有反应**。
这不是换装引入的（改前同样是裸 `FONT_BODY`/`FONT_CAPTION`），简报也没给这个动作，
但它属于换装的直接影响面，把这句原样留着会让人误判"已解决"。
登记与裁决见 §7 风险；`ExamDetailPage` 自身还有一处内部不一致（`:223/:236/:269` 用裸值、
`:392/:429` 用 `sizeOf`），一并列入。
⚠️ 偏移量本表原写"±4/±2/0"，Task 2 采纳 §6.2 的 (a) 后实际是 **±2/±1/0**（极小 -2、小 -1、标准 0、大 +1、极大 +2），
本行已按代码现值更正；极小档 `FONT_CAPTION_UNIT` 现为 **9fp** 而非 7fp。

**档位的"字重/行高"是档位定义的一部分，不是可选项**（Task 10 审查后补，Ruling T10-A）：
上表每一行的字重与行高直接抄自设计源 `DESIGN.md` 的 typography token 块（如 `label-sm: 12px/500/16px`、
`caption-unit: 11px/500/14px`），**采用该档即采用该字重**，写裸 `FontWeight` 或漏配字重都不算对齐。

**哪些元素能用哪些档，设计源有明文许可**（此前 spec 漏抄，导致实施者各按口味选档，是 Task 9/10 分叉的根因）。
`DESIGN.md` §Typography / Application Rules 第三条原文：
> **Metadata and Badging:** Status pills, chapter identifiers, and time stamps employ **`label-sm` or `caption-unit`**
> to keep visual prominence focused strictly on task execution.

⇒ **状态胶囊、题型/章节标识、时间戳这类 badging/metadata 元素只许 `label-sm`(12/500) 或
`caption-unit`(11/500)；`label-md`(14) 不在许可档位内。** 按钮文字不受此条管（CTA 用 `body-lg`，次级按钮用 `label-md`）。
同一字段跨屏出现时（如题型标签同时出现在答题页、首页卡、回顾卡头），必须同档——
按本条它们**一律 `label-sm`**。

**badging 的判据是语义角色，不是外观**（Task 10 审查驳回 controller 派单里的反向判据后补，Ruling T10-F）。
本计划一度按"带不带 tint 底 + 圆角"判 badging，结果把结果页一句通栏正文（`AnswerResultPage`「已生成电子证书，
可在个人中心查看」，带 `LINE_BODY_SM` 行高与 `layoutWeight(1)`）降到了 `label-sm`，
而同一次巡检对**结构完全同款**的答题页防作弊条（`ExamDetailPage` 语义色 tint 底 + 圆角 + 通栏句子）判"不是胶囊、按 body 档"——
两条理由不能同时成立。⇒ **许可条管辖的对象只有三类：状态胶囊、章节/题号标识、时间戳。**
**通栏提示条与句子属正文**，走 body 家族，不套许可条；它们有 tint 底和圆角只是banner 形态，不改变"要人读一句话"的语义。
两条款定同档 `FONT_BODY_MD`(14/400) + `LINE_BODY_MD`：句子是给用户读的，
`§6.2` 立偏移上限守的就是这条可读线（12 档在极小档会落到 10fp）。
反面登记：若终审主张"提示条应当弱化"，那就**两处一起**降到 `FONT_BODY_SM`，不许一升一降。

**`letterSpacing`：设计源给 5 个档定义了它，本仓一处都没做，且本计划裁为不在换装窗口内补**（Task 10 审查后补，Ruling T10-E）。
设计源原文逐档：`display-score -0.02em`、`display-score-mobile -0.02em`、`headline-lg -0.01em`、
`headline-lg-mobile -0.01em`、`caption-unit +0.04em`（其余档无）。
本计划此前只抄了"大数字档做负字距"，**漏了 `caption-unit` 那条正字距**——它是本仓唯一真正在用的辅助档（3 处引用）。

换算：ArkUI `.letterSpacing()` 收维度值不是 em，`36fp × -0.02 ≈ -0.7fp`、`11fp × 0.04 ≈ 0.44fp`。
裁为不补的理由（可反驳，但请把理由一起反驳）：
① 0.44fp 的位移低于肉眼可辨阈值（`11fp × 0.04`），且这三处引用全在左对齐 `Row` 内，改了也看不见
  ——Task 10 审查复核后同意此结论；
  ⚠️ 我原先还写过一条"ArkUI 的 letterSpacing 在首字符前也加间距、会把居中胶囊改偏"，
  **那句在本地未核到 SDK 依据，属未经证实的推断，现予撤回**，裁决不依赖它（理由②③独立成立）。
② 负字距那 4 档（-0.01/-0.02em）方向相反、且都在大数字档，一旦要做就得同时做，成本是 5 档 + 5 枚新令牌；
③ 换装窗口内像素验收不可用（Task 13 才上机），用一个**可能的布局副作用**换一个**看不见的收益**不划算。
⇒ 列入 Task 13 设备目检清单：上机后若大分值数字的排布观感与设计屏明显发松、或辅助单位可读性受损，再单开小任务补，
   且必须先确认居中元素的 letterSpacing 副作用。

### 3.4 圆角 / 间距 / 阴影

| 项 | 新值 | 现值 |
|---|---|---|
| 卡片圆角 | 16 | 12 |
| 按钮圆角 | 8 | — |
| 输入框圆角 | 10 | — |
| 复选框圆角 | 6 | — |
| 标签圆角 | 全圆（pill） | 4 |
| 按钮高度 | 48 | 50 |
| 页面左右边距 | 16 | 16（不变） |
| 卡片内边距 | 16（紧凑 12） | 16 |
| 卡片纵向间距 | 12 | — |
| 网格 `columnsGap`（横向沟） | 16 | 16（不变） |
| 网格 `rowsGap`（纵向节奏） | 12 | 16 |
| 分区标题→下方内容间距 | 12 | 16（首页）/ 16（刷题页） |
| 分割线 | 0.5 | — |

**间距模型只有一个：横向 gutter 16、纵向节奏 12。** 适用对象是**容器与容器之间的间距**——列表行距、网格两轴、分区标题到其下方内容。Task 6 审查发现原简报把 `rowsGap` 也写成 16，那是简报读错，不是"网格例外"。

**边界（Task 6 复审要求补的，防止这条被过度推广）**：不适用于元素内部的排版偏移——胶囊自身的 `margin({top: 6})`、卡片内标题到副行的 `margin({top: 8})` 这类是组件内部构造，由各自简报逐字规定，不受这条模型约束。

分区标题间距本轮定死为 12：首页（`HomeView.ets:156`）已是 12，刷题页（`ExamSubjectView.ets:107`）留 16 会让同域两屏可见不对称。归 Task 12 落地（它已认领 `ExamSubjectView.ets`）。

阴影 Level 1（标准卡）：`shadow({ radius: 2, type: Color, color: '#08000000', offsetX: 0, offsetY: 1 })`。
Level 3（吸底操作栏）：`shadow({ radius: 8, color: '#08000000', offsetY: -2 })`。
Level 4（对话框/抽屉）：`shadow({ radius: 16, color: '#14182431', offsetY: -8 })`。

DESIGN.md 正文说按钮圆角是 `rounded-md`，但它的 token 表里 `md = 0.75rem = 12px`、`DEFAULT = 0.5rem = 8px`。两处自相矛盾。**取 8px**，理由是正文同时写了"structured stability"且与 48px 按钮高度比例更协调；这条记为设计决定，不是照抄。

## 4. 逐屏改动清单

| 屏 | 文件 | 改动 |
|---|---|---|
| F01 登录 | `login/view/LoginPage.ets` | 表单收进单张白卡（圆角 16 + Level 1 阴影）；输入框底 `#F2F4F6` → 聚焦转白 + 1.5 主色描边；按钮纯色 |
| F02 首页 | `home/view/HomeView.ets`、`components/PaperCard.ets` | 轮播保持现有图片 banner + `RADIUS_CARD` 圆角，**并加 `.clip(true)`**（ArkUI 容器圆角默认不裁剪子节点，不加则是方图盖圆框，圆角等于没落地）；**不改造成"浅底药丸卡"**——导出稿那张药丸卡上是「47 套模拟卷已更新」这类数据型文案（App 无此字段）+ Material Symbols 图标（ArkUI 无该字体），照改属内容替换不是换装，且会废掉六张现有 banner 与自动轮播行为；`PaperCard` 等级标签从"描边方角"改"浅蓝底全圆胶囊"（**tint 底、无描边**，见 §6.4），成绩角标同改；收编 `#FFFFFF` 硬编码 |
| F03 考试科目 | `exam/view/ExamSubjectView.ets`、`components/ExamSubjectCard.ets` | 双列网格卡按新令牌重排（科目名 + `共 N 套`）；**不加稿子里的图标容器、属性标签与"进入练习"链接**——`categoryName` 之外没有可填的字段；错误态按新令牌 |
| F04 考卷列表 | `exam/view/ExamListPage.ets` | 行结构与 F02 统一；**不加筛选器与排序** |
| F05 答题页 | `exam/view/ExamDetailPage.ets` | 告警条改浅红底红字（**盾牌位不做**，理由见下）；进度条改主色纤细；选项卡选中态 = 主色描边 + `#140A59F7` 底；中部内容加 `Scroll`（换装加高选项行后长题干会裁切且无法滚，属本次引入的回归）；**提交按钮去渐变**。**"底部控制栏三行结构"不做**，理由见下 |

**F05 两处明确不做的元素，第三次漂着后在此关账**（Task 7 复审指出它们一直"漂着没人认领"，漂着的缺口不会自己关）：

- **盾牌位图标不做。** 不是因为没有素材——`SymbolGlyph` + `sys.symbol.*` 是 ArkUI 内置能力，加图标零素材成本（这一点 Task 7 审查纠正过我原来的错判，见 §6.5）。不做是因为它属于**新增装饰元素**，超出已批准的"只移植设计语言"范围，且告警条缺图标不影响任何可读性。
- **"系统按键已锁定"那一行不做。** 它断言的是一个**本应用没有实现的系统级行为**——本页 `onWillDisappear` 明确支持物理返回。写上去就是编造文案，违反"no invented copy"硬约束。三行结构剩下的两行（按钮行 + 提交按钮）已经是现状形态。
| F06 答题卡 | 同上（`bindSheet`） | 抽屉圆角 16 + **平台系统拖拽条**（Task 8 修复轮换掉手绘条：`SheetOptions.dragBar` **`@default true`**，手绘那条 `#0A000000` 合成后对比度仅 1.09:1 属隐形装饰，见 ledger Ruling T8-1）；格子圆角 8，已答/存疑/未答换 §3.2 的 tint 底；存疑格加右上实心点；当前题 = 存疑底 + 主色描边复合态；底部左次右主（继续作答 40% / 提交试卷 60%） |
| F07 答题结果 | `exam/view/AnswerResultPage.ets` | 大分值 48/36 主色，"分"用 `FONT_CAPTION_UNIT` 弱化；通过/未通过改全圆胶囊 + tint 底；迷你分布图换 tint 色 |
| F08 逐题回顾 | `exam/view/ReviewPage.ets`、`ReviewQuestionCard.ets` | 左侧 4vp 状态轨保留，色换 `#00B578/#E84026`；选项 tint 底换 §3.2 值；解析盒 `#F2F4F6`；收编该文件 5 处硬编码 |
| F09 我的 | `mine/view/MineView.ets`、`components/SettingItem.ets` | 分组菜单卡用内嵌发丝分割线（`#0A000000`）替代间距；**字号行保持现有 `Select` 形态，只把行尾当前值换成 `body-md` + 次文本色**（Task 11 审查实测：导出屏里根本没有分段控制器——无 `<select>`/`role="tablist"`/`type="radio"`，只有一个 `shrink-0` 的「标准」span；原句"改分段控制器形态"是把结论安在了设计源没画过的控件上，本条已按实测纠正）；**不加指标栏与认证徽章** |
| F10 考试记录 | `exam/view/AttemptHistoryPage.ets` | 行结构对齐 F02；通过/未通过胶囊化；**不加汇总卡** |
| F11 我的证书 | `exam/view/CertificatePage.ets` | 证书卡网格排布编号/颁发/到期；有效绿胶囊、过期灰胶囊；**不加下载按钮与防伪话术** |
| F12 状态补充 | 分散在各页错误/空态 | 空态、错误态、401 态统一按新令牌；401 文案与按钮沿用 `a3da388` 已入库的分流逻辑 |

## 5. 验证方案

1. **构建门禁**：`devecocli build` 0 ERROR。`hvigorw test` 不编译视图，只跑单测等于没验视图。
2. **单测门禁**：跑前删 `entry/.test/default/intermediates/test/coverage_data/test_result.txt`，只认尾行 `Tests run: N, Failure: 0, Error: 0`，且 N 与本轮 `it()` 数对得上。换装前基线 121 例，换装后必须仍是 121（用例数变了就是回归）。
3. **令牌一致性静态检查**：换装后 `grep -rn "'#[0-9A-Fa-f]\{6\}'" entry/src/main/ets/features/**/view` 必须只剩 0 处硬编码（现 10 处）。
4. **模拟器目检**：这是硬要求，不能只靠单测。数值框、描边、圆角、阴影这类东西单测测不出来。逐屏截图对 `v2-final2/*/screen.png`，重点看五档字号下 `FONT_CAPTION_UNIT` 的可读性。
5. **合并态复跑**：ff 合并后站在 master 再跑一次全量测试。

## 6. 三个设计决定（需拍板）

### 6.1 提交试卷按钮去渐变

现状是全宽渐变 `#70b8f8→#416ff5`。方案A 明令"杜绝任何渐变"，改纯色 `#0A59F7`。这是肉眼最明显的一处变化，不是改色号。

### 6.2 极小档的可读性下限

`FONT_CAPTION_UNIT` 基准 11，极小档（-4）得 7fp。三个选项：
- (a) 极小档下限抬到 -2，即最小 9fp —— 改 `FONT_LEVELS`，影响所有层级
- (b) 辅助文字基准提到 12 —— 与 DESIGN.md 不符
- (c) 不动，接受 7fp —— 不推荐

建议 (a)，并同步核 `sizeOf()` 的兜底逻辑。

### 6.3 主色从 #007AFF 变 #0A59F7

应用图标、启动页背景、商店截图里的蓝会与新界面不一致。本次不动图标，但上架素材要另行重出，否则商店图与 App 内观感割裂。

### 6.4 设计源自相矛盾时的取舍原则：取更克制的那一读

执行中发现 `DESIGN.md` 的 prose 与导出屏的实际 HTML **两处互相矛盾**，且方向相反：

| 案例 | prose 怎么说 | 导出屏怎么做 | 取谁 |
|---|---|---|---|
| 底部导航毛玻璃（Task 11） | "杜绝毛玻璃模糊"（Zero Decorative Bloat） | `backdrop-blur-xl` + `bg-surface/90` | **prose**（更克制） |
| 胶囊描边（Task 5） | "Hairline border paired with matching tint background"，Success 示例给 `1px solid rgba(0,181,120,.20)` | 胶囊 class 里**没有** border | **导出屏**（更克制） |

**原则不是"prose 优先"也不是"屏优先"，而是"取更克制的那一读"。** 理由：这套方案的立身之本就是克制（无渐变、无插画、无弥散光），两处冲突都往回收才不会把"设计系统文档"读成"允许加装饰的许可证"。

**由此定：胶囊只做 tint 底，不加描边。** 这不省不了事——令牌层根本没有 tint 描边色（`rgba(0,181,120,.20)` ≈ `#3300B578`，全表无此项），补描边要先扩三个令牌再改 Task 1 的钉表测试；但即便补得起也不补，因为原则在先。

留给终审的反面意见：Task 5 审查认为按 Task 11 判例应当 prose 赢、补描边。两条裁决方向相反是**有意的**，判据是克制程度而非文档层级。若终审不认同这条原则，需要同时翻掉毛玻璃与描边两处，不能只翻一处。

### 6.5 底部 Tab 条：改高度与字阶，不加图标

`MainPage.ets` 原不在任何任务的认领范围内（Task 5 实施时发现），现归 Task 11 Step 0。

- 高度 52 → 64，对齐导出稿的 `h-16`；标签走 `FONT_LABEL_SM` + 选中态 `WEIGHT_SEMI`。
- **不加图标。** ⚠️ 这条理由**修正过一次**：我原本写"稿子的图标是 Material Symbols 连字，ArkUI 没有这套字体，加图标等于引一条图标素材管道"——Task 7 审查指出该论证不成立，我随后在 SDK 里核实：`SymbolGlyph` 是 ArkUI 内置组件（`component/symbolglyph.d.ts`），`sys.symbol.*` 系统图库存在，**加图标并不需要外部素材**。
  裁决不变，但地基换成两条真的：① 当前 Tab 条是纯文字，加图标属于**新增 UI 元素**，超出本计划已批准的"只移植设计语言、不加新区块"范围；② Material 图标到鸿蒙 symbol 的映射（`menu_book` 对应哪个 `sys.symbol`）是审美决定，归用户，不该由执行链静默选定。
  若用户点头要图标，这是一条独立小任务，成本不高（`SymbolGlyph($r('sys.symbol.xxx'))` + 字号/颜色），不是素材工程。
- 导航条用平面 `COLOR_CARD_BG` + Level 3 阴影（`SHADOW_BOTTOM_BAR`），不做毛玻璃——见 §6.4。

### 6.6 卡面配方的全局裁决：白底 + 圆角 16 + Level 1 阴影，**不给整周描边**

这是本计划第三次漂着的同一个洞（Task 9 审查记为张力、Task 10 审查点名"逐屏各缺一半"、Task 11 直接报"同屏两套卡面"）。
按 §7 之后立的规矩——**漂三次的缺口必须在 spec 关账，不能留给终审目检**——现在关。

判据不是新原则，是 §6.4 那条"取更克制的那一读"套到卡面上，而且这次**量得出数**：

| 证据 | 内容 |
|---|---|
| `DESIGN.md` §Components / Cards | 「Pure white background, `16px` corner radius, `16-20px` internal padding. **Encased in a `1px` border using `rgba(0,0,0,0.04)`**. Divided internally with subtle inset horizontal lines…」 |
| `DESIGN.md` §Elevation Levels | Level 1 命名为 **Standard Card**，即卡有阴影档 |
| 导出的 12 屏 HTML 实测 | 卡级圆角容器（`rounded-xl/2xl/3xl/card`）串共 **63** 个：**带 border 0 个**，**带 shadow 51 个** |

⇒ prose 的卡配方 = 描边 + 阴影两件套；实际导出屏 = **只有阴影，一条描边都没有**。
按 §6.4 取更克制的一读：**卡面 = 白底 + `RADIUS_CARD` + `SHADOW_CARD`，不加整周 hairline。**
这与 §6.4 已裁的"胶囊只做 tint 底、不加描边"同向，不是特例。

**描边仍然合法的四类对象，不要在清扫时误删**（它们不是"卡面装饰"，各有出处）：

- `TextInput` 的静息描边（§Input Fields / Option Selectors 明文）——`LoginPage.ets:84/104/127` 属此类，保留。
- 次级/描边按钮的轮廓——`ExamDetailPage.ets:526`「答题卡」那颗，保留。
- **组内 bottom 分割线** `width: { bottom: DIVIDER_WIDTH }`——`SettingItem.ets:35`、`MineView.ets:92`，
  这是 prose「Divided internally with subtle inset horizontal lines」的落地，保留。
- 选项行 / 答题卡格子 / 迷你分布图格子的**条件描边**（当前题=主色、非当前=hairline）与状态轨默认色——
  `ExamDetailPage.ets:162/443`、`AnswerResultPage.ets:146`、`ReviewQuestionCard.ets:50`，属控件态，保留。

**要动的三处**（同一配方给卡加了 prose-only 的第二层装饰）：
`PaperCard.ets:91`、`ExamSubjectCard.ets:40`、`ExamListPage.ets:94` 的整周
`.border({ width: DIVIDER_WIDTH, color: COLOR_BORDER_HAIRLINE })` 删除，`:92/:41/:95` 的 `.shadow(SHADOW_CARD)` 保留。

**反向补齐**：凡 `§4` 逐屏行里出现"卡"而未点名装饰的屏，一律按本配方给 `SHADOW_CARD`——
这翻掉 Ruling T9-C（结果页白卡当时裁"不补阴影"）与 Task 10 §4-e、Task 11 concern 3 的"半套卡面"。
理由：本条把卡面从"逐屏点名的 extend"升格为**组件配方**，配方统一后 §4 不必逐屏重述，
逐屏未点名不再构成"不加"的依据；而"只加阴影不加描边"仍是克制读法，未引入新元素。

**不由本条管辖的两类容器**（Task 10 复审把它们当作 §6.6 缺口报上来，核后判为不同档，不改）：

- **吸底操作栏**（`ExamDetailPage.ets:575-577`：`width 100%` + `CARD_BG` + padding，无圆角无阴影）。
  §3.4 给它的是 **Level 3**（radius 8 / offsetY -2），不是 Level 1 卡档；§4 F05 行也没点名它。
  给它补阴影属 extend，本轮不做。若终审主张"吸底栏就该有 Level 3 投影"，那是**一条独立的 §6.6 姊妹裁决**，
  要连着设计源 §Elevation Level 3 那句「top-edge hairline border `rgba(0,0,0,0.06)`」一起决定，别只翻一半。
- **底部 Tab 条**（`MainPage.ets:58-59`）已经吃了 `SHADOW_BOTTOM_BAR`（值与 §3.4 Level 3 逐字对上：radius 8 /
  `#08000000` / offsetY -2），但**挂在三个 tabBar 项上而不是整条 bar**——ArkUI 未给自定义 tabBar 暴露整条容器节点。
  这是平台限制下的合法替代，不是配方偏离；`SHADOW_BOTTOM_BAR` 因此不再是死令牌。

代价与可逆性：三处删除 + 若干屏补一行 `.shadow(...)`，合计 < 20 行；`COLOR_BORDER_HAIRLINE` 仍被上述四类消费，
不会变成死令牌。4% alpha 的描边在屏幕上近乎不可见，删与不删的差别只能上机判 —— 已列设备目检项。

留给终审的反面意见：若终审认为 prose 的 Cards 段应当赢（补回描边），那就同时得给 51/63 之外的 12 个无阴影卡
也补齐 prose 的两件套，并翻 §6.4 已裁的胶囊那条——**原则只能整体翻，不能只翻一处。**

### 6.7 旧别名 FONT_SUBTITLE(18) 无同值档：迁移必须择档，跨屏一致性待审

Task 12 实施者核出、controller 当场验证：计划写的「四个旧别名与新档同值、
漏改渲染一模一样」对其中一个**不成立**——`FONT_SUBTITLE`=18，而本节 §3.3 的档位表里
**根本没有 18 这一档**（它的上下邻是 20 与 16），原稿把它等同于 `FONT_BODY_SM`=12 是抄错。

事实（`git log -p -S` 逐站比对得出，非推断）：`FONT_SUBTITLE` 的迁移落点分三种——
`FONT_HEADLINE_MD`(20)、`FONT_BODY_LG`(16)、`FONT_BODY_MD`(14)，各屏各自择档。
实施者无过：表里无 18，必须择档；错在计划把它宣称为同值替换，从而把这批站点
排除在了"目棇态已知、只需机器对齐"的清单之外。

风险（预测，未上机验证）：厘头 18 的元素可能在不同屏变成 14/16/20，
相对优先级发生漂移——这恰恰是换装最不该留下的东西。

**机器可判的部分（已写进 Task 13 Step 3c）**：先用 diff 定位所有曾持 `FONT_SUBTITLE` 的站点，
列成表（屏 / 元素 / 现档）；同一语义角色若落在不同档，就按 §3.3 的角色取齐。
唯一不能本地定的是"取齐到 16 还是 20"这个审美选择，它归老大，不归实施者。


## 7. 风险

- **并行会话**：本仓库常有其它会话在改同一批文件。换装要动 12 个 view，冲突面大。开工前必须确认工作区干净、且没有别的会话正在写这些文件。
- **推送**：master 已 ahead 10 未推送。本次换装不推送，push 另需明确指令并先扫历史。
- **回退**：换装走独立 feature 分支，一次提交对应一屏或一组同构屏，改坏可单点回退，不做大爆炸提交。
- **字号档跨屏分叉（Task 10 审查揭出，本计划范围外，需老大拍）**：回顾页与结果页的题干/选项用裸令牌、
  不走 `sizeOf()`，所以用户在「我的 → 字号大小」选的任何档位对这两页**毫无作用**；答题页走 `sizeOf()` 正常响应。
  事实：这是既存缺陷（改前两页同样是裸 `FONT_BODY`），不是换装造成的。
  预测：若不在上架前处理，"调字号"这个设置项会被用户在最常用的两页上测出无效，观感是"设置没做完"。
  三种范围：(a) 不动，本次只交付视觉换装，把该缺陷记入 backlog；(b) 只把回顾页题干/选项接上 `sizeOf()`
  （2 个文件、约 8 处，需同步核 `lineHeight` 是否一起偏移，否则大字档会撑破卡）；(c) 全仓统一走 `sizeOf()`。
  我倾向 (b)——它是"设置项能不能用"的问题，且改动面可控；但这是**加功能不是换装**，越出已批准范围，所以由你定。

## 8. 我纠正的先前说法（执行期回补，共五条）

1. ~~"五档字号设置必须重新标定，否则极大可能比现在还小"~~ —— 错。`FontSetting` 存偏移量不存绝对值，换基准不影响档位机制。真正的问题是极小档下限（§6.2）。
2. ~~"答题卡 A/B 出成了独立整屏，不是半模态"~~ —— 结论对、**出处写错**（Task 8 审查核出）。
   真实的半模态证据在导出的第 11 屏 HTML：`fixed bottom` + `rounded-t-2xl` + 内含"答题卡/提交试卷"；
   而 `DESIGN.md` 全文**没有逐屏章节、没有 F06 标识、没有 Bottom Sheet 字样**（只有 §Elevation 的
   Level 4 "System Dialog & Inspection Sheets"，那是阴影档不是形态指派）。原句"DESIGN.md F06 明确写
   Bottom Sheet"是把结论安到了没写过它的文档上，本条已改按导出 HTML 立据。
4. ~~"模拟器起不来，要修得手动补约 1GB 系统镜像"~~ —— 错，Task 8 审查核盘推翻。
   `D:/system-image/HarmonyOS-6.1.1/phone_all_x86/system.img` = 3,670,016,000 B 完整在盘，
   AVD 的 `hardware-qemu.ini` 正指过去；`devecocli` 报"找不到"是它按 AVD `config.ini` 的
   `sdkPath=D:/DevEco Studio/sdk` + `imageSubPath=system-image/...` 拼了一个不存在的位置。
   直启入口在 `D:/DevEco Studio/tools/emulator/Emulator.exe`。**设备门禁没被环境打断，是被一次没做全的排查打断**，
   §5 的模拟器目检步骤据此恢复为可执行项（真阻塞只剩内存余量：实测 free 1.0 GB 时不起，先报数再启）。
3. ~~"有了字段白名单，它就没地方编出正确率 88.5%"~~ —— 只对一半。白名单管得住数据型发明，管不住惯例型发明（登录页的记住我/忘记密码、顶栏的搜索和头像）。v2 实测：加了字段白名单后统计卡确实消失，但英文顶栏残留 9 处、溢出菜单残留 9 屏，都是惯例型。

5. ~~"证书条带 `backgroundColor` + `borderRadius`，所以它确属 pill、在 badging 许可条管辖内"~~ —— 错，Task 10 审查驳回。
   判 badging 用外观（有没有 tint 底 + 圆角）会一路推到解析盒和选项行；用语义角色才收得住。
   同一次巡检我自己对结构完全同款的防作弊条给了反向判据，两判据不能并存。
   已按语义角色改写许可条（§3.3 Ruling T10-F），两处通栏句子统一回 `body-md`。
