# Gate Mechanism

At the end of each Stage, the Leader executes a Gate checkpoint:

1. **Collect** — aggregate all agent reports from the current stage.
2. **Quality check** — evaluate deliverables against the pass criteria below.
3. **Persist** — write to `{root_path}/.dev-flow/{issue_key}-state.json`:
   - `stage_results[current_stage]` = the Gate Summary text
   - `current_stage` = next stage number
   - `updated_at` = current ISO timestamp
4. **Present** — display a structured summary (see format below).
5. **Confirm (semi-auto)** — user confirms → advance + `/compact`; user requests changes → forward to the relevant agent, re-run Gate; user aborts → `/delete-team`, flow ends.
6. **Auto-pass (full-auto)** — after quality check + persist, log summary and advance; `/compact` after advancing; escalate to user when quality is insufficient.

## Gate Pass Criteria

| Gate | Must Satisfy | When Insufficient |
|---|---|---|
| Gate 1 | proposal.md + design.md: core sections present + all triggered engineering sections present + no TBD/TODO placeholders + every acceptance criterion has a test-strategy entry + (Complex) architecture decisions non-empty | requirements-analyst/architect revises, re-run Gate |
| Gate 2 | TaskList clean + `tdd`/`regression`/`smoke`-tagged units tested green + every `spec-delta` either confirmed (scope-changing) or logged (clarification) | Incomplete tasks continue; blocked tasks handled as exceptions |
| Gate 3 | No CRITICAL issues + no unresolved HIGH issues + all tests pass + no unfixed bugs | Dev fixes; code-reviewer/tester re-evaluate (max 3 rounds, then escalate) |
| Gate 4 | Branch pushed + deploy_branch merged (if configured) + Jenkins succeeded/skipped (if configured) + Jira updated (jira mode) | Dev completes missing steps |

## Gate Summary Format

```
Stage N: <stage name>
Deliverables: <file path list>
Key decisions: <1-3 items>
Risks: <if any — description + impact + mitigation>
Quality: Pass / Fail (list failing items)
Next Stage: <name> | Effort: <light/medium/heavy> | User interaction: <none / checkpoint-only / frequent>
Next Stage will spawn: <agent list (if any new)>
```

## Risk Examples

- "design.md involves a new table requiring DBA review → impacts release timeline, suggest communicating early."
- "Option B has better performance but a larger change scope → impacts regression testing scope, suggest adding test time."
- "The meaning of field X is unconfirmed → may cause rework, suggest confirming before Gate."
