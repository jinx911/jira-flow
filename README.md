**English** | [中文](README.zh-CN.md)

# Jira-Flow: Full-Lifecycle Agent Team Development Workflow

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that orchestrates a multi-agent team to handle the complete development lifecycle from a Jira issue: requirement analysis, design, planning, TDD development, code review, testing, and commit.

```
Jira Issue → 6 Phases + 6 Gates → Branch Pushed + Jira Updated

Phase 1: Requirement Analysis   → proposal.md + design.md
Phase 2: Task Planning + Branch → tasks.md + git branch
Phase 3: TDD Development        → implementation code
Phase 4: Code Review            → structured review report
Phase 5: Test Verification      → evidence-based test report
Phase 6: Finalization           → commit + Jira update
```

Each Phase ends with a **Gate** — a checkpoint where the Leader summarizes the Phase output for your confirmation before proceeding. Two modes available: **Semi-auto** (default, you confirm each Gate) or **Full-auto** (Gates auto-pass, only exceptions escalate).

## Architecture

- **Leader** (your main Claude session) coordinates, decides, and routes — never executes directly
- **Hub-and-Spoke** communication: all agent messages go through the Leader
- **7 specialized agents** are spawned on-demand across the lifecycle
- **Superpowers methodology** integrated at each Phase (TDD, code review, debugging, etc.)

## Prerequisites

