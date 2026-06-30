**English** | [中文](README.zh-CN.md)

# Dev-Flow: Full-Lifecycle Agent Team Development Workflow

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that orchestrates a multi-agent team through the complete development lifecycle — from a Jira issue OR a natural-language requirement — via four reusable sub-skills: spec, dev, review-test, ship.

```
Requirement (Jira key or text) → 4 Stages + 4 Gates → Branch Pushed + Jira Updated

Stage 1: Spec        (spec-author)   → proposal.md + design.md (adaptive engineering sections)
Stage 2: Dev         (dev-loop)      → tasks.md + branch + implementation (conditional TDD)
Stage 3: Review-Test (review-test)   → review + verify + fix loop
Stage 4: Ship        (ship)          → push + deploy + Jira wrap-up
```

Each Stage ends with a **Gate** (a checklist the Leader presents for your confirmation). Two modes: **Semi-auto** (default, confirm each Gate) or **Full-auto** (Gates auto-pass, only exceptions escalate).

## Architecture

- **Leader** (your main Claude session) coordinates, decides, routes — never executes directly (keeps its context clean)
- **Thin orchestrator + 4 sub-skills**: each stage is an independently invocable skill (`/spec-author`, `/review-test`, `/ship` can run standalone)
- **Hub-and-spoke** communication: all agent messages route through the Leader
- **Role expertise lives inside sub-skills** — dev-flow does NOT depend on `~/.claude/agents/*.md`
- **Living docs**: spec-deltas update the docs before code when requirements change mid-dev
- **Conditional TDD**: TDD only for logic-bearing work; scaffolding/config skip it

## What's new vs the old jira-flow

| Was (jira-flow, 6 phases) | Now (dev-flow, 4 stages) |
|---|---|
| Double self-scoring rubric | Structural doc template + checklist Gate (no self-score) |
| Frozen Phase 1-2 docs | Living docs (doc-first change protocol) |
| TDD everywhere | Conditional TDD (per-unit test strategy) |
| 6-step Prompt Build per spawn | Pre-resolved prompt files; spawn = read + `Agent()` |
| ack / `[URGENT-NOACK]` / 3-level health detection | TaskList as source of truth; one ping → ask user |
| Depended on agent definition files | Decoupled; role expertise embedded in sub-skills |

## Prerequisites

