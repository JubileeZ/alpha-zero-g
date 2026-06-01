---
name: execute-dfp
description: Stateful orchestrator that runs a parallel execution dependency flow plan (DFP) using subagents. Use when executing layered issues in parallel using TDD or Grilling sessions.
---

# Dependency Flow Executor (execute-dfp)

## Quick start

1. Run `to-dfp` to generate `dependency_flow_plan.md`.
2. Locate the first incomplete layer.
3. Start the orchestrator state machine.

## Workflows

### 1. Initialize State Machine
Orchestrator reads or creates `dfp_state.json` in workspace root:
```json
{
  "current_layer": 1,
  "active_subagents": {},
  "completed_issues": [],
  "failed_issues": {}
}
```

### 2. Spawn Parallel Layer Subagents
Identify all incomplete issues in the current layer with zero active blockers. Construct a single concurrent `invoke_subagent` array call:
For each issue, check GitHub labels (`ready-for-agent` vs `needs-triage`):

- **If `ready-for-agent` (AFK)**: Spawn TDD subagent directly:
  - **Role**: "TDD Developer for Issue #<number>"
  - **TypeName**: "self"
  - **Prompt**: "Implement Issue #<number> using `/tdd`. Target 100% test coverage and Ruff/Mypy compliance. Send `{\"status\": \"success\", \"issue\": <number>}` on finish."
- **If `needs-triage` or other (HITL)**: Spawn Grill subagent:
  - **Role**: "Grill Master for Issue #<number>"
  - **TypeName**: "self"
  - **Prompt**: "Run `/grill-with-docs` for Issue #<number>. When aligned, post Agent Brief, apply `ready-for-agent` label, and send `{\"status\": \"ready\", \"issue\": <number>}`."

Save active subagents in `dfp_state.json` under `"active_subagents"`.

### 3. Handle Asynchronous Wakeups
When subagents complete and send callbacks, parse `dfp_state.json`:

- **Grill callback (`ready`)**: Remove from `active_subagents`. Instantly spawn TDD subagent for that issue. Update state.
- **TDD callback (`success`)**: Remove from `active_subagents`. Close GitHub issue:
  ```bash
  gh issue close <number> --comment "Resolved via parallel TDD subagent."
  ```
  Add to `completed_issues`. Update state.
- **Failure callback**: Remove from `active_subagents`. Add to `failed_issues`. Do not kill other running subagents; let them finish.

### 4. Triage and Advance
Once `"active_subagents"` is empty for the current layer:
- If `"failed_issues"` is not empty: Present failure details to USER, halt execution, and await manual triage.
- If all layer issues succeeded: Increment `current_layer`, wipe `failed_issues`, and proceed to next layer.

### 5. Manual Interrupts
If USER inputs "pause", "stop", or "abort":
- Kill all active subagents using `manage_subagents` with `Action="kill"`.
- Clean up active list in `dfp_state.json`. Report status.
