# Jira-Flow Training Guide

> Full-lifecycle Agent Team development workflow — from Jira Issue to code commit

---

## 1. Overview

### What is Jira-Flow?

Jira-Flow is a Claude Code Skill that automates the complete development workflow from a Jira Issue to code commit. It coordinates multiple AI Agents via a Hub-and-Spoke pattern through 6 Phases + 6 Gates:

```
Jira Issue → Requirement Analysis → Architecture Design → Task Planning → TDD Development → Code Review → Test Verification → Commit & Push
```

### Core Value

- **Full-lifecycle automation**: From requirements to commit, no manual tool switching
- **Built-in quality**: 6 Gate checkpoints ensure quality at every step
- **TDD-driven**: Test-first enforcement guarantees code quality
- **Human-AI collaboration**: Semi-auto mode keeps key decisions with the user
- **Recoverable**: Breakpoint recovery mechanism — resume after interruption

### Two Running Modes

| Feature | Semi-auto (default) | Full-auto |
|---------|---------------------|-----------|
| Gate | Show summary + user confirmation | Auto-pass, log summary |
| Exceptions | All exceptions ask user | Only over-limit asks user |
| Jira finalization | User confirms before submit | Auto-submit |
| Use case | Complex requirements, first-time use | Simple requirements, experienced users |

---

## 2. Architecture Deep Dive

### Hub-and-Spoke Pattern

```
                    ┌──────────┐
                    │   User   │
                    └────┬─────┘
                         │ /jira-flow OA-3650
                    ┌────▼─────┐
                    │  Leader  │ ← Orchestrator (never executes operations)
                    └────┬─────┘
                         │ SendMessage
              ┌──────────┼──────────┐
         ┌────▼────┐ ┌──▼────┐ ┌──▼──────┐
         │Core Team│ │Dev    │ │Review   │
         │         │ │Team   │ │Team     │
         └─────────┘ └───────┘ └─────────┘
```

**Key Principles**:
- Leader **never executes** any operation directly
- Leader only coordinates, decides, and manages state transitions
- All inter-Agent communication **must route through Leader**
- Agents **must not communicate directly** with other Agents

### 7 Agent Roles

| Agent | Model | Created at | Responsibility |
|-------|-------|-----------|----------------|
| requirements-analyst | Opus | Phase 0 | Read Jira, analyze requirements, generate proposal |
| architect | Opus | Phase 0 | Architecture design, generate design.md |
| planner | Opus | Phase 0 | Task breakdown, TDD step planning |
| backend-developer | Sonnet | After Gate 1 | Backend code implementation |
| frontend-developer | Sonnet | After Gate 1 | Frontend code implementation (on-demand) |
| code-reviewer | Sonnet | Before Phase 4 | Code review with severity grading |
| tester | Sonnet | Before Phase 5 | Test verification, bug reporting |

### On-Demand Scaling Strategy

Not all Agents are created upfront:

```
Phase 0: Core Team (requirements-analyst + architect + planner)
  ↓
Gate 1: Check if design.md involves frontend/backend
  ↓
After Gate 1: Create backend-developer / frontend-developer
  ↓
Before Phase 4: Create code-reviewer
  ↓
Before Phase 5: Create tester
```

**Why?** Resource efficiency — create on demand, each Agent has a clear lifecycle.

---

## 3. Phase Details

### Phase 0: Initialization

**What happens**:
1. Prerequisite checks (dependency skills, superpowers plugin, agent definitions, MCP)
2. Parse Jira Issue Key
3. Load configuration (projects.json → project-config.md → jira-flow config)
4. Breakpoint detection (check for unfinished workflows)
5. Select running mode (semi-auto / full-auto)
6. Create core team

**Pre-cleanup**: First agent in Phase 1 runs `find {changes_path} -type d -empty -delete` to clean up residual empty directories.

**Output**: Configuration ready + core team created

---

### Phase 1: Requirement Analysis

**Participants**: requirements-analyst → architect

