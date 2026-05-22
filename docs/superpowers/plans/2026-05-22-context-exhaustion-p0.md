# P0 Context Exhaustion Prevention — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent jira-flow team workflows from stalling when agent context windows fill up, by adding structured output constraints, two-level exhaustion detection with auto-recovery, and enhanced state persistence.

**Architecture:** Modify 5 skill configuration files (Markdown, no executable code). Changes are declarative — they instruct LLM agents how to behave. No tests in the traditional sense; validation is manual review of the modified files against the spec.

**Tech Stack:** Markdown skill definitions for Claude Code agent orchestration

---

## File Structure

| File | Responsibility | Change Type |
|------|---------------|-------------|
| `skills/jira-flow/team-rules.md` | Communication rules injected into every agent | Add 2 new rules |
| `skills/jira-flow/skill.md` | Main workflow skeleton + exception handling | Add 1 new section |
| `skills/jira-flow/resume.md` | Breakpoint recovery logic | Enhance schema + recovery procedure |
| `skills/jira-flow/gate.md` | Gate checkpoint mechanism | Add persistence + compact trigger |
| `skills/jira-flow/phases/phase-3-brief.md` | Phase 3 TDD development instructions | Minor reference update |

---

### Task 1: Add Structured Output Rules to team-rules.md

**Files:**
- Modify: `skills/jira-flow/team-rules.md:48-63` (inside the `### Task Execution` code block)

- [ ] **Step 1: Add "Message Format" rule after the Task Execution section**

Insert after line 53 (`- Send a completion message to the Leader`) inside the code block:

```markdown
### Message Format (Context Protection)
- **Completion Report** — When finishing a task or sub-task, send to Leader using this exact format:
  ```
  ## Task Completion Report

  **Status**: completed | failed | blocked
  **Summary**: ≤3 sentences describing the result
  **Files Changed**: [file list, max 10]
  **Test Result**: pass/fail/N/A + key metrics (e.g., coverage %)
  **Issues**: [blocker descriptions, or "None"]
  ```
  - NEVER include code snippets, diffs, or full file contents in messages
  - Leader will Read files directly if it needs details
  - Exception: Phase 1-2 deliverables (proposal.md/design.md) are file-based; only report file paths in the completion message

- **Progress Update** — When executing operations expected to take >3 minutes, send a brief update after each sub-step:
  ```
  ## Progress Update

  **Task**: [current task name]
  **Step**: [current step] / [total steps]
  **Status**: in_progress
  **ETA**: [estimated remaining time or "unknown"]
  ```
  - This is critical: Leader uses progress updates to distinguish "agent is busy" from "agent context exhausted"
  - Failing to send progress updates may cause Leader to incorrectly判定 context exhaustion and spawn a replacement agent
```

- [ ] **Step 2: Verify the edit**

Read `skills/jira-flow/team-rules.md` and confirm:
- The new rules are inside the code block (between the triple backticks)
- They appear after the existing `### Task Execution` section
- The existing `### Exception Escalation` section is untouched below it

- [ ] **Step 3: Commit**

```bash
git add skills/jira-flow/team-rules.md
git commit -m "feat: add structured output and progress reporting rules to team-rules"
```

---

### Task 2: Add Context Exhaustion Detection & Recovery to skill.md

**Files:**
- Modify: `skills/jira-flow/skill.md:218-250` (Exception Handling section, after "Agent unresponsive" row)

- [ ] **Step 1: Update the "Agent unresponsive" row in the Unified Retry Limits table**

Replace the existing row:

```markdown
| Agent unresponsive | Resend message 1 time | Leader asks user |
```

With:

```markdown
| Agent unresponsive | Resend message 1 time | Leader asks user |
| Agent context exhausted | Spawn replacement agent ≤1 time | Leader asks user |
```

- [ ] **Step 2: Replace the "Waiting and Timeouts" section**

Replace the entire "Waiting and Timeouts" section (lines 235-240) with:

