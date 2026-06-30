---
name: ship
description: Use when finalizing a dev branch: run full tests, strip debug code, commit and push, then optionally merge to deploy_branch, trigger Jenkins, and do Jira wrap-up (jira mode). Reusable by bugfix-flow. Independently invocable.
---

# Ship: Finalize + Deploy + Jira

## 1. Finalize
backend-developer: run the FULL test suite, remove debug code (console.log/dd/dump/var_dump), commit and push the branch (push branch only — MR is created manually by the user).

## 2. Deploy merge (optional)
If `deploy_branch` is configured: checkout deploy_branch → pull → merge {branch} → push → checkout {branch}. Purpose: trigger auto-deploy to the test env. Skip if not configured.

## 3. Jenkins (optional)
Only if `jenkins` config AND Jenkins MCP both present. AskUserQuestion to confirm params → `mcp__jenkins__jenkins_build_and_watch` (poll_interval 15, timeout_seconds 600). On failure: retrieve log via `jenkins_get_build_log`, ask user retry (≤2) / skip / abort.

## 4. Jira wrap-up (jira mode only)
- `getTransitionsForJiraIssue` → transition main issue to testing status (triggers auto sub-issue creation).
- `searchJiraIssuesUsingJql` (`parent = {issue_key} ORDER BY created DESC`) → find auto-created sub-issues.
- For each testing-note sub-issue: fill notes (project-config `testing_note_template`: change overview / affected modules / testing highlights / prerequisites / verification steps) → transition to completion status.
- Skip test-plan sub-issues (QA handles them).
- free mode: skip this step entirely.

If requirements-analyst is unresponsive, the Leader may perform Jira MCP operations directly (no business code involved).

## Driven by
Orchestrator spawns: backend-developer (finalize + deploy); requirements-analyst or Leader (Jira wrap-up). Role expertise embedded here; `~/.claude/agents/*.md` NOT read.

## Gate 4
- [ ] Branch pushed
- [ ] deploy_branch merged (if configured)
- [ ] Jenkins succeeded or skipped (if configured)
- [ ] Jira updated (jira mode)

## Dependencies
- Skills: git-ops
- Agents (embedded): backend-developer, requirements-analyst
- MCP: jenkins (optional), atlassian-rovo (jira mode)
- Plugin: superpowers (finishing-a-development-branch)
