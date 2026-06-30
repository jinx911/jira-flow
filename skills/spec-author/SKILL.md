---
name: spec-author
description: 把需求（Jira issue 或自然语言文本）转成结构化 proposal.md + design.md 时使用。按触发条件展开必填工程章节（数据模型 / API 契约 / 接口边界 / 状态流程 / 错误契约 / 测试策略）。Gate 是完整性 checklist，不打分。可独立调用。
---

# Spec-Author：需求 → 结构化 spec

把需求转成工程级的 `proposal.md` + `design.md`，让开发者无需猜测就能实现。

## 输入
- Jira key（jira 模式）或 `{requirement_text}`（free-flow 模式）
- 触发条件集：由编排器传入，或从代码扫描自检。见 `triggers.md`。

## 产出
- `{changes_path}/{spec_name}/proposal.md`
- `{changes_path}/{spec_name}/design.md`
- 向 Leader 返回：`spec_name`、简短摘要、使用的触发集

## 驱动的 agent
编排器 spawn 本 skill 的 agent：requirements-analyst（核心章节 + 澄清）→ architect（工程章节 + 架构决策）。角色专长内嵌本 skill，**不读** `~/.claude/agents/*.md`。

## 流程
1. requirements-analyst：读 Jira/需求 + 相关代码 → 写**核心章节** → 仅在歧义时问澄清。
2. 检测触发条件（见 `triggers.md`）。
3. architect：写**触发的工程章节** + 架构决策 + 关键文件 + 复用点。
4. 按 Gate 1 checklist 自检；补齐缺口后再汇报。

## 核心章节（恒必填）—— proposal.md
- **背景与目标**
- **范围** —— 明确 in / out
- **验收标准** —— 每个场景 Given/When/Then
- **影响模块**

## 条件工程章节 —— 见 triggers.md
仅在对应触发条件命中时展开（数据模型、API 契约、接口边界、状态流程、错误契约）。测试策略恒必填（深度随复杂度变化）。

## design.md 追加
- **架构决策** —— 复杂需求强制非空（格式：决策 / 理由 / 备选方案）
- **关键文件** —— 每个文件写明打算怎么改
- **复用点** —— 先找现有实现来复用/扩展

## 澄清（取代固定 checkpoint）
仅在需求**确实歧义**时才问澄清——不是固定的 3-checkpoint 仪式。用户确认集中在 Gate 1 一次。

## Gate 1（checklist，不打分）
- [ ] 所有核心章节存在且填写完整
- [ ] 所有触发的工程章节存在且填写完整
- [ ] 无 TBD/TODO/占位符
- [ ] 每条验收标准有对应的测试策略条目
- [ ] 复杂需求：架构决策非空

pass/fail。无数字分数。无自评循环。

## 模板
- `templates/proposal.template.md`
- `templates/design.template.md`

## Dependencies
- Agents（内嵌）：requirements-analyst、architect
- MCP：atlassian-rovo（jira 模式）
- Plugin：superpowers（brainstorming——方案/决策需探索时）