```markdown
### Waiting and Timeouts

Leader behavior while waiting for agent replies:
- **Normal wait**: While an agent is executing a task, the Leader stands by (no hard timeout)
- **No-response detection (Level 1)**: If an agent does not reply within the expected timeframe (Phase 1-2: 5 minutes; Phase 3-5: 10 minutes), the Leader sends a ping message
- **Context exhaustion detection (Level 2)**: If ping is unanswered AND the agent's last message or progress report was >15 minutes ago → 判定 context_exhausted
- **Ping unanswered (Level 1 only)**: Leader uses AskUserQuestion to ask user: wait / skip / terminate
- **Agent proactively reports blocking**: Not a timeout — handle via the normal exception path

### Context Exhaustion Recovery

When the Leader detects context_exhausted for an agent:

```
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
```

### Leader Context Protection

After each Gate passes:
1. Persist Gate summary to state.json (see gate.md for procedure)
2. Execute `/compact` to compress the Leader's own context
3. If `/compact` causes loss of recent context → read state.json to restore phase_decisions and gate_summaries
```

- [ ] **Step 3: Verify the edit**

Read `skills/jira-flow/skill.md` and confirm:
- The new "Context Exhaustion Recovery" section exists between "Waiting and Timeouts" and "Exception Routing"
- The "Leader Context Protection" section follows immediately after
- The Exception Routing section is preserved

- [ ] **Step 4: Commit**

```bash
git add skills/jira-flow/skill.md
git commit -m "feat: add context exhaustion detection, recovery, and leader self-protection"
```

---

### Task 3: Enhance State File Schema and Recovery in resume.md

**Files:**
- Modify: `skills/jira-flow/resume.md:16-29` (State File JSON schema)

- [ ] **Step 1: Replace the state.json schema**

Replace the entire JSON block (lines 17-29) with:

```json
{
  "issue_key": "{issue_key}",
  "team_name": "jira-flow-{issue_key}",
  "mode": "semi-auto",
  "branch": "<branch-name>",
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

- [ ] **Step 2: Add persistence timing section after the schema**

Insert after the schema block, before the `## Recovery Procedure` heading:

```markdown
### New Fields

| Field | Purpose | Updated When |
|-------|---------|-------------|
| `phase_decisions` | Key decisions per phase (≤100 chars/field) | After each Gate passes |
| `agent_context_snapshots` | Last known progress per agent | On every agent progress report / completion |

### Persistence Timing

- **Gate passes**: Leader writes `gate_summaries` + `phase_decisions` + advances `current_phase`
- **Agent progress report received**: Leader updates `agent_context_snapshots[agent_name]`
- **Agent task completes**: Leader updates corresponding snapshot
- **Phase 3 — each task completed**: Leader updates snapshot for the dev agent
```

- [ ] **Step 3: Update the Recovery Procedure to use new fields**

Replace the existing Recovery Procedure code block (lines 36-45) with:

```markdown
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
   current_phase == 1: proposal.md exists → Phase 2, otherwise → Phase 1
   current_phase == 2: tasks.md exists → Phase 3, otherwise → Phase 2
   current_phase == 3: TaskList has incomplete tasks → continue Phase 3, otherwise → Phase 4
   current_phase == 4-6: Start from that Phase
6. Agents read context from disk files (proposal/design/tasks) AND state.json phase_decisions
```
```

- [ ] **Step 4: Verify the edit**

Read `skills/jira-flow/resume.md` and confirm:
- New state.json schema includes `phase_decisions` and `agent_context_snapshots`
- Persistence timing section exists
- Recovery procedure references new fields
- Exception Recovery Scenarios section is preserved

- [ ] **Step 5: Commit**

```bash
git add skills/jira-flow/resume.md
git commit -m "feat: enhance state.json with phase_decisions and agent_context_snapshots"
```

---

### Task 4: Add Gate Summary Persistence to gate.md

**Files:**
- Modify: `skills/jira-flow/gate.md:17-19` (after the quality check item, before confirm item)

- [ ] **Step 1: Add persistence step to the Gate checkpoint procedure**

After step 2 ("Quality check") and before step 3 ("Present"), insert a new step and renumber subsequent steps:

```markdown
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
```

- [ ] **Step 2: Verify the edit**

Read `skills/jira-flow/gate.md` and confirm:
- The new step 3 "Persist" exists between "Quality check" and "Present"
- Steps are renumbered correctly (1-6)
- The Gate Summary Format section is unchanged
- The Risk Examples section is unchanged

- [ ] **Step 3: Commit**

```bash
git add skills/jira-flow/gate.md
git commit -m "feat: add Gate summary persistence to state.json with /compact trigger"
```

---

### Task 5: Update Phase 3 Brief with Progress Reporting Reference

**Files:**
- Modify: `skills/jira-flow/phases/phase-3-brief.md:26-28` (the Leader monitors section)

- [ ] **Step 1: Add progress reporting reference to the monitor instruction**

Replace line 28:

```markdown
3. Leader monitors: on completion report → TaskUpdate + notify waiting agents; on exception → handle per exception protocol
```

With:

```markdown
3. Leader monitors:
   - On progress update → update state.json agent_context_snapshots[agent_name]
   - On completion report → TaskUpdate + notify waiting agents
   - On exception → handle per exception protocol
   - On no message for 10 min → ping agent; on ping unanswered + 15 min silence → context exhaustion recovery (see skill.md)
