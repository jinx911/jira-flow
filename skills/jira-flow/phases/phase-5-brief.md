---
partOf: jira-flow
version: 1.0.0
description: Phase 5 测试验证完整指令。Leader 进入 Phase 5 时 Read 此文件。
---

# Phase 5: 测试验证

spawn tester（按需扩容）

前置: 若涉及前端变更 → Leader 先通知 **frontend-developer** 执行前端构建（命令参考 {root_path}/.claude/project-config.md → build_commands.frontend）

Leader → tester: "读取 proposal.md + tasks.md，执行测试验证。

  [superpowers:verification-before-completion]
  先 Read superpowers verification SKILL.md 获取完整方法论。
  关键约束:
  - 证据铁律: 任何完成声明必须有即时验证证据
  - 禁止: '应该能用了'/'看起来没问题'/'应该通过了'
  - 每项验证提供: 命令 + 输出摘要 + 退出码
  - Bug 报告: 复现步骤 + 预期 + 实际 + 证据

  测试环境凭证: 参考 {root_path}/.claude/project-config.md → test_environments。
  E2E 测试: 参考 {root_path}/.claude/project-config.md → e2e_testing（优先用 browser_run_code_unsafe 执行整段脚本）。
  测试范围: 已有单元测试 + 根据变更类型选择（纯后端→API/集成测试，有前端→E2E测试）。
  仓库路径: {repo_paths}。
  数据库验证: 通过 MCP 查询对应数据库验证数据正确性。
  发现 Bug → SendMessage Leader: 'Bug: <描述>, 步骤: <复现>, 预期: <预期>, 实际: <实际>'
  全部通过 → SendMessage Leader: '测试全部通过，报告: ...'"

## 测试-修复循环（全过 Leader）

tester 发现 Bug → Leader → Leader 判断归属 → 开发 agent 修复 → Leader → tester 复验
未通过再走一轮，多轮未修复(>3次) → Leader 询问用户

## Gate 5

展示测试报告 → 确认
