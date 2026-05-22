---
title: P0 Context Window Exhaustion Prevention
date: 2026-05-22
status: approved
scope: P0 - Leader context protection + agent output constraints + state persistence
---

# P0: Context Window Exhaustion Prevention

## Problem

When jira-flow teams run complex tasks, agent context windows fill up. When an agent's context is exhausted, it stops responding silently. The Leader has no way to detect this or recover from it, causing the entire workflow to stall.

Root causes:
1. No constraints on agent output volume — agents send full content to Leader
2. No detection mechanism for context exhaustion — only timeout-based ping
3. No state persistence between phases — context loss is unrecoverable
4. Leader accumulates all agent output without compression

## Solution: Agent Built-in Summarization + State Enhancement

Four coordinated changes to the jira-flow skill files.

### 1. Agent Output Constraints (team-rules.md)

Add two rules to the Communication Rules section:

**Rule 1: Structured Summary Output**

All agent messages to Leader must follow this format:

```
## Task Completion Report

**Status**: completed | failed | blocked
**Summary**: ≤3 sentences describing the result
**Files Changed**: [file list, max 10]
**Test Result**: pass/fail/N/A + key metrics (e.g., coverage %)
**Issues**: [blocker descriptions, or "None"]
```

No code snippets, diffs, or full file contents. If Leader needs details, it will Read files directly.

Exception: Phase 1-2 analysis results (proposal.md/design.md content) follow the existing file-based delivery. The JSON summary rule applies to status reports and completion messages.

**Rule 2: Progress Reporting**

When executing operations expected to take >3 minutes, agents must send a brief progress update after each sub-step:

```
## Progress Update

**Task**: [current task name]
**Step**: [current step] / [total steps]
**Status**: in_progress
**ETA**: [estimated remaining time or "unknown"]
```

This enables the Leader to distinguish "agent is busy" from "agent context is exhausted."

### 2. Context Exhaustion Detection & Recovery (skill.md)

Add to Exception Handling section:

**Detection Logic (Two-Level)**:

```
Level 1 - Timeout Detection (existing):
  Phase 1-2: No message for 5 min → send ping
  Phase 3-5: No message for 10 min → send ping

Level 2 - Context Exhaustion Determination (new):
  ping unanswered AND last message/progress report > 15 min ago
  →判定为 context_exhausted
```

**Recovery Flow**:

```
1. Leader detects agent context_exhausted
2. Leader reads state.json → get the agent's task assignments
3. Leader reads agent_context_snapshots → get last known progress
4. Leader spawns new agent, injecting:
   a. Original task description (from phase-N-brief.md)
   b. Phase decisions from state.json → phase_decisions[current_phase]
   c. Agent's last context snapshot from state.json → agent_context_snapshots[agent_name]
   d. Instruction: "Previous agent ran out of context. Continue from where it left off."
5. New agent continues without restarting
6. Leader updates state.json spawned_agents list
```

**Leader Self-Protection**:

After each Gate passes, the Leader executes `/compact` (Claude Code's built-in context compression). Gate summaries are persisted to state.json so critical decisions survive compression.

### 3. State Persistence Enhancement (resume.md + state.json)

**Enhanced state.json schema**:

```json
{
  "issue_key": "OA-3650",
  "team_name": "jira-flow-OA-3650",
  "mode": "semi-auto",
  "branch": "OA-3650",
  "current_phase": 3,
  "spawned_agents": ["requirements-analyst", "architect", "planner", "backend-dev"],
  "openspec_name": "{spec_name}",
  "gate_summaries": {
    "1": "proposal: xxx, design: xxx",
    "2": "tasks: 12 total, branch: OA-3650"
  },
  "phase_decisions": {
    "1": {
      "scope": "Backend API for user auth",
      "key_files": ["src/auth/controller.ts", "src/auth/service.ts"],
      "architecture_choice": "JWT + refresh token",
      "risks": ["New table needed - requires DBA review"]
    },
    "2": {
      "total_tasks": 12,
      "parallel_groups": 3,
      "estimated_complexity": "medium"
    }
  },
  "agent_context_snapshots": {
    "backend-dev": {
      "last_progress": "Step 5/8: implementing auth service",
      "last_files_changed": ["src/auth/service.ts", "tests/auth/service.test.ts"],
      "last_update": "2026-05-22T10:30:00Z"
    }
  },
  "updated_at": "<ISO>"
}
```

**New fields**:

| Field | Purpose | Updated When |
|-------|---------|-------------|
| `phase_decisions` | Key decisions per phase (≤100 chars/field) | After each Gate passes |
| `agent_context_snapshots` | Last known progress per agent | On every progress report / completion |

**Persistence timing**:

- Gate passes → write `gate_summaries` + `phase_decisions` + advance `current_phase`
- Agent sends progress report → update `agent_context_snapshots[agent_name]`
- Agent task completes → update corresponding snapshot
- Phase 3: each task completed → update snapshot

**Recovery usage**:

- Leader context compressed → read `phase_decisions` from state.json to restore key context
- New agent spawned for recovery → inject `phase_decisions[phase]` + `agent_context_snapshots[agent]` as background

### 4. Gate Summary Persistence (gate.md)

Add "Gate Summary Persistence" rule:

After Gate passes, Leader executes:

```
1. Generate Gate Summary (existing format)
2. Extract key decisions → write to state.json phase_decisions[current_phase]
3. Update state.json gate_summaries[current_phase] = summary
4. Update state.json current_phase = next_phase
5. Update state.json updated_at = now()
6. Execute /compact to free Leader context
```

**Extraction rules**:

- `scope`: From agent summary, ≤1 sentence
- `key_files`: From files_changed list, ≤10 files
- `architecture_choice`: Core decision from design.md or architect report
- `risks`: From Gate Summary Risks section

## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `skills/jira-flow/team-rules.md` | Add rules | Structured summary output + progress reporting |
| `skills/jira-flow/skill.md` | Add section | Context exhaustion detection & recovery flow |
| `skills/jira-flow/resume.md` | Enhance | State file schema + recovery with phase_decisions and snapshots |
| `skills/jira-flow/gate.md` | Add section | Gate summary persistence + /compact trigger |
| `skills/jira-flow/phases/phase-3-brief.md` | Minor update | Reference progress reporting rule |

## Success Criteria

1. Agent messages to Leader are consistently ≤500 chars (excluding file-based deliverables)
2. Leader can detect context exhaustion within 15 minutes of occurrence
3. Leader can recover by spawning a new agent with sufficient context
4. Leader's own context grows ≤30% compared to current behavior
5. All state survives Leader `/compact` — recoverable from state.json alone

## Out of Scope (P1+)

- Agent task splitting (>5 files → auto-split)
- Agent context budget management
- Token usage tracking/metrics
- rule-advisor pattern (dynamic rule loading)
