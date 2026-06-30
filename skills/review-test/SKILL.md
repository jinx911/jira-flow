---
name: review-test
description: Use when reviewing and verifying a dev branch. Runs a structured code review (severity CRITICAL/HIGH/MEDIUM/LOW, multi-round pipeline) then evidence-based test verification (unit/integration/E2E + DB), with a fix loop. Independently invocable.
---

# Review-Test: Review + Verify + Fix Loop

## Flow
1. **Review** — code-reviewer reviews the branch diff via the multi-round pipeline:
   - Round 1 Quality (always) → Round 2 Architecture (if ≥3 files or new interfaces) → Round 3 Security (if user input / auth / data write).
   - Severity per issue: CRITICAL (block) / HIGH (fix before merge) / MEDIUM (suggestion) / LOW (optional).
   - Each issue: `file:line` + description + fix suggestion.
2. **Verify** — tester runs unit/integration/E2E + DB verification (per project-config `databases`), evidence-first: command → output summary → exit code. Forbidden: "should work" / "looks fine".
3. **Fix loop** — CRITICAL/HIGH issues + bugs → dev fixes → re-review/re-test. Max 3 rounds, then escalate to user.

## Prerequisite
If frontend changed, the orchestrator first has frontend-developer run the frontend build (project-config `build_commands.frontend`).

## Driven by
Orchestrator spawns: code-reviewer → tester; fixes routed back to dev agents. Methodology embedded here; `~/.claude/agents/*.md` NOT read.

## Gate 3
- [ ] No CRITICAL issues
- [ ] No unresolved HIGH issues
- [ ] All tests pass, no unfixed bugs

## Dependencies
- Agents (embedded): code-reviewer, tester
- Plugin: superpowers (requesting-code-review, verification-before-completion)
