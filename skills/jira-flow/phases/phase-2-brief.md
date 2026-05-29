---
partOf: jira-flow
version: 1.0.0
description: Phase 2 任务规划 + 分支完整指令。Leader 进入 Phase 2 时 Read 此文件。
---

# Phase 2: 任务规划 + 分支

## 步骤 2a: 任务拆分

Leader → planner: "拆分任务，写 tasks.md + TaskCreate 创建跟踪条目（标注 blockedBy）

    [superpowers:writing-plans]
    先 Read superpowers writing-plans SKILL.md 获取完整方法论。
    关键约束:
    - 咬合粒度: 每步 2-5 分钟（测试→验证→实现→验证→提交）
    - TDD 步骤: RED → Verify RED → GREEN → Verify GREEN → REFACTOR → Commit
    - 零占位符: 禁止 TBD/TODO — 每步含完整代码和命令
    - 精确路径: 每步标注文件路径
    - 自查: spec 覆盖完整、无占位符、类型一致
    输出写入: {changes_path}/{spec_name}/tasks.md + TaskCreate 条目"

等待 → Gate 2a: 展示任务列表 → 确认

## 步骤 2b: 创建分支

Leader → backend-developer: "/git-ops 创建分支 {config.branch_naming.format}"

等待 → Gate 2b: 展示分支信息 → 确认