**Flow**:
```
requirements-analyst:
  1. Clean empty directories: find {changes_path} -type d -empty -delete
  2. Read Jira Issue via Atlassian MCP (description, comments, attachments)
  3. Propose 2-3 implementation approaches (with trade-off analysis)
  4. Provide recommended approach with rationale
  5. Baseline association check (if baseline_path exists and is non-empty):
     - Scan related baseline documents under baseline_path
     - Mark "baseline constraints" section in proposal
     - Ensure approach doesn't conflict with baselines
  6. Spec self-review (placeholder, consistency, scope, ambiguity checks)
  7. Output: proposal.md

architect:
  1. Read proposal.md
  2. Explore related code architecture
  3. Design module breakdown (single responsibility, clear interfaces)
  4. Design self-review
  5. Output: design.md + whether backend/frontend is involved
```

**Output**: `proposal.md` + `design.md`

**Gate 1 Pass Criteria**:
- proposal.md + design.md have no placeholders (TBD/TODO)
- Internally consistent (no contradictions across sections)
- Affected modules clearly identified

---

### Phase 2: Task Planning + Branch

**Participants**: planner → backend-developer

**Flow**:
```
planner:
  1. Read design.md
  2. Break into bite-sized tasks (2-5 minutes each)
  3. Each task includes TDD steps:
     RED(write failing test) → Verify RED → GREEN(minimal implementation) → Verify GREEN → REFACTOR → Commit
  4. Create tasks.md + TaskCreate tracking entries
  5. Mark blockedBy dependencies

backend-developer:
  1. /git-ops create development branch
  2. Branch from master, naming follows project-config rules
```

**Output**: `tasks.md` + git branch

**Gate 2 Pass Criteria**:
- tasks.md has no placeholders
- Each step has file paths and commands
- blockedBy dependencies are correct

---

### Phase 3: TDD Development

**Participants**: backend-developer + frontend-developer (parallel)

**Core Principle — TDD Discipline**:
> Never write production code without a failing test first. Write tests first — always!

**Flow**:
```
For each task:
  1. RED:    Write minimal test demonstrating expected behavior
  2. Verify: Run and confirm failure (missing feature, not syntax error)
  3. GREEN:  Write minimal code to pass test
  4. Verify: Run and confirm pass, no other tests regress
  5. REFACTOR: Clean up (deduplicate, improve naming, extract helpers)
  6. Commit: Commit current step
```

**Frontend/Backend Conflict Handling**:

| Scenario | Strategy |
|----------|----------|
| Different repos | Natural isolation, develop independently |
| Same repo, different files | Same branch, each modifies their own |
| Same repo, same file, different locations | Same branch, watch merge order |
| Same repo, same file, overlapping changes | **Worktree isolation** — each in independent working tree |

**Output**: Implementation code + test code

**Gate 3 Pass Criteria**:
- All Tasks status completed
- Tests passing

---

### Phase 4: Code Review

**Participants**: code-reviewer

**Flow**:
```
code-reviewer:
  1. Get BASE_SHA (before branch creation) and HEAD_SHA (current HEAD)
  2. git diff structured review (no relying on memory)
  3. Severity grading:
     CRITICAL: Security vulnerability / data loss risk → Block merge
     HIGH: Bug or significant quality issue → Fix before merge
     MEDIUM: Maintainability concern → Suggest fix
     LOW: Style or minor suggestion → Optional
  4. For each issue: file path:line number + problem description + fix suggestion
```

**Output**: Review report (graded by C/H/M/L)

**Gate 4 Pass Criteria**:
- No CRITICAL issues
- No unaddressed HIGH issues
- If any → dev fixes, code-reviewer re-reviews

---

### Phase 5: Test Verification

**Participants**: tester

**Core Principle — Evidence Discipline**:
> Any completion claim must be backed by immediately verifiable evidence. No "it should work now"!

**Flow**:
```
tester:
  1. Read proposal.md + tasks.md
  2. Run test suites (unit + integration + E2E)
  3. Database verification (via MCP queries)
  4. Each verification provides: command + output summary + exit code
  5. Bug report: reproduction steps + expected + actual + evidence
```

