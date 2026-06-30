---
name: dev-loop
description: 从 spec 开始实现时使用。产出 tasks.md（每个单元标注测试策略）、建分支，再按条件化 TDD 开发。内置文档优先变更：开发中发现需求缺口，先改文档再改代码。可独立调用。
---

# Dev-Loop：Spec → 实现（含文档优先变更）

## 流程
1. **规划** —— planner 读 proposal+design → 写 `tasks.md`。每个任务单元带 `test_strategy` 标签（来自 design.md 测试策略）。
2. **建分支** —— backend-developer 通过 `/git-ops` 建分支。
3. **实现** —— dev agent 按单元的测试策略执行。

## 驱动的 agent
编排器 spawn：planner → backend-developer / frontend-developer。角色专长内嵌本 skill，**不读** `~/.claude/agents/*.md`。

## 条件化 TDD（非必要不用）
按单元的 `test_strategy` 标签决定纪律：

| 标签 | 适用 | 行为 |
|---|---|---|
| `tdd` | 可测业务逻辑 / 算法 / 状态流转 | RED → 验证 → GREEN → 验证 → REFACTOR |
| `regression` | bug 修复 | 先写回归测试，再修 |
| `smoke` | 脚手架 / 配置 / migration / UI 布局 | 直接实现；可选冒烟测试 |
| `none` | 纯配置 / typo / 文档 | 不写测试 |

`tasks.md` 步骤格式按标签变化——**不再统一**是 test→verify→implement→verify→commit。

## 文档优先变更（发现任何需求缺口时必须）
实现中发现需求缺口/错误，先改文档再改代码。见 `doc-first-change.md`。

## 长任务上下文保护
`tasks.md` 超过 8 个单元时分轮（每轮 ≤8 单元）。轮间 Leader 持久化进度；下一轮从第一个待办单元继续。TaskList 为进度源（不追心跳/snapshot）。

## 前后端协同
若后端和前端在同一仓库改了重叠文件，用 worktree 隔离；否则同分支并行。Leader 按 architect 的关键文件列表判断。

## Gate 2
- [ ] TaskList 干净（所有单元完成）
- [ ] `tdd`/`regression`/`smoke` 标签单元测试绿
- [ ] 每个 `spec-delta` 已确认（范围性）或已记录（澄清性）

## Dependencies
- Agents（内嵌）：planner、backend-developer、frontend-developer
- Skills：git-ops
- Plugin：superpowers（test-driven-development、executing-plans）
