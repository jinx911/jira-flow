# Dev-Flow 培训指南

> 全链路 Agent Team 开发工作流 —— 从需求（Jira Issue 或自然语言）到代码提交

---

## 1. 概述

### 什么是 Dev-Flow？

Dev-Flow 是一个 Claude Code Skill，自动化执行从需求到代码提交的完整开发流程。它用一个**薄编排器 + 4 个可复用子 skill**，通过 Hub-and-Spoke 模式协调多个 AI Agent，以 **4 个 Stage + 4 个 Gate** 完成：

```
需求（Jira key 或文本）→ spec → dev → review-test → ship → 分支推送 + Jira 更新

Stage 1: spec-author   需求 → proposal.md + design.md（自适应工程章节）
Stage 2: dev-loop      tasks.md + 分支 + 实现（条件化 TDD + 文档优先变更）
Stage 3: review-test   审查 + 验证 + 修复环
Stage 4: ship          定稿 + 部署 + Jira 收尾
```

### 核心价值

- **全链路自动化**：从需求到提交，无需手动切换工具
- **文档驱动**：结构化 proposal/design，按触发条件展开工程章节；Gate 是完整性 checklist（不自评打分）
- **活文档**：开发中发现需求缺口，先改文档再改代码（spec-delta + `doc_version` 追踪）
- **条件化 TDD**：TDD 只用于可测逻辑；脚手架/配置不折腾
- **人机协作**：半自动模式下 Gate 由用户确认
- **可恢复**：断点恢复，状态存 `.dev-flow/{issue_key}-state.json`

### 两种运行模式

| 特性 | 半自动（默认） | 全自动 |
|------|--------------|--------|
| Gate | 展示 checklist 摘要 + 用户确认 | 自动放行，记录摘要 |
| 范围性 spec-delta（mini-Gate） | 总是问用户 | 仅超重试上限才问 |
| Jira/分支动作 | 先确认 | 自动执行 |
| 适用场景 | 复杂需求、首次使用 | 简单需求、熟悉流程后 |

---

## 2. 架构详解

### 薄编排器 + 4 子 skill

```
                    ┌──────────┐
                    │   User   │
                    └────┬─────┘
                         │ /dev-flow OA-3650
                    ┌────▼─────┐
                    │  Leader  │ ← 编排器（只协调，不执行业务）
                    └────┬─────┘
                         │ 触发子 skill（每阶段一个）
         ┌──────────┬────┴────┬──────────┐
     spec-author  dev-loop  review-test   ship
         │            │          │          │
       (spawn)     (spawn)    (spawn)    (spawn)
         └────────────┴──────────┴──────────┘
                         │ SendMessage（hub-spoke）
                    各角色 Agent
```

**关键原则**：
- Leader **永不直接执行**业务操作，只协调/决策/路由（保持上下文干净）
- 每个阶段是一个**可独立调用**的子 skill（`/spec-author`、`/review-test`、`/ship` 能单独跑）
- 所有 Agent 通信**必须经 Leader 路由**，严禁直连
- **角色专长内嵌在子 skill** —— dev-flow **不读** `~/.claude/agents/*.md`（agent 文件可选）
- **预生成 prompt**：流程开始一次性把变量代入 `.dev-flow/{key}/prompts/{stage}.md`，spawn = 读文件 + `Agent()`
- **TaskList 是唯一事实源** —— 不追心跳/snapshot

### 角色（内嵌于子 skill，非外部依赖）

| 角色 | 所在子 skill | 职责 |
|-------|---------|------|
| requirements-analyst | spec-author | 读 Jira/需求、核心章节、澄清 |
| architect | spec-author | 工程章节、架构决策 |
| planner | dev-loop | tasks.md 拆分 |
| backend-developer | dev-loop / ship | 建分支、实现、定稿、部署 |
| frontend-developer | dev-loop | 前端实现（按需） |
| code-reviewer | review-test | 评审、严重性分级 |
| tester | review-test | 测试验证、Bug 报告 |

> 这些角色的专长已收进对应子 skill 的 SKILL.md。`~/.claude/agents/*.md` 不再被读取，可留可删。

### 按需 spawn

