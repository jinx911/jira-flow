# 初始化细节（检测命令 / 配置模板 / 校验清单）

SKILL.md 只描述工作流骨架，本文件放具体命令、模板、清单。执行对应步骤时 Read 本节。

## 1. 技术栈检测命令

```bash
# 技术栈检测
ls composer.json package.json pom.xml build.gradle go.mod Cargo.toml 2>/dev/null
# 仓库结构（多仓库检测）
find . -name .git -maxdepth 3 -type d 2>/dev/null
# 前端检测
cat package.json 2>/dev/null | grep -E '"react"|"vue"|"angular"|"svelte"'
ls */package.json 2>/dev/null
# 数据库检测
grep -r "DB_" .env 2>/dev/null
grep -r "database" config/ 2>/dev/null
# Docker 检测
ls docker-compose.yml Dockerfile 2>/dev/null
# Git 主分支
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null
```

| 检测到 | 推断 |
|----------|----------|
| `composer.json` + `"laravel"` | backend: laravel |
| `package.json` + `"react"` | frontend: react |
| `package.json` + `"vue"` | frontend: vue |
| `pom.xml` / `build.gradle` | backend: java/spring |
| `go.mod` | backend: go |
| `.env` 含 `DB_CONNECTION=mysql` | database: mysql |
| `docker-compose.yml` | docker: yes |
| 子目录有 `.git` | 多仓库架构 |

## 2. 流程配置模板 `~/.claude/skills/dev-flow/project-config.md`

> 已存在则：读当前内容，**保留用户自定义的 branch_naming 和 openspec 设置**，只更新 cloudId 和 root_path。

```markdown
---
name: dev-flow-project-config
description: Dev-Flow 流程配置。项目级信息在 {root_path}/.claude/project-config.md。
---

# Dev-Flow 流程配置

> 本文件只含 dev-flow 工作流自身的配置。
> 项目级信息（仓库、数据库、测试环境等）在 `{root_path}/.claude/project-config.md`。
> 项目配置由 `/init-dev-flow` 生成，或手动用 `project-config.example.md` 作参考创建。

---

## Jira 配置
cloudId: "{auto_detected_cloudId}"

## 项目路径
root_path: "{detected_project_path}"

## OpenSpec
openspec:
  changes_path: "openspec/changes"
  baseline_path: "openspec/specs"

## 分支命名
branch_naming:
  format: "{type}/{issue_key}"   # v2 默认带类型前缀

## Jira 状态映射
# 流转 ID 运行时通过 getTransitionsForJiraIssue 获取
```

## 3. 项目配置模板 `{root_path}/.claude/project-config.md`

> 已存在则：**不要覆盖**；提示用户手动合并缺失字段。

```markdown
# {project_name} 项目配置

> **用途**：agent 与 skill 共享的项目级配置。消费方直接 Read 本文件。

---

## 基础信息
root_path: "{project_path}"
tech_stack: { backend: "{backend}", frontend: "{frontend}", database: "{database}" }

## 仓库架构
{基于检测结果：单仓库或模块列表}

## Git 配置
git:
  main_branch: "{master 或 main}"
  branch_naming:
    format: "{type}/{issue_key}"
    type_map: { "Story": "feat", "Task": "feat", "Bug": "fix" }

## OpenSpec
openspec:
  changes_path: "openspec/changes"      # v2：spec 文档进 .dev-flow/{key}/spec/；此处仅旧数据兼容
  baseline_path: "openspec/specs"

## 数据库 MCP
{按可用 MCP 工具填写}

## 构建命令
build_commands:
  frontend: "{检测到的前端构建命令}"
  backend: "{检测到的后端构建命令}"

## Jira 工作流
jira_workflow:
  testing_status: "测试中"              # 主单 → 此状态触发子单创建
  auto_creates_sub: true
  sub_completion_status: "已完成"
  testing_note_template: |
    Change overview: <summary>
    Affected modules: <modules>
    Testing highlights: <key results>
    Prerequisites: <setup needed>
    Verification steps: <how to verify>

## Jenkins 部署（可选）
# jenkins:
#   job_name: ""
#   default_params: { deploy_type: "api", test_version: "kn" }
#   branch_param: "oa_branch"
#   branch_value: "test"

## Migration
migration:
  steps:
    - "{检测到的 migration 命令}"
```

关键字段：`root_path`(必需)、`tech_stack`(必需)、`backend.main_repo`(必需)、`git.main_branch`(必需)；`frontend.repo_path`/`modules`/`databases`/`build_commands`/`migration`(条件)；`test_environments`/`e2e_testing`/`deploy_branch`/`jira_workflow`(可选)。

## 4. settings.local.json 模板 `{root_path}/.claude/settings.local.json`

> 已存在则跳过。按检测到的技术栈生成最小权限：

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(grep:*)", "Bash(cat:*)", "Bash(curl:*)"
    ]
  }
}
```
追加（按栈）：Node→`Bash(npm/pnpm/npx/node:*)`；PHP→`Bash(php artisan/composer:*)`；Docker→`Bash(docker/docker-compose:*)`；Java→`Bash(gradle/mvn:*)`；Go→`Bash(go run/go test:*)`。

## 5. 注册 + 建目录

```bash
mkdir -p ~/.claude/configs {root_path}/.claude/skills {root_path}/.claude/hooks {root_path}/.dev-flow
```

更新 `~/.claude/configs/projects.json`（已存在则合并，不删已有）：
```json
{ "version": 1, "projects": { "{project_path}": { "name": "{name}", "description": "{一行描述}" } } }
```

## 6. 依赖验证清单

**Skills（`~/.claude/skills/`）**：create-team、delete-team、git-ops、dev-flow、spec-author、dev-loop、review-test、ship、learn。
**Agents（可选，非依赖）**：dev-flow 不读 agents；缺了不阻塞。
**Superpowers**：`~/.claude/plugins/` 有 superpowers 目录，或 settings.json plugins 含 superpowers（>=5.0.0）。
**MCP**：atlassian-rovo（第 2 步已验）；MySQL / Playwright 可选（查 settings.json mcpServers）。

## 7. 最终校验 Checklist

```
[ ] ~/.claude/skills/dev-flow/project-config.md 存在且 cloudId 非空
[ ] {root_path}/.claude/project-config.md 存在且 root_path 正确
[ ] {root_path}/.claude/settings.local.json 存在
[ ] {root_path}/.claude/skills/、.claude/hooks/、.dev-flow/ 目录存在
[ ] jira_workflow 含 testing_status 和 sub_completion_status
[ ] ~/.claude/configs/projects.json 含新条目
[ ] atlassian-rovo MCP 已连接
```

## 注意

- 已存在的项目配置文件**不覆盖**；提示用户手动合并。
- `project-config.md` 可能含敏感信息——提醒把 `.claude/` 加入 `.gitignore`。
- 数据库 MCP 工具名必须与用户 settings.json 配置一致。
- 多项目时每次运行更新 `dev-flow/project-config.md` 的 `root_path`。
