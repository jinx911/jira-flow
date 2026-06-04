---
partOf: jira-flow
version: 2.0.0
description: Phase 1 complete instructions for interactive requirements analysis. Leader reads this file when entering Phase 1.
---

# Phase 1: Requirements Analysis (Interactive)

> **Core principle**: Phase 1 is the foundation of the entire workflow. Direction errors here cascade downstream. The user MUST validate key decisions before proceeding.

## Overview

Phase 1 consists of 5 steps with 3 interaction checkpoints (A/B/C), followed by Gate 1:

| Step | Agent | Output | User Interaction |
|------|-------|--------|------------------|
| Step 1: Initial Analysis | requirements-analyst | Requirement summary + clarifying questions | **Checkpoint A**: User confirms understanding |
| Step 2: Options Proposal | requirements-analyst | 2-3 implementation approaches | **Checkpoint B**: User selects approach |
| Step 3: Generate Proposal | requirements-analyst | proposal.md | None |
| Step 3b: Quality Check | requirements-analyst | Quality score (80/100 threshold) | None (automatic, borderline → user) |
| Step 4: Architecture Design | architect | design.md + key design decisions | **Checkpoint C**: User confirms design decisions (conditional) |
| Gate 1 | Leader | Final confirmation | Gate 1 |

### State Tracking

After each step, Leader updates `{root_path}/.jira-flow/{issue_key}-state.json`:
- `phase1_substep`: "step1" | "step2" | "step3" | "step3b" | "step4" | "gate1"
- `user_answers`: accumulates user responses from Checkpoint A and B
- `quality_score`: populated after Step 3b (total, dimensions, passed, attempt)

---

## Step 1: Initial Analysis

Leader → requirements-analyst: "Read Jira issue {key} via Atlassian MCP (including description, comments, and attachments), explore related code, and produce:

1. **Requirement understanding summary** (≤10 sentences): what the issue asks for, affected modules, constraints
2. **Clarifying questions** (1-5 questions): ambiguous, missing, or conflicting information in the Jira issue. If everything is clear, output an empty list.

[superpowers:brainstorming]
First read the superpowers brainstorming SKILL.md for the full methodology.
Key constraints:
- This step is ONLY about understanding — do NOT propose solutions yet
- Focus on: purpose, constraints, success criteria, scope boundaries
- Identify any conflicts with existing code patterns or baselines

Baseline correlation (if {baseline_path} exists and is non-empty):
- Scan all spec.md files under {baseline_path} to identify baseline documents related to the current requirement
- Note any baseline constraints that may affect implementation scope

Reference the format of existing specs under {changes_path}.
Output via SendMessage to Leader (NOT a file):
  - requirement_summary: ≤10 sentence summary
  - clarifying_questions: list of questions (may be empty)
  - affected_modules: list of modules/repos likely involved
  - baseline_conflicts: list of baseline constraints found (may be empty)"

Wait for completion → update state: `phase1_substep = "step1"`

### Checkpoint A: Requirement Confirmation

**Semi-auto mode**:
Leader uses AskUserQuestion to present to the user:
- The requirement understanding summary from the agent
- Each clarifying question (if any) as a separate question
- "Does this understanding match your intent? Anything to add or correct?"

Collect user responses → save to state: `user_answers.checkpoint_a = <user response>`

**Full-auto mode**:
Leader logs the requirement summary and auto-passes. If there are clarifying questions, log them as assumptions.

---

## Step 2: Options Proposal

Leader → requirements-analyst: "Based on the confirmed requirement understanding and the user's input from Checkpoint A:
{user_answers.checkpoint_a}

Now propose 2-3 implementation options for {key}. For each option include:
- **Name**: short label for the option
- **Description**: what it does and how (≤5 sentences)
- **Architectural impact**: which modules/repos affected, new vs modified components
- **Implementation complexity**: estimated relative effort (low/medium/high)
- **Risk factors**: potential issues, migration needs, breaking changes

Provide a recommended option with rationale.

[superpowers:brainstorming — Exploring Approaches]
First read the superpowers brainstorming SKILL.md for the full methodology.
Key constraints:
- Each option must be viable — do not include straw-man options
- The recommendation should consider the project's existing patterns and constraints
- If baseline constraints exist, ensure all options respect them (or explicitly flag violations)

Output via SendMessage to Leader:
  - options: list of 2-3 options with the above fields
  - recommendation: which option and why
  - trade_off_summary: key differences between options in ≤3 sentences"

Wait for completion → update state: `phase1_substep = "step2"`

### Checkpoint B: Option Selection

**Semi-auto mode**:
Leader uses AskUserQuestion to present options to the user:
- Show each option's name, description, complexity, and risks
- Show the recommendation
- Ask: "Which approach do you prefer?" (options: each option name + "Other")

Collect user response → save to state: `user_answers.checkpoint_b = <selected option or custom input>`

**Full-auto mode**:
Leader logs the options and auto-selects the recommended one. Save: `user_answers.checkpoint_b = <recommended option>`

