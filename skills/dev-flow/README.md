# Dev-Flow Skill

Dev-Flow orchestrates a multi-agent team through the full development lifecycle via **four reusable sub-skills**. This is the thin orchestrator (Leader playbook).

## Pipeline

```
Requirement (Jira key or text) → 4 Stages + 4 Gates → Branch Pushed + Jira Updated

Stage 1: spec-author   → proposal.md + design.md (adaptive engineering sections)
Stage 2: dev-loop      → tasks.md + branch + implementation (conditional TDD)
Stage 3: review-test   → review + verify + fix loop
Stage 4: ship          → push + deploy + Jira wrap-up
```

The Leader triggers one sub-skill per stage, runs the Gate (checklist), then advances. The Leader never executes business code — it only coordinates, so its context stays clean.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Entry, stage routing, Gate/delegation rules, state, initialization |
| `gate.md` | Checklist Gate definitions + summary format |
| `team-rules.md` | Slim communication rules + Health (idle/ping) + variable injection |
| `resume.md` | Breakpoint recovery + retry limits + legacy `.jira-flow` compat |
| `project-config.example.md` | Project config template |

## Sub-skills (each independently invocable)

- `spec-author` — requirement → structural proposal + design
- `dev-loop` — TDD development with doc-first change
- `review-test` — code review + verification + fix loop
- `ship` — finalize + deploy + Jira wrap-up

## Key properties

- **Role expertise is embedded in sub-skills** — dev-flow does NOT read `~/.claude/agents/*.md`.
- **Living docs** — requirement gaps found mid-dev update the spec before code (`doc_version` tracked).
- **Conditional TDD** — per-unit test strategy (`tdd` / `regression` / `smoke` / `none`).
- **Pre-resolved prompt files** — spawn = read file + `Agent()`; no per-spawn prompt building.

See the top-level `README.md` for installation, configuration, and the full file tree.
