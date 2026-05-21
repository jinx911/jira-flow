# Hub-and-Spoke Team Collaboration Workflow

## Architecture

```
User
  |
  v
Leader (sole hub, does not do work, only routes)
  |     |     |     |
  v     v     v     v
Req    FE    BE    QA
Analyst Dev   Dev   Test
```

## Communication Rules

1. **All interactions must go through the Leader** — direct member-to-member communication is prohibited
2. **The Leader does not do hands-on work** — only judges, routes, and consolidates
3. **After each node completes, the Leader decides the next step**: continue / pause for human confirmation / rework

## Full Task Lifecycle

```
Phase 1: Requirements
  User assigns task → Leader
  Leader determines if requirements analysis is needed:
    |- Yes → Forward to Requirements Analyst → Analysis complete, return to Leader
    +- No  → Proceed directly to next phase
  Leader consolidates analysis results → Determine if human confirmation is needed:
    |- Yes → Ask user to confirm/adjust → Continue after user feedback
    +- No  → Continue

Phase 2: Development
  Leader breaks down development tasks → Assign to FE/BE (can be parallel)
  Development complete → Return to Leader

Phase 3: Code Review
  Leader determines if review is needed:
    |- Yes → Forward to Review role → Review results return to Leader
    |        |- Approved → Continue
    |        +- Issues found → Leader sends back to developer for fix → Return to Phase 3
    +- No  → Continue

Phase 4: Testing
  Leader determines if testing is needed:
    |- Yes → Forward to QA → Test results return to Leader
    |        |- Passed → Continue
    |        +- Bugs found → Enter Bug Fix Loop
    +- No  → Continue

Phase 5: Report
  Leader generates final report → Report to user

Phase 6: Confirmation
  User confirms → Done / Rework
```

## Bug Fix Loop

```
QA reports bug → Leader
  → Leader assigns bug to responsible developer (FE bug → FE dev, BE bug → BE dev)
    → Developer fixes → Returns to Leader
      → Leader forwards back to QA for retest
        |- Passed → Exit loop
        +- Still buggy → Repeat this loop
```

### Bug Loop Rules

- After a fix, QA must retest — no skipping
- The Leader tracks bug count per round; the trend should decrease
- **Still unfixed after 3 rounds** → Leader pauses the loop and reports the situation to the user

## Final Report Format

The Leader consolidates and generates a report containing:

1. **Requirements Analysis Summary** — key requirements, breakdown results
2. **Development Change Log** — what FE/BE each delivered
3. **Code Review Conclusion** — approved / issues / fix records
4. **Test Results** — test case count, pass rate, bug records
5. **Bug Fix Log** — bug count per round, fix details
6. **Final Status** — Complete / Partially Complete / Needs Rework

## Leader Decision Guide

| Scenario | Decision |
|----------|----------|
| Requirements are ambiguous | Must run requirements analysis first; do not assign development directly |
| Task involves both FE and BE | Split into independent tasks, assign in parallel |
| Review finds issues | Send back to original developer for fix, re-review after fix |
| Testing finds bugs | Assign by responsibility, QA retests after fix |
| Bugs persist after 3 rounds | Pause and report to user |
| Task complete | Generate report, wait for user confirmation |
