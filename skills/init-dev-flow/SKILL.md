---
name: init-dev-flow
description: 为项目初始化 dev-flow 时使用。一键初始化——自动检测技术栈、生成两份配置文件、注册项目、验证全部前置依赖。每个项目运行一次。
---

# Init Dev-Flow

为项目一键初始化 dev-flow 工作流。自动检测技术栈、生成配置、注册项目、验证依赖。

**触发**：用户说 "init dev-flow" / "初始化 dev-flow" / `/init-dev-flow`

**输入**：`$ARGUMENTS`（可选，项目路径；默认当前工作目录）

## 工作流

```
1. Detect:   扫描项目目录，识别技术栈、仓库结构、数据库
2. MCP:      验证 atlassian-rovo 连通性，获取 cloudId
3. Generate: 生成两份配置文件
4. Register: 更新 projects.json
5. Dependencies: 验证 skills / superpowers
6. Validate: 确认所有文件就位、引用正确
```

---

## 1. Detect

确定项目根路径：

```
ARGUMENTS 非空 → 用指定路径
ARGUMENTS 为空 → 用当前工作目录
```

在项目根目录跑扫描：

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

推断结果：

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

---

## 2. MCP 验证

> 注意：atlassian-rovo MCP 可选。不可用时 dev-flow 仍能在 free-flow 模式工作（无需 Jira 单）。

```
Call mcp__atlassian-rovo__atlassianUserInfo
  → 成功：取用户信息，确认 MCP 可用
  → 失败：AskUserQuestion "atlassian-rovo MCP 不可用。请检查 settings.json 配置。是否继续生成配置文件？"

Call mcp__atlassian-rovo__getAccessibleAtlassianResources
  → 获取 cloudId
```

---

## 3. Generate

### 3a. 流程配置 `~/.claude/skills/dev-flow/project-config.md`

本文件是 dev-flow 流程级配置，每台机器一份。

> 已存在则：读当前内容，**保留用户自定义的 branch_naming 和 openspec 设置**，只更新 cloudId 和 root_path。

生成内容：

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
  format: "{issue_key}"

## Jira 状态映射

# 流转 ID 运行时通过 getTransitionsForJiraIssue 获取
```

### 3b. 项目配置 `{root_path}/.claude/project-config.md`

本文件是项目级配置，含仓库、数据库、测试环境等完整信息。

> 已存在则：**不要覆盖**；提示用户手动合并缺失字段。

基于检测结果生成。用 `project-config.example.md` 格式填入检测值。最小模板：

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
    format: "{issue_key}"

## OpenSpec

openspec:
  changes_path: "openspec/changes"
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
  auto_creates_sub: true                # 流转是否自动建子单？
  sub_completion_status: "已完成"       # 子单填完提测说明后 → 此状态
  testing_note_template: |
    Change overview: <summary>
    Affected modules: <modules>
    Testing highlights: <key results>
    Prerequisites: <setup needed>
    Verification steps: <how to verify>

## Jenkins 部署（可选）

# jenkins:
#   job_name: ""                         # Jenkins 任务名（就绪后填）
#   default_params:                      # 构建默认参数（按任务填）
#     deploy_type: "api"
#     test_version: "kn"
#   branch_param: "oa_branch"            # 分支参数名
#   branch_value: "test"                 # 要部署的分支（通常为 deploy_branch，不是 feature 分支）

## Migration

migration:
  steps:
    - "{检测到的 migration 命令}"
```

关键字段：

| 字段 | 来源 | 必需 |
|-------|--------|----------|
| `root_path` | 项目路径 | 是 |
| `tech_stack` | 检测结果 | 是 |
| `backend.main_repo` | 仓库结构检测 | 是 |
| `frontend.repo_path` | 仓库结构检测 | 条件 |
| `modules` | 子仓库检测 | 条件 |
| `git.main_branch` | Git 检测 | 是 |
| `databases` | 用户确认 | 条件 |
| `build_commands` | 技术栈推断 | 条件 |
| `migration` | 技术栈推断 | 条件 |
| `test_environments` | 用户输入 | 否 |
| `e2e_testing` | 用户输入 | 否 |
| `deploy_branch` | 用户输入 | 否 |
| `jira_workflow` | 用户输入 | 否 |

### 3c. 确认

生成前用 AskUserQuestion 展示检测结果供用户确认或更正：