```
Stage 1: spec-author 的 requirements-analyst + architect
Stage 2: dev-loop 的 planner → backend-developer / frontend-developer
Stage 3: review-test 的 code-reviewer + tester（修复回 dev）
Stage 4: ship 的 backend-developer；Jira 收尾 → requirements-analyst 或 Leader
```

---

## 3. Stage 详解

### Stage 0：初始化（编排器自己）

**做什么**：
1. 预检：依赖 skill（create-team / delete-team / git-ops / init-dev-flow / spec-author / dev-loop / review-test / ship）、superpowers 插件；jira 模式需 Atlassian MCP + CodeGraph
2. 解析输入（jira 模式 / free-flow 模式）
3. 加载配置（dev-flow config → projects.json → 项目 config）
4. 断点检测（`.dev-flow/{key}-state.json` 存在则按 `resume.md` 恢复）
5. 选运行模式
6. **预生成每阶段 prompt 文件** + `/create-team`（`team_name = dev-flow-{key}`）

**产出**：配置就绪 + 团队已建 + prompt 文件就位

---

### Stage 1：spec-author（需求 → 结构化 spec）

**参与者**：requirements-analyst → architect

**流程**：
```
requirements-analyst:
  1. jira 模式：经 Atlassian MCP 读 Jira（描述/评论/附件）；free 模式：用 requirement_text
  2. 写核心章节：背景目标 / 范围(in,out) / 验收标准(Given/When/Then) / 影响模块
  3. 仅在歧义时问澄清（自适应，非固定 checkpoint）
  4. 检测触发条件（见下）

architect:
  1. 读 proposal + 探索相关代码
  2. 按触发条件展开工程章节
  3. 写架构决策（复杂需求强制非空）+ 关键文件 + 复用点
  4. 输出 design.md
```

**自适应工程章节（按触发条件展开）**：

| 触发条件 | 章节 |
|---|---|
| 新表/字段/migration | 数据模型 |
| 新增/改动接口 | API 契约 |
| 跨模块/跨服务 | 接口边界 |
| 状态机/多步/异步 | 状态与流程 |
| 重要错误路径/权限/支付 | 错误契约 |
| 恒久 | 测试策略（每条 AC） |

**产出**：`proposal.md` + `design.md`

**Gate 1（checklist，不打分）**：
- 核心 + 触发的工程章节齐
- 无 TBD/TODO 占位符
- 每条验收标准有测试策略条目
- 复杂需求架构决策非空

---

### Stage 2：dev-loop（tasks + 分支 + 条件化 TDD + 文档优先变更）

**参与者**：planner → backend-developer / frontend-developer

**流程**：
```
planner:
  1. 读 proposal + design
  2. 拆 tasks.md，每个单元带 test_strategy 标签（来自 design 测试策略）
  3. 标注 blockedBy 依赖

backend-developer:
  1. /git-ops 建分支

dev:
  按单元 test_strategy 实现
```

**条件化 TDD（非必要不用）**：

| 标签 | 适用 | 行为 |
|---|---|---|
| `tdd` | 可测业务逻辑/算法/状态流转 | RED→验证→GREEN→验证→REFACTOR |
| `regression` | bug 修复 | 先写回归测试再修 |
| `smoke` | 脚手架/配置/migration/UI | 直接实现，可选冒烟测试 |
| `none` | 纯配置/typo/文档 | 不写测试 |

**文档优先变更（核心创新）** —— 发现需求缺口/错误时：
1. 暂停编码，标记 spec-delta
2. **先改** proposal/design/tasks.md（标注 `> [SPEC-DELTA vN] 原因`）
3. 分类：范围性 → Leader 拉用户 mini-Gate；澄清性 → 记录继续
4. `doc_version++`，记 `spec_deltas[]`
5. 按更新后的文档继续

**长任务**：tasks.md >8 单元分轮（≤8/轮），轮间持久化进度。

**Gate 2**：TaskList 干净 + 标签单元测试绿 + spec-delta 已确认/记录

---

### Stage 3：review-test（审查 + 验证 + 修复环）

**参与者**：code-reviewer → tester；修复回 dev

