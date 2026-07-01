---
partOf: bugfix-flow
version: 1.0.0
description: Step 2 instructions for fix implementation and verification. Leader reads this file when entering Step 2.
---

# Step 2: Fix + Verify

> **Objective**: Implement the confirmed fix with TDD discipline, verify tests pass, and update spec if available.

## Prerequisites

- Gate 1 has passed — fix approach is confirmed
- All target repos are checked out on the correct branch
- `step_results.1.fix_proposal` contains the confirmed fix plan

## 1. TDD Fix Implementation

Leader delegates to **backend-developer** (and **frontend-developer** if frontend changes are involved):

"Implement the bug fix following the confirmed approach.

### Confirmed Fix Plan:
{step_results.1.fix_proposal}

### Repositories:
{repos_to_fix}

### TDD Discipline:

For each repo that needs changes:

**RED** — Write a failing test first:
  - Write a test that reproduces the bug
  - Run the test — confirm it FAILS (proves the bug exists)
  - If the bug cannot be reproduced by a unit test (e.g., UI-only, integration issue), write a minimal verification script instead and document why unit testing is infeasible

**GREEN** — Write minimal code to fix:
  - Implement the fix as described in the proposal
  - Run the test — confirm it PASSES

**REFACTOR** — Clean up:
  - Review the fix for clarity and consistency with surrounding code
  - Run the test again — still passes

### Build Commands:
  Backend: {project-config → build_commands.backend}
  Frontend: {project-config → build_commands.frontend}

### Migration (if needed):
  {project-config → migration.steps}

### Self-Fix Rules:
- If a test fails after fix attempt: analyze error, adjust fix, re-run. Up to 2 self-fix attempts per repo.
- If still failing after 2 attempts: report back to Leader with error details.

### Code Quality Checklist:
- [ ] No debug statements (console.log, dd(), dump(), var_dump, etc.)
- [ ] No commented-out code related to the fix
- [ ] Error handling is appropriate
- [ ] Fix follows existing code patterns in the project
- [ ] No unintended side effects in modified files

### Report Format:
For each repo, send to Leader:
```
## Fix Report — {repo_name}

**Status**: completed | failed | blocked
**Files Modified**: [list]
**Files Added**: [list, e.g., test files]
**Test Result**: pass/fail/N/A
  - Command: {test command}
  - Exit code: {number}
  - Summary: {1-2 sentences}
**Issues**: [blocker descriptions, or 'None']
```
"

## 2. Cross-Repo Verification

If the fix touches multiple repos:

Leader delegates verification:

"Verify the fix works across repos:
1. Run all relevant test suites in each modified repo
2. If there are integration points between modified repos, verify they still work together
3. Check for any import/API contract changes that might break other repos"

## 3. Diff Summary

Leader collects diffs from all repos:

```
For each repo in repos_to_fix:
  git -C {repo_path} diff --stat
  git -C {repo_path} diff
```

Compile a unified diff summary showing all changes across repos.

## 4. Spec Update (Optional)

If an existing OpenSpec spec directory exists for this feature:

```
Check if {changes_path}/{spec_name}/proposal.md exists
  where spec_name comes from:
    - jira-flow state.json → openspec_name (if available)
    - or search {changes_path}/ for a directory matching the parent issue context

If exists → append to proposal.md:
  ---
  ## Bug Fix Record — {date}

  **Bug**: {bug_description}
  **Root Cause**: {step_results.1.root_cause}
  **Fix Summary**: {what was changed, 2-3 sentences}
  **Test Result**: {pass/fail summary}
  **Files Changed**: {list}
  ---

If spec does not exist → skip, do NOT create a new spec.
```

## Gate 2

**Semi-auto**: Present via AskUserQuestion:
```
## Fix Summary

### Changes:
{repo_1}: {N} files modified
  - {file}: {1-line description of change}
{repo_2}: {N} files modified
  - {file}: {1-line description of change}

### Test Results:
{repo_1}: {N} tests passed, {N} failed
{repo_2}: {N} tests passed, {N} failed

### Spec Updated: yes/no

Proceed to deploy?
```

User can: Confirm / Request changes / Abort

**Full-auto**: Log the diff and test results, auto-proceed.

Update state.json: `current_step = 2`, `step_results.2 = { files_changed, test_results, spec_updated, confirmed }`.
