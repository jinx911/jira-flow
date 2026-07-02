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
1. Detect      扫描项目，识别技术栈/仓库结构/数据库
2. MCP         验证 atlassian-rovo，获取 cloudId
3. Generate    生成两份配置文件 + settings.local.json
4. Register    更新 projects.json + 建目录
5. Dependencies 验证 skills / superpowers / MCP
6. Validate    确认所有文件就位、引用正确
```

**所有"具体命令 / 配置模板 / 校验清单"在 `references/setup-detail.md`**，执行对应步骤时 Read 它。

## 1. Detect

确定项目根（`$ARGUMENTS` 非空用之，否则当前工作目录）。检测命令 + 推断表见 `references/setup-detail.md` §1。产出：`tech_stack`、仓库结构、数据库、docker、主分支。

## 2. MCP 验证

atlassian-rovo MCP **可选**（不可用时 dev-flow 仍能 free-flow 工作）。验证流程见 `references/setup-detail.md` §2：`atlassianUserInfo` 确认可用 → `getAccessibleAtlassianResources` 取 cloudId。失败则 AskUserQuestion 是否继续。

## 3. Generate

按检测结果生成（模板见 `references/setup-detail.md` §2-§4）：
- **3a** `~/.claude/skills/dev-flow/project-config.md`（流程级，每机一份；已存在则保留用户自定义、只更新 cloudId/root_path）
- **3b** `{root_path}/.claude/project-config.md`（项目级；**已存在不覆盖**）
- **3c** AskUserQuestion 展示检测结果供确认/更正
- **3d** `{root_path}/.claude/settings.local.json`（最小权限；**已存在跳过**）

## 4. Register + 建目录

`mkdir -p` 必要目录 + 更新 `projects.json`（已存在则合并）。见 `references/setup-detail.md` §5。

## 5. Dependencies

按序检查 skills / agents(可选) / superpowers / MCP，汇总缺失项。清单见 `references/setup-detail.md` §6。

## 6. Validate

跑最终校验 checklist（见 `references/setup-detail.md` §7），展示校验结果 + 生成的文件路径 + 缺失依赖列表。

## 注意

见 `references/setup-detail.md` §注意（不覆盖已有配置、敏感信息、MCP 工具名一致性、多项目切换）。
