[English](README.md) | **中文**

# Dev-Flow: 全链路 Agent Team 开发工作流

一个 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill，通过编排多 Agent 团队完成完整开发生命周期 —— 从 Jira Issue **或** 自然语言需求出发，经四个可复用子 skill：需求、开发、审查测试、收尾。

```
需求（Jira key 或文本）→ 4 个 Stage + 4 个 Gate → 分支推送 + Jira 状态更新

Stage 1: 需求     (spec-author)   → proposal.md + design.md（自适应工程章节）
Stage 2: 开发     (dev-loop)      → tasks.md + 分支 + 实现（条件化 TDD）
Stage 3: 审查测试 (review-test)   → 审查 + 验证 + 修复环
Stage 4: 收尾     (ship)          → 推送 + 部署 + Jira 收尾
```

每个 Stage 结束经过一个 **Gate**（Leader 呈现 checklist 等你确认）。两种模式：**半自动**（默认，每个 Gate 需确认）或 **全自动**（Gate 自动通过，仅异常时暂停）。

## 核心架构

- **Leader**（你的主 Claude 会话）只协调、决策、路由 —— 永不直接执行（保持上下文干净）
- **薄编排器 + 4 个子 skill**：每个阶段都是可独立调用的 skill（`/spec-author`、`/review-test`、`/ship` 可单独跑）
- **Hub-and-Spoke** 通信：所有 Agent 消息经过 Leader 中转
- **角色专长内嵌在子 skill** —— dev-flow **不依赖** `~/.claude/agents/*.md`
- **活文档**：开发中发现需求变更，先改文档再改代码（spec-delta）
- **条件化 TDD**：只有含可测逻辑的工作才用 TDD；脚手架/配置跳过

## 相比旧 jira-flow 的变化

| 旧（jira-flow，6 阶段） | 新（dev-flow，4 阶段） |
|---|---|
| 双重自评 rubric | 结构化文档模板 + checklist Gate（不自评打分） |
| Phase 1-2 文档冻结 | 活文档（文档优先变更协议） |
| 处处 TDD | 条件化 TDD（按单元测试策略） |
| 每次 spawn 走 6 步 Prompt Build | 预生成 prompt 文件；spawn = 读文件 + `Agent()` |
| ack / `[URGENT-NOACK]` / 3 级健康探测 | TaskList 为唯一事实源；一次 ping → 问用户 |
| 依赖 agent 定义文件 | 解耦；角色专长内嵌子 skill |

## 代码质量与工具（v2）

- **主动调度工具箱**：子 agent 像正常会话一样主动调用已装 skill（`/simplify`、`/code-review`、`/security-review`、`/test-coverage`、`/build-fix`、各栈 reviewer、UI 类…）——新装工具自动接入，dev-flow 零改动。
- **强制质量契约**（dev-loop）：GREEN 后必做去冗余 + 可读性 pass；`/test-coverage` ≥80%；函数<50 行、文件<800 行、注释写"为什么"。
- **风格权威**：非 Java 跟仓库现有风格；**Java 按市场主流 + `java-coding-standards` agent，不沿用历史**；各栈 `*-coding-standards` agent 为最终权威。
- **分支**：`{type}/{issue_key}`（如 `feat/OA-3650`、`fix/OA-3650`）。
- **提交**：开发期不 commit，ship 时**一个需求一个大 commit**（中文 message + Issue 号）。
- **文档**：每需求归并到 `.dev-flow/{issue_key}/spec/`，全中文。

## 前置条件

