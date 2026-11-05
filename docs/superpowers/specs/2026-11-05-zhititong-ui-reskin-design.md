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
| `COLOR_ANALYSIS_BG` | `surface-container-low` | `#F2F4F6` | 解析盒、未答网格 |
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

**字号设置不受影响**：`FontSetting` 存的是偏移量（`common/src/main/ets/model/FontSetting.ets:24`，五档 ±4/±2/0），实际字号 = 基准 + 偏移。换基准值不动这套机制，五档照常工作。

真正要处理的是可读性下限：`FONT_CAPTION_UNIT` 基准 11，极小档算出 7fp。ArkUI 上 7fp 的中文辅助文字基本看不清。处置见 §6.2。

`letterSpacing` 在 DESIGN.md 是 em（`-0.02em`），ArkUI 的 `.letterSpacing()` 收的是维度值，要按字号换算（36fp 下 ≈ -0.7fp）。只在大数字档做，正文档不动。

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
| F06 答题卡 | 同上（`bindSheet`） | 抽屉圆角 16 + 手柄条；格子圆角 8，已答/存疑/未答换 §3.2 的 tint 底；存疑格加右上实心点；当前题 = 存疑底 + 主色描边复合态；底部左次右主（继续作答 40% / 提交试卷 60%） |
| F07 答题结果 | `exam/view/AnswerResultPage.ets` | 大分值 48/36 主色，"分"用 `FONT_CAPTION_UNIT` 弱化；通过/未通过改全圆胶囊 + tint 底；迷你分布图换 tint 色 |
| F08 逐题回顾 | `exam/view/ReviewPage.ets`、`ReviewQuestionCard.ets` | 左侧 4vp 状态轨保留，色换 `#00B578/#E84026`；选项 tint 底换 §3.2 值；解析盒 `#F2F4F6`；收编该文件 5 处硬编码 |
| F09 我的 | `mine/view/MineView.ets`、`components/SettingItem.ets` | 分组菜单卡用内嵌发丝分割线（`#0A000000`）替代间距；字号选择器改分段控制器形态；**不加指标栏与认证徽章** |
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

## 7. 风险

- **并行会话**：本仓库常有其它会话在改同一批文件。换装要动 12 个 view，冲突面大。开工前必须确认工作区干净、且没有别的会话正在写这些文件。
- **推送**：master 已 ahead 10 未推送。本次换装不推送，push 另需明确指令并先扫历史。
- **回退**：换装走独立 feature 分支，一次提交对应一屏或一组同构屏，改坏可单点回退，不做大爆炸提交。

## 8. 我纠正的三条先前说法

1. ~~"五档字号设置必须重新标定，否则极大可能比现在还小"~~ —— 错。`FontSetting` 存偏移量不存绝对值，换基准不影响档位机制。真正的问题是极小档下限（§6.2）。
2. ~~"答题卡 A/B 出成了独立整屏，不是半模态"~~ —— 错。DESIGN.md F06 明确写 Bottom Sheet，缩略图上是把抽屉单独展示而已。
3. ~~"有了字段白名单，它就没地方编出正确率 88.5%"~~ —— 只对一半。白名单管得住数据型发明，管不住惯例型发明（登录页的记住我/忘记密码、顶栏的搜索和头像）。v2 实测：加了字段白名单后统计卡确实消失，但英文顶栏残留 9 处、溢出菜单残留 9 屏，都是惯例型。
