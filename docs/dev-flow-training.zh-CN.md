> ⚠️ **状态：** Dev-Flow 已从旧的 6 阶段 jira-flow 重构为**薄编排器 + 4 个子 skill**（`spec-author` → `dev-loop` → `review-test` → `ship`）。下方命名已更新；后续章节的逐阶段详解为旧版内容，正在刷新。当前架构见顶层 [README](../README.zh-CN.md)。

[English](dev-flow-training.md) | **中文**

# Dev-Flow 培训指南

> 全链路 Agent Team 开发工作流 — 从 Jira Issue 到代码提交

---

## 1. 概述

### 什么是 Dev-Flow？

Dev-Flow 是一个 Claude Code Skill，自动化执行从 Jira Issue 到代码提交的完整开发流程。它通过 Hub-and-Spoke 模式协调多个 AI Agent，以 6 个 Phase + 6 个 Gate 的结构完成：

```
Jira Issue → 需求分析 → 架构设计 → 任务规划 → TDD开发 → 代码评审 → 测试验证 → 提交推送
```

### 核心价值

- **全链路自动化**: 从需求到提交，无需手动切换工具
- **质量内建**: 6 个 Gate 检查点，确保每步质量
- **TDD 驱动**: 强制测试先行，代码质量有保障
- **人机协作**: 半自动模式下关键节点由用户确认
- **可恢复**: 断点恢复机制，中断后可继续

### 两种运行模式

| 特性 | 半自动（默认） | 全自动 |
|------|--------------|--------|
| Gate | 展示摘要 + 用户确认 | 自动通过，记录摘要 |
| 异常 | 所有异常询问用户 | 仅超限时询问 |
| Jira 收尾 | 用户确认后提交 | 自动提交 |
| 适用场景 | 复杂需求、首次使用 | 简单需求、熟悉流程后 |

---

## 2. 架构详解

### Hub-and-Spoke 模式

```
                    ┌──────────┐
                    │   User   │
                    └────┬─────┘
                         │ /dev-flow OA-3650
                    ┌────▼─────┐
                    │  Leader  │ ← 编排器（不执行任何操作）
                    └────┬─────┘
                         │ SendMessage
              ┌──────────┼──────────┐
         ┌────▼────┐ ┌──▼────┐ ┌──▼──────┐
         │Core Team│ │Dev    │ │Review   │
         │         │ │Team   │ │Team     │
         └─────────┘ └───────┘ └─────────┘
```

**关键原则**:
- Leader **永远不直接执行**任何操作
- Leader 只做协调、决策和状态流转
- 所有 Agent 间通信**必须通过 Leader 路由**
- Agent **严禁直连**其他 Agent

### 7 个 Agent 角色

| Agent | 模型 | 创建时机 | 职责 |
|-------|------|---------|------|
| requirements-analyst | Opus | Phase 0 | 读取 Jira、分析需求、生成 proposal |
| architect | Opus | Phase 0 | 架构设计、生成 design.md |
| planner | Opus | Phase 0 | 任务拆分、TDD 步骤规划 |
| backend-developer | Sonnet | Gate 1 后 | 后端代码实现 |
| frontend-developer | Sonnet | Gate 1 后 | 前端代码实现（按需） |
| code-reviewer | Sonnet | Phase 4 前 | 代码评审、严重性分级 |
| tester | Sonnet | Phase 5 前 | 测试验证、Bug 报告 |

### 按需扩容策略

不是所有 Agent 都一开始就创建：

```
Phase 0: Core Team (requirements-analyst + architect + planner)
  ↓
Gate 1: 检查 design.md 是否涉及前端/后端
  ↓
Gate 1 后: 创建 backend-developer / frontend-developer
  ↓
Phase 4 前: 创建 code-reviewer
  ↓
Phase 5 前: 创建 tester
```

**为什么？** 节省资源，按需创建，每个 Agent 都有明确的生命周期。

---

## 3. Phase 详解

### Phase 0: 初始化

**做什么**:
1. 前置检查（依赖 skill、superpowers 插件、agent 定义、MCP）
2. 解析 Jira Issue Key
3. 加载配置（projects.json → project-config.md → dev-flow config）
4. 断点检测（检查是否有未完成的流程）
5. 选择运行模式（半自动/全自动）
6. 创建核心团队