| 依赖 | 版本 | 安装方式 |
|------|------|---------|
| **Claude Code CLI** | 最新版 | [官方文档](https://docs.anthropic.com/en/docs/claude-code) |
| **superpowers** 插件 | >= 5.0.0 | [superpowers 仓库](https://github.com/nicekid1/superpowers) |
| **atlassian-rovo** MCP | 任意版本 | jira 模式必需；free-flow 模式不需要 |
| **jenkins** MCP | 任意版本（可选） | 用于 Stage 4 自动部署 |
| **playwright** MCP | 任意版本（可选） | 用于 Stage 3 的 E2E 测试 |

### Agent 定义（可选）

本仓库包含 Agent 定义，但 **dev-flow 不读取它们** —— 角色专长内嵌在每个子 skill 中。它们仍可在 dev-flow 之外独立使用。

## 安装

```bash
# 1. 克隆
git clone https://github.com/jinx911/dev-flow.git
cd dev-flow

# 2. 安装（符号链接 skills 到 ~/.claude/）
chmod +x install.sh
./install.sh

# 3. 验证
ls ~/.claude/skills/dev-flow/        # 应显示 SKILL.md, gate.md, ...
ls ~/.claude/skills/spec-author/     # 4 个子 skill 都在
```

### 卸载

```bash
./uninstall.sh
```

仅移除符号链接，克隆的仓库保留。

## 快速开始

### 第 1 步：初始化项目

```
/init-dev-flow
```

一键设置 —— 自动检测技术栈，生成配置文件，注册项目，验证连通性。

或手动操作：将 `skills/dev-flow/project-config.example.md` 复制到 `<your-project>/.claude/project-config.md`，填写实际值。

### 第 2 步：运行 dev-flow

**jira 模式**（需 Jira Issue key）：

```
/dev-flow OA-3650
```

**free-flow 模式**（无需 Jira 单）：

```
/dev-flow 给用户管理增加 CSV 导出功能
```

free-flow 模式跳过依赖 Jira 的步骤（Jira 收尾），直接用你的自然语言描述作为需求来源。

### 第 3 步：审核 Gate 并迭代

Leader 会在每个 Gate 呈现 checklist 汇总。半自动模式（默认）需你确认后继续；全自动模式 Gate 自动通过，仅异常时暂停。

## 配置

```
~/.claude/configs/projects.json                  ← 全局索引（路径 → 项目名映射）
<project-root>/.claude/project-config.md         ← 项目配置（仓库、数据库、环境）
~/.claude/skills/dev-flow/project-config.md      ← 流程配置（root_path、cloudId、分支命名）
```

查找链：
1. 读取 `dev-flow/project-config.md` → 获取 `root_path`
2. 读取 `projects.json` → 匹配 `root_path` → 获取项目名
3. 读取 `{root_path}/.claude/project-config.md` → 获取完整项目配置

详见 [`skills/dev-flow/project-config.example.md`](skills/dev-flow/project-config.example.md)。

## 文件结构

```
dev-flow/
├── skills/
│   ├── dev-flow/                ← 薄编排器（Leader playbook）
│   │   ├── SKILL.md             ← 阶段、Gate、委托、state
│   │   ├── gate.md              ← checklist Gate 定义
│   │   ├── team-rules.md        ← 瘦身通信规则 + Health
│   │   ├── resume.md            ← 断点恢复
│   │   └── project-config.example.md
│   ├── spec-author/             ← Stage 1：需求 → proposal + design
│   │   ├── SKILL.md
│   │   ├── triggers.md          ← 触发条件 → 必填工程章节
│   │   └── templates/           ← proposal / design 模板
│   ├── dev-loop/                ← Stage 2：tasks + 分支 + TDD + 文档优先变更
│   │   ├── SKILL.md
│   │   └── doc-first-change.md
│   ├── review-test/             ← Stage 3：审查 + 验证 + 修复环
│   │   └── SKILL.md
│   ├── ship/                    ← Stage 4：收尾 + 部署 + Jira
│   │   └── SKILL.md
│   ├── learn/                   ← 学习闭环：capture/apply/distill（自我成长）
│   │   └── SKILL.md
│   ├── init-dev-flow/           ← 项目初始化
│   ├── create-team/             ← 团队创建（Hub-and-Spoke）
│   ├── delete-team/             ← 团队清理
│   └── git-ops/                 ← 多仓库 Git 操作
└── agents/                      ← 可选 Agent 定义（dev-flow 不读取）
```

## 依赖关系

| 类型 | 必须 | 说明 |
|------|------|------|
| **Skills** | create-team, delete-team, git-ops, init-dev-flow, spec-author, dev-loop, review-test, ship | 本仓库已包含 |
| **插件** | superpowers >= 5.0.0 | 方法论 skill |
| **Agents** | 无必需 | 角色专长内嵌子 skill；bundled agents 可选 |
| **MCP** | atlassian-rovo | Jira/Confluence 操作（jira 模式） |
| **MCP** | jenkins, playwright | 可选（部署 / E2E） |
| **MCP** | mysql/postgres | 可选（数据库验证） |

## Superpowers 集成

每个子 skill 引用一个 superpowers skill，运行时加载：

| Stage | 子 skill | Skill |
|---|---|---|
| 1 | spec-author | brainstorming |
| 2 | dev-loop | test-driven-development + executing-plans |
| 3 | review-test | requesting-code-review + verification-before-completion |
| 4 | ship | finishing-a-development-branch |

## 异常处理

| 异常类型 | 自动修复上限 | 超限处理 |
|---------|-------------|---------|
| 构建失败 | 2 次自修复 | 询问用户 |
| 测试 Bug 修复循环 | 3 次 | 询问用户 |
| 需求/设计修订（spec-delta） | 2 次 | 询问用户是否终止 |
| 任务冲突 | 1 次重排 | Leader 决策串行化或 worktree |
| Agent 无响应 | 1 次 ping | 询问用户 |
| MCP 连接断开 | 2 次重试 | 保存状态，提示恢复后继续 |

所有异常超过上限 → 必须升级到用户，不继续自动重试。

## 核心原则

- **Leader 永不执行** —— 只协调、决策、路由（上下文保持干净）
- **Hub-and-Spoke 通信** —— 所有 Agent 消息经过 Leader
- **checklist Gate** —— 每个 Stage 结束等待用户确认
- **活文档** —— spec-delta 先改文档再改代码
- **条件化 TDD** —— 只有含可测逻辑的工作才用 TDD
- **基于证据的验证** —— 没有证据不认结论
- **断点恢复** —— 每个 Stage 后保存状态，随时可恢复
