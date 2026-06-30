[English](CONTRIBUTING.md) | **中文**

# 贡献指南

感谢你对 dev-flow 的贡献兴趣！

## 如何贡献

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 进行修改
4. 用真实的 Jira Issue（jira 模式）和 free-flow 需求描述端到端测试你的修改
5. 更新 `CHANGELOG.md` — 在 `[Unreleased]` 下添加你的变更（Added / Changed / Fixed 等）
6. 提交 Pull Request

## Skill 编写规范（官方标准）

所有 skill 遵循官方 Claude Code Agent Skill 标准：

- 入口文件为 `skills/<name>/` 下的 **`SKILL.md`**（大写）
- frontmatter 只含官方字段：`name` + `description`（+ 可选 `allowed-tools`）。**不要**加 `partOf`、`version`、`tags`、`dependencies` 等 —— 依赖信息写进正文 `## Dependencies` 小节。
- `name` 必须与目录同名（小写、连字符、≤64 字符）。
- `description` 为第三人称 "Use when..."，≤1024 字符。
- **渐进式披露 + 行数预算**：`SKILL.md` 保持精简，细节挪进 bundled 文件（模板、协议）按需加载。预算：编排器 ≤150 行，子 skill ≤80–100。

### 结构

- `dev-flow/` 是薄编排器；每个阶段是一个可复用子 skill（`spec-author`、`dev-loop`、`review-test`、`ship`）。
- 阶段细节放在子 skill 的 `SKILL.md` + bundled 文件里，不放编排器。

### Agents（可选）

- Agent 定义放在 `agents/<role>.md`，但 **dev-flow 不读取它们** —— 角色专长内嵌在子 skill 中。
- Agent 无状态，所有上下文来自任务或 Leader 消息。

### 通用规范

- 保持指令清晰无歧义 —— Agent 会字面理解。
- 用 markdown 表格组织结构化数据（触发条件、严重级别、测试策略等）。
- 为非显而易见的模式添加示例。
- 禁止硬编码路径、凭证或公司特定引用。

## 问题反馈

- 描述问题发生在哪个 Stage（1 需求 / 2 开发 / 3 审查测试 / 4 收尾）
- 包含涉及的子 skill 或 Agent 角色
- 附上相关错误/异常信息
- 注明你的环境：Claude Code 版本、superpowers 版本、已配置的 MCP 服务器

## 许可证

提交贡献即表示你同意你的贡献将在 MIT 许可证下发布。
