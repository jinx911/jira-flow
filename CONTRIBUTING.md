**English** | [中文](CONTRIBUTING.zh-CN.md)

# Contributing to Dev-Flow

Thank you for your interest in contributing!

## How to Contribute

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test your changes end-to-end with a real Jira issue (jira mode) and a free-flow requirement
5. Update `CHANGELOG.md` — add your changes under `[Unreleased]` (Added / Changed / Fixed / etc.)
6. Submit a Pull Request

## Skill Authoring Standard (official)

All skills follow the official Claude Code Agent Skill standard:

- Entry file is **`SKILL.md`** (uppercase) in `skills/<name>/`
- Frontmatter contains only official fields: `name` + `description` (+ optional `allowed-tools`). **Do not** add `partOf`, `version`, `tags`, `dependencies`, etc. — put dependency info in a `## Dependencies` section in the body.
- `name` must match the directory name (lowercase, hyphens, ≤64 chars).
- `description` is third-person "Use when...", ≤1024 chars.
- **Progressive disclosure + line budget**: keep `SKILL.md` lean; move detail into bundled files (templates, protocols) loaded on demand. Budgets: orchestrator ≤150 lines, sub-skills ≤80–100.

### Structure

- `dev-flow/` is the thin orchestrator; each stage is a reusable sub-skill (`spec-author`, `dev-loop`, `review-test`, `ship`).
- Stage detail lives in the sub-skill's `SKILL.md` + bundled files, not in the orchestrator.

### Agents (optional)

- Agent definitions live in `agents/<role>.md` but **dev-flow does not read them** — role expertise is embedded in sub-skills.
- Agents are stateless; all context comes from the task or Leader messages.

### General

- Keep instructions clear and unambiguous — agents interpret them literally.
- Use markdown tables for structured data (triggers, severity levels, test strategies).
- Add examples for non-obvious patterns.
- No hardcoded paths, credentials, or company-specific references.

## Reporting Issues

- Describe the Stage where the issue occurred (1 Spec / 2 Dev / 3 Review-Test / 4 Ship)
- Include the sub-skill or agent role involved
- Share the relevant error/exception if available
- Note your environment: Claude Code version, superpowers version, MCP servers configured
