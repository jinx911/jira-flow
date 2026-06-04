---
partOf: jira-flow
version: 1.1.0
description: Phase 5 test verification instructions. Leader reads this file when entering Phase 5.
---

# Phase 5: Test Verification

Spawn tester (scale on demand).

Prerequisite: if frontend changes are involved → Leader first instructs **frontend-developer** to run the frontend build (command from {root_path}/.claude/project-config.md → build_commands.frontend).

Leader → tester: "Read proposal.md + tasks.md, then execute test verification.

  [superpowers:verification-before-completion]
  First read the superpowers verification SKILL.md for the full methodology.
  Key constraints:
  - Evidence rule: every completion claim must have immediate verification evidence
  - Forbidden: 'should work' / 'looks fine' / 'should pass'
  - Each verification item provides: command + output summary + exit code
  - Bug report: reproduction steps + expected + actual + evidence

  Test environment credentials: see {root_path}/.claude/project-config.md → test_environments.
  E2E testing: see {root_path}/.claude/project-config.md → e2e_testing (prefer browser_run_code_unsafe for script execution).
  Test scope: existing unit tests + selection based on change type (backend-only → API/integration tests, frontend changes → E2E tests).
  Repository paths: {repo_paths}.
  Database verification: use MCP to query the corresponding database and verify data correctness.
  Bug found → SendMessage Leader: 'Bug: <description>, Steps: <reproduction>, Expected: <expected>, Actual: <actual>'
  All passed → SendMessage Leader: 'All tests passed, report: ...'"

## Test-Fix Loop (all routed through Leader)

tester finds Bug → Leader → Leader determines owner → dev agent fixes → Leader → tester re-verifies
If still failing, run another round. After >3 failed attempts → Leader asks user.

## Gate 5

Present test report → confirm
