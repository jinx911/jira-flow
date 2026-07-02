---
name: git-ops
description: Use when user wants to perform git operations — creating branches, committing code, pushing, updating branches, merging, or cleaning up branches. Supports single-repo and multi-repo architectures via project-config.
---

# Git Ops：多仓库/单仓库 Git 操作

**输入**：`$ARGUMENTS`（可选：模块名、分支名等）

## 初始化

1. 读 `<root_path>/.claude/project-config.md`（唯一来源；不存在→提示先 `/init-project`）。
2. 提取：`root_path`、`git.main_branch`(默认 main)、`git.commit_format`、`git.branch_naming.format`、`modules`（有=多仓库）、`backend.main_repo`、`frontend.repo`、`java` 仓库列表。

## 架构检测

```
有 modules → multi-repo: [main_repo]+modules+[frontend_repo]+[java_repos]，分支/推/并/清操作展示交互选择；commit 自动扫变更仓库
无 modules → single-repo: [root_path]，所有操作直接执行
```

## 触发词

| 触发 | 操作 |
|------|------|
| "创建分支"/"开始需求" | 创建分支 |
| "更新分支"/"rebase" | 更新分支 |
| "commit"/"提交" | 提交代码 |
| "push"/"推送" | 推送远程 |
| "完成需求"/"合并分支" | 合并到主分支 |
| "清理分支"/"删除分支" | 清理分支 |

## 仓库选择（仅 multi-repo）

分支/推/并/清操作前列仓库供选（后端 `[1]主仓库 [2]模块…` / 前端 / Java），编号逗号分隔或 `all`。**commit 例外**：自动扫有变更仓库。

## 分支保护 + Stash + 各操作详细步骤

**见 `references/git-detail.md`**：
- §分支保护规则（master/test/pre 保护 + 合并方向白名单 + 检测逻辑）
- §Stash 兜底（写操作前自动 stash/unstash）
- §各操作流程（创建/更新/提交/推送/合并/清理的具体命令 + 展示清单）
- §全局规则（写操作必确认、冲突即停、不擅自 push、`git -C` 不依赖 cd 等）

## 全局规则（核心）

- 所有写操作**必须用户确认**，绝不擅自执行；每次前展示清单。
- 冲突**不自动解决**，立即停止。
- `master`/`test`/`pre` 禁止直接 commit；`test`/`pre` 禁止向外合并（详见 references）。
- 默认不 push；无变更仓库跳过；用 `git -C <path>` 执行。
