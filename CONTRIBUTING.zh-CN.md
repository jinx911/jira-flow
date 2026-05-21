[English](CONTRIBUTING.md) | **中文**

# 贡献指南

感谢你对 jira-flow 的贡献兴趣！

## 如何贡献

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 进行修改
4. 用真实的 Jira Issue 端到端测试你的修改
5. 提交 Pull Request

## 规范

### Skills

- 每个 skill 位于 `skills/<name>/` 目录，以 `skill.md`（或 `SKILL.md`）作为入口
- 所有 skill 文件使用 frontmatter 元数据（`name`、`description`、`version`、`tags`）
- Phase 指令采用懒加载方式（独立文件放在 `phases/` 目录）

### Agents

- Agent 定义放在 `agents/<role>.md`
- 包含：角色描述、可用工具、约束条件、输出格式
- Agent 应无状态 — 所有上下文来自任务描述或 Leader 消息

### 通用规范

- 保持指令清晰无歧义 — Agent 会字面理解
- 使用 markdown 表格组织结构化数据（触发条件、严重级别等）
- 为非显而易见的模式添加示例
- 禁止硬编码路径、凭证或公司特定引用
- **所有文件统一使用英文**（面向用户的双语文档除外）

## 问题反馈

- 描述问题发生在哪个 Phase
- 包含涉及的 Agent 角色
- 附上相关错误/异常信息
- 注明你的环境：Claude Code 版本、superpowers 版本、已配置的 MCP 服务器

## 许可证

提交贡献即表示你同意你的贡献将在 MIT 许可证下发布。
