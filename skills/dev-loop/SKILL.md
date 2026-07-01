---
name: dev-loop
description: 从 spec 开始实现时使用。产出 tasks.md（每个单元标注测试策略）、建分支，再按条件化 TDD 开发。内置文档优先变更 + 代码质量契约。可独立调用。
---

# Dev-Loop：Spec → 实现（含文档优先变更）

## 流程
1. **规划** —— planner 读 proposal+design → 写 `{root_path}/.dev-flow/{issue_key}/spec/tasks.md`。每个任务单元带 `test_strategy` 标签（来自 design.md 测试策略）。
2. **建分支** —— backend-developer 通过 `/git-ops` 建分支，格式 `{type}/{issue_key}`（feat/fix/refactor/chore…；type 由 issue type / 需求文本推断，project-config `branch_naming` 可覆盖）。
3. **实现** —— dev agent 按单元的测试策略执行。

## 驱动的 agent
编排器 spawn：planner → backend-developer / frontend-developer。角色专长内嵌本 skill，**不读** `~/.claude/agents/*.md`（仅读各栈 `*-coding-standards` 作风格权威，见下）。

## 工具使用
你已安装的全部 skill / agent 都可用，主动选与任务相关的调用，不要重造轮子：
- 查代码 → codegraph / code-explorer / repo-scan
- 简化去冗余 → simplify / code-simplifier
- 补测试/覆盖 → test-coverage
- 构建失败 → build-fix / build-error-resolver
- 各栈规范 → 对应 *-coding-standards / *-reviewer
未装某工具时正常降级，不报错。

## 质量契约
写码前：
- DRY 硬步骤——先搜现有实现复用（codegraph / repo-scan）
- 按栈读风格权威（见"风格对齐"）

实现中（强制规则）：
- 不可变、函数<50 行、文件<800 行、无深嵌套(>4 层)、命名规范、显式错误处理、无魔法数字
- 注释：写"为什么"不写"是什么"；公开 API 文档化

GREEN 后、验证通过前（本阶段不 commit）：
- 强制去冗余 + 可读性 pass（用 simplify 类工具）
- /test-coverage 校验 ≥80%（tdd/regression 单元）

## 风格对齐
按 project-config 的 tech_stack.backend 判断：
- java / spring → 按市场主流规范（Spring Boot 社区），**不沿用仓库历史风格**；以 ~/.claude/agents/java-coding-standards.md 为权威
- 其他栈 → 跟目标仓库现有代码风格
- 任何栈：存在 ~/.claude/agents/<栈>-coding-standards.md 时，以其为最终权威
- 无对应 coding-standards agent：Java→Spring 社区主流；其他→跟仓库现有

## 条件化 TDD（非必要不用）
按单元的 `test_strategy` 标签决定纪律：

| 标签 | 适用 | 行为 |
|---|---|---|
| `tdd` | 可测业务逻辑 / 算法 / 状态流转 | RED → 验证 → GREEN → 验证 → REFACTOR |
| `regression` | bug 修复 | 先写回归测试，再修 |
| `smoke` | 脚手架 / 配置 / migration / UI 布局 | 直接实现；可选冒烟测试 |
| `none` | 纯配置 / typo / 文档 | 不写测试 |

`tasks.md` 步骤格式按标签变化——**开发期不 commit**，实现→验证→累积在工作树（commit 统一在 ship）。

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
