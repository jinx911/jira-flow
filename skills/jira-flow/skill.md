---
name: jira-flow
description: Use when user provides a Jira issue key or URL and wants to execute the full development lifecycle — requirement analysis, design, planning, branch creation, TDD development, code review, and commit. Creates a full-lifecycle agent team for end-to-end coordination with context isolation.
version: 1.1.0
tags: [jira, workflow, team, tdd, code-review, agent-orchestration]
dependencies:
  skills:
    - create-team
    - delete-team
    - git-ops
    - init-jira-flow
  plugins:
    - superpowers >= 5.0.0
  agents:
    - requirements-analyst
    - architect
    - planner
    - backend-developer
    - frontend-developer
    - code-reviewer
    - tester
  mcp_servers:
    - name: atlassian-rovo
      required: true
    - name: playwright
      required: false
      note: "E2E testing"
  project_config: true
---

# Jira-Flow: Full-Lifecycle Agent Team Development Workflow

**Input**: `$ARGUMENTS` (Jira issue key like `OA-3650`, or full URL)

## Leader Constraints

> The Leader (main session) never directly executes any operations — it only coordinates, makes decisions, and drives state transitions.
> All execution is delegated via SendMessage. Read is allowed for understanding and loading Phase instructions.
> Direct agent-to-agent communication is strictly prohibited; all communication routes through the Leader.

**Allowed**: Read, SendMessage, TaskCreate/TaskUpdate, AskUserQuestion, /create-team, /delete-team
**Allowed Write**: Only `{root_path}/.jira-flow/{issue_key}-state.json` (breakpoint recovery state file)
**Forbidden**: Write (business code), Edit, Bash, /git-ops, Atlassian MCP write operations
**Forbidden to hold**: Source code, diffs, full design content, Jira descriptions, teammate execution logs

### Leader Context Budget

The Leader holds only at any given time:
- state.json key summary (current_phase + phase_decisions + latest 1 gate_summary)
- Current Phase brief only (other Phase briefs are released after use)
- Latest message from each member (older messages: extract key points → write to state.json → discard)

Enforcement rules:
1. Phase briefs are released after the Phase transitions (not retained)
2. Gate summaries: retain only current + previous Phase (older ones stay in state.json)
3. Member reports: extract key info → persist to state.json → discard original message
4. Long phases (Phase 3+): execute `/compact` after every 3 progress updates received
5. Every Gate pass: execute `/compact` (existing mechanism preserved)

## Superpowers Integration

Each Phase brief contains `[superpowers:xxx]` markers. Agents Read the corresponding SKILL.md themselves — the Leader does not need to know the details.

| Phase | Superpowers Skill |
|-------|------------------|
| 1 Requirements Analysis | brainstorming |
| 2 Task Planning | writing-plans |
| 3 TDD Development | test-driven-development + executing-plans |
| 4 Code Review | requesting-code-review |
| 5 Test Verification | verification-before-completion |
| 6 Finalization | finishing-a-development-branch |

## Run Modes

| Behavior | Semi-Auto (default) | Full-Auto |
|----------|---------------------|-----------|
| Gate | Display summary + AskUserQuestion | Auto-pass, log summary |
| Phase 1 Checkpoints | Interactive — A/B require input, C conditional | Auto-pass all |
| Exceptions | All prompt user | Only retry-exceeded prompt user |
| Jira/Branch | Confirm before executing | Auto-execute |

## Configuration

Config lookup: `~/.claude/skills/jira-flow/project-config.md` → `root_path` → `~/.claude/configs/projects.json` → `{root_path}/.claude/project-config.md`

File structure and detailed docs: see `README.md`.

## Initialization

### 0. Pre-flight Checks

Verify dependencies. Summarize missing items and prompt — do not auto-install:
1. Skills: `create-team`, `delete-team`, `git-ops` in `~/.claude/skills/`; Superpowers plugin ≥5.0.0
2. Agent definitions in `~/.claude/agents/` (see dependencies.agents)
3. Atlassian-rovo MCP available; CodeGraph: check `.codegraph/` in `{root_path}` — missing → AskUserQuestion
4. Pending cleanup: empty dirs under `{changes_path}` → delegate to first Bash-capable agent

### 1. Parse + Configure

