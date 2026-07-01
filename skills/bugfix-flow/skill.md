---
name: bugfix-flow
description: Use when fixing bugs reported from test environment or found locally — lightweight 3-step flow for bug analysis, fix, and deploy. Supports both Jira-linked bugs and free-form descriptions.
version: 1.0.0
tags: [bugfix, workflow, grafana, jenkins]
dependencies:
  skills:
    - git-ops
  mcp_servers:
    - name: atlassian-rovo
      required: false
      note: "Required for Jira-linked bugs only"
    - name: grafana
      required: false
      note: "Required for test environment bug analysis"
    - name: jenkins
      required: false
      note: "Required for auto-deploy in Step 3"
  project_config: true
---

# Bugfix-Flow: Lightweight Bug Fix Workflow

**Input**: `$ARGUMENTS` (optional — Jira issue key, or bug description, or empty for full interactive)

Mode detection:
- Matches `^[A-Z]+-\d+$` or contains `/browse/` → **jira mode**
- Any other text → **free mode** (natural language bug description)
- Empty → **full interactive mode** (all info collected via AskUserQuestion)

## Overview

```
Pre-flight (interactive)   → 收集 bug 信息 + 定位分支 + 切换
Step 1: Bug Analysis       → Grafana 日志 + 代码定位 + 修复方案
Step 2: Fix + Verify       → TDD 修复 + 测试 + spec 追加
Step 3: Deploy             → commit + merge + Jenkins 部署 + Jira 更新
```

Each Step ends with a **Gate** — a checkpoint where the summary is presented for confirmation.

## Run Modes

| Behavior | Semi-Auto (default) | Full-Auto |
|----------|---------------------|-----------|
| Gate | Display summary + AskUserQuestion | Auto-pass, log summary |
| Exception | All prompt user | Only retry-exceeded prompt user |
| Grafana | Show logs + confirm analysis | Auto-analyze |
| Jenkins | Interactive parameter confirmation | Auto-deploy with defaults |

## Leader Constraints

> The Leader (main session) coordinates, makes decisions, and drives state transitions. Execution is delegated to agents via SendMessage.

**Allowed**: Read, SendMessage, TaskCreate/TaskUpdate, AskUserQuestion, Bash (git operations only)
**Allowed Write**: Only `{root_path}/.bugfix-flow/{bug_id}-state.json`
**Forbidden**: Write (business code), Edit, Atlassian MCP write operations (except Jira comment/status in Step 3)

## Step 0: Pre-flight (Interactive)

All user input is collected here before any execution begins.

### 0.1 Parse + Configure

1. **Mode detection** from `$ARGUMENTS`:
   - Matches `^[A-Z]+-\d+$` or contains `/browse/` → **jira mode**, extract issue key
   - Any other text → **free mode**, store as `bug_description`
   - Empty → **full interactive mode**

2. Read `{root_path}/.claude/project-config.md` → get:
   - `root_path`, `repo_path`, module paths, `deploy_branch`
   - `jenkins` config (if exists)
   - `git.branch_naming.format` (default: "{issue_key}")

3. If jira mode:
   - Read Jira issue via `mcp__atlassian-rovo__getJiraIssue`
   - If issue is a sub-task → extract parent issue key
   - Store: `issue_key`, `parent_key`, `jira_summary`, `jira_description`

### 0.2 Collect Bug Context (AskUserQuestion)

**Q1: Bug Description**

- jira mode: Show Jira title + description. Ask: "以上是 Jira 中的 bug 描述，是否需要补充？" + free text field
- free mode / full interactive: Ask: "请描述 bug 的表现、复现步骤和预期行为"

Save response as `bug_description`.

**Q2: Environment Source**

Ask: "这个 bug 是哪里发现的？"
- Option A: 测试环境 (Step 1 会查 Grafana 日志)
- Option B: 本地开发环境 (跳过 Grafana)

Save as `env_source`: "test" | "local".

**Q3: Trace ID (conditional)**

Only if env_source == "test": "是否有关联的 trace_id 或 request_id？（没有可跳过）"
- Save as `trace_id` (may be empty)

