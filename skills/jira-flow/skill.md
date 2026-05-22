---
name: jira-flow
description: Use when user provides a Jira issue key or URL and wants to execute the full development lifecycle — requirement analysis, design, planning, branch creation, TDD development, code review, and commit. Creates a full-lifecycle agent team for end-to-end coordination with context isolation.
version: 1.0.0
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

## Superpowers Integration

> Each Phase references superpowers methodologies. The Leader annotates delegate instructions with `[superpowers:xxx]`.
> Agents receiving these should first Read the corresponding SKILL.md to get the full methodology.

| Phase | Superpowers Skill |
|-------|------------------|
| 1 Requirements Analysis | brainstorming |
| 2 Task Planning | writing-plans |
| 3 TDD Development | test-driven-development + executing-plans |
| 4 Code Review | requesting-code-review |
| 5 Test Verification | verification-before-completion |
| 6 Finalization | finishing-a-development-branch |
| Exception Handling | systematic-debugging |

## Run Modes

| Behavior | Semi-Auto (default) | Full-Auto |
|----------|---------------------|-----------|
| Gate | Display summary + AskUserQuestion for confirmation | Auto-pass, log summary without interrupting |
| Exceptions | All exceptions prompt the user | Only prompt when retry limit is exceeded |
| Jira Finalization | Display testing notes for user confirmation before submitting | Auto-submit |
| Branch Operations | Display branch info for confirmation before executing | Auto-execute |

In full-auto mode, the Leader still logs Gate summaries (for post-hoc review) but skips interactive confirmation. Exceptions and limit-exceeded scenarios must always be escalated to the user.

## File Structure

```
~/.claude/skills/jira-flow/
├── skill.md                    ← This file (flow skeleton)
├── gate.md                     ← Gate mechanism + pass criteria + summary format
├── phases/                     ← Phase instructions (loaded on demand)
│   ├── phase-1-brief.md
│   ├── phase-2-brief.md
│   ├── phase-3-brief.md
│   ├── phase-4-brief.md
│   ├── phase-5-brief.md
│   └── phase-6-brief.md
├── project-config.md           ← jira-flow process configuration
├── project-config.example.md   ← Project config example
├── team-rules.md               ← Communication rules + project context
└── resume.md                   ← Breakpoint recovery logic

~/.claude/configs/
└── projects.json               ← Global index (project path → name mapping)

<project-root>/.claude/
├── project-config.md           ← Full project config (repos, databases, test environments, etc.)
└── settings.local.json         ← Project permission whitelist
```

## Configuration Architecture

```
Lookup chain: jira-flow/project-config.md → root_path → projects.json → {root_path}/.claude/project-config.md

Global index (~/.claude/configs/projects.json)
  └── Project path → project name mapping (maintained by /init-jira-flow)

Project config (<project-root>/.claude/project-config.md)
  └── Full project info: tech stack, repos, databases, test environments, build commands, etc.
  └── Contains sensitive info — should be added to .gitignore

jira-flow process config (~/.claude/skills/jira-flow/project-config.md)
  └── Only jira-flow workflow settings: root_path, cloudId, branch naming, OpenSpec paths
```

---

## Initialization

### 0. Pre-flight Checks

Verify the following dependencies are ready. Summarize any missing items and prompt the user to install/configure — do not auto-install:

1. Required skills: `create-team`, `delete-team`, `git-ops` exist in `~/.claude/skills/`
2. Superpowers plugin installed (≥5.0.0)
3. Agent definitions exist in `~/.claude/agents/`:
   - requirements-analyst, architect, planner (core team)
   - backend-developer, frontend-developer (dev team)
   - code-reviewer, tester (review/test team)