**流程**：
```
code-reviewer:
  1. git diff 结构化评审（不凭记忆）
  2. 多轮管道：质量（恒过）→ 架构(≥3 文件/新接口) → 安全(用户输入/认证/数据写入)
  3. 严重性分级：CRITICAL(阻断)/HIGH(合并前必修)/MEDIUM(建议)/LOW(可选)
  4. 每条：file:line + 描述 + 修复建议

tester:
  1. 跑单元/集成/E2E + 数据库验证（MCP）
  2. 证据优先：命令 → 输出 → 退出码（禁止"应该能用"）
  3. Bug 报告：复现 + 预期 + 实际 + 证据
```

**修复环**：CRITICAL/HIGH + bug → dev 修 → 重审/重测，≤3 轮再升级用户。

**Gate 3**：无 CRITICAL + 无未解决 HIGH + 测试通过无未修 bug

---

### Stage 4：ship（定稿 + 部署 + Jira）

**参与者**：backend-developer；Jira 收尾 → requirements-analyst 或 Leader

**流程**：
```
backend-developer:
  1. 跑全量测试 + 清 debug 代码（console.log/dd/dump/var_dump）
  2. 提交并推送分支（只推分支，MR 手动）
  3. 配置了 deploy_branch → 合并并推送（触发自动部署）

Jenkins（可选，配置 + MCP 都在）:
  AskUserQuestion 确认参数 → jenkins_build_and_watch → 失败取 log 问用户

Jira 收尾（仅 jira 模式）:
  1. transition 主单 → 测试状态（触发自动建子单）
  2. JQL 查子单
  3. 填提测说明（按 testing_note_template）→ transition 子单完成
```

**Gate 4**：分支已推送 + deploy_branch 合并(若配置) + Jenkins 成功/跳过(若配置) + Jira 更新(jira 模式)

---

## 4. 配置体系

### 三层配置

```
Layer 1: 全局索引   ~/.claude/configs/projects.json            （路径 → 项目名）
Layer 2: 项目配置   {root_path}/.claude/project-config.md       （仓库/数据库/环境/构建）
Layer 3: 流程配置   ~/.claude/skills/dev-flow/project-config.md （root_path/cloudId/分支命名/OpenSpec）
```

### 查找链

```
dev-flow/project-config.md → root_path
  → projects.json → 项目名
    → {root_path}/.claude/project-config.md → 完整配置
```

### 关键配置项

```yaml
# dev-flow/project-config.md
root_path: ""
cloudId: ""
branch_naming: { format: "{issue_key}" }
openspec: { changes_path: "openspec/changes", baseline_path: "openspec/specs" }

# {root_path}/.claude/project-config.md
databases:        { main: { mcp: "...", desc: "..." } }
build_commands:   { frontend: "...", backend: "..." }
deploy_branch:    "test"           # 可选
jenkins:          { job_name: "...", ... }          # 可选
jira_workflow:    { testing_status: "测试中", ... }  # 可选
spec.triggers:    { ... }           # 可选，扩展 spec-author 触发条件
```

---

## 5. Superpowers 集成

每个子 skill 引用一个 Superpowers 方法论；Agent 执行时按 `[superpowers:xxx]` 标记加载。

| Stage | 子 skill | Superpowers Skill | 核心约束 |
|---|---|---|---|
| 1 | spec-author | brainstorming | 自适应章节 + checklist Gate |
| 2 | dev-loop | test-driven-development + executing-plans | 条件化 TDD + 文档优先变更 |
| 3 | review-test | requesting-code-review + verification-before-completion | 严重性分级 + 证据铁律 |
| 4 | ship | finishing-a-development-branch | 全量测试 → 清理 → 推送 |

---

## 6. 异常处理

### 统一重试上限

| 异常 | 自修复上限 | 超限 |
|---|---:|---|
| 构建失败 | 2 | 问用户 |
| 测试 bug 循环 | 3 | 问用户 |
| 需求/设计修订（spec-delta） | 2 | 问是否终止 |
| 任务冲突 | 1 次重排 | Leader 串行化/worktree |
| Agent 无响应 | 1 次 ping | 问用户 |
| 上下文耗尽 | 1 次替补审批 | 问用户 |
| MCP 故障 | 2 次重试 | 存状态，停止 |

### 空闲检测（取代心跳）

