# 项目配置示例

> 本文件是项目配置的示例模板。
> 实际使用时 `/init-dev-flow` 会在 `<project-root>/.claude/project-config.md` 自动生成。
> 也可手动复制本文件并填入实际值。

---

## OpenSpec

openspec:
  changes_path: "openspec/changes"      # dev-flow 工作输出目录（相对 root_path）
  baseline_path: "openspec/specs"       # 系统基线文档（可选，留空则跳过基线关联检查）

## 基础信息

root_path: "/path/to/your/project"
tech_stack: { backend: "laravel", frontend: "react", database: "mysql" }

## 运行时

# 若用 Docker：
docker: { container: "your-php-container", workdir: "/workspace/your-project/" }
artisan: 'docker exec your-php-container bash -c "cd /workspace/your-project && {cmd}"'

## 仓库架构

# 单仓库：
backend: { main_repo: "." }

# 多仓库（取消注释并填写）：
# backend: { main_repo: "backend/", modules_path: "backend/modules/" }
# frontend: { repo: "frontend/" }
# modules:
#   - { name: "module-a", desc: "Module A", path: "backend/modules/module-a/" }

## Git 配置

git:
  main_branch: "master"  # 或 "main"
  branch_naming:
    format: "{issue_key}"
    types: [feature, fix, refactor]
  commit_format: "<type>(<scope>): <description>"

## 部署分支（可选）

# 若项目从特定分支自动部署（如 "test" → staging）：
# deploy_branch: "test"
# 未配置则 Stage 4 跳过合并到部署分支这一步。

## Jenkins 部署（可选）

# 若项目有 Jenkins CI/CD，配置此项以在 Stage 4 定稿后自动部署。
# 未配置或 Jenkins MCP 不可用时，部署步骤静默跳过——不报警、不报错。
#
# jenkins:
#   job_name: "oa-service"               # Jenkins 任务名（出现 jenkins 段时必填）
#   default_params:                       # 构建默认参数
#     deploy_type: "api"
#     test_version: "kn"
#   branch_param: "oa_branch"             # 接收分支名的参数名（默认 "oa_branch"）
#   branch_value: "test"                  # 要部署的分支值——通常为 deploy_branch（如 "test"），不是 feature 分支

## Jira 工作流

# dev-flow 在未配置本段时使用下列默认值：
#   testing_status: 自动检测（在可用流转里找含 'Test'/'测试' 的状态）
#   auto_creates_sub: true
#   sub_completion_status: 自动检测（找含 'Done'/'完成' 的状态）
#   testing_note_template: 内置 5 字段模板（变更概述 / 影响模块 / 测试要点 / 前置条件 / 验证步骤）
#
# Jira 用了非标准状态名时覆盖：
# jira_workflow:
#   testing_status: "In Testing"
#   auto_creates_sub: true
#   sub_completion_status: "Done"
#   testing_note_template: |
#     Change overview: <summary>
#     Affected modules: <modules>
#     Testing highlights: <key results>
#     Prerequisites: <setup needed>
#     Verification steps: <how to verify>

## 数据库 MCP

# MCP 工具名取自 ~/.claude/settings.json 的 mcpServers
databases:
  main: { mcp: "mcp__your-db-name__mysql_query", desc: "主数据库" }
  # tenant_a: { mcp: "mcp__tenant-a__mysql_query", desc: "租户 A" }

## 测试环境

# 敏感凭证——加入 .gitignore 或用环境变量
test_environments:
  default:
    url: "http://your-test-env.example.com"
    account: ""   # 填测试账号
    password: ""  # 填测试密码
    desc: "默认测试环境"

## E2E 测试

e2e_testing:
  approach: "browser_run_code_unsafe"
  login_template: |
    async (page) => {
      await page.goto('{url}/login');
      await page.fill('input[name="email"]', '{account}');
      await page.fill('input[type="password"]', '{password}');
      await page.click('button:has-text("Login")');
      await page.waitForURL('**/dashboard', { timeout: 10000 });
      return { loggedIn: true };
    }

---

## 构建命令（agent 参考）

build_commands:
  frontend: "npm run build"  # 前端文件变更时执行的命令
  backend: ""               # PHP 项目通常不需要

## Migration（Stage 2 后端开发参考）

migration:
  steps:
    - "php artisan migrate --force"
    - "php artisan tenancy:migrate --force"  # 多租户时
  note: "仅当 migration 文件新建/修改时执行"

## 部署清单

- [ ] 确认 git 分支
- [ ] 前端构建（若改了前端）
- [ ] 数据库 migration（若改了 migration）
- [ ] 路由缓存清理（若改了路由）
