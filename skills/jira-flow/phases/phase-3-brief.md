---
partOf: jira-flow
version: 1.1.0
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
    - Before writing new code, search the codebase for existing similar implementations to reuse or extend
    - If blocked → send a message to the Leader; do not guess

    Branch: {branch}, repository: {repo_path}.
    Backend development: Reference {root_path}/.claude/project-config.md → databases (read/write data) + migration (table creation/field modification conventions).
    Frontend development: Reference {root_path}/.claude/project-config.md → frontend_build (must build after changes to take effect).
    If multiple development agents need to modify the same repository → use worktree isolation.
    If issues arise, follow the escalation path defined in team-rules.md."
3. Leader monitors:
   - On progress update → update state.json agent_context_snapshots[agent_name] + agent_heartbeats[agent_name]
   - On completion report → TaskUpdate + notify waiting agents
   - On exception → handle per exception protocol
   - On no message for 15 min → follow three-level health detection (see skill.md)
   - On Context Warning → save snapshot, arrange wrap-up, prepare replacement

## Long Task Context Protection

When tasks.md has **more than 8 steps**, the Leader MUST split the work into rounds to prevent agent context exhaustion:

| Step Count | Strategy |
|-----------|----------|
| ≤8 steps | Single agent instance, standard flow |
| 9-16 steps | 2 rounds: assign ≤8 steps per round |
| >16 steps | 3+ rounds: assign ≤6 steps per round |

**Round execution:**
1. Leader assigns ≤8 steps from tasks.md to the dev agent
2. Agent completes steps, sends Completion Report for the round
3. Leader saves progress to state.json → agent_context_snapshots
4. Leader sends next round assignment to the same agent (or spawns replacement if context warning received)
5. Next round prompt includes: "Round {N}/{total}. Previous round completed steps {X}-{Y}. Continue from step {Z}."

**Why**: Each TDD cycle (RED→GREEN→REFACTOR) consumes significant context. Limiting to ≤8 steps per round keeps agent context healthy and eliminates most context exhaustion scenarios.

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
