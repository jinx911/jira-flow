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

   Reference {root_path}/.claude/project-config.md → jira_workflow (if configured) for status names and template overrides.
   If jira_workflow is not configured, use the following defaults:

   a. getTransitionsForJiraIssue → find the transition ID for the testing status
      Configured: use jira_workflow.testing_status
      Default: look for a status containing 'Test' or '测试' (e.g., 'In Testing', '测试中')

   b. Transition the MAIN issue to the testing status
      **IMPORTANT**: This transition triggers automatic creation of sub-issues (with testing note fields).
      Wait a moment for auto-creation to complete, then proceed to step c.

   c. searchJiraIssuesUsingJql → search for auto-created sub-issues by parent
      JQL: parent = {issue_key} ORDER BY created DESC

   d. editJiraIssue → fill in the testing notes on EACH SUB-ISSUE
      Content based on: proposal summary + change scope + test results
      Template: use jira_workflow.testing_note_template if configured, otherwise use default:
        - Change overview: <summary of changes>
        - Affected modules: <modules involved>
        - Testing highlights: <key test results>
        - Prerequisites: <what needs to be set up before testing>
        - Verification steps: <how to verify the changes>

   e. transition EACH SUB-ISSUE to completion status
      Configured: use jira_workflow.sub_completion_status
      Default: look for a status containing 'Done' or '完成' (e.g., 'Done', '已完成')"

## 5. Cleanup

Call /delete-team

## Gate 6

Final summary (branch name + sub-issue links + reminder that MR must be created manually)
