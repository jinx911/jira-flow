# 断点恢复

dev-flow 检测到 `{root_path}/.dev-flow/{issue_key}-state.json` 时，按本流程处理。

## 最小 state 结构

```json
{
  "issue_key": "OA-3650",
  "flow_mode": "jira",
  "team_name": "dev-flow-OA-3650",
  "run_mode": "semi-auto",
  "started_at": "2026-06-30T10:00:00Z",
  "current_stage": 1,
  "complexity": "medium",
  "spec_name": null,
  "branch": null,
  "doc_version": 1,
  "spec_deltas": [],
  "stage_results": {},
  "spawned_agents": [],
  "updated_at": "<ISO>"
}
```

## 字段说明

| 字段 | 用途 |
|---|---|
| `flow_mode` | `jira` 或 `free`；决定跳过哪些步骤（free 模式跳过 Jira 收尾） |
| `current_stage` | 当前阶段（1-4） |
| `complexity` | `simple` / `medium` / `complex` |
| `spec_name` | `{changes_path}` 下的 spec 目录名（阶段 1 产出） |
| `branch` | 开发分支（阶段 2 产出） |
| `doc_version` | spec 版本号；每次 spec-deta 自增 |
| `spec_deltas[]` | 开发中文档变更日志（`{stage, reason, classification, at}`） |
| `stage_results` | 每阶段 Gate 摘要文本（恢复上下文用） |
| `spawned_agents` | 恢复时预期存在的 agent |

## 持久化时机

- Gate 通过 → 写 `stage_results[current_stage]`、下一 `current_stage`、`updated_at`
- spec-delta → `doc_version++`、追加 `spec_deltas[]`
- agent 完成 → 不追心跳（TaskList 为唯一事实源）

---

## 统一重试上限

| 异常 | 自修复上限 | 超限后 |
|---|---:|---|
| 构建失败 | 2 | 问用户 |
| 测试 bug 循环 | 3 | 问用户 |
| 需求/设计修订（spec-delta） | 2 | 问用户是否终止 |
| 任务冲突 | 1 次重排 | Leader 决定串行化/worktree |
| Agent 无响应 | 1 次 ping | 问用户（等待/跳过/spawn 替补） |
| Agent 上下文耗尽 | 1 次替补审批 | 问用户 |
| MCP 故障 | 2 次重试 | 存状态，停止 |

任何异常超上限必须升级到用户。

---

## 恢复流程

1. 读 `{issue_key}-state.json`。
2. 问：恢复还是删状态重启？
3. 恢复则问要 re-spawn 哪些 agent。
4. 只 re-spawn 确认的 agent；注入 `stage_results` + `spec_deltas` + 磁盘交付物。
5. 从 `current_stage` 恢复：
   - `1` → `spec-author`（重读现有 proposal/design；补齐缺失章节）
   - `2` → `dev-loop`（查 TaskList + `git log` 找已完成项；继续）
   - `3` → `review-test`（确认代码状态，再审查/验证）
   - `4` → `ship`（确认推送/部署/Jira 状态，补齐缺失步骤）
6. `spec_deltas` 非空时，恢复编码前先回放最新文档状态。
7. 阶段 4 完成后删除 state 文件。

## 崩溃恢复

- `current_stage < 2`：直接从已存交付物恢复。
- `current_stage == 2`：查 TaskList + `git log --oneline -20` + `git status`；必要时 re-spawn dev。
- `current_stage >= 3`：确认分支代码状态，再恢复当前阶段。

---

## 旧版兼容（`.jira-flow/*-state.json`）

对旧 jira-flow 版本写入的 state 文件：
- `current_phase`（1-6）→ `current_stage`（1-4）映射：phase 1→1、2→2、3→2、4→3、5→3、6→4。
- 忽略 `phase1_substep`、`agent_context_snapshots`、`agent_heartbeats`、`jira_quality_score`、`quality_score`（不再使用）。
- `spec_name`、`branch`、`complexity`、`user_answers` 原样保留。
- 缺 `doc_version` 则设为 1，`spec_deltas` 设为 `[]`。
- 若旧流程卡在 Phase 1 打分中途，问用户是否用新 checklist Gate 重启阶段 1。
