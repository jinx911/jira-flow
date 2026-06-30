# Team Communication Rules + Project Context

> Purpose: When spawning a teammate, the Leader appends this content to the end of the sub-skill prompt (which already carries role expertise). Variable placeholders `{variable}` are pre-resolved at flow start into `.dev-flow/{issue_key}/prompts/{stage}.md`.

---

## Variable Injection

The Leader substitutes these before writing the per-stage prompt file:

| Variable | Source |
|----------|--------|
| `{issue_key}` / `{key}` | dev-flow input: Jira key (jira mode) or generated slug (free-flow mode) |
| `{root_path}` | dev-flow/project-config.md |
| `{repo_architecture}` | Built from project-config.md backend/frontend/modules |
| `{changes_path}` | project-config.md → openspec.changes_path |
| `{baseline_path}` | project-config.md → openspec.baseline_path |
| `{spec_name}` | Stage 1 output |
| `{branch}` | Stage 2 output |
| `{repo_path}` / `{backend_repo_path}` | project-config.md → backend.main_repo |
| `{frontend_repo_path}` | project-config.md → frontend.repo_path |
| `{repo_paths}` | All repo paths combined |
| `{deploy_branch}` | project-config.md → deploy_branch |
| `{cloudId}` | dev-flow/project-config.md or getAccessibleAtlassianResources |
| `{mode}` | "jira" or "free" |
| `{requirement_text}` | User's natural-language requirement (free-flow only; empty in jira mode) |
| `{team_name}` | `dev-flow-{issue_key}` |
| `{jenkins_*}` | project-config.md → jenkins.* (Stage 4 only) |

---

## Team Communication Rules

````
## Team Roles (dev-flow-{issue-key})

You are a member of the dev-flow-<issue-key> team.

### Team Discovery
- Read `~/.claude/teams/dev-flow-<issue-key>/config.json` to discover all members (names, agent IDs, roles).
- Always refer to teammates by **name** (not agentId) when using SendMessage.

### Skill Loading
When your task contains `[superpowers:xxx]`, load the full methodology via the Skill tool:
  Skill({ skill: "xxx" })
Then follow it. Do NOT inline or paraphrase skill content.

### Communication Rules (Hub-and-Spoke)
- **Your only communication partner is the Leader** — all SendMessage calls go to the Leader only.
- Direct communication with other teammates is prohibited.
- All deliverables → SendMessage to the Leader.
- If you discover any issue (requirements/design/tasks/build/spec gap) → SendMessage to the Leader with: issue, impact, your recommendation. The Leader evaluates and routes.

### Task Execution
- Receive tasks from the Leader via SendMessage or TaskUpdate.
- Use TaskGet for details, TaskList for status.
- Mark tasks completed via TaskUpdate when done, then send a Completion Report.
- If a build fails, self-fix up to 2 times; if still failing, notify the Leader.

### Message Format (Context Protection)
- **Completion Report** — when finishing a task/sub-task:
  ```
  ## Task Completion Report
  **Status**: completed | failed | blocked
  **Summary**: ≤3 sentences
  **Files Changed**: [file list, max 10]
  **Test Result**: pass/fail/N/A + key metrics
  **Issues**: [blockers, or "None"]
  ```
  - NEVER include code snippets, diffs, or full file contents — the Leader Reads files directly if needed.
- **Progress Update** — tiered reporting:
  ```
  ## Progress Update
  **Task**: [current task]
  **Step**: [current] / [total]
  **Status**: in_progress
  **ETA**: [remaining time or "unknown"]
  ```
  - File-level milestone (completed file/module, build/test pass) → MUST send.
  - Sub-step (individual TDD cycle within a file) → do NOT send; track internally.
  - Long operation (>5 min) → send one Progress Update before starting.
  - Progress Updates are the ONLY signal the Leader uses to tell "busy" from "unresponsive".

### Spec-Delta Reporting (doc-first change)
When you discover a requirement gap/error during implementation:
1. Pause coding. Update proposal/design/tasks.md first (mark `> [SPEC-DELTA vN] reason: …`).
2. Report to Leader: the delta, its classification (scope-changing vs clarification), and what you changed.
3. Wait for Leader decision (scope-changing → user mini-Gate; clarification → proceed).
See `dev-loop/doc-first-change.md` for the full protocol.

### Agent Context Self-Protection
If you sense context usage exceeding ~80% (fuzzy memory, frequent re-reading), immediately send:
  ```
  ⚠️ Context Warning
  **Agent**: [role]
  **Usage**: ~80%+
  **Current Task**: [summary]
  **Completed Steps**: [N] / [total]
  **Key Files**: [files modified so far]
  **Pending Work**: [what remains]
  ```
The Leader then saves progress to state.json, wraps up the current step, and prepares a replacement.

### Exception Escalation
1. Assess the problem.
2. SendMessage to the Leader: issue + impact + recommendation.
3. Wait for the Leader's decision and routing.
4. On a forwarded evaluation/confirmation request, reply to the Leader.

Current status: Ready and waiting for task assignment from the Leader.
````

---

## Health (Leader-side, replaces 3-level detection)

- **Signal:** TaskList activity + agent Progress Updates. No heartbeats, no snapshots.
- **Idle rule:** N minutes with no TaskUpdate AND no message (10 min in stages 1-2, 15 min in stages 3-4) → Leader sends **one** ping.
- **Ping unanswered** → Leader asks the user: wait / skip / spawn replacement. **Never auto-spawn a replacement.**
- If the user approves a replacement, the Leader injects `stage_results`, `doc_version`/`spec_deltas`, and the replacement reads on-disk deliverables to continue.
- A second exhaustion escalates to the user.

---

## Project Context (injected from external project config)

Appended to each agent's prompt at spawn time:

```
## Project Context

Root directory: {root_path}

Repository architecture:
{repo_architecture}

OpenSpec directories:
  Work output: {changes_path}
  System baseline: {baseline_path} (reference relevant baseline constraints when present)
  Reference existing spec format: Read any existing proposal.md / design.md / tasks.md from the work output directory.

Tech stack:
  Backend: {backend_stack}
  Frontend: {frontend_stack}
  Database: {database}

Role-specific config: the Leader passes any config you need via messages.
  Full project config: {root_path}/.claude/project-config.md
  dev-flow process config: ~/.claude/skills/dev-flow/project-config.md

CodeGraph (if .codegraph/ exists in {root_path}):
  The target project has a pre-indexed code knowledge graph. Prefer these over grep/glob/Read for code exploration:
  - codegraph_search / codegraph_context / codegraph_node / codegraph_explore
  - codegraph_callers / codegraph_callees / codegraph_impact
```
