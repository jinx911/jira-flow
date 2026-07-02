# Step 3：部署

> 目标：一个 bug 一个 commit + push，合并 deploy 分支，Jenkins 部署，更新 Jira。

## 前置
- Gate 2 已过，修复确认，测试通过
- 所有改动未提交在工作树

## 1. 单 commit + push（每仓库）

委托 backend-developer：调 `/git-ops` 提交并推送。

**一个 bug 一个 commit**（每仓库一个 commit，含本次修复全部改动）。commit message（中文）：
```
fix(<scope>): <一句话修复概述>

<1-3 行说明>

Refs {issue_key 或 bug_id}
```
`/git-ops` 处理：扫变更、展示清单确认、`git add <具体文件>`（不用 -A）、commit、push origin/{branch}、分支保护、stash 安全。
Leader 收集每仓库 commit SHA。

## 2. 合并到 deploy 分支

> 仅配置了 `deploy_branch` 才做，否则跳过。

委托 backend-developer：`/git-ops` 合并 `{branch} → {deploy_branch}`。`/git-ops` 处理分支保护/方向校验、stash、`checkout deploy → pull → merge → push → checkout 回`、冲突即停。冲突 → 停，用户手解。

## 3. Jenkins 部署（交互）

> 仅 `jenkins` 配置 + Jenkins MCP 都在才做，否则静默跳过。

### 3a 任务选择
单任务（`jenkins.job_name`）直接用；多任务（`jenkins.jobs`）AskUserQuestion 让用户选（按改动仓库勾选服务）。存 `jobs_to_deploy`。

### 3b 参数确认（每任务）
`jenkins_get_job` 取参数定义 → 合并 `default_params` + `branch_param=branch_value`（通常 test）→ 跳过密码参数。AskUserQuestion 确认/改/跳。

### 3c 触发构建
`jenkins_build_and_watch`（poll_interval 15、timeout_seconds 600）。

### 3d 结果处理
成功 → 记 build 号；失败 → `jenkins_get_build_log` 取日志，AskUserQuestion 重试(≤2)/跳过/中止。

### 3e 部署摘要
```
| 任务 | Build# | 结果 | 耗时 |
|---|---|---|---|
```

## 4. Jira 更新（仅 jira 模式）

> 仅 `issue_key` 非空执行；free 模式跳过。

### 4a 加修复评论
`addCommentToJiraIssue`：根因 / 修复 / 改动文件 / 测试全过 / 部署（deploy_branch + Jenkins build 号）/ 分支。

### 4b 流转状态（子任务时）
子任务：`getTransitionsForJiraIssue` → 找完成流转 → `transitionJiraIssue` 到 Done。普通 issue 不流转，仅评论。

## Gate 3

Semi-auto：AskUserQuestion 展示最终摘要（bug / 根因 / 各仓库 commit SHA / 部署 / Jira）+ "分支 {branch} 可建 MR（MR 手动创建）"。确认 → 删 state 文件。Full-auto：记录自动完成。
更新 state：`current_step=3`，`step_results.3={commits, deploy_results, jira_updated}`。
Gate 3 通过 → 删 `{root_path}/.bugfix-flow/{bug_id}-state.json`。
