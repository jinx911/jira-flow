# Step 0：预检（交互式）

所有用户输入在此收集完毕后再开始执行。SKILL.md 只放骨架，本文件放 Step 0 细节。

## 0.1 解析 + 配置

1. 从 `$ARGUMENTS` 判断模式：
   - 匹配 `^[A-Z]+-\d+$` 或含 `/browse/` → **jira 模式**，取 issue key
   - 其它文本 → **free 模式**，存为 `bug_description`
   - 空 → **全交互模式**
2. 读 `{root_path}/.claude/project-config.md` → `root_path`、`repo_path`、模块路径、`deploy_branch`、`jenkins`、`git.branch_naming`
3. jira 模式：`mcp__atlassian-rovo__getJiraIssue` 读 issue；若是子任务 → 提取父 issue key。存 `issue_key`、`parent_key`、`jira_summary`、`jira_description`

## 0.2 收集 bug 上下文（AskUserQuestion）

- **Q1 bug 描述**：jira 模式展示标题+描述问是否补充；free/交互式问"表现+复现+预期"。存 `bug_description`
- **Q2 来源**：测试环境（Step1 查 Grafana）/ 本地（跳过 Grafana）。存 `env_source`
- **Q3 trace_id**（仅 test）：关联 trace_id/request_id？可空。存 `trace_id`
- **Q4 确认分支（多仓库感知）**：
  - 查找优先：jira+父 issue → 读 `{root_path}/.dev-flow/{parent_key}-state.json` 取 `branch`；jira 无 state → 按父 key 推；free/交互 → 列活跃分支让用户选
  - 扫描所有 repo：`git -C {repo} branch --list {branch}`，存在则纳入切换列表
  - 展示结果让用户确认；存 `repos_to_fix`：`[{path, branch}]`
  - 注：bugfix 通常在 bug 所在的**现有分支**上修；仅 free 模式无现有分支时新建 `fix/{bug_id}`
- **Q5 运行模式**：semi-auto（推荐）/ full-auto。存 `run_mode`

## 0.3 执行分支切换

委托 backend-developer：对 `repos_to_fix` 每个 repo 调 `/git-ops` "更新分支 {branch}"。`/git-ops` 处理 stash 安全、checkout、pull、冲突检测。Leader 提供 repo 列表，agent 无需交互选 repo。

## 0.4 初始化 state

写 `{root_path}/.bugfix-flow/{bug_id}-state.json`：

```json
{
  "bug_id": "<slug 或 issue_key>",
  "flow_mode": "jira | free",
  "run_mode": "semi-auto | full-auto",
  "env_source": "test | local",
  "bug_description": "<描述>",
  "trace_id": "<trace_id 或 null>",
  "issue_key": "<jira key 或 null>",
  "parent_key": "<父 jira key 或 null>",
  "branch": "<分支名>",
  "repos_to_fix": [{"path": "...", "branch": "..."}],
  "current_step": 0,
  "step_results": {},
  "created_at": "<ISO>"
}
```

`bug_id` 生成：jira→issue_key；free→描述前 30 字 slug（lowercase、空格→`-`、去特殊字符）。

## 0.5 最终确认

展示摘要（bug / 来源 / 分支 / 模式 + 即将执行的 Step 1-3），用户确认 → 进 Step 1。
