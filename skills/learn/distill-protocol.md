# Learn distill 协议

distill = 把累积信号提炼成"经验沉淀 + skill 升级提议"。由 `/dev-flow learn --upgrade` 触发，或 `lessons_captured` 每 ≥5 时编排器提醒（不自动跑结构改动）。

## 流程

spawn 一个临时 curator agent（general-purpose）：

1. **读**：本项目全部 `{root_path}/.dev-flow/*/lessons-*.jsonl` + 现有 `knowledge.md` + 全局 `playbook.md`
2. **聚类**：按 signal 类型 + detail 关键词聚类，识别重复 ≥2 次的模式
3. **分类落地**（按分级安全）：
   - **项目事实**（该项目专属）→ 更新 `{root_path}/.dev-flow/knowledge.md`（自动）
   - **通用经验**（跨项目）→ 追加 `skills/dev-flow/playbook.md`（自动）
   - **"skill 该强制 X"**（如某 Gate 检查项反复失败）→ 生成结构 diff → 入待审队列
4. **汇报**：自动落地摘要 + 待审结构 diff
5. **用户批准结构 diff** → commit（dev-flow 仓库）→ `./sync-local.sh`

## diff 生成与审核

- 结构 diff 范围：`SKILL.md` / `gate.md` Gate 规则 / `templates` 必填章节 / `triggers.md` 触发表 / `team-rules.md` / `resume.md` / `init-dev-flow`
- diff 必须保持目标文件行数预算（编排器 ≤150、子 skill ≤100）；超出则 curator 改提"提炼/拆分"，不直接堆
- diff 以 unified diff 呈现，每条带理由 + 溯源 issue
- 未批准的 diff 不落地；用户可逐条 accept / reject

## 去重 / 精简 / 归档

- `knowledge.md` / `playbook.md` 超 200 行：distill 合并重复、删过时（保留每类最近 N 条）
- `lessons` 超 30 天归档（移到 `.dev-flow/archive/` 或删，不删可查）
- 找不到新模式 → no-op，不刷屏
