---
partOf: jira-flow
version: 1.1.0
description: Phase 2 task planning and branch creation instructions. Leader reads this file when entering Phase 2.
---

# Phase 2: Task Planning + Branch

## Step 2a: Task Breakdown

Leader → planner: "Break down tasks, write tasks.md + TaskCreate tracking items (with blockedBy annotations).

    [superpowers:writing-plans]
    First read the superpowers writing-plans SKILL.md for the full methodology.
    Key constraints:
    - Granularity: each step 2-5 minutes (test→verify→implement→verify→commit)
    - TDD steps: RED → Verify RED → GREEN → Verify GREEN → REFACTOR → Commit
    - Zero placeholders: no TBD/TODO — every step contains complete code and commands
    - Exact paths: every step must specify file paths
    - Self-check: spec coverage complete, no placeholders, type consistency
    Output to: {changes_path}/{spec_name}/tasks.md + TaskCreate entries"

Wait → Gate 2a: present task list → confirm

## Step 2b: Create Branch

Leader → backend-developer: "/git-ops create branch following the naming convention from {root_path}/.claude/project-config.md → branch_naming.format"

Wait → Gate 2b: present branch info → confirm
