[English](README.md) | **中文**

# Jira-Flow: 全链路 Agent Team 开发工作流

一个 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill，通过编排多 Agent 团队，从 Jira Issue 出发完成完整开发生命周期：需求分析、架构设计、任务规划、TDD 开发、代码评审、测试验证、代码提交。

```
Jira Issue → 6 个 Phase + 6 个 Gate → 分支推送 + Jira 状态更新

Phase 1: 需求分析         → proposal.md + design.md
Phase 2: 任务规划 + 分支  → tasks.md + git branch
Phase 3: TDD 开发         → 实现代码
Phase 4: 代码评审         → 结构化评审报告
Phase 5: 测试验证         → 基于证据的测试报告
Phase 6: 收尾             → commit + Jira 更新
```

每个 Phase 结束后经过一个 **Gate**（关卡）— Leader 会汇总该 Phase 产出，等待你确认后才进入下一步。两种运行模式：**半自动**（默认，每个 Gate 需确认）或 **全自动**（Gate 自动通过，仅异常时暂停）。

## 核心架构

- **Leader**（你的主 Claude 会话）只协调、决策、路由 — 永不直接执行
- **Hub-and-Spoke** 通信：所有 Agent 消息经过 Leader 中转
- **7 个专职 Agent** 按需动态创建
- **Superpowers 方法论** 集成在每个 Phase（TDD、代码评审、调试等）

## 前置条件