**Bug Fix Loop** (all routed through Leader):
```
tester finds Bug → Leader → Leader assigns owner → dev fixes → Leader → tester re-verifies
→ Not passed → Another round (≤3 times) → Still failing → Leader asks user
```

**Output**: Test report

**Gate 5 Pass Criteria**:
- All tests passing
- No unfixed bugs

---

### Phase 6: Finalization

**Participants**: backend-developer + requirements-analyst

**Flow**:
```
backend-developer:
  1. Confirm all tests pass (full test suite)
  2. Clean up debug code (console.log/dd/dump etc.)
  3. Commit and push branch
  4. Merge to deploy_branch (if test branch is configured)

requirements-analyst:
  1. Transition main Jira → "In Testing" (or configured target status)
  2. Search for auto-created sub-issues
  3. Fill in testing notes (change summary, affected modules, testing highlights)
  4. Transition sub-issues → "Done" (or configured completion status)
```

**Output**: Branch pushed + Jira updated + team cleaned up

**Gate 6 Pass Criteria**:
- Branch pushed
- deploy_branch merged (if configured)
- Jira updated

---

## 4. Configuration System

### Three-Layer Configuration Architecture

```
Layer 1: Global Index
  ~/.claude/configs/projects.json
  → Project path → project name mapping

Layer 2: Project Config
  {root_path}/.claude/project-config.md
  → Full project info (repos, databases, test environments, build commands)

Layer 3: Flow Config
  ~/.claude/skills/jira-flow/project-config.md
  → jira-flow workflow config (root_path, cloudId, branch naming, OpenSpec)
```

### Lookup Chain

```
jira-flow/project-config.md → root_path
  → projects.json → project name
    → {root_path}/.claude/project-config.md → full config

When root_path is empty: auto-fill from projects.json
```

### Key Configuration Fields

```yaml
# jira-flow/project-config.md
root_path: ""                    # Empty = auto-fill from projects.json
cloudId: ""                      # Atlassian Cloud ID (auto-detected)
branch_naming:
  format: "{issue_key}"          # Branch naming rule (use Jira key directly)
openspec:
  changes_path: "openspec/changes"   # Working output (proposal/design/tasks)
  baseline_path: "openspec/specs"    # System baseline (optional, Phase 1 baseline check)

# project-config.md
databases:                       # Database connections (for test verification)
  - name: main
    connection: "tenant-wd"
test_environments:               # Test environments
  - url: "https://..."
    credentials: "..."
build_commands:                  # Build commands
  backend: "php artisan"
  frontend: "pnpm build:backend"
deploy_branch: "test"            # Deploy branch (optional)
jira_workflow:                   # Jira workflow (optional)
  testing_status: "In Testing"
  auto_creates_sub: true
  sub_completion_status: "Done"
  testing_note_template: "..."
```

---

## 5. Superpowers Integration

Each Phase references a Superpowers methodology skill. Agents read the corresponding SKILL.md at runtime to get the full methodology.

| Phase | Superpowers Skill | Core Constraint |
|-------|------------------|-----------------|
| 1 Requirement Analysis | brainstorming | 2-3 approaches + trade-offs + self-review |
| 2 Task Planning | writing-plans | Bite-sized + TDD steps + zero placeholders |
| 3 TDD Development | TDD + executing-plans | RED→Verify→GREEN→Verify→REFACTOR |
| 4 Code Review | requesting-code-review | git diff + severity grading |
| 5 Test Verification | verification | Evidence discipline: command→output→conclusion |
| 6 Finalization | finishing-a-branch | Full tests → cleanup → push |
| Exception Handling | systematic-debugging | Reproduce first → root cause → minimal fix |

---

## 6. Exception Handling

### Unified Retry Limits

