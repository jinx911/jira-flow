# Dev-Flow Skill

Dev-Flow 通过**四个可复用子 skill** 编排多 agent 团队跑完整开发生命周期。本 skill 是薄编排器（Leader playbook）。

## 流水线

```
需求（Jira key 或文本）→ 4 个 Stage + 4 个 Gate → 分支推送 + Jira 更新

Stage 1: spec-author   → proposal.md + design.md（自适应工程章节）
Stage 2: dev-loop      → tasks.md + 分支 + 实现代码（条件化 TDD）
Stage 3: review-test   → 审查 + 验证 + 修复环
Stage 4: ship          → 推送 + 部署 + Jira 收尾
```

Leader 每阶段触发一个子 skill、跑 Gate（checklist）、再推进。Leader 绝不写业务代码——只协调，保持上下文干净。

## 文件

| 文件 | 用途 |
|---|---|
| `SKILL.md` | 入口、阶段路由、Gate/委托规则、state、初始化 |
| `gate.md` | checklist Gate 定义 + 摘要格式 |
| `team-rules.md` | 瘦身通信规则 + Health（空闲/ping）+ 变量注入 |
| `resume.md` | 断点恢复 + 重试上限 + 旧 `.jira-flow` 兼容 |
| `project-config.example.md` | 项目配置模板 |

## 子 skill（每个可独立调用）

- `spec-author` —— 需求 → 结构化 proposal + design
- `dev-loop` —— TDD 开发 + 文档优先变更
- `review-test` —— 代码审查 + 验证 + 修复环
- `ship` —— 收尾 + 部署 + Jira 收尾

## 关键特性

- **角色专长内嵌子 skill** —— dev-flow **不读** `~/.claude/agents/*.md`。
- **活文档** —— 开发中发现需求缺口，先改文档再改代码（追踪 `doc_version`）。
- **条件化 TDD** —— 按单元测试策略（`tdd` / `regression` / `smoke` / `none`）。
- **预生成 prompt 文件** —— spawn = 读文件 + `Agent()`；不做每次 spawn 的 prompt 拼接。

安装、配置、完整文件树见顶层 `README.md`。