| 依赖 | 版本 | 安装方式 |
|------|------|---------|
| **Claude Code CLI** | 最新版 | [官方文档](https://docs.anthropic.com/en/docs/claude-code) |
| **superpowers** 插件 | >= 5.0.0 | [superpowers 仓库](https://github.com/nicekid1/superpowers) — 提供 8 个方法论 skill（TDD、brainstorming、调试等） |
| **atlassian-rovo** MCP | 任意版本 | 在 `~/.claude/settings.json` → `mcpServers` 中配置 — [MCP 快速开始](https://docs.anthropic.com/en/docs/claude-code/mcp) |
| **playwright** MCP | 任意版本（可选） | 用于 Phase 5 的 E2E 测试 |

### Agent 定义

本仓库包含 21 个 Agent 定义。jira-flow 核心使用 7 个：

| Agent | Phase | 职责 |
|-------|-------|------|
| `requirements-analyst` | 1, 6 | 读取 Jira Issue，生成 OpenSpec proposal，处理 Jira 收尾 |
| `architect` | 1 | 生成 design.md，包含架构决策 |
| `planner` | 2 | 将设计拆分为可执行的 TDD 任务 |
| `backend-developer` | 2, 3, 6 | 创建分支，实现后端代码 |
| `frontend-developer` | 3, 6 | 实现前端代码（设计涉及前端时创建） |
| `code-reviewer` | 4 | 评审分支所有变更，输出分级报告 |
| `tester` | 5 | 运行单元/集成/E2E 测试，报告 Bug |

其余 Agent（各语言 reviewer、优化器等）可在 jira-flow 之外独立使用。

## 安装

```bash
# 1. 克隆
git clone https://github.com/jinx911/jira-flow.git
cd jira-flow

# 2. 安装（符号链接 skills + agents 到 ~/.claude/）
chmod +x install.sh
./install.sh

# 3. 验证
ls ~/.claude/skills/jira-flow/      # 应显示 skill.md, phases/ 等
ls ~/.claude/agents/requirements-analyst.md  # 应存在
```

### 卸载

```bash
./uninstall.sh
```

仅移除符号链接，克隆的仓库保留。

## 快速开始

### 第 1 步：初始化项目

```
/init-jira-flow
```

一键设置 — 自动检测技术栈，生成配置文件（流程配置 + 项目配置），注册项目，验证 MCP 连通性。

或手动操作：将 `skills/jira-flow/project-config.example.md` 复制到 `<your-project>/.claude/project-config.md`，填写实际值。

### 第 2 步：运行 jira-flow

```
/jira-flow OA-3650
```

或使用完整 URL：

```
/jira-flow https://your-domain.atlassian.net/browse/OA-3650
```

### 第 3 步：审核 Gate 并迭代

Leader 会在每个 Gate 展示汇总信息。半自动模式（默认）需你确认后继续；全自动模式 Gate 自动通过，仅异常时暂停。

## 配置

```
~/.claude/configs/projects.json                  ← 全局索引（路径 → 项目名映射）
<project-root>/.claude/project-config.md         ← 项目配置（仓库、数据库、环境）
~/.claude/skills/jira-flow/project-config.md     ← 流程配置（root_path、cloudId、分支命名）
```

查找链：
1. 读取 `jira-flow/project-config.md` → 获取 `root_path`
2. 读取 `projects.json` → 匹配 `root_path` → 获取项目名
3. 读取 `{root_path}/.claude/project-config.md` → 获取完整项目配置

详见 [`skills/jira-flow/project-config.example.md`](skills/jira-flow/project-config.example.md)。

## 文件结构

```
jira-flow/
├── README.md                     ← English overview
├── README.zh-CN.md               ← 中文概览（本文件）
├── LICENSE                       ← MIT
├── CONTRIBUTING.md               ← 贡献指南 (EN)
├── CONTRIBUTING.zh-CN.md         ← 贡献指南 (中文)
├── install.sh                    ← 一键安装
├── uninstall.sh                  ← 清理卸载
├── skills/
│   ├── jira-flow/                ← 主 skill（6 阶段生命周期）
│   │   ├── skill.md              ← 流程骨架 + 初始化
│   │   ├── gate.md               ← Gate 机制 + 通过标准
│   │   ├── phases/               ← Phase 指令（按需加载）
│   │   │   ├── phase-1-brief.md  ← 需求分析
│   │   │   ├── phase-2-brief.md  ← 任务规划 + 分支创建
│   │   │   ├── phase-3-brief.md  ← TDD 开发
│   │   │   ├── phase-4-brief.md  ← 代码评审
│   │   │   ├── phase-5-brief.md  ← 测试验证
│   │   │   └── phase-6-brief.md  ← 收尾
│   │   ├── team-rules.md         ← 团队通信规则
│   │   ├── resume.md             ← 断点恢复逻辑
│   │   └── project-config.example.md  ← 配置模板
│   ├── init-jira-flow/           ← 项目初始化 skill
│   ├── create-team/              ← 团队创建（Hub-and-Spoke）
│   ├── delete-team/              ← 团队清理
│   └── git-ops/                  ← 多仓库 Git 操作
└── agents/                       ← 21 个 Agent 定义
```

## 依赖关系

| 类型 | 必须 | 说明 |
|------|------|------|
| **Skills** | create-team, delete-team, git-ops, init-jira-flow | 本仓库已包含 |
| **插件** | superpowers >= 5.0.0 | 8 个方法论 skill |
| **Agents** | 7 个核心（共 21 个） | 由 `install.sh` 安装 |
| **MCP** | atlassian-rovo | Jira/Confluence 操作 |
| **MCP** | playwright | 可选，用于 E2E 测试 |
| **MCP** | mysql/postgres | 可选，用于数据库验证 |

## Superpowers 集成

每个 Phase 引用一个 superpowers skill，Agent 运行时读取完整 skill 内容：

| Phase | Skill | 核心约束 |
|-------|-------|---------|
| 1 | brainstorming | 2-3 个方案 + 权衡对比 + 自我评审 |
| 2 | writing-plans | 可执行的任务 + TDD 步骤 + 零占位符 |
| 3 | test-driven-development + executing-plans | RED → 验证 → GREEN → 验证 → REFACTOR |
| 4 | requesting-code-review | git diff 结构化评审 + 严重级别 |
| 5 | verification-before-completion | 证据优先：命令 → 输出 → 结论 |
| 6 | finishing-a-development-branch | 全量测试 → 清理调试代码 → 推送 |

## 异常处理

| 异常类型 | 自动修复上限 | 超限处理 |
|---------|-------------|---------|
| 构建失败 | 2 次自修复 | 询问用户 |
| 测试 Bug 修复循环 | 3 次 tester→dev | 询问用户 |
| 需求/设计问题 | 2 次重 Gate | 询问用户是否终止 |
| 任务冲突 | 1 次重排 | Leader 决策串行化或 worktree |
| Agent 无响应 | 1 次 ping | 询问用户 |
| MCP 连接断开 | 2 次重试 | 保存状态，提示恢复后继续 |

所有异常超过上限 → 必须升级到用户，不继续自动重试。

## 核心原则

- **Leader 永不执行** — 只协调、决策、路由
- **Hub-and-Spoke 通信** — 所有 Agent 消息经过 Leader
- **Gate 关卡** — 每个 Phase 结束后等待用户确认
- **基于证据的验证** — 没有证据不认结论
- **断点恢复** — 每个 Phase 后保存状态，随时可恢复

## 许可证

[MIT](LICENSE)