1. Extract issue key from `$ARGUMENTS`
2. Read `project-config.md` → resolve `root_path` (empty → read `projects.json`, multiple → AskUserQuestion)
3. Read `{root_path}/.claude/project-config.md` → full project config
4. `cloudId` empty → call `getAccessibleAtlassianResources`
5. Breakpoint: check `{root_path}/.jira-flow/{issue_key}-state.json` → exists → read `resume.md`
6. AskUserQuestion: semi-auto (recommended) / full-auto

### 1.5 Variable Substitution

Read phase-N-brief.md and substitute `{variable}` placeholders. Full table: `team-rules.md → Variable Injection Mechanism`.

Key variables: `{issue_key}`, `{root_path}`, `{changes_path}`, `{spec_name}` (Phase 1), `{branch}` (Phase 2), `{repo_path}`, `{repo_paths}`.

> "project-config.md → xxx" always means `{root_path}/.claude/project-config.md`.

### 2. Create Core Team

Invoke `/create-team` in programmatic mode with `team_name: "jira-flow-{issue_key}"`, roles from dependencies.agents, and `custom_prompt` = team-rules.md with variables substituted. Scale on demand using Agent spawn.

| Timing | Roles | Decision Criteria |
|--------|-------|-------------------|
| Phase 0 | requirements-analyst, architect, planner | Fixed core team |
| After Gate 1 | backend-dev / frontend-dev | design.md involves backend/frontend |
| Before Phase 4 | code-reviewer | Fixed addition |
| Before Phase 5 | tester | Fixed addition |

---

## Phase Summary

> When entering a Phase, Read `phases/phase-N-brief.md`. When executing a Gate, Read `gate.md`.

| Phase | Output | Gate |
|-------|--------|------|
| 1 Requirements Analysis (Interactive) | proposal.md + design.md (4 steps + Checkpoint A/B/C) | Confirm → spawn dev agents |
| 2 Task Planning + Branch | tasks.md + git branch | Confirm task list + branch |
| 3 TDD Development | Implementation code | Confirm progress |
| 4 Code Review | Review report | CRITICAL/HIGH → fix |
| 5 Test Verification | Test report | Confirm tests pass |
| 6 Finalization | commit + push + Jira update | Final summary |

---

## Exception Handling

All exceptions flow: teammate → Leader → Leader evaluates → Leader forwards to the appropriate role.

### Agent Health Detection (Three-Level)

Replaces the old ping + 15min auto-judgment logic with a progressive three-level approach:

| Level | Trigger | Leader Action |
|-------|---------|---------------|
| **Level 1** (10/15min) | Phase 1-2: 10min; Phase 3-5: 15min no reply | Send ping message, wait 5 minutes |
| **Level 2** (15/20min) | Ping unanswered + last message exceeds threshold | **AskUserQuestion to user** (wait/skip/terminate) — NOT auto-judged |
| **Level 3** (25/30min) | User confirms agent is unresponsive | Execute context exhaustion recovery |

> **Key change**: The Leader never auto-judges context exhaustion. Level 2 always requires a user decision.

### Agent Context Exhaustion Recovery

When user confirms an agent is unresponsive:

1. Read state.json → get agent's task assignments and context snapshot
2. Spawn replacement agent (same role + team-rules.md), injecting:
   - Original task description (from phase-N-brief.md)
   - Phase decisions: state.json → phase_decisions[current_phase]
   - Agent's last context snapshot
   - Instruction: "Previous agent ran out of context. Continue from where it left off. Do NOT restart completed work."
3. Update state.json → replace exhausted agent + reset snapshot
4. If replacement also exhausts context → escalate to user (no third spawn)

### Message Confirmation Protocol

Prevents message loss between members and Leader:

1. Leader must reply with brief acknowledgment after receiving any member message: `"Acknowledged, {summary}"`
2. If member sends a message and receives **no acknowledgment within 2 minutes** → resend once, marking the message `[RETRY]`
3. Leader must prioritize any message with `[RETRY]` marker
4. If resend also receives no acknowledgment → member marks message `[URGENT-NOACK]`, Leader saves progress to state.json immediately upon receipt

### Exception Routing

- Requirements/design issues → requirements-analyst/architect → may trigger planner re-sequencing
- Build failure → dev self-fixes (≤2 times) → still failing → Leader asks user
- Task conflict → planner reports → Leader decides serialization or worktree
- Test bug → tester → Leader → dev fixes → tester re-verifies (≤3 loops)
- MCP failure → retry ≤2 times → save state, prompt user to resume
- **Message unconfirmed** → member retries 1 time → Leader checks and replies

> Full retry limits table see `resume.md → Unified Retry Limits`.
