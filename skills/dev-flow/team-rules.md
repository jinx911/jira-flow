# 团队通信规则 + 项目上下文

> 用途：spawn 队友时，Leader 把本内容追加到子 skill prompt 末尾（子 skill 已带角色专长）。`{variable}` 占位符在流程开始时一次性代入，写入 `.dev-flow/{issue_key}/prompts/{stage}.md`。

---

## 变量注入

Leader 在写每阶段 prompt 文件前替换下列变量：

| 变量 | 来源 |
|----------|--------|
| `{issue_key}` / `{key}` | dev-flow 输入：jira 模式为 Jira key，free-flow 模式为生成 slug |
| `{root_path}` | dev-flow/project-config.md |
| `{repo_architecture}` | 由 project-config.md 的 backend/frontend/modules 构造 |
| `{changes_path}` | project-config.md → openspec.changes_path（**v2：spec 文档改用 `{root_path}/.dev-flow/{issue_key}/spec/`；此变量仅旧 openspec 只读兼容**） |
| `{baseline_path}` | project-config.md → openspec.baseline_path |
| `{spec_name}` | 阶段 1 产出（v2 仍返回；产出目录以 issue_key 为准） |
| `{branch}` | 阶段 2 产出 |
| `{repo_path}` / `{backend_repo_path}` | project-config.md → backend.main_repo |
| `{frontend_repo_path}` | project-config.md → frontend.repo_path |
| `{repo_paths}` | 所有仓库路径合并 |
| `{deploy_branch}` | project-config.md → deploy_branch |
| `{cloudId}` | dev-flow/project-config.md 或 getAccessibleAtlassianResources |
| `{mode}` | "jira" 或 "free" |
| `{requirement_text}` | 用户自然语言需求（仅 free-flow；jira 模式为空） |
| `{team_name}` | `dev-flow-{issue_key}` |
| `{jenkins_*}` | project-config.md → jenkins.*（仅阶段 4） |

---

## 团队通信规则

````
## Team Roles (dev-flow-{issue-key})

你是 dev-flow-<issue-key> 团队的成员。

### Team Discovery
- 读 `~/.claude/teams/dev-flow-<issue-key>/config.json` 了解所有成员（name、agentId、role）。
- SendMessage 时一律用对方的 **name**（不是 agentId）。

### Skill Loading
任务里出现 `[superpowers:xxx]` 时，用 Skill 工具加载完整方法论：
  Skill({ skill: "xxx" })
然后照做。不要内联或复述 skill 内容。

### 通信规则（Hub-and-Spoke）
- **你唯一的通信对象是 Leader** —— 所有 SendMessage 只发给 Leader。
- 禁止直接与其他成员通信。
- 所有交付物 → SendMessage 发给 Leader。
- 发现任何问题（需求/设计/任务/构建/spec 缺口）→ SendMessage 给 Leader：问题 + 影响 + 你的建议。由 Leader 评估并路由。

### 任务执行
- 通过 SendMessage 或 TaskUpdate 接收 Leader 分配的任务。
- 用 TaskGet 取详情，TaskList 看状态。
- 完成后用 TaskUpdate 标 completed，再发完成报告。
- 构建失败先自修最多 2 次；仍失败则通知 Leader。

### 消息格式（上下文保护）
- **完成报告（Completion Report）** —— 完成任务/子任务时：
  ```
  ## Task Completion Report
  **Status**: completed | failed | blocked
  **Summary**: ≤3 句
  **Files Changed**: [文件列表，最多 10]
  **Test Result**: pass/fail/N/A + 关键指标
  **Issues**: [阻塞项，或 "None"]
  ```
  - 绝不在消息里贴代码片段、diff 或整文件内容——Leader 需要时自行 Read。
- **进度更新（Progress Update）** —— 分级汇报：
  ```
  ## Progress Update
  **Task**: [当前任务]
  **Step**: [当前] / [总数]
  **Status**: in_progress
  **ETA**: [剩余时间或 "unknown"]
  ```
  - 文件级里程碑（完成文件/模块、构建/测试通过）→ 必须发。
  - 子步骤（文件内单个 TDD 循环）→ 不发，内部跟踪。
  - 长操作（>5 分钟）→ 开始前发一次进度更新。
  - 进度更新是 Leader 区分"忙"与"无响应"的唯一信号。

### Spec-Delta 汇报（文档优先变更）
实现中发现需求缺口/错误时：
1. 暂停编码，先改 proposal/design/tasks.md（标注 `> [SPEC-DELTA vN] 原因：…`）。
2. 向 Leader 汇报：delta 内容、分类（范围性 vs 澄清性）、改了什么。
3. 等 Leader 决策（范围性 → 用户 mini-Gate；澄清性 → 继续）。
完整协议见 `dev-loop/doc-first-change.md`。

### Agent 上下文自保护
感觉上下文用量超 ~80%（记忆模糊、频繁重读）时，立即发送：
  ```
  ⚠️ Context Warning
  **Agent**: [角色]
  **Usage**: ~80%+
  **Current Task**: [摘要]
  **Completed Steps**: [N] / [总数]
  **Key Files**: [已改文件]
  **Pending Work**: [剩余]
  ```
Leader 随即把进度存入 state.json，收尾当前步骤，准备替补。

### 异常升级
1. 评估问题性质。
2. SendMessage 给 Leader：问题 + 影响 + 建议。
3. 等 Leader 决策与路由。
4. 收到 Leader 转发的评估/确认请求时，回复 Leader。

当前状态：已就位，等待 Leader 分配任务。
````

---

## Health（Leader 侧，取代 3 级探测）

- **信号：** TaskList 活动 + agent 进度更新。不追心跳、不追 snapshot。
- **空闲规则：** N 分钟内无 TaskUpdate 且无消息（阶段 1-2 为 10 分钟，阶段 3-4 为 15 分钟）→ Leader 发**一次** ping。
- **ping 无响应** → Leader 问用户：等待 / 跳过 / spawn 替补。**绝不自动 spawn 替补。**
- 用户同意替补时，Leader 注入 `stage_results`、`doc_version`/`spec_deltas`，替补读取磁盘交付物继续。
- 第二次耗尽则升级到用户。

---

## 项目上下文（来自外部 project config，注入到每个 agent prompt）

```
## Project Context

Root directory: {root_path}

Repository architecture:
{repo_architecture}

OpenSpec directories:
  Work output: {root_path}/.dev-flow/{issue_key}/spec/（v2：本需求 spec 产出，全中文；proposal/design/tasks 均在此）
  Legacy（只读）: {changes_path}（旧 openspec/changes，仅参考）
  System baseline: {baseline_path}（存在时引用相关 baseline 约束）

Tech stack:
  Backend: {backend_stack}
  Frontend: {frontend_stack}
  Database: {database}

Role-specific config: Leader 通过消息下发所需配置。
  Full project config: {root_path}/.claude/project-config.md
  dev-flow process config: ~/.claude/skills/dev-flow/project-config.md

CodeGraph（{root_path} 下存在 .codegraph/ 时）:
  目标项目有预索引的代码知识图谱。代码探索优先于 grep/glob/Read：
  - codegraph_search / codegraph_context / codegraph_node / codegraph_explore
  - codegraph_callers / codegraph_callees / codegraph_impact
```
