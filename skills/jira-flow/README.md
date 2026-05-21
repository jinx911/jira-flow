# Jira-Flow: Full-Lifecycle Agent Team Development Workflow

A Claude Code skill that orchestrates a multi-agent team to handle the complete development lifecycle from a Jira issue: requirement analysis, design, planning, TDD development, code review, testing, and commit.

## Architecture

```
Jira Issue → 6 Phases + 6 Gates → Branch Pushed + Jira Updated

Phase 1: Requirement Analysis   → proposal.md + design.md
Phase 2: Task Planning + Branch → tasks.md + git branch
Phase 3: TDD Development        → implementation code
Phase 4: Code Review            → structured review report
Phase 5: Test Verification      → evidence-based test report
Phase 6: Finalization           → commit + Jira update

Gate mechanism: Leader summarizes each Phase for user confirmation before proceeding.
Two modes: Semi-auto (default, Gate confirmation) / Full-auto (auto-approve Gates).
```

## Quick Start

### 1. Install Dependencies

Ensure the following are in place:

```
~/.claude/skills/
├── jira-flow/          ← This skill
├── create-team/        ← Team creation
├── delete-team/        ← Team cleanup
├── git-ops/            ← Git operations
└── init-jira-flow/     ← One-command jira-flow setup

~/.claude/agents/       ← Agent definitions
├── requirements-analyst.md
├── architect.md
├── planner.md
├── backend-developer.md
├── frontend-developer.md
├── code-reviewer.md
└── tester.md
```

Required plugins: **superpowers** (v5.0+)

Required MCP: **atlassian-rovo** (Jira access)

### 2. Initialize

```
/init-jira-flow
```

One-command setup — auto-detects tech stack, generates both config files (flow + project), registers project, verifies MCP connectivity.

### 3. Run Jira-Flow

```
/jira-flow OA-3650
```

Or with a full URL:
```
/jira-flow https://your-domain.atlassian.net/browse/OA-3650
```

## Configuration Architecture

```
~/.claude/configs/projects.json          ← Global index (path → name mapping)
<project-root>/.claude/project-config.md ← Project config (repos, DBs, envs)
~/.claude/skills/jira-flow/project-config.md ← Flow config (root_path, cloudId, branch naming)
```

Lookup chain:
1. Read `jira-flow/project-config.md` → get `root_path`
2. Read `projects.json` → match `root_path` → get project name
3. Read `{root_path}/.claude/project-config.md` → get full project config

## File Structure

```
~/.claude/skills/jira-flow/
├── README.md                    ← This file (English overview)
├── skill.md                     ← Flow skeleton (frontmatter + init + phase summary + exception handling)
├── gate.md                      ← Gate mechanism (pass criteria + summary format + risk examples)
├── phases/                      ← Phase instructions (lazy-loaded on demand)
│   ├── phase-1-brief.md         ← Requirement analysis
│   ├── phase-2-brief.md         ← Task planning + branch creation
│   ├── phase-3-brief.md         ← TDD development
│   ├── phase-4-brief.md         ← Code review
│   ├── phase-5-brief.md         ← Test verification
│   └── phase-6-brief.md         ← Finalization (commit + Jira update)
├── project-config.md            ← Flow config (root_path, cloudId, branch naming)
├── project-config.example.md    ← Project config template (for open-source users)
├── team-rules.md                ← Team communication rules + variable injection
└── resume.md                    ← Breakpoint recovery logic

All .md files include frontmatter metadata (version, description) for discoverability.
Phase instructions are lazy-loaded: Leader reads phase-N-brief.md only when entering that Phase.
```

## Dependencies

| Type | Required | Details |
|------|----------|---------|
| **Skills** | create-team, delete-team, git-ops, init-jira-flow | In `~/.claude/skills/` |
| **Plugin** | superpowers >= 5.0.0 | 8 methodology skills |
| **Agents** | 7 agents (see below) | In `~/.claude/agents/` |
| **MCP** | atlassian-rovo | Jira/Confluence operations |
| **MCP** | playwright | Optional, for E2E testing |
| **MCP** | mysql/postgres | Optional, for database verification |

### Agent Roles

| Agent | Phase(s) | Purpose |
|-------|----------|---------|
| `requirements-analyst` | 1, 6 | Reads Jira issue, generates OpenSpec proposal.md, handles Jira finalization |
| `architect` | 1 | Reads proposal, generates design.md with architecture decisions |
| `planner` | 2 | Breaks design into bite-sized TDD tasks (tasks.md + TaskCreate) |
| `backend-developer` | 2, 3, 6 | Creates branch, implements backend code, merges to test |
| `frontend-developer` | 3, 6 | Implements frontend code (spawned if design involves frontend) |
| `code-reviewer` | 4 | Reviews all branch changes with severity-graded report |
| `tester` | 5 | Runs unit/integration/E2E tests, reports bugs with evidence |

## Superpowers Integration

Each Phase references a superpowers skill. Agents read the full SKILL.md at runtime rather than relying on inline excerpts:

| Phase | Skill | Key Constraint |
|-------|-------|----------------|
| 1 | brainstorming | 2-3 solutions + trade-off + self-review |
| 2 | writing-plans | Bite-sized tasks + TDD steps + zero placeholders |
| 3 | test-driven-development + executing-plans | RED→Verify→GREEN→Verify→REFACTOR |
| 4 | requesting-code-review | git diff structured review + severity levels |
| 5 | verification-before-completion | Evidence-first: command→output→conclusion |
| 6 | finishing-a-development-branch | Full test suite → clean debug code → push |

## Core Principles

- **Leader never executes** — only coordinates, decides, and routes
- **Hub-and-Spoke communication** — all agent messages go through Leader
- **Gate checkpoints** — each Phase ends with a Gate for user confirmation
- **Evidence-based verification** — no claims without supporting evidence

## License

MIT
