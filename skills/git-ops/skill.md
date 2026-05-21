---
name: git-ops
description: Use when user wants to perform git operations — creating branches, committing code, pushing, updating branches, merging, or cleaning up branches. Supports single-repo and multi-repo architectures via project-config.
---

# Git Ops: Multi-Repo / Single-Repo Git Operations

**Input**: `$ARGUMENTS` (optional: module name, branch name, etc.)

## Initialization

1. Read project configuration:
   - `<root_path>/.claude/project-config.md` (single source of truth)
   - Not found → prompt user to initialize project config first (`/init-project` or `/init-jira-flow`)
2. Extract from config:
   - `root_path` — project root directory
   - `git.main_branch` — main branch name (default `main`)
   - `git.commit_format` — commit message format (default `<type>: <description>`)
   - `git.branch_naming.format` — branch naming format (default `{type}/{description}`)
   - `modules` — module list (present = multi-repo, absent = single-repo)
   - `backend.main_repo` — backend main repo path
   - `frontend.repo` — frontend repo path (optional)
3. Config not found → prompt user to initialize project config first (`/init-project` or `/init-jira-flow`)

## Architecture Detection

```
Has modules list → multi-repo:
  Build repo list: [main_repo] + modules + [frontend_repo]
  Branch/push/merge/cleanup operations: show interactive selection
  Commit operations: auto-scan repos with changes

No modules → single-repo:
  Repo list: [root_path]
  All operations execute directly, skip repo selection
```

## Trigger Words

| Trigger | Operation |
|---------|-----------|
| "create branch" / "start feature" | Create branch |
| "update branch" / "rebase" | Update branch |
| "commit" / "提交" | Commit code |
| "push" / "推送" | Push to remote |
| "complete feature" / "merge branch" | Merge into main branch |
| "clean branch" / "delete branch" | Clean up branches |

## Repo Selection (multi-repo only)

Before branch/push/merge/cleanup operations, list repos for user selection:

```
Backend:
  [1] {main_repo_name} (main repo)   [2] {module_1}   [3] {module_2} ...
Frontend:
  [N] {frontend_repo_name}

Select (comma-separated numbers, or all):
```

**Exception for commit operations**: auto-scan repos with changes; no pre-selection needed.

## Workflows

### Create Branch

1. Parse branch name:
   - `$ARGUMENTS` provides branch name → use directly
   - Otherwise → generate using `git.branch_naming.format` (confirm interactively)
2. **multi-repo**: list repos, user selects
3. For each selected repo: `git -C <path> fetch origin && git -C <path> checkout {main_branch} && git -C <path> pull origin {main_branch} && git -C <path> checkout -b {branch}`
   **single-repo**: execute directly in root_path
4. Display results summary

**Exceptions**: uncommitted changes → skip and notify; branch already exists → ask whether to switch.

### Update Branch

1. **multi-repo**: detect active branch in each repo, user selects repos
   **single-repo**: detect current branch
2. Ask for strategy: merge (default, safe) or rebase (linear history; use with caution on pushed branches)
3. For each repo: `git -C <path> fetch origin` → execute merge or rebase
4. **Stop immediately on conflict**, list conflicting files for user to resolve manually

### Commit Code

1. Scan for changes:
   - **multi-repo**: iterate all repos with `git -C <path> status --short` + `git -C <path> diff --stat`
   - **single-repo**: run `git status --short` + `git diff --stat` in root_path
   - When a module is specified, only scan matching repos
2. Analyze `git diff` content
3. Generate commit message using `git.commit_format`
   - Default: `<type>: <description>`
   - If format includes `<scope>`: extract module name from changed file paths (use repo name for multi-repo, directory name for single-repo)
4. Show changed files + commit message, **wait for user confirmation**
5. `git add <specific files>` + `git commit` (do not use `git add -A`)

### Push to Remote

1. **multi-repo**: detect current branch and unpushed commit count for each repo, user selects
   **single-repo**: detect current branch and unpushed commits
2. No upstream → `git push -u origin {branch}`; has upstream → `git push`
3. Display results

### Complete Requirement (Merge into Main Branch)

1. Detect current branch, ask for merge strategy (merge / squash / rebase, default merge)
2. **multi-repo**: user selects repos
3. For each repo: `checkout {main_branch} → pull`, then merge per strategy:
   - **merge**: `git merge {branch}`
   - **squash**: `git merge --squash {branch}` → `git commit`
   - **rebase**: `git checkout {branch} → git rebase {main_branch} → git checkout {main_branch} → git merge {branch}`
4. Ask whether to push main branch and whether to delete the merged branch
5. **Merge operations require a second confirmation**

### Clean Up Branches

1. Scan local branches across repos (excluding main branch), mark as merged/unmerged
2. User selects branches to delete
3. Deleting unmerged branches requires extra confirmation; optionally delete remote branches too

## Global Rules

- **All write operations require user confirmation** — never execute autonomously
- **Do not auto-resolve conflicts** — stop immediately
- Do not push by default; only push when the user requests it
- Skip repos with no changes
- Each repo is operated independently; a failure in one does not affect others
- Use `git -C <path>` to execute commands; do not rely on cd
