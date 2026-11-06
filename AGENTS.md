# AGENTS.md

本仓库是鸿蒙应用「智题通」（ArkTS / ArkUI / MVVM / feature 分包）。
分层与工程规范以 skill `harmonyos-mvvm-scaffold` 为准，本文件只写它猜不到的事。

## 外部资料库

接口字段、HTTP 方法、后端行为、教材任务复刻相关的判断，先读 `knowledge/harmonyos-textbook/`
——文件名即主题，分组清单见 `knowledge/README.md`。里面是 **2026-10-10 的静态快照**，
用之前先看文件里的日期，过期内容比没有内容更危险。

口径冲突时的优先级：`backend-verified-notes.md`（对 jar 与 exam.db 的实测）
> `api-contract-v1.md`（2026-07-26 的文档口径）> 你的先验知识。

## 会改变行为的硬约束

- 后端主键是雪花 ID，响应里一律以 **string** 下发；客户端所有 `id`/`paperId`/`attemptId`/`questionId`
  按 string 建模，用 number 承载会在第 16 位起静默丢精度，表现为"时隐时现查不出"
- `isPassed` 是数字 `1`/`0`，不是布尔；判断题的正确答案也以选项 `A`/`B` 提交
- 证书列表 `status` 是英文枚举 `VALID`/`EXPIRED`，而详情接口输出中文——同一后端两种口径，不可混用
- 交卷超时判定依赖客户端触发，服务端不会自动收卷：断网或挂机不会变成 `TIMEOUT`
- 未经用户明确要求，不要 `commit` / `push` / 切分支 / 覆盖写；本仓库常有并行会话

## 引用外部资料时给出文件名

答"某接口返回什么""某字段什么类型"这类结论时，标明出自哪个文件，便于复核。