**Q4: Confirm Branch (多仓库感知)**

Branch lookup priority:
1. **jira mode + parent issue** → Read `{root_path}/.jira-flow/{parent_key}-state.json` → get `branch` field
2. **jira mode + no state file** → Derive branch name from parent_key using `branch_naming.format`
3. **free mode / full interactive** → List all active branches across repos, let user choose

After finding branch name, scan ALL repos in project-config:
```
For each repo_path:
  git -C {repo_path} branch --list {branch_name}
  → exists → include in checkout list
  → missing → skip
```

Present result to user:
```
分支 {branch_name} 存在于以下仓库:
  ✓ oa-service
  ✓ oa-frontend
  ✗ oa-platform-php (分支不存在，跳过)

确认在以上仓库切换到 {branch_name}？
```

Save as `repos_to_fix`: list of `{repo_path, branch}` objects.

**Q5: Run Mode**

Ask: "选择运行模式"
- Option A: semi-auto (recommended) — 每个 Step 结束后确认
- Option B: full-auto — 自动执行，异常才提示

Save as `run_mode`: "semi-auto" | "full-auto".

### 0.3 Execute Branch Switch

Delegate to **backend-developer**: invoke `/git-ops` with "更新分支 {branch}" for each repo in `repos_to_fix`.

`/git-ops` handles stash safety, checkout, pull, and conflict detection automatically. Leader provides the repo list so the agent does not need to select repos interactively.

### 0.4 Initialize State

Write `{root_path}/.bugfix-flow/{bug_id}-state.json`:

```json
{
  "bug_id": "<slug or issue_key>",
  "flow_mode": "jira | free",
  "run_mode": "semi-auto | full-auto",
  "env_source": "test | local",
  "bug_description": "<description>",
  "trace_id": "<trace_id or null>",
  "issue_key": "<jira key or null>",
  "parent_key": "<parent jira key or null>",
  "branch": "<branch_name>",
  "repos_to_fix": [{"path": "...", "branch": "..."}],
  "current_step": 0,
  "step_results": {},
  "created_at": "<ISO>"
}
```

`bug_id` generation:
- jira mode → issue_key
- free mode → slug from first 30 chars of description (lowercase, spaces→`-`, strip special chars)

### 0.5 Final Confirmation

Present summary:
```
## Bugfix-Flow 准备就绪

Bug: {bug_description}
来源: 测试环境 / 本地
分支: {branch} ({repos with this branch})
模式: {run_mode}

即将执行:
  Step 1: Bug 分析（Grafana 日志 + 代码定位）
  Step 2: 修复 + 测试
  Step 3: 部署（commit + merge + Jenkins + Jira 更新）
```

Confirm → proceed to Step 1.

---

## Step Summary

> When entering a Step, Read `steps/step-N-brief.md`.
> **Universal rule**: on every agent completion, Leader updates `step_results[N]` in state.json.

| Step | Output | Gate |
|------|--------|------|
| 1 Bug Analysis | root cause + fix proposal | Confirm fix approach |
| 2 Fix + Verify | implementation code + test results | Confirm diff + tests |
| 3 Deploy | commit + merge + Jenkins + Jira update | Confirm deployment |

---

## Gate Mechanism

After each Step:

1. **Collect**: Aggregate agent reports
2. **Persist**: Write to state.json → `step_results[current_step]`
3. **Present**:
   - Semi-auto: Display summary via AskUserQuestion → user confirms/adjusts/aborts
   - Full-auto: Auto-pass, log summary
4. **Advance**: `current_step++`

---

## Exception Handling

| Exception | Auto-Fix | Escalation |
|-----------|----------|------------|
| Test failure after fix | Dev self-fixes ≤2 times | Ask user |
| Jenkins build failure | Retry ≤2 times | Ask user (retry/skip/abort) |
| Grafana MCP unavailable | Skip log analysis, note in report | Continue without logs |
| Agent unresponsive | Ping 1 time, wait 5 min | Ask user |
| Branch not found in any repo | N/A | Ask user to select manually |
| Merge conflict during deploy_branch merge | N/A | Stop, prompt user to resolve manually |
