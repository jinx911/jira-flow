---
partOf: bugfix-flow
version: 1.0.0
description: Step 3 instructions for deployment. Leader reads this file when entering Step 3.
---

# Step 3: Deploy

> **Objective**: Commit changes, merge to deploy branch, trigger Jenkins deployment, and update Jira status.

## Prerequisites

- Gate 2 has passed — fix is confirmed and tests pass
- All changes are uncommitted in the working trees of target repos

## 1. Commit + Push (Per Repo)

For each repo in `repos_to_fix`:

Leader delegates to **backend-developer**:

"Invoke `/git-ops` to commit and push the bug fix.

Commit message format:
  - Jira mode: fix({scope}): {brief fix description}

    Refs {issue_key}"
  - Free mode: fix({scope}): {brief fix description}"

Repos with changes: {repos_to_fix list}
Branch: {branch}

`/git-ops` handles:
- Scanning changed files across repos
- Presenting change list for confirmation
- Per-file `git add` (not `git add -A`)
- Commit with formatted message
- Push to origin/{branch}
- Branch protection checks
- Stash safety if needed"

Leader collects: commit SHA for each repo.

## 2. Merge to Deploy Branch

> **Guard**: Only execute if `deploy_branch` is configured in project-config. If not configured, skip this section.

Leader delegates to **backend-developer**:

"Invoke `/git-ops` to merge the bug fix branch into {deploy_branch}.

Source: {branch} → Target: {deploy_branch}
Repos: {repos_to_fix list}

`/git-ops` handles:
- Branch protection checks (merge direction validation)
- Stash safety before switching branches
- Checkout deploy_branch → pull → merge → push → checkout back
- Merge conflict detection — stops immediately on conflict
- Push confirmation

If any repo has merge conflicts → `/git-ops` will stop and report. Leader then prompts user to resolve manually."

## 3. Jenkins Deploy (Interactive)

> **Config guard**: Only executes if `jenkins` section exists in project-config AND Jenkins MCP (`mcp__jenkins__jenkins_build_and_watch`) is available. If EITHER is missing → skip this section silently.

### 3a. Job Selection

Read project-config → `jenkins` section.

**Single job** (`jenkins.job_name` exists, `jenkins.jobs` does not exist):
- Use the single job directly
- Convert to internal format: `jobs = [{ job_name, default_params, branch_param, branch_value }]`

**Multiple jobs** (`jenkins.jobs` array exists):
- Present all jobs to user for selection

Leader uses AskUserQuestion:
```
## Jenkins Deploy — Select Services

Bug fix 涉及以下仓库，需要部署对应的服务:

  [✓] oa-service  (涉及后端代码)
  [✓] oa-frontend (涉及前端代码)
  [ ] oa-platform-php (未改动，跳过)

确认部署以上服务？（可取消勾选不需要的服务）
```

Save selected jobs as `jobs_to_deploy`.

### 3b. Parameter Confirmation (Per Job)

For each selected job:

1. Get job definition: `mcp__jenkins__jenkins_get_job(job_name)`
2. Parse parameter definitions
3. Construct parameters by merging:
   - `jenkins.default_params` (or per-job `default_params`)
   - `branch_param`: use `branch_value` from config (typically "test")
   - Password params: skip (use Jenkins defaults)

Leader uses AskUserQuestion:
```
## Jenkins Deploy — {job_name}

Parameters:
  - test_version: kn (Choice: kn / stage / u1)
  - deploy_type: api (Choice: api / job)
  - oa_branch: test

Confirm / Modify parameters / Skip this job
```

Save confirmed parameters per job.

### 3c. Trigger Builds

For each job with confirmed parameters:

Leader delegates to **backend-developer**:

"Trigger Jenkins build:
- Job: {job_name}
- Parameters: {confirmed_params}
- Use mcp__jenkins__jenkins_build_and_watch
  - job_name: {job_name}
  - parameters: {params}
  - poll_interval: 15
  - timeout_seconds: 600"

### 3d. Build Result Handling

**On success**: Note build number and result.

**On failure**:
1. Leader retrieves build log: `mcp__jenkins__jenkins_get_build_log(job_name, build_number)`
2. Leader uses AskUserQuestion: "Jenkins build #{build_number} for {job_name} failed. Log excerpt above. Retry / Skip / Abort?"
3. Retry → re-trigger (max 2 total attempts per job)
4. Skip → continue to next job, note failure in Gate 3 summary
5. Abort → end flow, save state

### 3e. Deploy Summary

```
## Jenkins Deploy Results

| Job | Build # | Result | Duration |
|-----|---------|--------|----------|
| oa-service | 1352 | SUCCESS | 8m 23s |
| oa-frontend | 550 | SUCCESS | 3m 12s |
```

## 4. Jira Update (If Applicable)

> **Guard**: Only execute if `issue_key` is non-null (jira mode). Free mode skips this section.

### 4a. Add Fix Comment

Leader adds comment to the bug issue:

```
mcp__atlassian-rovo__addCommentToJiraIssue(cloudId, issue_key, comment)

Comment body:
## Bug Fix Applied

**Root Cause**: {step_results.1.root_cause summary}
**Fix**: {step_results.2.fix summary}
**Files Changed**: {file list}
**Tests**: All passed
**Deployed**: {deploy_branch} via Jenkins (build #{numbers})
**Branch**: {branch}
```

### 4b. Transition Status (if sub-task)

If the issue is a sub-task (bug issue created by QA):

1. `mcp__atlassian-rovo__getTransitionsForJiraIssue(cloudId, issue_key)` → find completion transition
2. `mcp__atlassian-rovo__transitionJiraIssue(cloudId, issue_key, transition)` → move to Done/Completed

If the issue is a regular issue (not sub-task) → skip transition, only add comment.

## Gate 3

**Semi-auto**: Present final summary via AskUserQuestion:
```
## Bugfix-Flow Complete

Bug: {bug_description}
Root Cause: {1-line summary}

### Changes:
{repo}: {N} files (commit {sha})
{repo}: {N} files (commit {sha})

### Deploy:
  Merge to {deploy_branch}: ✓
  Jenkins oa-service: ✓ (build #1352)
  Jenkins oa-frontend: ✓ (build #550)

### Jira:
  Comment added to {issue_key}: ✓
  Status transitioned: ✓

Branch {branch} is ready for MR (MR is created manually by user).
```

User confirms → cleanup state file.

**Full-auto**: Log the summary, auto-complete.

Update state.json: `current_step = 3`, `step_results.3 = { commits, deploy_results, jira_updated }`.

On Gate 3 pass → delete `{root_path}/.bugfix-flow/{bug_id}-state.json`.