**前置清理**: Phase 1 首个 agent 执行 `find {changes_path} -type d -empty -delete` 清理残留空目录。

**产出**: 配置就绪 + 核心团队已创建

---

### Phase 1: 需求分析

**参与者**: requirements-analyst → architect

**流程**:
```
requirements-analyst:
  1. 清理空目录: find {changes_path} -type d -empty -delete
  2. 通过 Atlassian MCP 读取 Jira Issue（描述、评论、附件）
  3. 提出 2-3 个实现方案（含权衡分析）
  4. 给出推荐方案及理由
  5. 基线关联检查（若 baseline_path 存在且非空）:
     - 扫描 baseline_path 下相关基线文档
     - 在 proposal 中标注"基线约束"段落
     - 确保方案不与基线冲突
  6. spec self-review（占位符、一致性、范围、歧义检查）
  7. 输出: proposal.md

architect:
  1. 读取 proposal.md
  2. 探索相关代码架构
  3. 设计模块拆分（单一职责、接口清晰）
  4. design self-review
  5. 输出: design.md + 是否涉及后端/前端
```

**产出**: `proposal.md` + `design.md`

**Gate 1 通过标准**:
- proposal.md + design.md 无占位符（TBD/TODO）
- 内部一致（各章节不矛盾）
- 涉及模块明确

---

### Phase 2: 任务规划 + 分支

**参与者**: planner → backend-developer

**流程**:
```
planner:
  1. 读取 design.md
  2. 拆分为咬合粒度任务（每步 2-5 分钟）
  3. 每个任务包含 TDD 步骤:
     RED(写失败测试) → Verify RED → GREEN(最小实现) → Verify GREEN → REFACTOR → Commit
  4. 创建 tasks.md + TaskCreate 跟踪条目
  5. 标注 blockedBy 依赖关系

backend-developer:
  1. /git-ops 创建开发分支
  2. 基于 master 创建，命名规则参考 project-config
```

**产出**: `tasks.md` + git branch

**Gate 2 通过标准**:
- tasks.md 无占位符
- 每步有文件路径和命令
- blockedBy 依赖正确

---

### Phase 3: TDD 开发

**参与者**: backend-developer + frontend-developer（并行）

**核心原则 — TDD 铁律**:
> 禁止无失败测试先写生产代码。先写测试 → 先写测试 → 先写测试！

**流程**:
```
对每个任务:
  1. RED:   写最小测试展示期望行为
  2. Verify: 运行确认失败（特性缺失，非语法错误）
  3. GREEN: 写最小代码通过测试
  4. Verify: 运行确认通过，无其他测试回归
  5. REFACTOR: 清理（去重、改善命名、提取辅助）
  6. Commit: 提交当前步骤
```

**前后端并行冲突处理**:

| 场景 | 策略 |
|------|------|
| 不同仓库 | 天然隔离，各自开发 |
| 同仓库不同文件 | 同分支，各改各的 |
| 同仓库同文件不同位置 | 同分支，注意合并顺序 |
| 同仓库同文件有重叠 | **Worktree 隔离**，各自在独立工作树开发 |

**产出**: 实现代码 + 测试代码

**Gate 3 通过标准**:
- 所有 Task 状态 completed
- 测试通过

---

### Phase 4: 代码评审

**参与者**: code-reviewer

**流程**:
```
code-reviewer:
  1. 获取 BASE_SHA（分支创建前）和 HEAD_SHA（当前 HEAD）
  2. git diff 结构化评审（不凭记忆）
  3. 严重性分级:
     CRITICAL: 安全漏洞/数据丢失风险 → 阻断合并
     HIGH: Bug 或重大质量问题 → 合并前修复
     MEDIUM: 可维护性问题 → 建议修复
     LOW: 风格或小建议 → 可选
  4. 对每个问题: 文件路径:行号 + 问题描述 + 修复建议
```

**产出**: 评审报告（按 C/H/M/L 分级）

**Gate 4 通过标准**:
- 无 CRITICAL
- 无未处理的 HIGH
- 如有 → dev 修复后 code-reviewer 重评

---

### Phase 5: 测试验证

**参与者**: tester

**核心原则 — 证据铁律**:
> 任何完成声明必须有即时验证证据支撑。禁止"应该能用了"！