---

## Step 3: Generate Proposal

Leader → requirements-analyst: "The user selected: {user_answers.checkpoint_b}

Generate the OpenSpec proposal.md for {key} based on the selected approach.

[superpowers:brainstorming — Presenting the Design]
Key constraints:
- Proposal must reflect the selected approach and all user inputs from Checkpoint A and B
- Spec self-review (check after writing): no placeholders, internally consistent, scope is covered, no ambiguity
- Baseline Constraints section: cite key constraints from relevant baselines (if any)
- Ensure the proposal does not conflict with baselines; if a baseline must be violated, explicitly state the reason and impact

Reference the format of existing specs under {changes_path}.
Output to: {changes_path}/{spec_name}/proposal.md
spec_name naming rule: <module-abbreviation>-<brief-description>, following the naming style of existing directories.
On completion, send a message containing: spec_name, proposal summary (key points only)"

Wait for completion → update state: `phase1_substep = "step3"`, record `spec_name`

---

## Step 3b: Proposal Quality Check

Leader → requirements-analyst: "Score the proposal.md you just generated.

1. Read `~/.claude/skills/jira-flow/phases/quality-rubric.md`
2. Read `{changes_path}/{spec_name}/proposal.md`
3. Score each dimension (0/50/100) using the rubric criteria
4. Calculate weighted total
5. Generate improvement suggestions for any dimension scoring below 100

Output via SendMessage to Leader:
  - quality_score: { total_score, passed, dimensions, failures, improvement_suggestions }
  - Do NOT modify proposal.md yet"

Wait for score report → update state: `phase1_substep = "step3b"`, `quality_score = <score object>`

### Quality Gate Decision

**Score >= 80 AND all dimension minimums met**:
- Proceed to Step 4

**Score < 80 OR any dimension below minimum**:
1. Leader delegates to requirements-analyst: "Post a quality score comment to Jira issue {key} using mcp__atlassian-rovo__addCommentToJiraIssue (cloudId: {cloudId}) with the following content:

   ```
   ## Proposal Quality Score: {total}/100 — REVISION REQUIRED

   | Dimension | Score | Weight | Status |
   |-----------|-------|--------|--------|
   | {dimension rows with PASS/FAIL} |

   ### Failing Dimensions
   {for each failure: **Dimension (Score)**: reason}

   ### Improvement Suggestions
   {numbered list of actionable suggestions}
   ```"

2. Leader delegates revision to requirements-analyst: "Revise proposal.md to address: {improvement_suggestions}. Re-score after revision."
3. Retry limit: max 2 scoring attempts total (1 initial + 1 revision)
4. After 2 failed attempts: Leader asks user whether to proceed anyway or abort

### Run Mode Behavior

**Semi-auto mode**:
- Leader displays score breakdown to the user
- Score >= 80: auto-proceed to Step 4
- Score 75-79: user decides whether to proceed
- Score < 75: always block, auto-revise once

**Full-auto mode**:
- Score >= 80: auto-proceed to Step 4
- Score < 80: auto-revise once; if revised score >= 75, auto-proceed; else ask user

## Step 4: Architecture Design

Leader → architect: "Read {changes_path}/{spec_name}/proposal.md, generate design.md, and explore the related code architecture.
Database: Reference {root_path}/.claude/project-config.md → databases (query table structures to assist design).

[superpowers:brainstorming — Design Principles]
First read the superpowers brainstorming SKILL.md for the full methodology.
Key constraints:
- Module decomposition: each unit has a single responsibility, clear interfaces, and can be independently understood/tested
- Follow existing code patterns; do not introduce unrelated refactoring
- Design self-review: confirm no placeholders, type consistency, and complete file dependencies

Output to: {changes_path}/{spec_name}/design.md

On completion, send a message containing:
  - design_summary: design overview (≤5 sentences)
  - involves_backend: true/false
  - involves_frontend: true/false
  - key_files: list of files that will be modified or created (≤15)
  - design_decisions: list of key architectural decisions that may need user attention (may be empty)
    Each decision: { decision: '...', rationale: '...', alternatives_rejected: ['...'] }"

Wait for completion → update state: `phase1_substep = "step4"`

### Checkpoint C: Design Confirmation (Conditional)

Trigger condition: architect reported non-empty `design_decisions` list.

**Semi-auto mode**:
Leader uses AskUserQuestion to present key design decisions to the user:
- Show each decision with its rationale
- Ask: "Do you agree with these design decisions?"

Collect user response → if user disagrees, Leader relays feedback to architect for revision.

**Full-auto mode**: Auto-pass, log design decisions.

If architect reported empty `design_decisions` → skip Checkpoint C entirely (both modes).

---

## Gate 1

Present the agent summaries (proposal summary + design summary + key files + which sides affected) → after confirmation, spawn development agents (backend-developer / frontend-developer) based on the architect's report of which sides are affected.

Update state: `phase1_substep = "gate1"`, then advance to Phase 2.
