**English** | [中文](CONTRIBUTING.zh-CN.md)

# Contributing to Jira-Flow

Thank you for your interest in contributing!

## How to Contribute

1. Fork this repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test your changes with a real Jira issue end-to-end
5. Submit a Pull Request

## Guidelines

### Skills

- Each skill lives in `skills/<name>/` with a `skill.md` (or `SKILL.md`) as the entry point
- Use frontmatter metadata (`name`, `description`, `version`, `tags`) in all skill files
- Phase instructions should be lazy-loaded (separate files in `phases/`)

### Agents

- Agent definitions go in `agents/<role>.md`
- Include: role description, available tools, constraints, and output format
- Agents should be stateless — all context comes from the task description or Leader messages

### General

- Keep instructions clear and unambiguous — agents interpret them literally
- Use markdown tables for structured data (triggers, severity levels, etc.)
- Add examples for non-obvious patterns
- No hardcoded paths, credentials, or company-specific references

## Reporting Issues

- Describe the Phase where the issue occurred
- Include the agent role involved
- Share the relevant error/exception if available
- Note your environment: Claude Code version, superpowers version, MCP servers configured

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
