---
partOf: jira-flow
version: 1.0.0
description: Phase 6 complete instructions for wrap-up. Leader reads this file when entering Phase 6.
---

# Phase 6: Wrap-Up

## 1. Development Branch Finalization

Leader → **backend-developer**: "Finalize the development branch:
   [superpowers:finishing-a-development-branch]
   - Confirm all tests pass (run the full test suite, not incremental)
   - Confirm no leftover debug code (console.log/dd/dump/var_dump, etc.)
   - Commit and push the branch (/git-ops commit + push — push the branch only; MR is created manually by the user)"

## 2. Deploy Branch Merge (Optional)

If deploy_branch is configured in project-config:
Leader → **backend-developer**: "Merge the development branch into {deploy_branch} and push"
- checkout {deploy_branch} → pull → merge {development branch} → push → checkout {development branch}
- Purpose: trigger automatic deployment to the test environment

If deploy_branch is not configured → skip this step

## 3. Confirm Final State

- All repository branches have been pushed
- deploy_branch has been merged (if configured)
- Update jira-flow-state.json

## 4. Jira Wrap-Up

Leader → requirements-analyst: "Perform Jira wrap-up operations:
   Reference {root_path}/.claude/project-config.md → jira_workflow (if configured), otherwise discover dynamically via MCP:
   a. getTransitionsForJiraIssue to get the transition ID for the target status
      → If jira_workflow.testing_status exists: use the configured value
      → If not configured: list available transitions and ask the Leader to select
   b. Transition the main Jira issue to the target status
   c. If jira_workflow.auto_creates_sub == true:
      searchJiraIssuesUsingJql to search for auto-created sub-issues by parent
   d. editJiraIssue to fill in the testing notes (based on proposal summary + change scope + test results)
      → If jira_workflow.testing_note_template exists: use the template
      → If not configured: use default format (change overview, modules affected, testing highlights, prerequisites, verification steps)
   e. Transition sub-issues → jira_workflow.sub_completion_status"

## 5. Cleanup

Call /delete-team

## Gate 6

Final summary (branch name + sub-issue links + reminder that MR must be created manually)
