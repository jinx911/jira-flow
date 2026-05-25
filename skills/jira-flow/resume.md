---
partOf: jira-flow
version: 1.0.0
description: Breakpoint recovery logic. When jira-flow detects a state.json file, follow this procedure to resume the interrupted workflow.
---

# Breakpoint Recovery

> When `/jira-flow` detects an existing `{issue_key}-state.json`, follow this recovery procedure.

## State File

Location: `{root_path}/.jira-flow/{issue_key}-state.json`

```json
{
  "issue_key": "{issue_key}",
  "team_name": "jira-flow-{issue_key}",
  "mode": "semi-auto",
  "branch": "<branch-name>",
  "current_phase": 3,
  "phase1_substep": "gate1",
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
    }
  },
  "user_answers": {
    "checkpoint_a": "<user requirement confirmation>",
    "checkpoint_b": "<user selected option>"
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

### New Fields

| Field | Purpose | Updated When |
|-------|---------|-------------|
| `phase_decisions` | Key decisions per phase (≤100 chars/field) | After each Gate passes |
| `agent_context_snapshots` | Last known progress per agent | On every agent progress report / completion |
| `phase1_substep` | Phase 1 internal step tracking ("step1"\|"step2"\|"step3"\|"step4"\|"gate1") | After each Phase 1 step completes |
| `user_answers` | User responses from Phase 1 Checkpoint A and B | After each checkpoint interaction |

### Persistence Timing

- **Gate passes**: Leader writes `gate_summaries` + `phase_decisions` + advances `current_phase`
- **Agent progress report received**: Leader updates `agent_context_snapshots[agent_name]`
- **Agent task completes**: Leader updates corresponding snapshot
- **Phase 3 — each task completed**: Leader updates snapshot for the dev agent

## Recovery Procedure

```
1. Read {issue_key}-state.json
2. AskUserQuestion: "Found incomplete workflow for {issue_key} (Phase {n}/6). Resume?"
   → No: Delete state, start from scratch
   → Yes:
3. Re-spawn all agents listed in state.spawned_agents (appending team-rules.md)
4. For each re-spawned agent, inject context from state:
   - phase_decisions[current_phase] → agent gets key decisions from prior phases
   - agent_context_snapshots[agent_name] → agent knows where the previous instance left off
5. Determine breakpoint → jump to the corresponding Phase:
   current_phase == 1:
     phase1_substep not set or "step1" → Step 1 (initial analysis)
     phase1_substep == "step2" → Step 2 (options proposal, re-use user_answers.checkpoint_a)
     phase1_substep == "step3" → Step 3 (generate proposal, re-use user_answers.checkpoint_b)
     phase1_substep == "step4" → Step 4 (architecture design)
     phase1_substep == "gate1" → Gate 1
   current_phase == 2: tasks.md exists → Phase 3, otherwise → Phase 2
   current_phase == 3: TaskList has incomplete tasks → continue Phase 3, otherwise → Phase 4
   current_phase == 4-6: Start from that Phase
6. Agents read context from disk files (proposal/design/tasks) AND state.json phase_decisions
```

After each Gate confirmation, the Leader updates the state file (setting current_phase to the next Phase number).
After Phase 6 completes, the state file is deleted.

## Exception Recovery Scenarios

### Agent Spawn Failure

```
Spawning a specific agent fails → Leader records the failed agent name in state.failed_agents
→ Retry spawn (up to 2 times)
→ Still failing → AskUserQuestion: continue without that role / abort the workflow
```

### Leader Session Crash

```
On recovery, the Leader reads the state:
  - current_phase < 3 → prior deliverables (proposal/design/tasks) are on disk, can resume directly
  - current_phase == 3 → check TaskList for completed and incomplete tasks
    → re-spawn dev agent, continue from incomplete tasks in TaskList
  - current_phase >= 4 → check git log to confirm code state, resume from the corresponding Phase
  - gate_summaries records each Gate's summary for user reference during recovery
```

### MCP Connection Lost

```
Atlassian MCP unavailable (Phase 1 reads Jira / Phase 6 updates Jira):
  → Leader AskUserQuestion: "MCP connection failed. Retry?"
  → Retry up to 2 times
  → Still failing → save state, prompt user to manually restore MCP then re-run /jira-flow

MySQL MCP unavailable (Phase 5 database verification):
  → Tester skips the database verification step, notes in test report "DB verification skipped (MCP unavailable)"
  → Does not block the workflow
```

### External Config Modified Mid-Workflow

```
{root_path}/.claude/project-config.md was modified:
  → Leader detects it (by comparing Read against cached config summary)
  → AskUserQuestion: "Project config has changed. Continue with the new config?"
  → Yes: reload config, notify running agents
  → No: continue with the previous config
```
