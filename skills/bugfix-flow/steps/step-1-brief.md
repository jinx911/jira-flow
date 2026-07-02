# Step 1：Bug 分析

> 目标：通过日志分析（测试环境）+ 代码定位找到根因，提修复方案。

## 1. 日志分析（仅测试环境）

> 仅 `env_source == "test"` 执行；本地跳到 §2。

测试环境 + Grafana MCP 可用时：

### 1a 关键词搜日志
委托 code-explorer：用 `mcp__grafana__query_loki_logs`（datasourceUid 取 project-config `grafana` 或自动检测；logql 按服务标签 + 错误关键词；limit 20；direction backward）搜与 bug 相关错误日志（bug 描述 / 受影响服务 / 时间窗）。提取：错误信息 + 堆栈、request/trace id、时间频率、失败服务/模块。

### 1b 链路追踪（有 trace_id 时）
`trace_id` 非空：`logql: {service=~".+"} |= "{trace_id}"`，跨服务追请求链，定位错误起源于哪个服务。

### 1c 日志摘要
```
## Grafana 日志分析
错误模式 / 频率（近 24h）/ 起源服务 / 受影响端点 / 堆栈要点 / 链路流（如有）
```
Grafana MCP 不可用 → 注明"跳过日志分析"，继续代码定位。

## 2. 代码定位

委托 code-explorer：

**起点（按优先级）**：
1. **dev-flow state.json**（若存在）：读 `{root_path}/.dev-flow/{parent_key}-state.json` → 取关键文件（原开发改动文件，bug 多在附近）
2. **日志错误信息**（测试环境）：在代码搜错误字符串定位
3. **bug 关键词**：搜 bug 描述里的模块/函数名

**分析步骤**：探索相关代码 → 定位根因（逻辑错/空指针/查询错/竞态等）→ 评估影响范围（哪些文件要改、下游依赖）→ 查同类代码路径（潜在同源 bug）。

**输出**：
```
## 根因分析
根因：<1-3 句>
受影响文件：{repo}/path:行 — <问题>
影响范围：直接 / 副作用风险 / 同类路径
复现：<如何触发>
```

## 3. 修复方案

```
## 修复方案
思路：<3-5 句>
各仓库改动：{repo}: 改 {file}:<改什么>；加 {test_file}: 复现测试
预估范围：{N} 文件 / {M} 仓库
风险评估：回归风险（低/中/高）/ 副作用 / 是否需 migration
```

## Gate 1

Semi-auto：AskUserQuestion 展示根因 + 方案 + "按此方案修复？"。用户：确认/调整方案/中止。Full-auto：记录自动推进。
更新 state：`current_step=1`，`step_results.1={root_cause, fix_proposal, confirmed}`。