| Exception Type | Self-fix limit | Over-limit action |
|---------------|----------------|-------------------|
| Build failure | dev ≤2 times | Leader asks user |
| Test bug | Loop ≤3 times | Leader asks user |
| Requirement/design issue | Re-Gate after fix ≤2 times | Leader asks whether to terminate |
| Task conflict | planner replan ≤1 time | Leader serializes or uses worktree |
| Agent no response | Resend 1 time | Leader asks user |
| MCP connection failure | Retry ≤2 times | Save state, resume later |

### Timeout Detection

- Phase 1-2: Agent doesn't respond in 5 minutes → Leader sends ping
- Phase 3-5: Agent doesn't respond in 10 minutes → Leader sends ping
- ping no response → Leader asks user: Wait / Skip / Terminate

---

## 7. File Structure

```
~/.claude/skills/
├── jira-flow/
│   ├── skill.md                    ← Flow skeleton
│   ├── gate.md                     ← Gate mechanism (pass criteria + summary format)
│   ├── phases/                     ← Phase instructions (lazy-loaded)
│   │   ├── phase-1-brief.md        ← Requirement analysis
│   │   ├── phase-2-brief.md        ← Task planning + branch
│   │   ├── phase-3-brief.md        ← TDD development
│   │   ├── phase-4-brief.md        ← Code review
│   │   ├── phase-5-brief.md        ← Test verification
│   │   └── phase-6-brief.md        ← Finalization
│   ├── project-config.md           ← Flow config
│   ├── project-config.example.md   ← Project config template
│   ├── team-rules.md               ← Team communication rules
│   └── resume.md                   ← Breakpoint recovery logic
├── create-team/                    ← Team creation
├── delete-team/                    ← Team cleanup
├── git-ops/                        ← Git operations
└── init-jira-flow/                 ← One-command initialization
```

**Lazy Loading Design**: Leader only reads phase-N-brief.md when entering that Phase, minimizing context usage.

---

## 8. Quick Start

### 1. Install Dependencies

Ensure the following are ready:
- Claude Code CLI
- superpowers plugin (v5.0+)
- Dependency skills: create-team, delete-team, git-ops, init-jira-flow
- Agent definitions: 7 agents in `~/.claude/agents/`
- MCP: atlassian-rovo (required), mysql (optional), playwright (optional)

### 2. Initialize

```
/init-jira-flow
```

One-command setup: auto-detect tech stack, generate both configs, register project, verify MCP connectivity.

### 3. Run

```
/jira-flow OA-3650
```

Or:
```
/jira-flow https://your-domain.atlassian.net/browse/OA-3650
```

### 4. Interact

In semi-auto mode, each Gate shows a summary and waits for confirmation:
- Confirm → Continue to next Phase
- Modify → Leader forwards modification instructions
- Terminate → Clean up team, workflow ends

---

## 9. FAQ

**Q: Why can't Leader execute operations directly?**
A: Separation of concerns. Leader only coordinates and decides; all execution is done by specialized Agents. This ensures clear responsibility attribution and audit trail for every operation.

**Q: What if tasks conflict between Agents?**
A: Leader detects conflicts and uses worktree isolation (creating independent working trees for each Agent) to avoid file conflicts.

**Q: Can I pause mid-workflow?**
A: Yes. jira-flow supports breakpoint recovery. State is saved in `{root_path}/.jira-flow/{issue_key}-state.json`. Restarting the same Issue will auto-resume.

**Q: Is full-auto mode safe?**
A: In full-auto mode, CRITICAL and HIGH issues still escalate to the user. Gate quality checks still execute — they just skip manual confirmation. Over-limit retries also escalate to the user.

**Q: How do I configure jira-flow for a new project?**
A: Run `/init-jira-flow` for one-command auto-detection of tech stack, config generation, and MCP verification. You can also manually create `project-config.md` (see `project-config.example.md`).

**Q: How do Superpowers skills work?**
A: Each Phase references a specific superpowers skill. When an Agent receives a `[superpowers:xxx]` tag, it first reads the corresponding SKILL.md for the full methodology, then follows those principles. jira-flow's Gate mechanism replaces superpowers' interactive verification.
