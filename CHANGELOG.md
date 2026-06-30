# Changelog

All notable feature-level changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Bugfix flow skill (`skills/bugfix-flow/`) — guided 3-step workflow for structured bug fixing with Sentry integration and Jira tracking

### Changed

- **Renamed jira-flow → dev-flow** (full rename: main skill, init skill, `.dev-flow` state dir, team name, README/repo title). "jira mode" retained as a mode name.
- **Restructured into a thin orchestrator + 4 reusable sub-skills**: `spec-author`, `dev-loop`, `review-test`, `ship` (6 phases → 4 stages). Each sub-skill is independently invocable.
- **Adaptive-depth docs**: structural proposal/design templates with engineering sections (data model / API contract / interface boundaries / state-flow / error contract / test strategy) expanded by triggers; checklist Gate replaces the double self-scoring rubric.
- **Doc-first change protocol**: requirement gaps found mid-dev update the spec before code, tracked by `doc_version`.
- **Conditional TDD**: TDD applied per-unit test strategy (`tdd` / `regression` / `smoke` / `none`), not forced everywhere.
- **Slimmed team protocol**: removed ack/`[URGENT-NOACK]`, 3-level health detection, heartbeats/snapshots, and the 6-step Prompt Build; TaskList is the source of truth; pre-resolved prompt files.
- **Decoupled from `~/.claude/agents/*.md`**: role expertise embedded in sub-skills.
- **Official SKILL.md standard**: uppercase `SKILL.md`, `name`+`description` frontmatter only, progressive disclosure with line budgets.

### Removed

- `skills/jira-flow/phases/` (6 phase briefs + `jira-quality-rubric.md` + `quality-rubric.md`) — superseded by sub-skills + structural templates.

## [1.6.0] - 2026-06-04

### Added

- Proposal quality scoring system at Phase 1 Step 4 (formerly Step 3b)
- Jira requirement quality scoring at Phase 1 Step 1 (formerly Step 0)
- Full audit resolution across 1 CRITICAL, 4 HIGH, and 4 MEDIUM findings

### Changed

- Renumbered Phase 1 steps from 0/1/2/3/3b/4 to 1/2/3/4/5/6 for clarity

### Fixed

- Team coordination and context exhaustion issues in multi-agent workflow
- Code walk-through HIGH issues in skill documentation

## [1.5.0] - 2026-05-29

### Added

- Synced agents and skills from deployed configuration — new agent roles and updated skill definitions to match production setup

## [1.4.0] - 2026-05-26

### Fixed

- Phase 6 Jira wrap-up now distinguishes sub-issue types (Bug vs Task vs Story) instead of treating all sub-issues identically

## [1.3.0] - 2026-05-25

### Added

- Interactive checkpoints in Phase 1 requirements analysis — pause for user confirmation before proceeding to next step

## [1.2.0] - 2026-05-22

### Added

- Context exhaustion prevention (P0) — detection, recovery, and leader self-protection mechanisms
- Structured output and progress reporting rules in team-rules
- `phase_decisions` and `agent_context_snapshots` fields in state.json
- Gate summary persistence to state.json with `/compact` trigger
- Context exhaustion monitoring in Phase 3 leader instructions
- CodeGraph integration into jira-flow workflow

### Fixed

- Restored Phase 6 Jira wrap-up workflow with proper defaults and causal chain
- Removed duplicate Persistence Timing heading in resume.md

### Docs

- Added P0 context exhaustion prevention design spec
- Added P0 context exhaustion implementation plan

## [1.1.0] - 2026-05-21

### Added

- Chinese (zh-CN) translations for documentation (README, CONTRIBUTING, training guide, architecture diagrams)

## [1.0.0] - 2026-05-21

### Added

- Initial release of jira-flow — 6-phase AI-driven Jira workflow orchestration with multi-agent team coordination

---

> When adding entries, follow the [Keep a Changelog](https://keepachangelog.com/) categories:
> **Added** for new features, **Changed** for changes in existing functionality,
> **Deprecated** for soon-to-be removed features, **Removed** for removed features,
> **Fixed** for bug fixes, **Security** for vulnerability fixes.
