---
name: execute-dfp
description: Execute a Dependency Flow Plan (DFP) graph in parallel using subagents. Use when running issues that have dependencies on each other, or when asked to execute a DFP or run issues in parallel.
---

# Dependency Flow Executor (execute-dfp)

## Quick start

1. Run `to-dfp` to generate `dependency_flow_plan.md`.
2. Start the orchestrator state machine.
3. The orchestrator will parse the Mermaid graph and spawn subagents for root issues.

## Workflows

### 1. Initialize State Machine
- [ ] Read or create `dfp_state.json` in workspace root.
- [ ] Initialize the `"issues"` map to track status (`pending`, `running`, `completed`, `failed`) and `conversation_id`.

### 2. Spawn Ready Subagents (Graph Execution)
- [ ] Parse the Mermaid graph in `dependency_flow_plan.md` to find **root issues** (in-degree 0) and issues where **all parent dependencies have a `completed` status**.
- [ ] Filter this list to issues currently marked as `pending`.
- [ ] For each ready issue with label `ready-for-agent`: Spawn TDD subagent (`Role`: "TDD Developer", `TypeName`: "self").
- [ ] For each ready issue with label `needs-triage`: Spawn Grill subagent (`Role`: "Grill Master", `TypeName`: "self").
- [ ] Update `dfp_state.json` to mark spawned issues as `"running"` and record their `"conversation_id"`.

### 3. Handle Asynchronous Wakeups
When subagents complete and send callbacks, parse `dfp_state.json`:
- [ ] **Grill callback (`ready`)**: Instantly spawn TDD subagent for that issue. Keep status as `running` but update `conversation_id`.
- [ ] **TDD callback (`success`)**: Update issue status to `completed` and close the GitHub issue using `gh issue close`.
- [ ] **Failure callback**: Update issue status to `failed`. Do not kill other running subagents; independent branches continue executing.
- [ ] **Loop**: After any callback, immediately return to Step 2 to evaluate the Mermaid graph and spawn newly unblocked issues.

### 4. Triage and Halts
- [ ] If an issue fails, leave its dependents as `pending`.
- [ ] Halt execution and alert the user for manual triage ONLY when there are no `"running"` issues AND there are `"pending"` issues permanently blocked by a `"failed"` dependency.
- [ ] If all issues in the graph reach `"completed"`, announce the DFP execution is finished.

### 5. Manual Interrupts
If USER inputs "pause", "stop", or "abort":
- [ ] Kill all subagents marked `"running"` using `manage_subagents` with their `conversation_id`.
- [ ] Revert their status in `dfp_state.json` back to `"pending"`.
