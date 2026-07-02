# Step 2：修复 + 验证

> 目标：按确认方案修复（bug 走回归测试优先），按栈验证，对齐质量契约。**本步不 commit**（统一在 Step 3 单 commit）。

## 前置
- Gate 1 已过，方案已确认
- 各目标 repo 已在正确分支
- `step_results.1.fix_proposal` 含确认方案

## 工具使用 + 质量契约 + 风格对齐

- **工具**：主动用 codegraph / repo-scan 查码、simplify 去冗余、test-coverage 校覆盖、各栈 *-reviewer / *-coding-standards。
- **质量契约**：函数<50 行、文件<800 行、无深嵌套(>4 层)、显式错误处理、无魔法数字；注释写"为什么"；无 debug 残留（console.log/dd/dump/var_dump）。
- **风格对齐**：按 tech_stack——Java 走市场主流 + `java-coding-standards`（**不沿用历史**）；其他跟仓库现有；有对应 `<栈>-coding-standards` skill 以其为权威。
- **DRY**：先搜现有实现复用。

## 1. 修复实现（回归测试优先）

委托 backend-developer（+ frontend-developer 如涉前端）：按 `step_results.1.fix_proposal` 实现。

bug 默认走 **regression** 策略：先写复现 bug 的失败测试（证 bug 存在）→ 最小修复 → 测试通过 → REFACTOR。
> 若 bug 无法单测（纯 UI/集成），写最小验证脚本并注明原因。

构建命令：project-config `build_commands`；migration（若需）：`migration.steps`。
自修：测试失败 → 分析 + 调整 + 重跑，每 repo ≤2 次；仍失败报 Leader。

## 2. 按栈验证（证据优先：命令 → 输出 → 退出码）

- **PHP (Laravel)**：`php artisan test`（Feature + Unit）；API → Feature 测试；DB → 断言行数/字段
- **Java (Spring)**：`./mvnw test` 或 `gradle test`；Controller → `@WebMvcTest` + MockMvc；JPA → `@DataJpaTest`；纯逻辑 → JUnit5 + AssertJ
- **前端**：组件测试（vitest/jest）+ 改动相关 E2E（playwright）
- `/test-coverage` 校验覆盖（regression 单元必须有测试且通过）
- 跨仓库：各修改仓库相关测试 + 验集成点 + 查 API 契约变更

## 3. Diff 汇总

各 repo `git -C {repo} diff --stat` + `diff`，汇总跨仓库变更。

## 4. spec 更新（可选）

若该 feature 有现有 spec 目录（`{root_path}/.dev-flow/{parent_key}/spec/` 或旧 `openspec/changes/`），追加一条 Bug 修复记录（bug / 根因 / 修复摘要 / 测试 / 改动文件）。无 spec 不新建。

## Gate 2

Semi-auto：AskUserQuestion 展示改动 + 测试结果 + spec 是否更新 + "进入部署？"。用户：确认/要求改/中止。Full-auto：记录自动推进。
更新 state：`current_step=2`，`step_results.2={files_changed, test_results, spec_updated, confirmed}`。
