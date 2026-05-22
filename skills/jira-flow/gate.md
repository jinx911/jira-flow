---
partOf: jira-flow
version: 1.0.0
description: Gate mechanism detailed rules. Leader reads this file when executing Gate checkpoints.
---

# Gate Mechanism

At the end of each Phase, the Leader executes a Gate checkpoint:

1. **Collect**: Aggregate all agent reports from the current Phase
2. **Quality check**: Evaluate whether deliverables meet Gate pass criteria (see table below)
3. **Persist**: Write Gate results to `{root_path}/.jira-flow/{issue_key}-state.json`:
   - `gate_summaries[current_phase]` = the Gate Summary text
   - `phase_decisions[current_phase]` = extracted key decisions:
     - `scope`: From agent summary, ≤1 sentence
     - `key_files`: From files_changed list, ≤10 files
     - `architecture_choice`: Core decision from design.md or architect report (Phase 1-2 only; omit for Phase 3-6)
     - `risks`: From Gate Summary Risks section (if any)
   - `current_phase` = next phase number
   - `updated_at` = current ISO timestamp
4. **Present**: Display a structured summary to the user (see summary format)
5. **Confirm** (semi-auto mode):
   - User confirms → proceed to next Phase, then execute `/compact` to free Leader context
   - User requests changes → Leader forwards modification instructions to the relevant agent, re-run Gate after changes
   - User aborts → execute /delete-team cleanup, flow ends
6. **Auto-pass** (full-auto mode): After quality check + persist, log the summary to state and proceed directly; execute `/compact` after advancing; escalate to user when quality is insufficient

## Gate Pass Criteria

| Phase | Must Satisfy | When Quality is Insufficient |
|-------|-------------|------------------------------|
| Gate 1 | proposal.md + design.md have no placeholders (TBD/TODO), are internally consistent, affected modules are clearly identified | Leader forwards modification feedback to the relevant agent, re-run Gate after changes |
| Gate 2 | tasks.md has no placeholders, every step has file paths and commands, blockedBy is correct | Planner revises and re-runs Gate |
| Gate 3 | All Tasks are completed, tests pass | Incomplete tasks continue; blocked tasks are handled as exceptions |
| Gate 4 | No CRITICAL issues, no unresolved HIGH issues | Dev fixes, code-reviewer re-evaluates |
| Gate 5 | All tests pass, no unfixed bugs | Bug fix loop; escalate to user after >3 attempts |
| Gate 6 | Branch pushed, deploy_branch merged (if configured), Jira updated | Dev completes missing steps |

## Gate Summary Format

```
Phase N: <Phase name>
Deliverables: <file path list>
Key decisions: <1-3 items>
Risks: <if any, format: risk description + impact scope + suggested mitigation>
Quality: Pass / Fail (with failing items listed)
Next Phase will spawn: <agent list (if any new)>
```

## Risk Examples

- "design.md involves a new table requiring DBA review → impacts release timeline, suggest communicating early"
- "Option B has better performance but a larger change scope → impacts regression testing scope, suggest adding test time"
- "The meaning of field X in requirements is unconfirmed → may cause rework, suggest confirming with product before Gate"
