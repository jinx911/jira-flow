---
partOf: jira-flow
version: 1.0.0
description: Proposal quality scoring rubric for Phase 1 Step 3b. The requirements-analyst reads this file and scores proposal.md against these criteria.
---

# Proposal Quality Scoring Rubric

## Overall Rules

- **Passing threshold**: total score >= 80/100
- **Per-dimension minimum**: every dimension must score >= 60% of its weight
- **If any dimension below minimum**: automatic fail regardless of total
- **Scoring scale**: each dimension uses 0 / 50 / 100 (raw score)
- **Weighted total**: sum of (raw_score / 100 * weight) for all dimensions

---

## Dimensions

### D1: Completeness (Weight: 25 points)

Measures whether the proposal covers all necessary aspects without gaps.

| Score | Criteria |
|-------|----------|
| **0** | Missing one or more of: scope definition, constraints, success criteria. Major sections absent. No edge cases identified. |
| **50** | Scope, constraints, and success criteria present but superficial. Edge cases incomplete. Some requirements lack acceptance criteria. |
| **100** | All aspects covered: scope boundaries (in/out), constraints (technical/business), success criteria with measurable outcomes, edge cases (empty data, error states, concurrent access, invalid input), and explicit out-of-scope items. |

**Minimum pass**: 15/25 (60%)

### D2: Clarity (Weight: 20 points)

Measures whether language is unambiguous and a developer could implement without guessing.

| Score | Criteria |
|-------|----------|
| **0** | Vague language ("user-friendly", "fast", "intuitive") with no measurable criteria. Pronoun ambiguity. Implementation requires significant guessing. |
| **50** | Mostly clear but some ambiguous phrasing remains. Some requirements need clarification. Partial use of measurable language. |
| **100** | All requirements use precise, measurable language. Every functional requirement has Given/When/Then acceptance criteria. No ambiguity in scope or behavior. A developer can implement directly from this document. |

**Minimum pass**: 12/20 (60%)

### D3: Feasibility (Weight: 20 points)

Measures whether the proposed approach is technically viable given the existing codebase and architecture.

| Score | Criteria |
|-------|----------|
| **0** | Proposed approach contradicts existing architecture. Requires changes outside the codebase scope. Dependencies unavailable or incompatible. |
| **50** | Approach generally viable but has unresolved technical questions. Some assumptions need validation. May require minor architectural accommodation. |
| **100** | Approach aligns with existing codebase patterns. All dependencies available. Implementation path concrete with no unresolved technical blockers. Existing patterns are followed. |

**Minimum pass**: 12/20 (60%)

### D4: Traceability (Weight: 15 points)

Measures whether each requirement traces back to the Jira issue and acceptance criteria are testable.

| Score | Criteria |
|-------|----------|
| **0** | Requirements cannot be mapped to the Jira issue. No acceptance criteria. No way to verify completion. |
| **50** | Most requirements trace to the Jira issue. Some acceptance criteria present but not all testable. Traceability chain has gaps. |
| **100** | Every requirement traces to a specific Jira field (description, comment, attachment). All acceptance criteria testable with clear pass/fail outcomes. No orphan requirements or untraced Jira points. |

**Minimum pass**: 9/15 (60%)

### D5: Impact Awareness (Weight: 10 points)

Measures whether the proposal identifies affected modules, dependencies, migration needs, and breaking changes.

| Score | Criteria |
|-------|----------|
| **0** | No impact analysis. Affected modules not identified. No consideration of dependencies or migration. Breaking changes not flagged. |
| **50** | Affected modules identified at a high level. Some dependencies noted. Migration or breaking change risks partially addressed. |
| **100** | Complete impact map: all affected modules listed, upstream/downstream dependencies identified, migration steps specified, breaking changes explicitly flagged with mitigation. |

**Minimum pass**: 6/10 (60%)

### D6: Consistency (Weight: 10 points)

Measures internal consistency and alignment with existing baselines and patterns.

| Score | Criteria |
|-------|----------|
| **0** | Internal contradictions present. Conflicts with existing baselines or code patterns. Terminology inconsistent within the document. |
| **50** | Mostly consistent but minor contradictions or terminology inconsistencies. Baseline alignment noted but not fully verified. |
| **100** | No internal contradictions. Terminology consistent throughout. Aligns with existing baseline specs and codebase patterns. Any baseline deviation explicitly justified. |

**Minimum pass**: 6/10 (60%)

---

## Score Calculation

```
weighted_total = (D1_raw/100 * 25) + (D2_raw/100 * 20) + (D3_raw/100 * 20)
              + (D4_raw/100 * 15) + (D5_raw/100 * 10) + (D6_raw/100 * 10)

passed = (weighted_total >= 80)
         AND (D1_raw >= 60) AND (D2_raw >= 60) AND (D3_raw >= 60)
         AND (D4_raw >= 60) AND (D5_raw >= 60) AND (D6_raw >= 60)
```

## Score Output Format

```json
{
  "dimensions": {
    "completeness":    { "raw": 100, "weighted": 25.0, "pass": true },
    "clarity":         { "raw": 50,  "weighted": 10.0, "pass": true },
    "feasibility":     { "raw": 100, "weighted": 20.0, "pass": true },
    "traceability":    { "raw": 50,  "weighted": 7.5,  "pass": true },
    "impact":          { "raw": 100, "weighted": 10.0, "pass": true },
    "consistency":     { "raw": 100, "weighted": 10.0, "pass": true }
  },
  "total_score": 82.5,
  "passed": true,
  "failures": [],
  "improvement_suggestions": ["Clarity: replace vague terms with measurable criteria..."]
}
```
