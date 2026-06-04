---
partOf: jira-flow
version: 1.0.0
description: Jira requirement quality scoring rubric for Phase 1 Step 0. The requirements-analyst reads the Jira issue and scores it against these criteria before starting any analysis work.
---

# Jira Requirement Quality Scoring Rubric

## Overall Rules

- **Passing threshold**: total score >= 80/100
- **Per-dimension minimum**: every dimension must score >= 60% of its weight
- **If any dimension below minimum**: automatic fail regardless of total
- **Scoring scale**: each dimension uses 0 / 50 / 100 (raw score)
- **Weighted total**: sum of (raw_score / 100 * weight) for all dimensions
- **Purpose**: evaluate whether the product manager's Jira issue is clear and complete enough to start development. Poor requirements → rework → waste.

---

## Dimensions

### D1: Requirement Clarity (Weight: 25 points)

Measures whether the Jira description clearly states what is wanted, without ambiguity or room for misinterpretation.

| Score | Criteria |
|-------|----------|
| **0** | Description is vague ("optimize the system", "improve user experience"). No specific functionality described. Multiple interpretations possible. Reader has no idea what to build. |
| **50** | General intent is understandable but details are fuzzy. Some specific features mentioned but described imprecisely. Key questions remain unanswered (e.g., "what happens when...?"). Reader can guess the direction but cannot confirm. |
| **100** | Every feature or change is described with specific behavior. User interactions are step-by-step. Edge cases and error scenarios are mentioned. A developer can understand exactly what to build without asking further questions. |

**Minimum pass**: 15/25 (60%)

### D2: Acceptance Criteria (Weight: 25 points)

Measures whether there are testable completion criteria that define when the requirement is "done".

| Score | Criteria |
|-------|----------|
| **0** | No acceptance criteria at all. "Done" is undefined. No way to verify completion. Relies entirely on developer's interpretation. |
| **50** | Some acceptance criteria present but partial or informal. Listed as bullet points without testable outcomes. Missing criteria for key scenarios. "Should work correctly" type of vague criteria. |
| **100** | Clear, testable acceptance criteria for every scenario. Each criterion has a specific pass/fail condition (e.g., Given/When/Then, or "when X is clicked, Y should appear"). Covers happy path, error cases, and edge cases. QA can write test cases directly from these. |

**Minimum pass**: 15/25 (60%)

### D3: Scope Definition (Weight: 20 points)

Measures whether the boundary of what is in-scope and out-of-scope is clearly defined.

| Score | Criteria |
|-------|----------|
| **0** | No scope boundaries. Unclear what is included and what is not. Could range from a small fix to a full system redesign. Scope creep is inevitable. |
| **50** | General scope mentioned but boundaries are fuzzy. Some things explicitly in-scope, but out-of-scope is not defined. Unclear if related features/modules are included or not. |
| **100** | Clear in-scope items listed with specifics. Explicit out-of-scope section stating what will NOT be done. Boundaries defined by module, page, API endpoint, or user role. No ambiguity about what this ticket covers. |

**Minimum pass**: 12/20 (60%)

### D4: Context Completeness (Weight: 15 points)

Measures whether the Jira issue provides enough supporting materials for implementation.

| Score | Criteria |
|-------|----------|
| **0** | Text-only description with no supporting materials. No mockups, no data samples, no API references, no screenshots of current state. Developer must hunt for context elsewhere. |
| **50** | Some supporting materials attached but incomplete. May have a mockup but no data spec, or an API doc but no example response. Key context gaps remain (e.g., field definitions, permission rules, notification logic). |
| **100** | All necessary context provided: UI mockups/wireframes (if frontend), API contracts or field definitions (if backend), data samples or database schema changes, configuration or permission rules, links to related tickets or documentation. Developer has everything needed to start. |

**Minimum pass**: 9/15 (60%)

### D5: Impact Scope (Weight: 15 points)

Measures whether the requirement identifies which modules, systems, user roles, or processes are affected.

| Score | Criteria |
|-------|----------|
| **0** | No mention of which modules or systems are involved. No indication of affected user roles or business processes. Developer must investigate from scratch. |
| **50** | Some modules or systems mentioned but incomplete. May identify the primary module but miss downstream dependencies. Affected user roles partially identified. |
| **100** | All affected modules, APIs, databases, and third-party systems listed. User roles impacted clearly identified. Upstream/downstream dependencies noted. Migration or deployment considerations mentioned. Developer knows the blast radius. |

**Minimum pass**: 9/15 (60%)

---

## Score Calculation

```
weighted_total = (D1_raw/100 * 25) + (D2_raw/100 * 25) + (D3_raw/100 * 20)
              + (D4_raw/100 * 15) + (D5_raw/100 * 15)

passed = (weighted_total >= 80)
         AND (D1_raw >= 60) AND (D2_raw >= 60) AND (D3_raw >= 60)
         AND (D4_raw >= 60) AND (D5_raw >= 60)
```

## Score Output Format

```json
{
  "dimensions": {
    "clarity":               { "raw": 100, "weighted": 25.0, "pass": true },
    "acceptance_criteria":   { "raw": 50,  "weighted": 12.5, "pass": true },
    "scope":                 { "raw": 100, "weighted": 20.0, "pass": true },
    "context":               { "raw": 50,  "weighted": 7.5,  "pass": true },
    "impact":                { "raw": 100, "weighted": 15.0, "pass": true }
  },
  "total_score": 80.0,
  "passed": true,
  "failures": [],
  "improvement_suggestions": []
}
```
