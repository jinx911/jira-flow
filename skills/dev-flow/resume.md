# Breakpoint Recovery

When dev-flow detects `{root_path}/.dev-flow/{issue_key}-state.json`, follow this flow.

## Minimal State Shape

```json
{
  "issue_key": "OA-3650",
  "flow_mode": "jira",
  "team_name": "dev-flow-OA-3650",
  "run_mode": "semi-auto",
  "started_at": "2026-06-30T10:00:00Z",
  "current_stage": 1,
  "complexity": "medium",
  "spec_name": null,
  "branch": null,
  "doc_version": 1,
  "spec_deltas": [],
  "stage_results": {},
  "spawned_agents": [],
  "updated_at": "<ISO>"
}
```

## Field Reference

| Field | Purpose |
|---|---|
| `flow_mode` | `jira` or `free`; determines which steps are skipped (free mode skips Jira wrap-up) |
| `current_stage` | Current stage (1-4) |
| `complexity` | `simple` / `medium` / `complex` |
| `spec_name` | Spec directory name under `{changes_path}` (Stage 1 output) |
| `branch` | Development branch (Stage 2 output) |
| `doc_version` | Spec version counter; increments on each spec-delta |
| `spec_deltas[]` | Log of mid-dev spec changes (`{stage, reason, classification, at}`) |
| `stage_results` | Gate Summary text per stage (recovery context) |
| `spawned_agents` | Agents expected during recovery |

## Persistence Timing

- Gate pass → write `stage_results[current_stage]`, next `current_stage`, `updated_at`
- spec-delta → `doc_version++`, append `spec_deltas[]`
- Agent completion → no heartbeat tracking (TaskList is the source of truth)

---

## Unified Retry Limits

| Exception | Self-repair limit | After limit |
|---|---:|---|
| Build failure | 2 | Ask user |
| Test bug loop | 3 | Ask user |
| Requirement/design revision (spec-delta) | 2 | Ask user whether to abort |
| Task conflict | 1 resequence | Leader decides serialization/worktree |
| Agent unresponsive | 1 ping | Ask user (wait / skip / spawn replacement) |
| Agent context exhaustion | 1 replacement approval | Ask user |
| MCP failure | 2 retries | Save state, stop |

Any exception exceeding its limit escalates to the user.

---

## Recovery Procedure

1. Read `{issue_key}-state.json`.
2. Ask: resume or delete state and restart?
3. If resuming, ask which agents to re-spawn.
4. Re-spawn only confirmed agents; inject `stage_results` + `spec_deltas` + on-disk deliverables.
5. Resume from `current_stage`:
   - `1` → `spec-author` (re-read existing proposal/design; finish missing sections)
   - `2` → `dev-loop` (inspect TaskList + `git log` to find completed work; continue)
   - `3` → `review-test` (confirm code state, then run review/verify)
   - `4` → `ship` (confirm push/deploy/Jira state, finish missing steps)
6. If `spec_deltas` is non-empty, replay the latest doc state before resuming coding.
7. After Stage 4 completes, delete the state file.

## Crash Recovery

- `current_stage < 2`: resume directly from saved deliverables.
- `current_stage == 2`: inspect TaskList + `git log --oneline -20` + `git status`; re-spawn dev if needed.
- `current_stage >= 3`: confirm code state on branch, then resume the current stage.

---

## Legacy Compatibility (`.jira-flow/*-state.json`)

For state files written by the previous `jira-flow` version:
- Map `current_phase` (1-6) → `current_stage` (1-4): phase 1→1, phase 2→2, phase 3→2, phase 4→3, phase 5→3, phase 6→4.
- Ignore `phase1_substep`, `agent_context_snapshots`, `agent_heartbeats`, `jira_quality_score`, `quality_score` (no longer used).
- Carry over `spec_name`, `branch`, `complexity`, `user_answers` as-is.
- Set `doc_version = 1`, `spec_deltas = []` if absent.
- If the legacy flow was mid-Phase-1 scoring, ask the user whether to restart Stage 1 with the new checklist Gate.