**流程**:
```
tester:
  1. 读取 proposal.md + tasks.md
  2. 运行测试套件（单元 + 集成 + E2E）
  3. 数据库验证（通过 MCP 查询）
  4. 每项验证提供: 命令 + 输出摘要 + 退出码
  5. Bug 报告: 复现步骤 + 预期 + 实际 + 证据
```

**Bug 修复循环**（全过 Leader 路由）:
```
tester 发现 Bug → Leader → Leader 判断归属 → dev 修复 → Leader → tester 复验
→ 未通过 → 再走一轮（≤3次） → 仍失败 → Leader 询问用户
```

**产出**: 测试报告

**Gate 5 通过标准**:
- 全部测试通过
- 无未修复 Bug

---

### Phase 6: 收尾

**参与者**: backend-developer + requirements-analyst

**流程**:
```
backend-developer:
  1. 确认所有测试通过（完整测试套件）
  2. 清理调试代码（console.log/dd/dump 等）
  3. 提交并推送分支
  4. merge 到 deploy_branch（如配置了 test 分支）

requirements-analyst:
  1. transition 主 Jira → "测试中"（或配置的目标状态）
  2. 搜索自动创建的子 Jira
  3. 填写提测说明（变更概述、涉及模块、测试要点）
  4. transition 子 Jira → "已完成"（或配置的完成状态）
```

**产出**: 分支已推送 + Jira 已更新 + 团队已清理

**Gate 6 通过标准**:
- 分支已推送
- deploy_branch 已合并（若配置了）
- Jira 已更新

---

## 4. 配置体系

### 三层配置架构

```
Layer 1: 全局索引
  ~/.claude/configs/projects.json
  → 项目路径 → 项目名称映射

Layer 2: 项目配置
  {root_path}/.claude/project-config.md
  → 完整项目信息（仓库、数据库、测试环境、构建命令）

Layer 3: 流程配置
  ~/.claude/skills/dev-flow/project-config.md
  → dev-flow 工作流配置（root_path、cloudId、分支命名、OpenSpec）
```

### 查找链

```
dev-flow/project-config.md → root_path
  → projects.json → 项目名
    → {root_path}/.claude/project-config.md → 完整配置

root_path 为空时: 自动从 projects.json 填充
```

### 关键配置项

```yaml
# dev-flow/project-config.md
root_path: ""                    # 留空则从 projects.json 自动填充
cloudId: ""                      # Atlassian Cloud ID（自动获取）
branch_naming:
  format: "{issue_key}"          # 分支命名规则（直接用 Jira key）
openspec:
  changes_path: "openspec/changes"   # 工作产出（proposal/design/tasks）
  baseline_path: "openspec/specs"    # 系统基线（可选，Phase 1 基线关联检查）

# project-config.md
databases:                       # 数据库连接（测试验证用）
  - name: main
    connection: "tenant-wd"
test_environments:               # 测试环境
  - url: "https://..."
    credentials: "..."
build_commands:                  # 构建命令
  backend: "php artisan"
  frontend: "pnpm build:backend"
deploy_branch: "test"            # 部署分支（可选）
jira_workflow:                   # Jira 工作流（可选）
  testing_status: "测试中"
  auto_creates_sub: true
  sub_completion_status: "已完成"
  testing_note_template: "..."
```

---

## 5. Superpowers 集成

每个 Phase 都引用一个 Superpowers 方法论技能。Agent 在执行时先 Read 对应的 SKILL.md 获取完整方法论。

| Phase | Superpowers Skill | 核心约束 |
|-------|------------------|---------|
| 1 需求分析 | brainstorming | 2-3 方案 + 权衡 + self-review |
| 2 任务规划 | writing-plans | 咬合粒度 + TDD 步骤 + 零占位符 |
| 3 TDD 开发 | TDD + executing-plans | RED→Verify→GREEN→Verify→REFACTOR |
| 4 代码评审 | requesting-code-review | git diff + 严重性分级 |
| 5 测试验证 | verification | 证据铁律: 命令→输出→结论 |
| 6 收尾 | finishing-a-branch | 完整测试→清理→推送 |
| 异常处理 | systematic-debugging | 先复现→定位根因→最小修复 |

---

## 6. 异常处理

### 统一重试上限