- 信号：TaskList 活动 + agent 进度更新（**不追心跳/snapshot**）
- Stage 1-2：10 分钟无 TaskUpdate 且无消息 → Leader 发**一次** ping
- Stage 3-4：15 分钟
- ping 无响应 → 问用户（等待/跳过/spawn 替补，**不自动替补**）

---

## 7. 文件结构

```
~/.claude/skills/
├── dev-flow/                       ← 薄编排器
│   ├── SKILL.md                    ← 阶段路由 + Gate + 委托 + state
│   ├── gate.md                     ← checklist Gate
│   ├── team-rules.md               ← 通信规则 + Health + 变量注入
│   ├── resume.md                   ← 断点恢复 + 旧版兼容
│   └── project-config.example.md
├── spec-author/                    ← Stage 1
│   ├── SKILL.md
│   ├── triggers.md                 ← 触发条件 → 工程章节
│   └── templates/                  ← proposal/design 模板
├── dev-loop/                       ← Stage 2
│   ├── SKILL.md
│   └── doc-first-change.md         ← 文档优先变更协议
├── review-test/                    ← Stage 3
│   └── SKILL.md
├── ship/                           ← Stage 4
│   └── SKILL.md
├── init-dev-flow/                  ← 一键初始化
├── create-team/  delete-team/  git-ops/
└──（agents/ 可选，dev-flow 不读）
```

**渐进式披露**：每个 SKILL.md 保持精简（编排器 ≤150 行，子 skill ≤80–100），细节进 bundled 文件按需 Read。

---

## 8. 快速开始

### 1. 前置
- Claude Code CLI + superpowers 插件 (v5.0+)
- skills：create-team、delete-team、git-ops、init-dev-flow、spec-author、dev-loop、review-test、ship
- MCP：atlassian-rovo（jira 模式必选）、jenkins/playwright（可选）
- agents：**可选**（dev-flow 自包含）

### 2. 初始化
```
/init-dev-flow
```

### 3. 运行
```
/dev-flow OA-3650                  # jira 模式
/dev-flow 给用户管理加 CSV 导出    # free-flow 模式
```

### 4. 交互
半自动模式下每个 Gate 展示 checklist 摘要：确认 → 下一 Stage；修改 → Leader 转发；终止 → `/delete-team`。

---

## 9. FAQ

**Q：Leader 为什么不能直接执行？**
A：保持上下文干净。Leader 只协调/决策/路由，执行交给子 skill 的 agent。这保证职责清晰、可审计，且复杂需求不会撑爆 Leader 上下文。

**Q：和旧 jira-flow 的主要区别？**
A：① 6 阶段 → 4 阶段子 skill；② 双 rubric 自评 → 结构化模板 + checklist Gate；③ 文档冻结 → 活文档（文档优先变更）；④ 处处 TDD → 条件化 TDD；⑤ 重型协调协议（ack/心跳/6 步拼 prompt）→ 预生成 prompt + TaskList 事实源；⑥ 依赖 agent 文件 → 解耦（专长内嵌子 skill）。

**Q：子 skill 能单独用吗？**
A：能。`/spec-author` 只出设计、`/review-test` 只审现有分支、`/ship` 只收尾。bugfix-flow 也可复用 `ship` / `spec-author`。

**Q：开发中发现需求错了怎么办？**
A：触发文档优先变更——先改 proposal/design/tasks.md（标 spec-delta），范围性变更拉用户 mini-Gate 确认，再改代码。文档与代码始终同步。

**Q：可以中途暂停吗？**
A：可以。状态存 `.dev-flow/{issue_key}-state.json`，下次同 issue 自动恢复；旧 `.jira-flow/*-state.json` 也能兼容映射。

**Q：全自动模式安全吗？**
A：CRITICAL/HIGH 仍升级用户；Gate 质量检查照跑，只跳过人工确认；超重试上限也升级用户。

**Q：TDD 是强制的吗？**
A：不是。按单元 `test_strategy` 决定：`tdd`/`regression` 才走 TDD，`smoke`/`none` 直接实现。

**Q：agent 文件还需要吗？**
A：dev-flow 不读它们。可留作其他场景独立使用，也可删除，不影响 dev-flow。