| Dependency | Version | How to install |
|------------|---------|----------------|
| **Claude Code CLI** | latest | [Official docs](https://docs.anthropic.com/en/docs/claude-code) |
| **superpowers** plugin | >= 5.0.0 | [superpowers repo](https://github.com/nicekid1/superpowers) |
| **atlassian-rovo** MCP | any | Required for jira mode; not needed in free-flow mode |
| **jenkins** MCP | any (optional) | For auto-deploy in Stage 4 |
| **playwright** MCP | any (optional) | For E2E testing in Stage 3 |

### Agent definitions (optional)

This repo includes agent definitions, but **dev-flow does not read them** — role expertise is embedded in each sub-skill. They remain available for standalone use outside dev-flow.

## Installation

```bash
# 1. Clone
git clone https://github.com/jinx911/dev-flow.git
cd dev-flow

# 2. Install (symlinks skills into ~/.claude/)
chmod +x install.sh
./install.sh

# 3. Verify
ls ~/.claude/skills/dev-flow/        # Should show SKILL.md, gate.md, ...
ls ~/.claude/skills/spec-author/     # 4 sub-skills present
```

### Uninstall

```bash
./uninstall.sh
```

This removes the symlinks. Your cloned repo is preserved.

## Quick Start

### Step 1: Initialize your project

```
/init-dev-flow
```

One-command setup — auto-detects tech stack, generates config files, registers the project, verifies connectivity.

Or manually: copy `skills/dev-flow/project-config.example.md` to `<your-project>/.claude/project-config.md` and fill in values.

### Step 2: Run dev-flow

**Jira mode** (requires a Jira issue key):

```
/dev-flow OA-3650
```

**Free-flow mode** (no Jira ticket needed):

```
/dev-flow Add CSV export feature for user management
```

Free-flow mode skips Jira-dependent steps (Jira wrap-up) and uses your natural-language description directly as the requirement source.

### Step 3: Review Gates and iterate

The Leader presents a checklist summary at each Gate. In semi-auto (default), confirm to proceed; in full-auto, Gates pass automatically — only exceptions pause for your input.

## Configuration

```
~/.claude/configs/projects.json                  ← Global index (path → name)
<project-root>/.claude/project-config.md         ← Project config (repos, DBs, envs)
~/.claude/skills/dev-flow/project-config.md      ← Flow config (root_path, cloudId, branch naming)
```

Lookup chain:
1. Read `dev-flow/project-config.md` → get `root_path`
2. Read `projects.json` → match `root_path` → get project name
3. Read `{root_path}/.claude/project-config.md` → get full project config

See [`skills/dev-flow/project-config.example.md`](skills/dev-flow/project-config.example.md) for all fields.

## File Structure

```
dev-flow/
├── skills/
│   ├── dev-flow/                ← Thin orchestrator (Leader playbook)
│   │   ├── SKILL.md             ← Stages, Gates, delegation, state
│   │   ├── gate.md              ← Checklist Gate definitions
│   │   ├── team-rules.md        ← Slim comm rules + Health
│   │   ├── resume.md            ← Breakpoint recovery
│   │   └── project-config.example.md
│   ├── spec-author/             ← Stage 1: requirement → proposal + design
│   │   ├── SKILL.md
│   │   ├── triggers.md          ← Trigger → required engineering section
│   │   └── templates/           ← proposal / design templates
│   ├── dev-loop/                ← Stage 2: tasks + branch + TDD + doc-first change
│   │   ├── SKILL.md
│   │   └── doc-first-change.md
│   ├── review-test/             ← Stage 3: review + verify + fix loop
│   │   └── SKILL.md
│   ├── ship/                    ← Stage 4: finalize + deploy + Jira
│   │   └── SKILL.md
│   ├── init-dev-flow/           ← Project initialization
│   ├── create-team/             ← Team creation (hub-and-spoke)
│   ├── delete-team/             ← Team cleanup
│   └── git-ops/                 ← Multi-repo git operations
└── agents/                      ← Optional agent definitions (NOT read by dev-flow)
```

## Dependencies

| Type | Required | Details |
|------|----------|---------|
| **Skills** | create-team, delete-team, git-ops, init-dev-flow, spec-author, dev-loop, review-test, ship | Bundled |
| **Plugin** | superpowers >= 5.0.0 | Methodology skills |
| **Agents** | none required | Role expertise embedded in sub-skills; bundled agents optional |
| **MCP** | atlassian-rovo | Jira/Confluence ops (jira mode) |
| **MCP** | jenkins, playwright | Optional (deploy / E2E) |
| **MCP** | mysql/postgres | Optional (database verification) |

## Superpowers Integration

Each sub-skill references a superpowers skill, loaded at runtime:

| Stage | Sub-skill | Skill |
|---|---|---|
| 1 | spec-author | brainstorming |
| 2 | dev-loop | test-driven-development + executing-plans |
| 3 | review-test | requesting-code-review + verification-before-completion |
| 4 | ship | finishing-a-development-branch |

## Exception Handling

| Exception | Auto-fix limit | Escalation |
|-----------|---------------|------------|
| Build failure | 2 retries | Ask user |
| Test bug fix loop | 3 cycles | Ask user |
| Requirement/design revision (spec-delta) | 2 | Ask user whether to abort |
| Task conflict | 1 replan | Leader serializes or uses worktree |
| Agent no response | 1 ping | Ask user |
| MCP connection lost | 2 retries | Save state, resume later |

All exceptions exceeding limits escalate to the user. No infinite retries.

## Core Principles

- **Leader never executes** — only coordinates, decides, routes (context stays clean)
- **Hub-and-spoke** — all agent messages route through Leader
- **Checklist Gates** — each Stage ends with user confirmation
- **Living docs** — spec-deltas update docs before code
- **Conditional TDD** — TDD only when the work has testable logic
- **Evidence-based verification** — no claims without supporting evidence
- **Breakpoint recovery** — state saved per Stage, resume anytime
