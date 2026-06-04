---
partOf: jira-flow
version: 1.1.0
description: Phase 4 code review instructions. Leader reads this file when entering Phase 4.
---

# Phase 4: Code Review

Spawn code-reviewer (scale on demand).

Leader → code-reviewer: "Review all changes on the current branch, following the code-review rule Multi-Round Pipeline.
  Repository paths: {backend_repo_path}, {frontend_repo_path}.

  [superpowers:requesting-code-review]
  First read the superpowers requesting-code-review SKILL.md for the full methodology.
  Key constraints:
  - Structured review based on git diff, not memory
  - Severity levels: CRITICAL → block, HIGH → fix before merge, MEDIUM → suggestion, LOW → optional
  - For each issue provide: file path:line number, issue description, fix suggestion
  - Forbidden: skipping review, ignoring CRITICAL issues

  On completion, SendMessage with the review report (grouped by CRITICAL/HIGH/MEDIUM/LOW)."

code-reviewer independently: git diff → review per code-review rule pipeline → SendMessage report to Leader

## Gate 4

Present results → if CRITICAL/HIGH issues found, Leader delegates fixes to the dev agent
