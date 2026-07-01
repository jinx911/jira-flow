---
name: review-test
description: 审查并验证开发分支时使用。跑结构化代码审查（严重级 CRITICAL/HIGH/MEDIUM/LOW，多轮管道），再做基于证据的测试验证（单元/集成/E2E + 数据库），含修复环。可独立调用。
---

# Review-Test：审查 + 验证 + 修复环

## 工具使用
你已安装的全部 skill / agent 都可用，主动选与任务相关的调用：
- 代码审查 → code-review / 对应 *-reviewer（php / typescript / java / ...）
- 安全 → security-review
- 数据库 → database-reviewer
- 性能 → performance-optimizer
- 架构 → architect
未装时正常降级。

## 流程
1. **审查**（多轮，按需调专用工具）：
   - 质量（恒过，按栈对照 *-coding-standards）：冗余/可读性/注释/风格 adherence
   - 安全（用户输入/认证/数据写入）→ /security-review
   - 架构（≥3 文件/新接口）→ architect
   - 数据库（schema/query 改动）→ database-reviewer
   - 性能（热点路径）→ performance-optimizer
   - 每条问题：`file:line` + 描述 + 修复建议；严重级 CRITICAL/HIGH/MEDIUM/LOW
2. **验证** —— tester 跑单元/集成/E2E + 数据库验证（按 project-config `databases`），证据优先：命令 → 输出摘要 → 退出码。禁止 "should work" / "looks fine"。
3. **修复环** —— CRITICAL/HIGH 问题 + bug → dev 修复 → 重审/重测。最多 3 轮，再升级用户。

## 前置
若涉及前端，编排器先让 frontend-developer 跑前端构建（project-config `build_commands.frontend`）。

## 驱动的 agent
编排器 spawn：code-reviewer → tester；修复路由回 dev agent。方法论内嵌本 skill，**不读** `~/.claude/agents/*.md`。

## Gate 3
- [ ] 无 CRITICAL 问题
- [ ] 无未解决 HIGH 问题
- [ ] 所有测试通过，无未修 bug

## Dependencies
- Agents（内嵌）：code-reviewer、tester
- Plugin：superpowers（requesting-code-review、verification-before-completion）
