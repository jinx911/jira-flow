# Doc-First Change Protocol

When a developer discovers a requirement gap or error during implementation, the spec is updated BEFORE code. Docs are a living contract, not frozen artifacts.

## Steps
1. **Pause coding.** Label the discovery a `spec-delta`.
2. **Update the spec first** — edit the relevant section of `proposal.md` / `design.md` / `tasks.md`. Mark the change inline:
   `> [SPEC-DELTA vN] reason: <why the original was wrong/missing>`
3. **Classify impact** (developer proposes in the report; Leader confirms):
   - **Scope-changing** — adds/removes/alters an acceptance criterion or affected module → Leader opens a **mini-Gate** with the user to confirm.
   - **Clarification-only** — resolves ambiguity without changing scope → log and proceed (no user gate).
4. **Update state** — `doc_version++`, append to `spec_deltas[]` (`{stage, reason, classification, at}`).
5. **Resume coding** against the updated doc.

## Why
- Keeps docs and code in sync — no drift.
- Makes mid-dev requirement changes visible and reviewable instead of silent.
- The flow is no longer forward-only: code reality writes back to the spec.

## Limits
- Requirement/design revision retry limit: 2 (then ask user whether to abort). See `dev-flow/resume.md`.
