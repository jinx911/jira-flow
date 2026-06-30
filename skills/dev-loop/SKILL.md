---
name: dev-loop
description: Use when implementing from a spec. Produces tasks.md (each unit tagged with a test strategy), creates the branch, then develops with conditional TDD. Built-in doc-first change: any requirement gap found mid-dev updates the spec before code. Independently invocable.
---

# Dev-Loop: Spec → Implementation (with doc-first change)

## Flow
1. **Plan** — planner reads proposal+design → writes `tasks.md`. Each task unit carries a `test_strategy` tag (from design.md Test Strategy).
2. **Branch** — backend-developer creates the branch via `/git-ops`.
3. **Implement** — dev agents execute units per their test strategy.

## Driven by
Orchestrator spawns: planner → backend-developer / frontend-developer. Role expertise embedded here; `~/.claude/agents/*.md` NOT read.

## Conditional TDD (TDD only when necessary)
Per-unit `test_strategy` tag decides discipline:

| Tag | Applies to | Behavior |
|---|---|---|
| `tdd` | testable business logic / algorithm / state transition | RED → verify → GREEN → verify → REFACTOR |
| `regression` | bug fix | write regression test first, then fix |
| `smoke` | scaffolding / config / migration / UI layout | implement directly; optional smoke test |
| `none` | pure config / typo / docs | no test |

`tasks.md` step format adapts to the tag — NOT uniformly test→verify→implement→verify→commit.

## Doc-First Change (required on any requirement gap)
When you discover a requirement gap/error during implementation, update the spec BEFORE code. See `doc-first-change.md`.

## Long-Task Context Protection
When `tasks.md` has >8 units, split into rounds (≤8 units/round). Between rounds the Leader persists progress; the next round resumes from the first pending unit. TaskList is the progress source (no heartbeats/snapshots).

## Frontend-Backend Coordination
If both backend and frontend change the same repo with overlapping files, use worktree isolation; otherwise work in parallel on the same branch. The Leader decides from the architect's key-files list.

## Gate 2
- [ ] TaskList clean (all units done)
- [ ] `tdd`/`regression`/`smoke`-tagged units tested green
- [ ] Every `spec-delta` either confirmed (scope-changing) or logged (clarification)

## Dependencies
- Agents (embedded): planner, backend-developer, frontend-developer
- Skills: git-ops
- Plugin: superpowers (test-driven-development, executing-plans)
