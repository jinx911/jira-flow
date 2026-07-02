# Learn 知识格式

定义 capture 的 jsonl 行格式 + `knowledge.md` / `playbook.md` 结构。capture / apply / distill 共用本文件。

## jsonl 行 schema

每行一条 JSON（append-only）：

```json
{"at":"<ISO>","issue_key":"<KEY>","stage":<1-4>,"signal":"<gate_fail|spec_delta|retry_escalation|user_correction|manual_note|win>","severity":"<high|medium|low>","detail":"<≤2 句>","source":"<auto|user>"}
```

字段：
- `at`：ISO 时间戳
- `issue_key`：本次 run 的 issue key
- `stage`：信号发生阶段（1-4）
- `signal`：信号类型（见 `learn/SKILL.md` 信号分类表）
- `severity`：high / medium / low
- `detail`：≤2 句描述
- `source`：auto（dev-flow 自动捕获）/ user（`/dev-flow learn` 手动）

文件名：`{root_path}/.dev-flow/{issue_key}/lessons-{HHmm}.jsonl`（每次 run 一个文件，append-only，归并到该需求目录）。

## knowledge.md 结构（项目级）

```markdown
# {project} Dev-Flow 知识库

> 由 learn distill 自动维护。apply 只挑相关条目注入，不整本灌。每条带溯源。

## 必触发章节
- <章节名> — <何时触发> > source: <issue> @ <ISO>, signal: <type>

## 常见坑
- <坑描述> > source: ...

## 复用点
- <可复用实现> — <怎么用> > source: ...

## 项目约定
- <约定> > source: ...
```

## playbook.md 结构（全局）

结构与 knowledge.md 一致，但只放"跨项目通用"的条目（通用触发提示 / 通用常见坑 / 示例）；项目专属内容不进这里。初始内容见 `skills/dev-flow/playbook.md`。

## 溯源与去重

- 每条 knowledge/playbook 条目带 `> source: <issue> @ <ISO>, signal: <type>`。
- `knowledge.md` / `playbook.md` 超 200 行：distill 合并重复、删过时（保留每类最近 N 条）。
- `lessons` 超 30 天归档（移到 `.dev-flow/archive/` 或删，不删可查）。
