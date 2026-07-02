# Git Ops 流程细节（操作步骤 + 分支保护）

SKILL.md 放触发词/架构检测/全局规则，本文件放各操作的详细步骤。执行对应操作时 Read 本节。

## 分支保护规则

### 保护分支（禁止直接 commit）

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

每次写操作前：
1. 当前分支是否保护分支 → 是则阻止并提示。
2. 合并方向是否在白名单 → 不在则警告并二次确认。
3. 涉及 `pre` 合并 → 自动先同步 master。

## Stash 兜底

所有写操作前，检测到未提交变更：
```
git status --short → 有变更 → git stash --include-untracked → 执行操作 → git stash pop
```
stash pop 冲突 → 停止，提示用户手动处理。

## 各操作流程

### 创建分支
1. 解析分支名：`$ARGUMENTS` 提供→用之；否则按 `git.branch_naming.format` 生成（交互确认）。
2. multi-repo：列出仓库让用户选。
3. 每个选中仓库：`fetch origin` → stash（如有）→ `checkout {main_branch}` → `pull` → `checkout -b {branch}` → stash pop。
4. 同名分支已存在 → 提示是否切换。

### 更新分支
1. 检测活跃分支（multi-repo 各仓库 / single-repo 当前）。
2. 询问策略：merge（默认，安全）/ rebase（线性历史，已推送慎用）。
3. `git -C <path> fetch origin` → 按策略执行。
4. 冲突立即停止，列冲突文件让用户手动处理。

### 提交代码
1. 扫描变更：遍历仓库 `git -C <path> status --short` + `diff --stat`（指定模块只扫匹配仓库）。
2. 展示变更清单（**等用户确认**），每个文件附一句话描述（diff 分析得出）：
   ```
   📋 变更清单 — {仓库名}
   新增: + path/to/new.php — 新增XXX
   修改: ~ path/to/mod.php — 修改YYY
   删除: - path/to/old.php — 移除ZZZ
   Commit Message: feat(scope): description
   ```
3. 确认后 `git add <具体文件>` + `git commit`（**不用 `git add -A`**）。

### 推送远程
1. 检测各仓库当前分支 + 未推送提交数。
2. 展示推送清单（**等用户确认**）：
   ```
   📋 推送清单
   [1] oa-platform   branch: feature/OA-123   commits: 3 (↑待推送)
   ```
3. 无上游 → `git push -u origin {branch}`；有上游 → `git push`。

### 合并分支（按目标分流）
- **→ test（常规）**：选仓库+开发分支 → 清单确认 → `checkout test → pull → merge {branch}` → 询问是否推 test。
- **→ pre（须先同步 master）**：开发分支先 `merge origin/master`（冲突停止）→ 清单确认（标"已同步 master"）→ `checkout pre → pull → merge {dev}` → 询问是否推 pre。
- **→ master（二次确认）**：清单 + 输入 "yes" 确认 → 执行。
- **禁止方向**：检测 `test→*` / `pre→*` → 拦截 + 警告（"test/pre 只读，改动请在开发分支重实现"）。

### 清理分支
1. 扫描本地分支（排除保护分支），标记已合并/未合并。
2. 用户选要删的；未合并的删除需额外确认，可选同时删远程。

## 全局规则（重申）

- 所有写操作必须用户确认，绝不擅自执行。
- 每次操作前展示清单（commit 列文件、push 列仓库+提交数、merge 列源→目标）。
- 冲突不自动解决，立即停止。
- stash 兜底（见上）。
- 分支保护：master/test/pre 禁止直接 commit；test/pre 禁止向外合并。
- 默认不 push，只在用户要求时执行。
- 无变更仓库跳过；每仓库独立操作，单个失败不影响其他。
- 用 `git -C <path>` 执行，不依赖 cd。
