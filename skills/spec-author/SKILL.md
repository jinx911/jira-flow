---
name: spec-author
description: Use when turning a requirement (Jira issue or natural-language text) into a structured proposal.md + design.md. Expands required engineering sections (data model, API contract, interface boundaries, state-flow, error contract, test strategy) based on triggers. Gate is a completeness checklist, not a score. Independently invocable.
---

# Spec-Author: Requirement → Structured Spec

Turn a requirement into engineering-grade `proposal.md` + `design.md` that developers can implement from without guessing.

## Inputs
- Jira key (jira mode) or `{requirement_text}` (free-flow mode)
- Trigger set: passed by the orchestrator, or self-detected from a codebase scan. See `triggers.md`.

## Outputs
- `{changes_path}/{spec_name}/proposal.md`
- `{changes_path}/{spec_name}/design.md`
- Return to Leader: `spec_name`, short summary, trigger set used

## Driven by
The orchestrator spawns this skill's agents: requirements-analyst (core sections + clarification) → architect (engineering sections + architecture decisions). Role expertise is embedded here; `~/.claude/agents/*.md` is NOT read.

## Flow
1. requirements-analyst: read Jira/requirement + related code → write **core sections** → ask clarifying questions ONLY if ambiguous.
2. Detect triggers (see `triggers.md`).
3. architect: write **triggered engineering sections** + architecture decisions + key files + reuse points.
4. Self-check against Gate 1 checklist; fix gaps before reporting.

## Core Sections (always required) — proposal.md
- **Background & goal**
- **Scope** — explicit in / out
- **Acceptance criteria** — Given/When/Then per scenario
- **Affected modules**

## Conditional Engineering Sections — see triggers.md
Expanded only when the matching trigger fires (data model, API contract, interface boundaries, state-flow, error contract). Test Strategy is always required (depth scales with complexity).

## design.md appends
- **Architecture decisions** — mandatory non-empty for Complex (format: decision / rationale / alternatives)
- **Key files** — per file: intended change
- **Reuse points** — find existing implementations to reuse/extend first

## Clarification (replaces fixed checkpoints)
Ask clarifying questions ONLY when the requirement is genuinely ambiguous — not as a fixed 3-checkpoint ceremony. User confirmation happens once at Gate 1.

## Gate 1 (checklist, no score)
- [ ] All core sections present and filled
- [ ] All triggered engineering sections present and filled
- [ ] No TBD/TODO/placeholder text
- [ ] Every acceptance criterion has a test-strategy entry
- [ ] Complex: architecture decisions non-empty

Pass/fail. No numeric score. No self-grading loop.

## Templates
- `templates/proposal.template.md`
- `templates/design.template.md`

## Dependencies
- Agents (embedded): requirements-analyst, architect
- MCP: atlassian-rovo (jira mode)
- Plugin: superpowers (brainstorming — when options/decisions need exploration)
