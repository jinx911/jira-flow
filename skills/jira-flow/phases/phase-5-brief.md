---
partOf: jira-flow
version: 1.0.0
description: Phase 5 complete instructions for test verification. Leader reads this file when entering Phase 5.
---

# Phase 5: Test Verification

Spawn tester (scale as needed)

Prerequisite: If frontend changes are involved → Leader first notifies **frontend-developer** to run the frontend build (command reference: {root_path}/.claude/project-config.md → build_commands.frontend)

Leader → tester: "Read proposal.md + tasks.md, and execute test verification.

  [superpowers:verification-before-completion]
  First read the superpowers verification SKILL.md for the full methodology.
  Key constraints:
  - Evidence rule: every completion claim must be backed by immediate verification evidence
  - Forbidden: 'should work now' / 'looks fine' / 'should pass'
  - For each verification provide: command + output summary + exit code
  - Bug reports: reproduction steps + expected + actual + evidence

  Test environment credentials: Reference {root_path}/.claude/project-config.md → test_environments.
  E2E testing: Reference {root_path}/.claude/project-config.md → e2e_testing (prefer browser_run_code_unsafe for executing full scripts).
  Test scope: existing unit tests + selection based on change type (backend-only → API/integration tests, frontend involved → E2E tests).
  Repository paths: {repo_paths}.
  Database verification: Use MCP to query the corresponding database and verify data correctness.
  If a bug is found → send a message to Leader: 'Bug: <description>, Steps: <reproduction>, Expected: <expected>, Actual: <actual>'
  If all pass → send a message to Leader: 'All tests passed, report: ...'"

## Test-Fix Loop (all routed through Leader)

tester finds bug → Leader → Leader determines ownership → development agent fixes → Leader → tester re-verifies
If not passed, run another round. After multiple unresolved rounds (>3) → Leader asks the user

## Gate 5

Present test report → confirm
