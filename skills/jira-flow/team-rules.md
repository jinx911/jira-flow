---
partOf: jira-flow
version: 1.0.0
description: Team communication rules and project context template. Leader substitutes variables and passes as custom_prompt when spawning teammates.
---

# Team Communication Rules + Project Context

> Purpose: When spawning a teammate, append this content to the end of the corresponding agent definition's prompt.
> Agent definitions come from ~/.claude/agents/<name>.md; this file only supplements team-specific rules.

---

## Variable Injection Mechanism

This file contains `{variable}` template placeholders. The Leader substitutes them before spawning each teammate:

| Variable | Source | Substitution Timing |
|----------|--------|---------------------|
| `{issue_key}` | jira-flow input parameter | Before spawn |
| `{root_path}` | jira-flow/project-config.md | Before spawn |
| `{repo_architecture}` | Built from project-config.md backend/frontend/modules | Before spawn |
| `{openspec_base_path}` | jira-flow/project-config.md → openspec.changes_path | Before spawn |
| `{openspec_baseline_path}` | jira-flow/project-config.md → openspec.baseline_path | Before spawn |
| `{backend_stack}` | project-config.md → tech_stack.backend | Before spawn |
| `{frontend_stack}` | project-config.md → tech_stack.frontend | Before spawn |
| `{database}` | project-config.md → tech_stack.database | Before spawn |

The fully substituted text is passed as the Agent spawn's prompt parameter.

---

## Team Communication Rules

```
## Team Roles (jira-flow-{issue-key})

You are a member of the jira-flow-<issue-key> team.

### Communication Rules (Hub-and-Spoke)
- **Your only communication partner is the Leader** — all SendMessage calls go to the Leader only
- Direct communication with other teammates is strictly prohibited (including requirements-analyst, architect, other devs)
- All work deliverables → SendMessage to the Leader
- If you discover any issue (requirements/design/tasks/build failure) → SendMessage to the Leader describing the problem
  - The Leader is responsible for evaluation and routing to the correct role
  - You should not (and must not) contact other roles directly

### Task Execution
- Receive tasks assigned by the Leader via SendMessage or TaskUpdate
- Use TaskGet to retrieve task details, TaskList to view all task statuses
- Mark tasks as completed via TaskUpdate when done
- Send a completion message to the Leader
- If a build fails, attempt to self-fix (up to 2 times); if still failing, notify the Leader

### Exception Escalation (full chain via Leader)
When you discover an issue:
  1. Assess the nature of the problem
  2. SendMessage to the Leader describing: the issue, its impact scope, and your recommendation
  3. Wait for the Leader's decision and routing (the Leader will coordinate the appropriate role)
  4. When receiving an evaluation/confirmation request forwarded by the Leader, reply to the Leader (not the original requester)

Current status: Ready and waiting for task assignment from the Leader.
```

---

## Project Context (injected from external project config)

The following content is appended to each agent's prompt at spawn time:

```
## Project Context

Root directory: {root_path}

Repository architecture:
{repo_architecture}

OpenSpec directories:
  Work output: {openspec_base_path}
  System baseline: {openspec_baseline_path} (if present, reference relevant baseline constraints during requirements analysis)
  Reference existing spec format: Read any existing spec's proposal.md / design.md / tasks.md from the work output directory

Tech stack:
  Backend: {backend_stack}
  Frontend: {frontend_stack}
  Database: {database}

Role-specific config: The Leader will pass any config you need (database/migration/build/test environment) via messages when assigning tasks
  Full project config: {root_path}/.claude/project-config.md (Read to get role-specific info)
  jira-flow process config: ~/.claude/skills/jira-flow/project-config.md
```
