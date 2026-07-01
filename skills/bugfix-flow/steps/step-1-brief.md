---
partOf: bugfix-flow
version: 1.0.0
description: Step 1 instructions for bug analysis. Leader reads this file when entering Step 1.
---

# Step 1: Bug Analysis

> **Objective**: Locate the root cause of the bug through log analysis (if test environment) and code exploration, then propose a fix approach.

## 1. Log Analysis (Test Environment Only)

> **Guard**: Only execute if `env_source` is "test". If "local", skip to section 2.

If test environment and Grafana MCP is available:

### 1a. Search Logs by Keywords

Leader delegates to **code-explorer**:

"Search Grafana Loki for error logs related to this bug.

Bug description: {bug_description}
Affected services: {list services from repos_to_fix}
Time range: last 24 hours (or user-specified)

Use mcp__grafana__query_loki_logs with:
  - datasourceUid: from project-config → grafana.datasource_uid (if configured) or auto-detect
  - logql: construct based on service labels and error keywords
  - limit: 20
  - direction: backward (newest first)

Extract from logs:
  - Error messages and stack traces
  - Request IDs or trace IDs
  - Timestamps and frequency patterns
  - Which service/module is failing"

### 1b. Trace Follow (if trace_id provided)

If `trace_id` is non-empty:

"Trace the request chain across services using the trace ID: {trace_id}

Use mcp__grafana__query_loki_logs with:
  - logql: {service=~\".+\"} |= \"{trace_id}\"
  - Search across all services to find the full request chain

Map the request flow:
  Service A → Service B → Service C (where it failed)
  Identify at which service the error originates"

### 1c. Log Summary

Present findings to Leader:
```
## Grafana Log Analysis

Error pattern: <summary of error>
Frequency: <how often in last 24h>
Origin service: <which service>
Affected endpoints: <API paths if identifiable>
Stack trace highlights: <key error lines>
Trace flow (if applicable): <service chain>
```

If Grafana MCP is unavailable → note "Grafana log analysis skipped (MCP unavailable)" and proceed to code exploration.

## 2. Code Exploration

Leader delegates to **code-explorer**:

"Locate the root cause of this bug in the codebase.

Bug description: {bug_description}
Branches checked out: {repos_to_fix}

### Starting Points (prioritized):

1. **jira-flow state.json** (if exists):
   Read {root_path}/.jira-flow/{parent_key}-state.json → get phase_decisions[1].key_files
   These files were modified in the original development — the bug is likely in or near them.

2. **Error messages from logs** (if test environment):
   Search for error message strings in the codebase to find the exact source location.

3. **Bug keywords**:
   Search for relevant module/function names mentioned in the bug description.

### Analysis Steps:

1. Explore the relevant code areas
2. Identify the root cause (logic error, missing null check, wrong query, race condition, etc.)
3. Map the impact scope: which files need to change, are there downstream dependencies?
4. Check if the bug exists in other similar code paths (potential siblings of the same bug)

### Output Format:

```
## Root Cause Analysis

**Root Cause**: <1-3 sentences explaining exactly what's wrong>

**Affected Files**:
  - {repo_path}/path/to/file.php:142 — <what's wrong here>
  - {repo_path}/path/to/another-file.ts:58 — <what's wrong here>

**Impact Scope**:
  - Direct impact: <what functionality is broken>
  - Side effects risk: <what else might be affected by the fix>
  - Similar code paths: <any other places with the same pattern>

**Reproduction**: <how this bug triggers — from logs or code analysis>
```"

## 3. Fix Proposal

Based on the root cause analysis, propose a fix approach:

```
## Proposed Fix

**Approach**: <describe the fix strategy in 3-5 sentences>

**Changes per repo**:
  {repo_path}:
    - Modify {file}: {what to change}
    - Add {test_file}: reproduction test

  {repo_path}:
    - Modify {file}: {what to change}

**Estimated scope**: {N} files across {M} repos

**Risk assessment**:
  - Regression risk: <low/medium/high> — <why>
  - Side effects: <what to watch for>
  - Migration needed: <yes/no>
```

## Gate 1

**Semi-auto**: Present the full analysis + fix proposal via AskUserQuestion:
- "Root cause: {summary}. Fix approach: {summary}. Files to change: {list}. Proceed with this approach?"
- User can: Confirm / Adjust fix approach / Abort

**Full-auto**: Log the analysis and auto-proceed.

Update state.json: `current_step = 1`, `step_results.1 = { root_cause, fix_proposal, confirmed }`.
