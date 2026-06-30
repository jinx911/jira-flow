---
name: learn
description: dev-flow 的学习子 skill。三模式：capture（Stage 4 后自动记信号）、apply（Stage 0 自动注入相关经验）、distill（/dev-flow learn --upgrade 提炼升级）。两层知识（项目 knowledge.md / 全局 playbook.md）+ 分级安全（playbook 自动、skill 结构审核）。可独立调用。
---

# Learn：dev-flow 的学习闭环

dev-flow 的第 5 个子 skill，独占"捕获→沉淀→应用→提炼"。让 dev-flow 在使用中持续成长，且不失控。

## 三模式

| 模式 | 触发 | 做什么 |
|---|---|---|
| capture | Stage 4 收尾后自动 | 把本次 run 信号写成一条 jsonl |
| apply | Stage 0 自动 | 读 knowledge.md + 相关 log，挑与当前需求相关的，返回压缩块供注入 |
| distill | `/dev-flow learn --upgrade`（或每 5 次 capture 后提醒） | 聚类信号 → 沉淀 knowledge/playbook（自动）+ 结构改动出 diff（待审） |

`learn` 不常驻——capture/apply 由编排器直接执行；distill 才 spawn 临时 curator agent。

## 信号分类（capture 机械、可聚类）

| signal | 触发 | severity |
|---|---|---|
| `gate_fail` | 某 Gate 未通过、返工 | high |
| `spec_delta` | 发生 spec-delta（含 reason） | medium |
| `retry_escalation` | 异常超重试上限升级用户 | high |
| `user_correction` | 用户中途明确纠正 | medium |
| `manual_note` | `/dev-flow learn <note>` | 由用户 |
| `win` | 某事做得好（可选正反馈） | low |

## capture

- 文件：`{root_path}/.dev-flow/lessons/{issue_key}-{HHmm}.jsonl`（append-only，每行一条 JSON）
- 时机：编排器在 ship 的 Gate 4 通过后调用
- 数据源：扫描本次 run 的 `stage_results` + `spec_deltas` + 异常记录
- state：`lessons_captured++`
- jsonl 行 schema 见 `knowledge-format.md`

## apply

- 读 `{root_path}/.dev-flow/knowledge.md`（不存在→返回空，零开销）
- 按当前需求文本 + 检测到的触发条件挑相关条目，压缩 **≤6 条**（封顶 ~800 token）
- 注入目标：
  - `spec-author` ← 必触发章节 + 历史 spec 坑
  - `dev-loop` ← 开发坑 + 复用点
  - `review-test` ← 常被忽略的审查项
- **不整本灌** knowledge.md；首次 run 返回空

## distill

`/dev-flow learn --upgrade`：spawn curator agent，聚类信号 → 自动更新 `knowledge.md` / 追加 `playbook.md`；skill 结构改动出 diff 待审。完整流程见 `distill-protocol.md`。

## 分级安全

| 改动 | 落地 |
|---|---|
| 追加 `lessons/*.jsonl` / 更新 `knowledge.md` / 追加 `playbook.md` | 自动 |
| 改 `SKILL.md` / `gate.md` / `templates` / `triggers.md` / `team-rules.md` / `resume.md` / `init-dev-flow` | 必须用户审 diff |

`playbook.md` 是自动成长的缓冲层——绝大部分经验沉淀于此，不动核心 skill 结构。

## 数据文件位置

- 项目层：`{root_path}/.dev-flow/lessons/{key}-{HHmm}.jsonl` + `{root_path}/.dev-flow/knowledge.md`
- 全局层：`skills/dev-flow/playbook.md` + skill 结构文件（distill 提议、审核后改）

每条 knowledge/playbook 条目带 `> source: <issue> @ <ISO>, signal: <type>` 溯源；超 200 行由 distill 去重精简。

## Dependencies

无外部 skill 依赖。由 dev-flow 编排器在 Stage 0 / Stage 4 触发；distill spawn 临时 curator agent。
