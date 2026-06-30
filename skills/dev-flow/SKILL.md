---
name: dev-flow
description: Use when given a Jira issue key/URL (jira mode) or a natural-language requirement (free-flow mode) and you want a full dev lifecycle — spec → dev → review-test → ship. Orchestrates a multi-agent team where the Leader delegates execution to keep its context clean. Each stage is an independently invocable sub-skill.
---

# Dev-Flow: Full-Lifecycle Agent Team Development Workflow

**Input:** `$ARGUMENTS`
- **jira mode**: matches `^[A-Z]+-\d+$` or contains `/browse/`
- **free-flow mode**: everything else; the full text becomes `requirement_text`
  - Issue key auto-generated as `ff-{slug}-{HHmm}` (`{slug}` = first 40 chars of kebab-case text)

## Stages

Four stages, each a reusable sub-skill. The Leader triggers one per stage, runs the Gate, then advances.

| Stage | Sub-skill | Output | Gate |
|---|---|---|---|
| 1 Spec | `spec-author` | proposal.md + design.md (adaptive sections) | Gate 1: completeness checklist |
| 2 Dev | `dev-loop` | tasks.md + branch + implementation | Gate 2: tasks done + tests green |
| 3 Review-Test | `review-test` | review + verify report | Gate 3: no CRITICAL/HIGH + tests pass |
| 4 Ship | `ship` | push + deploy + Jira wrap-up | Gate 4: final summary |

Before each stage, Read that sub-skill's `SKILL.md`. Before each Gate, Read `gate.md`.

## Progress Dashboard

After every Gate pass:
```
Stage: [✅1][✅2][🔄3][·4]  {issue_key} | Branch: {branch} | Complexity: {complexity}
```
Symbols: `✅` done, `🔄` current, `·` pending.

## Leader Constraints

The main session is the Leader. It coordinates only; execution is delegated.

**Allowed:** Read, SendMessage, TaskCreate/TaskUpdate, AskUserQuestion, `/create-team`, `/delete-team`
**Write only:** `{root_path}/.dev-flow/{issue_key}-state.json`
**Forbidden:** business-code Write/Edit/Bash, `/git-ops`, Atlassian MCP writes, holding source/diffs/full docs in long-lived context

### Leader Context Budget
Keep only: state.json summary (`current_stage`, `doc_version`, latest gate summary), the current sub-skill brief, and the latest message from each member. Release previous stage briefs after transition. Run `/compact` after every Gate pass.

## Prompt Pre-resolution

At flow start, substitute variables ONCE into per-stage prompt files:
`{root_path}/.dev-flow/{issue_key}/prompts/{stage}.md` — built from each sub-skill's body + `team-rules.md`. Spawn = read that file + `Agent()`. **No per-spawn prompt building.**

## Delegation Rule

For each stage:
1. Read the pre-resolved prompt file for that stage.
2. Spawn ONE `general-purpose` agent:
   `Agent({ subagent_type: "general-purpose", name: "<role>", team_name: "dev-flow-{issue_key}", run_in_background: true, prompt: <prompt-file-content> })`
3. Assign the stage task via `TaskUpdate`.
4. Wait for the agent's structured Completion Report (or Progress Update).
5. On completion → run Gate; on blocker → route per `team-rules.md`.

**ALL agents spawn as `general-purpose`** (full tool access incl. SendMessage + MCP). Role identity comes from the prompt. The Leader never reads `~/.claude/agents/*.md` — role expertise lives inside each sub-skill.

## Variable Substitution

Common keys (full table in `team-rules.md`): `{issue_key}`, `{root_path}`, `{changes_path}`, `{baseline_path}`, `{spec_name}` (Stage 1 output), `{branch}` (Stage 2 output), `{repo_path}`, `{repo_paths}`, `{mode}`, `{requirement_text}`, `{deploy_branch}`, `{cloudId}`.

## Run Modes

| Behavior | Semi-auto (default) | Full-auto |
|---|---|---|
| Gate | Show summary + AskUserQuestion | Auto-pass, log summary |
| Mini-Gate (scope-changing spec-delta) | Always ask user | Ask only after retry limits exceeded |
| Jira/branch actions | Confirm first | Auto-execute |

## Configuration

Lookup chain:
1. `~/.claude/skills/dev-flow/project-config.md`
2. `~/.claude/configs/projects.json`
3. `{root_path}/.claude/project-config.md`

## Initialization

### 0. Pre-flight
1. Skills present: `create-team`, `delete-team`, `git-ops`, `init-dev-flow`, `spec-author`, `dev-loop`, `review-test`, `ship`
2. jira mode: Atlassian MCP available; CodeGraph at `{root_path}` or ask user
3. Leader ensures `{changes_path}` and `.dev-flow/` exist (`mkdir -p`) — infrastructure, not business code

### 1. Parse + Configure
1. Detect mode from `$ARGUMENTS`
2. Resolve `root_path`; ask if ambiguous
3. Read `{root_path}/.claude/project-config.md`
4. jira mode: resolve `cloudId` when empty
5. Check `.dev-flow/{issue_key}-state.json`; if present → follow `resume.md`
6. Ask: `semi-auto` (recommended) or `full-auto`

### 2. Pre-resolve prompts + Create team
1. Substitute variables → write `.dev-flow/{issue_key}/prompts/{stage}.md` for each stage
2. `/create-team` with `team_name: "dev-flow-{issue_key}"`, roles from Dependencies

## Health & Recovery

- Idle/ping rules + message format: see `team-rules.md`
- Breakpoint recovery + retry limits: see `resume.md`

## Dependencies

- **Skills:** create-team, delete-team, git-ops, init-dev-flow, spec-author, dev-loop, review-test, ship
- **Plugin:** superpowers >= 5.0.0
- **Agents (optional — NOT read by dev-flow):** requirements-analyst, architect, planner, backend-developer, frontend-developer, code-reviewer, tester. Role expertise is embedded in sub-skills; these files may exist for other contexts but are not a dependency.
- **MCP:** atlassian-rovo (jira mode), playwright (optional, E2E)
- **project_config:** required (via `/init-dev-flow`)