```
项目路径: {path}
技术栈: backend={x}, frontend={y}, database={z}
仓库结构: {单仓库 / 多仓库}
主分支: {main/master}
cloudId: {auto_detected}

附加配置:
- 分支命名格式: {format}（可定制）
- OpenSpec 路径: changes={c}, baseline={b}
- Jira 工作流: testing_status=测试中, auto_creates_sub=true, sub_completion_status=已完成
  （Jira 用了不同状态名时定制）
- 测试环境？(可选，可后续加)
- 部署分支？(可选)
- Jenkins 部署？(可选，需 jenkins MCP)
```

### 3d. settings.local.json `{root_path}/.claude/settings.local.json`

> 已存在则：**不要覆盖**；跳过。

按检测到的技术栈生成最小权限集：

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(cat:*)",
      "Bash(curl:*)",
      {Node.js: "Bash(npm run:*)", "Bash(npm install:*)", "Bash(npx:*)", "Bash(node:*)", "Bash(pnpm:*)"}
      {PHP: "Bash(php artisan:*)", "Bash(composer:*)"}
      {Docker: "Bash(docker exec:*)", "Bash(docker-compose:*)"}
      {Java: "Bash(gradle:*)", "Bash(mvn:*)"}
      {Go: "Bash(go run:*)", "Bash(go test:*)"}
    ]
  }
}
```

---

## 4. 注册 + 建目录

确保目录存在：

```bash
mkdir -p ~/.claude/configs
mkdir -p {root_path}/.claude/skills
mkdir -p {root_path}/.claude/hooks
mkdir -p {root_path}/{changes_path}
mkdir -p {root_path}/{baseline_path}
```

更新 `~/.claude/configs/projects.json`：

```json
{
  "version": 1,
  "description": "项目注册表——把项目路径映射到配置。",
  "projects": {
    "{project_path}": {
      "name": "{name}",
      "description": "{一行描述}"
    }
  }
}
```

文件已存在则合并新条目（不要删已有条目）。

---

## 5. 依赖验证

按序检查，汇总缺失项。

### 5a. Skills

检查 `~/.claude/skills/` 下是否存在：

- `create-team` —— 团队创建/删除
- `delete-team` —— 团队清理
- `git-ops` —— Git 操作
- `dev-flow` —— 编排器
- `spec-author`、`dev-loop`、`review-test`、`ship` —— 四个阶段子 skill

### 5b. Agents（可选——非依赖）

dev-flow 把角色专长内嵌在子 skill 里，**不读** `~/.claude/agents/*.md`。因此 agent 定义可选。存在时仍可供独立使用：

- `requirements-analyst.md`、`architect.md`、`planner.md`、`backend-developer.md`、`frontend-developer.md`、`code-reviewer.md`、`tester.md`

缺 agent 对 dev-flow **不是阻塞项**。

### 5c. Superpowers

检查 superpowers 插件已安装（>=5.0.0）：
- 查 `~/.claude/plugins/` 下是否有 superpowers 相关目录
- 或查 `~/.claude/settings.json` 的 `plugins` 配置里是否有 superpowers

### 5d. MCP

- atlassian-rovo：第 2 步已验证
- MySQL（可选）：查 settings.json 是否配了 mysql MCP
- Playwright（可选）：查 settings.json 是否配了 playwright MCP

---

## 6. 最终校验

```
Checklist:
  [ ] ~/.claude/skills/dev-flow/project-config.md —— 存在且 cloudId 非空
  [ ] {root_path}/.claude/project-config.md —— 存在且 root_path 正确
  [ ] {root_path}/.claude/settings.local.json —— 存在
  [ ] {root_path}/.claude/skills/ —— 目录存在
  [ ] {root_path}/.claude/hooks/ —— 目录存在
  [ ] {root_path}/{changes_path}/ —— 目录存在
  [ ] {root_path}/{baseline_path}/ —— 目录存在
  [ ] jira_workflow —— project-config.md 中存在 testing_status 和 sub_completion_status
  [ ] ~/.claude/configs/projects.json —— 含新条目
  [ ] atlassian-rovo MCP —— 已连接

缺失项汇总（如有）:
  [ ] Skill: xxx
  [ ] Superpowers: 未安装
```

展示校验结果 + 所有生成的文件路径列表 + 缺失依赖列表。

---

## 注意

- 已存在的项目配置文件**不覆盖**；提示用户手动合并。
- `project-config.md` 可能含敏感信息（测试环境凭证等）——提醒用户把 `.claude/` 加入 `.gitignore`。
- 数据库 MCP 工具名必须与用户 settings.json 里配置的名字一致。
- 多项目时，每次运行会更新 `dev-flow/project-config.md` 的 `root_path`（切换项目时重跑）。
- Agent 文件可选；dev-flow 通过子 skill 自包含。