| Dependency | Version | How to install |
|------------|---------|----------------|
| **Claude Code CLI** | latest | [Official docs](https://docs.anthropic.com/en/docs/claude-code) |
| **superpowers** plugin | >= 5.0.0 | [superpowers repo](https://github.com/nicekid1/superpowers) — provides 8 methodology skills (TDD, brainstorming, debugging, etc.) |
| **atlassian-rovo** MCP | any | Configure in `~/.claude/settings.json` → `mcpServers` — [MCP quickstart](https://docs.anthropic.com/en/docs/claude-code/mcp) |
| **playwright** MCP | any (optional) | For E2E testing in Phase 5 |

### Agent definitions

This repo includes 21 agent definitions. jira-flow uses 7 core agents:

| Agent | Phase(s) | Purpose |
|-------|----------|---------|
| `requirements-analyst` | 1, 6 | Reads Jira issue, generates OpenSpec proposal, handles Jira finalization |
| `architect` | 1 | Generates design.md with architecture decisions |
| `planner` | 2 | Breaks design into bite-sized TDD tasks |
| `backend-developer` | 2, 3, 6 | Creates branch, implements backend code |
| `frontend-developer` | 3, 6 | Implements frontend code (spawned if design involves frontend) |
| `code-reviewer` | 4 | Reviews all branch changes with severity-graded report |
| `tester` | 5 | Runs unit/integration/E2E tests, reports bugs with evidence |

Additional agents (reviewers, optimizers, etc.) are available for standalone use outside jira-flow.

## Installation

```bash
# 1. Clone
git clone https://github.com/jinx911/jira-flow.git
cd jira-flow

# 2. Install (symlinks skills + agents into ~/.claude/)
chmod +x install.sh
./install.sh

# 3. Verify
ls ~/.claude/skills/jira-flow/      # Should show skill.md, phases/, etc.
ls ~/.claude/agents/requirements-analyst.md  # Should exist
```

### Uninstall

```bash
./uninstall.sh
```

This removes the symlinks. Your cloned repo is preserved.

## Quick Start

### Step 1: Initialize your project

```
/init-jira-flow
```

One-command setup — auto-detects tech stack, generates both config files (flow + project), registers project, verifies MCP connectivity.

Or manually: copy `skills/jira-flow/project-config.example.md` to `<your-project>/.claude/project-config.md` and fill in your values.

### Step 2: Run jira-flow

```
/jira-flow OA-3650
```

Or with a full URL:

```
/jira-flow https://your-domain.atlassian.net/browse/OA-3650
```

### Step 3: Review Gates and iterate

The Leader will present a summary at each Gate. In semi-auto mode (default), confirm to proceed. In full-auto mode, Gates pass automatically — only exceptions pause for your input.

## Configuration

```
~/.claude/configs/projects.json                  ← Global index (path → name mapping)
<project-root>/.claude/project-config.md         ← Project config (repos, DBs, envs)
~/.claude/skills/jira-flow/project-config.md     ← Flow config (root_path, cloudId, branch naming)
```

Lookup chain:
1. Read `jira-flow/project-config.md` → get `root_path`
2. Read `projects.json` → match `root_path` → get project name
3. Read `{root_path}/.claude/project-config.md` → get full project config

See [`skills/jira-flow/project-config.example.md`](skills/jira-flow/project-config.example.md) for all available fields.

## File Structure

```
jira-flow/
├── README.md                     ← This file
├── LICENSE                       ← MIT
├── CONTRIBUTING.md               ← Contribution guidelines
├── install.sh                    ← One-command installer
├── uninstall.sh                  ← Clean uninstaller
├── skills/
│   ├── jira-flow/                ← Main skill (6-phase lifecycle)
│   │   ├── skill.md              ← Flow skeleton + initialization
│   │   ├── gate.md               ← Gate mechanism + pass criteria
│   │   ├── phases/               ← Phase instructions (lazy-loaded)
│   │   │   ├── phase-1-brief.md  ← Requirement analysis
│   │   │   ├── quality-rubric.md ← Proposal quality scoring rubric
│   │   │   ├── phase-2-brief.md  ← Task planning + branch creation
│   │   │   ├── phase-3-brief.md  ← TDD development
│   │   │   ├── phase-4-brief.md  ← Code review
│   │   │   ├── phase-5-brief.md  ← Test verification
│   │   │   └── phase-6-brief.md  ← Finalization
│   │   ├── team-rules.md         ← Team communication rules
│   │   ├── resume.md             ← Breakpoint recovery logic
│   │   └── project-config.example.md  ← Config template
│   ├── init-jira-flow/           ← Project initialization skill
│   ├── create-team/              ← Team creation (Hub-and-Spoke)
│   ├── delete-team/              ← Team cleanup
│   └── git-ops/                  ← Multi-repo git operations
└── agents/                       ← 21 agent definitions
    ├── requirements-analyst.md
    ├── architect.md
    ├── planner.md
    ├── backend-developer.md
    ├── frontend-developer.md
    ├── code-reviewer.md
    ├── tester.md
    └── ... (14 more specialized agents)
```

## Dependencies

| Type | Required | Details |
|------|----------|---------|
| **Skills** | create-team, delete-team, git-ops, init-jira-flow | Bundled in this repo |
| **Plugin** | superpowers >= 5.0.0 | 8 methodology skills |
| **Agents** | 7 core (21 total bundled) | Installed by `install.sh` |
| **MCP** | atlassian-rovo | Jira/Confluence operations |
| **MCP** | playwright | Optional, for E2E testing |
| **MCP** | mysql/postgres | Optional, for database verification |

## Superpowers Integration

Each Phase references a superpowers skill. Agents read the full skill at runtime:

| Phase | Skill | Key Constraint |
|-------|-------|----------------|
| 1 | brainstorming | 2-3 solutions + trade-off + self-review |
| 2 | writing-plans | Bite-sized tasks + TDD steps + zero placeholders |
| 3 | test-driven-development + executing-plans | RED → Verify → GREEN → Verify → REFACTOR |
| 4 | requesting-code-review | git diff structured review + severity levels |
| 5 | verification-before-completion | Evidence-first: command → output → conclusion |
| 6 | finishing-a-development-branch | Full test suite → clean debug code → push |

## Exception Handling

| Exception | Auto-fix limit | Escalation |
|-----------|---------------|------------|
| Build failure | 2 retries | Ask user |
| Test bug fix loop | 3 cycles | Ask user |
| Requirement/design issue | 2 re-Gates | Ask user to terminate? |
| Task conflict | 1 replan | Leader serializes or worktree |
| Agent no response | 1 ping | Ask user |
| MCP connection lost | 2 retries | Save state, resume later |

All exceptions exceeding limits escalate to the user. No infinite retries.

## Core Principles

- **Leader never executes** — only coordinates, decides, and routes
- **Hub-and-Spoke communication** — all agent messages go through Leader
- **Gate checkpoints** — each Phase ends with user confirmation
- **Evidence-based verification** — no claims without supporting evidence
- **Breakpoint recovery** — state saved after each Phase, resume anytime

## License

[MIT](LICENSE)