4. Atlassian-rovo MCP is available (try `mcp__atlassian-rovo__atlassianUserInfo`)
5. Pending cleanup: empty directories under `{changes_path}`. Delegate to the first Bash-capable agent (backend-developer / frontend-developer) spawned after Gate 1 to run `find {changes_path} -type d -empty -delete`. Non-blocking — cleanup failure does not affect the flow.
6. CodeGraph: check if `.codegraph/` exists in `{root_path}`:
   - Exists → agents will automatically use CodeGraph tools for code exploration (configured via team-rules.md)
   - Does not exist → AskUserQuestion: "CodeGraph is not initialized for this project. Initialize it for faster code understanding? (codegraph init -i)"
   - User declines → proceed without CodeGraph; agents use standard grep/glob/Read
→ All ready → continue

### 1. Parse + Configure

1. Extract Jira issue key from `$ARGUMENTS`
2. Read `jira-flow/project-config.md` → get `root_path`
   - `root_path` is non-empty → use it
   - `root_path` is empty → read `~/.claude/configs/projects.json`:
     - Only 1 project → auto-select
     - Multiple projects → AskUserQuestion for user to choose
     - No projects → prompt user to run `/init-jira-flow` first
3. Read `~/.claude/configs/projects.json` → match by `root_path` → get project name
4. Read `{root_path}/.claude/project-config.md` → get full project config
   - Exists: use it
   - Does not exist: prompt user to run `/init-jira-flow` to initialize project config
5. `cloudId` is empty → Leader calls `mcp__atlassian-rovo__getAccessibleAtlassianResources` to obtain it
6. Breakpoint detection: check `{root_path}/.jira-flow/{issue_key}-state.json`
   - Exists: read `resume.md` and execute breakpoint recovery
   - Does not exist: continue
7. `AskUserQuestion`: semi-auto (recommended) / full-auto

### 1.5 Phase Variable Substitution

When the Leader enters each Phase, it Reads phase-N-brief.md. Any `{variable}` placeholders are substituted before constructing the delegate message:

| Variable | Source | Description |
|----------|--------|-------------|
| `{issue_key}` | Input parameter | Jira issue key, e.g. OA-3650 |
| `{key}` | = `{issue_key}` | Alias used in phase briefs |
| `{changes_path}` | jira-flow/project-config.md → openspec.changes_path | Work output directory (relative to root_path) |
| `{baseline_path}` | jira-flow/project-config.md → openspec.baseline_path | System baseline directory (optional) |
| `{spec_name}` | Phase 1 output | Proposal directory name, determined by requirements-analyst |
| `{branch}` | Phase 2 output | Development branch name |
| `{repo_path}` | project-config.md → backend.main_repo | Backend repository path |
| `{backend_repo_path}` | = `{repo_path}` | Alias used in Phase 4 |
| `{frontend_repo_path}` | project-config.md → frontend.repo_path | Frontend repository path |
| `{repo_paths}` | All repo paths combined | backend + frontend + involved modules |
| `{root_path}` | jira-flow/project-config.md → root_path | Project root directory (resolved in Phase 0) |
| `{deploy_branch}` | project-config.md → deploy_branch | Deploy branch (optional, used in Phase 6) |

**Config reference convention**: In phase briefs, "refer to project-config.md → xxx" always means `{root_path}/.claude/project-config.md` (project config), not `~/.claude/skills/jira-flow/project-config.md` (process config).

### 2. Create Core Team

Invoke `/create-team` in programmatic mode, passing the following JSON:

```json
{
  "team_name": "jira-flow-{issue_key}",
  "roles": [
    {"name": "requirements-analyst", "agent": "requirements-analyst"},
    {"name": "architect", "agent": "architect"},
    {"name": "planner", "agent": "planner"}
  ],
  "custom_prompt": "<team-rules.md contents with variables substituted>"
}
```

custom_prompt generation: Read team-rules.md → substitute template variables (see team-rules.md variable injection instructions) → pass as custom_prompt.

Scale on demand (after Gate 1 / before Phase 4 / before Phase 5) using Agent spawn, appending team-rules.md as a prompt parameter for each spawn.

| Timing | Roles Created | Decision Criteria |
|--------|--------------|-------------------|
| Phase 0 | requirements-analyst, architect, planner | Fixed core team |
| After Gate 1 | backend-dev / frontend-dev | Whether design.md involves backend/frontend |
| Before Phase 4 | code-reviewer | Fixed addition |
| Before Phase 5 | tester | Fixed addition |

