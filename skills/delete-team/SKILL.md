---
name: delete-team
description: Use when user says "删除团队", "清理团队", "/delete-team" — gracefully shuts down all team members and cleans up team resources
---

# Delete Team

## Overview

Gracefully shut down the team: notify all members to stop → confirm all shutdowns → clean up team resources.

## Flow

```dot
digraph {
  rankdir=TB;
  start [label="User triggers /delete-team", shape=box];
  check [label="Check if an active team exists", shape=diamond];
  no_team [label="Inform user: no active team", shape=box];
  shutdown [label="Send shutdown_request to all members in parallel", shape=box];
  wait [label="Wait for all members to confirm shutdown", shape=box];
  delete [label="TeamDelete cleans up resources", shape=box];
  confirm [label="Report cleanup complete to user", shape=box];

  start -> check;
  check -> no_team [label="No team"];
  check -> shutdown [label="Team exists"];
  shutdown -> wait;
  wait -> delete;
  delete -> confirm;
}
```

## Steps

### 1. Check for Team

Read the `~/.claude/teams/` directory to confirm an active team exists. If no team is found, inform the user and exit.

### 2. Parallel Shutdown

Send a shutdown_request to each member using SendMessage:

```json
SendMessage({
  to: "<member name>",
  message: { "type": "shutdown_request", "reason": "Team tasks complete, cleaning up" }
})
```

Send to all members in parallel.

### 3. Wait for Confirmation

Wait for all members to respond with `shutdown_response` and `approve: true`.

If any member refuses or times out (30 seconds), report to the user and ask how to proceed.

### 4. Clean Up Resources

Once all shutdowns are confirmed, execute `TeamDelete` to clean up the team directory and task list.

### 5. Report

Confirm to the user that the team has been fully cleaned up.
