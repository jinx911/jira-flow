---
name: bugfix-flow
description: 修复测试环境或本地发现的 bug 时使用——轻量 3 步流程（bug 分析 → 修复+验证 → 部署）。支持 Jira 关联 bug 和自由描述。可独立调用。
---

# Bugfix-Flow：轻量 Bug 修复流程

**输入**：`$ARGUMENTS`（可选——Jira issue key、或 bug 描述、或空=全交互）

模式：匹配 `^[A-Z]+-\d+$` 或含 `/browse/` → **jira 模式**；其它文本 → **free 模式**；空 → **全交互模式**。

## 概览

```
Step 0 预检（交互）  → 收集 bug 信息 + 定位分支 + 切换（细节见 references/pre-flight.md）
Step 1 Bug 分析      → Grafana 日志 + 代码定位 + 修复方案
Step 2 修复 + 验证   → 回归优先修复 + 按栈测试 + 质量契约
Step 3 部署          → 单 commit + merge + Jenkins + Jira
```

每个 Step 结束有 **Gate**（展示摘要待确认）。

## 运行模式

| 行为 | Semi-auto（默认） | Full-auto |
|---|---|---|
| Gate | 展示摘要 + AskUserQuestion | 自动放行，记录 |
| 异常 | 都问用户 | 仅超限问 |
| Grafana | 展示日志 + 确认分析 | 自动分析 |
| Jenkins | 交互确认参数 | 默认自动部署 |

## Leader 约束

Leader（主会话）只协调/决策/驱动状态，执行委托 agent。

**允许**：Read、SendMessage、TaskCreate/TaskUpdate、AskUserQuestion、Bash（仅 git 操作）
**只可写**：`{root_path}/.bugfix-flow/{bug_id}-state.json`
**禁止**：写业务代码、Edit、Atlassian MCP 写（除 Step 3 的 Jira 评论/状态）

## 工具使用

你已安装的全部 skill / agent 都可用，主动调用：
- 查日志 → grafana（Loki）
- 查代码 → codegraph / code-explorer / repo-scan
- 简化去冗余 → simplify / code-simplifier
- 测试覆盖 → test-coverage
- 各栈规范 → 对应 *-coding-standards / *-reviewer
未装时降级。

## Step 概要

进入每步前 Read `steps/step-N-brief.md`（Step 0 读 `references/pre-flight.md`）。每完成一个 agent，Leader 更新 `step_results[N]`。

| Step | 产出 | Gate |
|---|---|---|
| 0 预检 | bug 上下文 + 分支切换 + state | 确认开干 |
| 1 Bug 分析 | 根因 + 修复方案 | 确认修复方案 |
| 2 修复 + 验证 | 代码 + 测试结果 | 确认 diff + 测试 |
| 3 部署 | 单 commit + merge + Jenkins + Jira | 确认部署 |

## Gate 机制

每步后：收集 → 写 `step_results[current_step]` → 展示（semi-auto 确认 / full-auto 自动）→ `current_step++`。

## 异常处理

| 异常 | 自修复 | 升级 |
|---|---|---|
| 修复后测试失败 | dev 自修 ≤2 | 问用户 |
| Jenkins 构建失败 | 重试 ≤2 | 问用户（重试/跳过/中止） |
| Grafana MCP 不可用 | 跳过日志分析，报告注明 | 无日志继续 |
| Agent 无响应 | ping 1 次，等 5 分钟 | 问用户 |
| 任何 repo 无分支 | — | 问用户手选 |
| deploy_branch merge 冲突 | — | 停止，用户手解 |

## Dependencies

- **Skills**：git-ops
- **MCP**：atlassian-rovo（jira 模式）、grafana（测试环境分析）、jenkins（Step 3 部署）——均可选
- **project_config**：是（读 `{root_path}/.claude/project-config.md`）
