---
name: git-ops
description: Use when user wants to perform git operations — creating branches, committing code, pushing, updating branches, merging, or cleaning up branches. Supports single-repo and multi-repo architectures via project-config.
---

# Git Ops: 多仓库/单仓库 Git 操作

**输入**: `$ARGUMENTS`（可选：模块名、分支名等）

## 初始化

1. 读取项目配置:
   - `<root_path>/.claude/project-config.md`（唯一来源）
   - 不存在 → 提示用户先运行 `/init-project`
2. 从配置中提取：
   - `root_path` — 项目根目录
   - `git.main_branch` — 主分支名（默认 `main`）
   - `git.commit_format` — commit message 格式（默认 `<type>: <description>`）
   - `git.branch_naming.format` — 分支命名格式（默认 `{type}/{description}`）
   - `modules` — 模块列表（有 = 多仓库，无 = 单仓库）
   - `backend.main_repo` — 后端主仓库路径
   - `frontend.repo` — 前端仓库路径（可选）
   - `java` — Java 仓库列表（可选）
3. 配置不存在 → 提示用户先运行 `/init-project`

## 架构检测

```
有 modules 列表 → multi-repo:
  构建仓库列表: [main_repo] + modules + [frontend_repo] + [java_repos]
  分支/推送/合并/清理操作: 展示交互选择
  提交操作: 自动扫描有变更的仓库

无 modules → single-repo:
  仓库列表: [root_path]
  所有操作直接执行，跳过仓库选择
```

## 触发词

| 触发 | 操作 |
|------|------|
| "创建分支" / "开始需求" | 创建分支 |
| "更新分支" / "rebase" | 更新分支 |
| "commit" / "提交" | 提交代码 |
| "push" / "推送" | 推送远程 |
| "完成需求" / "合并分支" | 合并到主分支 |
| "清理分支" / "删除分支" | 清理分支 |

## 仓库选择（仅 multi-repo）

分支/推送/合并/清理操作前，列出仓库供用户选择：

```
后端:
  [1] {main_repo_name} (主仓库)   [2] {module_1}   [3] {module_2} ...
前端:
  [N] {frontend_repo_name}
Java:
  [M] oa-gateway   [M+1] oa-service

请选择（编号逗号分隔，或 all）：
```

**提交操作例外**：自动扫描有变更的仓库，不需预先选择。

## 分支保护规则

### 保护分支（禁止直接 commit）

以下分支标记为**保护分支**，禁止直接 commit，只能通过 merge 进入：

| 分支 | 角色 | 规则 |
|------|------|------|
| `master` | 源头分支 | 禁止直接 commit；所有开发分支必须从 master 创建 |
| `test` | 测试分支 | 禁止直接 commit；禁止将 test 合并到其他分支 |
| `pre` | 预发分支 | 禁止直接 commit；合并前须先同步 master 到开发分支 |

### 合并方向白名单

| 方向 | 说明 | 是否需要确认 |
|------|------|-------------|
| `dev → test` | 开发合并到测试 | 正常确认 |
| `dev → pre` | 开发合并到预发 | 正常确认（须先同步 master） |
| `dev → master` | 开发合并到主分支 | 二次确认 |
| `master → dev` | 同步主分支到开发 | 正常确认 |
| `test → *` | **禁止** | **拦截并警告** |
| `pre → *` | **禁止** | **拦截并警告** |
| 其他方向 | 需二次确认 | 二次确认 |

### 检测逻辑

每次执行写操作前：
1. 检查当前分支是否为保护分支 → 是则阻止并提示
2. 检查合并方向是否在白名单内 → 不在则警告并二次确认
3. 涉及 `pre` 分支的合并 → 自动先执行 master 同步步骤

## Stash 兜底机制

所有写操作前，检测到未提交变更时自动处理：

```
1. 检测: git status --short
2. 有变更 → git stash --include-untracked
3. 执行操作
4. 操作完成 → git stash pop
5. 如果 stash pop 有冲突 → 停止并提示用户手动处理
```

## 流程

### 创建分支

1. 解析分支名：
   - `$ARGUMENTS` 提供分支名 → 直接使用
   - 否则 → 按 `git.branch_naming.format` 生成（交互确认）
2. **multi-repo**: 列出仓库，用户选择
3. 每个选中仓库执行：
   ```
   git fetch origin
   git stash --include-untracked（如有未提交变更）
   git checkout {main_branch}
   git pull origin {main_branch}
   git checkout -b {branch}
   git stash pop（如有 stash）
   ```
4. 展示结果汇总

