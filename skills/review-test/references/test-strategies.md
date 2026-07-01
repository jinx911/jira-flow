# 测试策略矩阵（按栈 × test_strategy）

tester 按 **project-config 的 tech_stack** + **spec 的 test_strategy 标签**选测试方式。证据优先：每项给"命令 → 输出摘要 → 退出码"，禁止 "should work" / "looks fine"。

## 后端：PHP（Laravel）

| test_strategy | 测试方式 |
|---|---|
| `tdd` / `regression` | `php artisan test`（Feature + Unit）；涉及 HTTP API → Feature 测试（`$response->assertStatus/Json`）；DB 写入 → 断言行数/字段 + migration 已跑 |
| `smoke` | `php artisan test --filter=<相关>` 或对改动点冒烟；至少构建通过 + 关键路径手验 |
| `none` | 跳过测试，仅确认无语法/构建错 |

- 覆盖率：调 `/test-coverage` 校验 ≥80%（tdd/regression 单元）。
- 涉及租户/多库 → 按配置 `databases` 切换连接验证。

## 后端：Java（Spring Boot）

| test_strategy | 测试方式 |
|---|---|
| `tdd` / `regression` | `./mvnw test` 或 `gradle test`；按层：Controller → `@WebMvcTest` + MockMvc；JPA/Repository → `@DataJpaTest`；领域/纯逻辑 → 纯单测（JUnit5 + AssertJ）；跨层 → 集成测试（`@SpringBootTest`） |
| `smoke` | 跑改动相关测试类；至少 `./mvnw compile` 通过 + 关键路径手验 |
| `none` | 跳过测试，仅 `./mvnw compile` 通过 |

- 覆盖率：调 `/test-coverage` 校验 ≥80%（tdd/regression 单元）。
- 异步/MQ → 验证消费幂等 + 可重试。

## 前端（React/Vue 等）

| test_strategy | 测试方式 |
|---|---|
| `tdd` / `regression` | 组件测试（项目已装框架，如 vitest/jest）+ 改动相关 E2E（playwright：`browser_run_code_unsafe` 或录制脚本） |
| `smoke` | 改动组件冒烟 + 关键交互手验（build 通过 + 登录/核心流程走通） |
| `none` | 仅 `npm run build` 通过 |

- E2E 登录模板取自 project-config `e2e_testing.login_template`；测试环境凭证取自 `test_environments`。
- 前端改动 → 前置先跑 `build_commands.frontend` 构建。

## 数据库验证（任意后端涉及 schema/query 改动）

通过 project-config `databases` 的 MCP 查询：
- 新表/字段 → 确认结构、索引、外键、soft-delete 时间戳
- 数据写入 → 行数与预期一致、字段值符合 design.md
- migration → 已执行、可回滚（`migrate:rollback` 不报错，PHP）

## 选择规则

1. 读 spec 的 `## 测试策略` → 拿到每条 AC 的 test_strategy 标签。
2. 按 tech_stack 选上面对应栈的表。
3. 每条 AC 按其标签执行对应测试，出证据。
4. `tdd`/`regression` 单元必须有对应测试且通过；`smoke` 至少冒烟；`none` 跳过。