```

- [ ] **Step 2: Verify the edit**

Read `skills/jira-flow/phases/phase-3-brief.md` and confirm:
- The Leader monitors section now has 4 sub-items
- Context exhaustion recovery reference is present
- The rest of the file is unchanged

- [ ] **Step 3: Commit**

```bash
git add skills/jira-flow/phases/phase-3-brief.md
git commit -m "feat: add context exhaustion monitoring to Phase 3 leader instructions"
```

---

### Task 6: Final Review and Verification

**Files:** All 5 modified files

- [ ] **Step 1: Cross-file consistency check**

Read all 5 modified files and verify:

1. `team-rules.md` — "Progress Update" format matches the format referenced in `skill.md`'s detection logic
2. `skill.md` — "Context Exhaustion Recovery" references `phase_decisions` and `agent_context_snapshots` which match `resume.md` schema
3. `resume.md` — state.json schema matches what `gate.md` persists and what `skill.md` reads during recovery
4. `gate.md` — persistence fields (`scope`, `key_files`, `architecture_choice`, `risks`) match `resume.md` `phase_decisions` structure
5. `phase-3-brief.md` — monitoring instructions align with `skill.md`'s detection timing (10 min → ping, 15 min → exhaustion)

- [ ] **Step 2: Verify against spec**

Open `docs/superpowers/specs/2026-05-22-context-exhaustion-p0-design.md` and check each requirement has a corresponding implementation:

| Spec Section | Implemented In | Status |
|-------------|---------------|--------|
| Structured Summary Output | team-rules.md Task Execution | |
| Progress Reporting | team-rules.md Task Execution | |
| Two-Level Detection | skill.md Waiting and Timeouts | |
| Recovery Flow | skill.md Context Exhaustion Recovery | |
| Leader Self-Protection | skill.md Leader Context Protection | |
| Enhanced state.json | resume.md State File | |
| Persistence Timing | resume.md Persistence Timing | |
| Gate Summary Persistence | gate.md step 3 | |
| /compact Trigger | gate.md steps 5-6 | |
| Phase 3 Monitoring | phase-3-brief.md | |

- [ ] **Step 3: Final commit if any fixes needed**

If any consistency issues were found and fixed:

```bash
git add -A
git commit -m "fix: resolve cross-file consistency issues from review"
```

---

## Self-Review Checklist

**Spec coverage:**
- Section 1 (Agent Output Constraints) → Task 1
- Section 2 (Context Exhaustion Detection & Recovery) → Task 2
- Section 3 (State Persistence Enhancement) → Task 3
- Section 4 (Gate Summary Persistence) → Task 4
- Phase 3 brief update → Task 5
- Cross-file consistency → Task 6

**Placeholder scan:** No TBD/TODO found. All steps contain exact content.

**Type consistency:** `phase_decisions` fields (`scope`, `key_files`, `architecture_choice`, `risks`) are defined identically in resume.md schema and gate.md extraction rules. `agent_context_snapshots` fields (`last_progress`, `last_files_changed`, `last_update`) are defined in resume.md and referenced consistently in skill.md recovery flow.