**异常**：已有同名分支 → 提示是否切换。

### 更新分支

1. **multi-repo**: 检测各仓库活跃分支，用户选择仓库
   **single-repo**: 检测当前分支
2. 询问策略：merge（默认，安全）或 rebase（线性历史，已推送分支慎用）
3. 每个仓库：`git -C <path> fetch origin` → 按 merge/rebase 执行
4. **冲突立即停止**，列出冲突文件让用户手动处理

### 提交代码

1. 扫描变更：
   - **multi-repo**: 遍历所有仓库 `git -C <path> status --short` + `git -C <path> diff --stat`
   - **single-repo**: 在 root_path 执行 `git status --short` + `git diff --stat`
   - 指定模块时只扫描匹配的仓库
2. 展示变更清单（**等待用户确认**）：
   ```
   📋 变更清单 — {仓库名}
   
   新增文件:
     + path/to/new-file.php — 新增XXX功能
   
   修改文件:
     ~ path/to/modified.php — 修改了YYY逻辑
   
   删除文件:
     - path/to/removed.php — 移除了ZZZ
   
   Commit Message:
     feat(scope): description
   ```
3. 每个文件附带**一句话描述**改动内容（通过 diff 分析得出）
4. 用户确认后 → `git add <具体文件>` + `git commit`（不用 `git add -A`）

### 推送远程

1. **multi-repo**: 检测各仓库当前分支和未推送提交数
   **single-repo**: 检测当前分支和未推送提交
2. 展示推送清单（**等待用户确认**）：
   ```
   📋 推送清单
   
   [1] oa-platform       branch: feature/OA-123   commits: 3 (↑待推送)
   [2] oa-app-attendance  branch: feature/OA-456   commits: 1 (↑待推送)
   
   确认推送以上仓库？(y/n)
   ```
3. 无上游 → `git push -u origin {branch}`；有上游 → `git push`
4. 展示结果

### 合并分支

根据目标分支走不同流程：

#### 合并到 test（常规）

1. 用户选择仓库和开发分支
2. 展示合并清单（**等待用户确认**）：
   ```
   📋 合并清单
   
   [1] oa-platform: feature/OA-123 → test
   [2] oa-app-attendance: feature/OA-456 → test
   
   确认合并？(y/n)
   ```
3. 每个仓库：`checkout test → pull origin test → merge {branch}`
4. 询问是否推送 test 分支

#### 合并到 pre（需先同步 master）

1. 用户选择仓库和开发分支
2. **自动前置步骤**：开发分支先 merge 最新 master
   ```
   git checkout {dev_branch}
   git pull origin {dev_branch}
   git fetch origin
   git merge origin/master
   ```
3. 如有冲突 → 停止，让用户解决后重试
4. 展示合并清单（**等待用户确认**）：
   ```
   📋 合并清单（已同步 master）
   
   [1] oa-platform: feature/OA-123 → pre
       ✓ 已同步最新 master (fast-forward)
   
   确认合并到 pre？(y/n)
   ```
5. 每个仓库：`checkout pre → pull origin pre → merge {dev_branch}`
6. 询问是否推送 pre 分支

#### 合并到 master（需二次确认）

1. 展示合并清单 + **二次确认**：
   ```
   ⚠️  即将合并到 master（源头分支）
   
   [1] oa-platform: feature/OA-123 → master
       commits: 5
   
   确认合并到 master？输入 "yes" 确认：
   ```
2. 执行合并

#### 禁止方向拦截

如果检测到 test → * 或 pre → * 的合并：
```
🚫 禁止操作

不允许将 test 分支合并到 {target} 分支。
test 是只读测试分支，只能通过 dev → test 方向合并。

如需将 test 的改动带回，请在开发分支上重新实现。
```

### 清理分支

1. 扫描仓库本地分支（排除保护分支），标记已合并/未合并
2. 用户选择要删除的分支
3. 未合并分支删除需额外确认，可选同时删除远程分支

## 全局规则

- **所有写操作必须用户确认**，绝不擅自执行
- **每次操作前展示清单**：commit 列出文件改动、push 列出仓库和提交数、merge 列出源→目标
- **冲突不自动解决**，立即停止
- **stash 兜底**：检测到未提交变更自动 stash，完成后自动 pop
- **分支保护**：master/test/pre 禁止直接 commit，test/pre 禁止向外合并
- 默认不 push，只在用户要求时执行
- 无变更的仓库直接跳过
- 每个仓库独立操作，单个失败不影响其他
- 使用 `git -C <path>` 执行命令，不依赖 cd
