---
partOf: jira-flow
version: 1.0.0
description: Phase 4 complete instructions for code review. Leader reads this file when entering Phase 4.
---

# Phase 4: Code Review

Spawn code-reviewer (scale as needed)

Leader → code-reviewer: "Review all changes on the current branch, following the Multi-Round Pipeline defined in the code-review rule.
  Repository paths: {backend_repo_path}, {frontend_repo_path}.

  [superpowers:requesting-code-review]
  First read the superpowers requesting-code-review SKILL.md for the full methodology.
  Key constraints:
  - Base the review on git diff output in a structured manner, not on memory
  - Severity levels: CRITICAL → block merge, HIGH → fix before merge, MEDIUM → suggestion, LOW → optional
  - For each issue provide: file path:line number, issue description, fix suggestion
  - Never: skip the review or ignore CRITICAL issues

  On completion, send a message containing the review report (categorized by CRITICAL/HIGH/MEDIUM/LOW)"

code-reviewer independently: git diff → review per code-review rule pipeline → send report message to Leader

## Gate 4

Present results → if CRITICAL/HIGH issues exist, Leader delegates fixes to development agents
