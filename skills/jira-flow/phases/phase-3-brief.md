---
partOf: jira-flow
version: 1.0.0
description: Phase 3 complete instructions for TDD development. Leader reads this file when entering Phase 3.
---

# Phase 3: TDD Development

## Development Instructions

1. Leader uses TaskUpdate to assign ownership to backend-developer / frontend-developer
2. Leader → development agents:
   "Complete the tasks assigned to you in the TaskList.

    [superpowers:test-driven-development + executing-plans]
    First read the corresponding SKILL.md for the full methodology.
    Key constraints:
    - TDD discipline: never write production code before a failing test
    - RED → Verify → GREEN → Verify → REFACTOR
    - Execute tasks.md steps one by one; only proceed to the next step after verification passes
    - If blocked → send a message to the Leader; do not guess

    Branch: {branch}, repository: {repo_path}.
    Backend development: Reference {root_path}/.claude/project-config.md → databases (read/write data) + migration (table creation/field modification conventions).
    Frontend development: Reference {root_path}/.claude/project-config.md → frontend_build (must build after changes to take effect).
    If multiple development agents need to modify the same repository → use worktree isolation.
    If issues arise, follow the escalation path defined in team-rules.md."
3. Leader monitors:
   - On progress update → update state.json agent_context_snapshots[agent_name]
   - On completion report → TaskUpdate + notify waiting agents
   - On exception → handle per exception protocol
   - On no message for 10 min → ping agent; on ping unanswered + 15 min silence → context exhaustion recovery (see skill.md)

## Frontend-Backend Parallel Conflict Coordination

When backend-developer and frontend-developer work simultaneously, the Leader evaluates whether worktree isolation is needed based on the following rules:

| Scenario | Conflict? | Resolution |
|----------|-----------|------------|
| Modifying different repositories (backend Laravel + frontend React separate projects) | No conflict | Work in parallel on the same branch, commit independently |
| Modifying different files in the same repository | No conflict | Work in parallel on the same branch, commit independently |
| Modifying the same file in the same repository (e.g., shared type definitions, API contracts) | Conflict | Backend commits first, frontend rebases on latest code; or Leader schedules sequential execution |
| Modifying the same repository with overlapping files (e.g., routes/api.php) | Conflict | Use worktree isolation — each developer works in an independent working directory; Leader coordinates merge order upon completion |

**Leader assessment timing**: After Gate 1 and before spawning development agents, evaluate whether file paths overlap based on the "key files list" reported by the architect. If overlap exists → notify development agents to use worktree; if no overlap → proceed in parallel on the same branch.

## Gate 3

Present progress → confirm