---

## Phase Summary

> When entering a Phase, Read `phases/phase-N-brief.md` for full instructions.
> When executing a Gate, Read `gate.md` for pass criteria and summary format.

| Phase | Output | Gate |
|-------|--------|------|
| 1 Requirements Analysis | proposal.md + design.md | Confirm → spawn dev agents |
| 2 Task Planning + Branch | tasks.md + git branch | Confirm task list + branch info |
| 3 TDD Development | Implementation code | Confirm progress |
| 4 Code Review | Review report | CRITICAL/HIGH → fix |
| 5 Test Verification | Test report | Confirm tests pass |
| 6 Finalization | commit + push + Jira update | Final summary |

---

## Exception Handling

All exceptions flow: teammate → Leader → Leader evaluates → Leader forwards to the appropriate role.

### Unified Retry Limits

| Exception Type | Self-Repair Attempts | Action When Exceeded |
|----------------|---------------------|----------------------|
| Build failure | Dev self-fixes ≤2 times | Leader asks user |
| Test bug fix | tester→dev loop ≤3 times | Leader asks user |
| Requirements/design issue | Revise and re-Gate ≤2 times | Leader asks user whether to abort |
| Task conflict | Planner re-sequences ≤1 time | Leader decides serialization or worktree |
| Agent unresponsive | Resend message 1 time | Leader asks user |
| Agent context exhausted | Spawn replacement agent ≤1 time | Leader asks user |
| MCP connection failure | Retry ≤2 times | Save state, prompt user to resume after recovery |

Any exception exceeding its limit → Leader must escalate to the user; do not continue retrying automatically.

### Waiting and Timeouts

Leader behavior while waiting for agent replies:
- **Normal wait**: While an agent is executing a task, the Leader stands by (no hard timeout)
- **No-response detection (Level 1)**: If an agent does not reply within the expected timeframe (Phase 1-2: 5 minutes; Phase 3-5: 10 minutes), the Leader sends a ping message
- **Context exhaustion detection (Level 2)**: If ping is unanswered AND the agent's last message or progress report was >15 minutes ago → 判定 context_exhausted
- **Ping unanswered (Level 1 only)**: Leader uses AskUserQuestion to ask user: wait / skip / terminate
- **Agent proactively reports blocking**: Not a timeout — handle via the normal exception path

### Context Exhaustion Recovery

When the Leader detects context_exhausted for an agent:

1. Read state.json → get agent's task assignments and context snapshot
2. Spawn a replacement agent (same role + team-rules.md), injecting:
   - Original task description (from the corresponding phase-N-brief.md)
   - Phase decisions: state.json → phase_decisions[current_phase]
   - Agent's last context snapshot: state.json → agent_context_snapshots[<agent_name>]
   - Instruction: "Previous agent ran out of context. Continue from where it left off. Do NOT restart completed work."
3. Update state.json:
   - Replace the exhausted agent in spawned_agents
   - Reset agent_context_snapshots[<agent_name>]
4. New agent continues without restarting
5. If replacement also exhausts context → escalate to user (do not spawn a third agent)

### Leader Context Protection

After each Gate passes:
1. Persist Gate summary to state.json (see gate.md for procedure)
2. Execute `/compact` to compress the Leader's own context
3. If `/compact` causes loss of recent context → read state.json to restore phase_decisions and gate_summaries

### Exception Routing

- Requirements/design issues → requirements-analyst/architect → may trigger planner re-sequencing
- Build failure → dev self-fixes (≤2 times) → still failing → Leader asks user
- Task conflict → planner reports → Leader decides serialization or worktree
- Test bug → tester → Leader → dev fixes → tester re-verifies
  - When dev fixes bugs, follow [superpowers:systematic-debugging]: write reproduction test first → identify root cause → minimal fix → verify
- MCP failure → handle per "MCP connection lost" scenario in resume.md
