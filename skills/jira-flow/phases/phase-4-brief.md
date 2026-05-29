---
partOf: jira-flow
version: 1.0.0
description: Phase 4 代码评审完整指令。Leader 进入 Phase 4 时 Read 此文件。
---

# Phase 4: 代码评审

spawn code-reviewer（按需扩容）

Leader → code-reviewer: "评审当前分支所有变更，按 code-review rule 的 Multi-Round Pipeline 执行。
  仓库路径: {backend_repo_path}, {frontend_repo_path}。

  [superpowers:requesting-code-review]
  先 Read superpowers requesting-code-review SKILL.md 获取完整方法论。
  关键约束:
  - 基于 git diff 结构化评审，不凭记忆
  - 严重性分级: CRITICAL → 阻断, HIGH → 修后合并, MEDIUM → 建议, LOW → 可选
  - 对每个问题给出: 文件路径:行号、问题描述、修复建议
  - 禁止: 跳过评审、忽略 CRITICAL

  完成时 SendMessage 包含评审报告（按 CRITICAL/HIGH/MEDIUM/LOW 分级）"

code-reviewer 自行: git diff → 按 code-review rule pipeline 评审 → SendMessage 报告 Leader

## Gate 4

展示结果 → CRITICAL/HIGH 则 Leader delegate 给开发 agent 修复