| 异常类型 | 自修复次数 | 超限处理 |
|---------|-----------|---------|
| 构建失败 | dev ≤2 次 | Leader 询问用户 |
| 测试 Bug | 循环 ≤3 次 | Leader 询问用户 |
| 需求/设计问题 | 修改后重 Gate ≤2 次 | Leader 询问是否终止 |
| Task 冲突 | planner 重排 ≤1 次 | Leader 决策串行化或 worktree |
| Agent 无响应 | 重发 1 次 | Leader 询问用户 |
| MCP 连接失败 | 重试 ≤2 次 | 保存 state，恢复后继续 |

### 超时检测

- Phase 1-2: Agent 5 分钟未回复 → Leader 发 ping
- Phase 3-5: Agent 10 分钟未回复 → Leader 发 ping
- ping 无响应 → Leader 询问用户: 等待 / 跳过 / 终止

---

## 7. 文件结构

```
~/.claude/skills/
├── dev-flow/
│   ├── skill.md                    ← 流程骨架
│   ├── gate.md                     ← Gate 机制（通过标准 + 摘要格式）
│   ├── phases/                     ← Phase 指令（按需加载）
│   │   ├── phase-1-brief.md        ← 需求分析
│   │   ├── phase-2-brief.md        ← 任务规划 + 分支
│   │   ├── phase-3-brief.md        ← TDD 开发
│   │   ├── phase-4-brief.md        ← 代码评审
│   │   ├── phase-5-brief.md        ← 测试验证
│   │   └── phase-6-brief.md        ← 收尾
│   ├── project-config.md           ← 流程配置
│   ├── project-config.example.md   ← 项目配置模板
│   ├── team-rules.md               ← 团队通信规则
│   └── resume.md                   ← 断点恢复逻辑
├── create-team/                    ← 团队创建
├── delete-team/                    ← 团队清理
├── git-ops/                        ← Git 操作
└── init-dev-flow/                 ← 一键初始化
```

**Lazy Loading 设计**: Leader 只在进入某个 Phase 时才 Read 对应的 phase-N-brief.md，减少上下文占用。

---

## 8. 快速开始

### 1. 安装依赖

确保以下已就绪：
- Claude Code CLI
- superpowers 插件 (v5.0+)
- 依赖 skills: create-team, delete-team, git-ops, init-dev-flow
- Agent 定义: 7 个 agent 在 `~/.claude/agents/`
- MCP: atlassian-rovo（必选）, mysql（可选）, playwright（可选）

### 2. 初始化

```
/init-dev-flow
```

一键初始化：自动检测技术栈、生成双份配置、注册项目、验证 MCP 连通性。

### 3. 运行

```
/dev-flow OA-3650
```

或：
```
/dev-flow https://your-domain.atlassian.net/browse/OA-3650
```

### 4. 交互

半自动模式下，每个 Gate 会展示摘要并等待确认：
- 确认 → 继续下一 Phase
- 修改 → Leader 转发修改指令
- 终止 → 清理团队，流程结束

---

## 9. FAQ

**Q: Leader 为什么不能直接执行操作？**
A: 关注点分离。Leader 只做协调和决策，所有执行由专门的 Agent 完成。这确保了每个操作都有明确的职责归属和审计链。

**Q: 如果 Agent 之间的任务有冲突怎么办？**
A: Leader 检测冲突后，会使用 worktree 隔离（为每个 Agent 创建独立工作树），避免文件冲突。

**Q: 可以在中途暂停吗？**
A: 可以。dev-flow 支持断点恢复，状态保存在 `{root_path}/.dev-flow/{issue_key}-state.json`。下次启动同一 Issue 会自动恢复。

**Q: 全自动模式安全吗？**
A: 全自动模式下，CRITICAL 和 HIGH 级别的问题仍然会升级到用户。Gate 质量检查仍然执行，只是跳过人工确认。超过重试上限也会升级到用户。

**Q: 如何为新项目配置 dev-flow？**
A: 运行 `/init-dev-flow`，一键自动检测技术栈、生成双份配置、验证 MCP。也可以手动创建 `project-config.md`（参考 `project-config.example.md`）。

**Q: Superpowers 技能怎么工作？**
A: 每个 Phase 引用特定的 superpowers 技能。Agent 收到 `[superpowers:xxx]` 标记后，会先 Read 对应的 SKILL.md 获取完整方法论，然后遵循其中的原则执行任务。dev-flow 的 Gate 机制替代了 superpowers 的交互式验证。
