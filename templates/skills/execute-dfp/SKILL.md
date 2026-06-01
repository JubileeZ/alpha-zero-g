---
name: execute-dfp
description: Orchestrates autonomous agents to execute a dependency flow plan (DFP). Use when the user wants to run a multi-agent orchestration loop to tackle open issues sequentially using grilling and TDD.
---

# Dependency Flow Executor (execute-dfp)

## Quick start

To start orchestrating the dependency flow plan:
1. Ensure the DFP flow is generated (using `to-dfp`).
2. Identify the first incomplete layer (Layer 1).
3. Run the orchestration workflow below for each issue.

## Workflows

### 1. Process Layer Issues
For the current layer in the DFP flow, identify all issues that have no active open blockers. Tackle them in order or concurrently:

### 2. Grill & Align (grill-with-docs)
To prevent context bloat in the main orchestrator, spawn a dedicated subagent for the grilling session:
1. Call `invoke_subagent` with:
   - **Role**: "Grill Master for Issue #<number>"
   - **TypeName**: "self"
   - **Prompt**: "Execute a `/grill-with-docs` session for Issue #<number>. Challenge the design against our existing domain model, align on equations and schemas, and update CONTEXT.md and ADRs. Report back by sending a message to parent ID containing `{\"status\": \"clean\"}` once requirements are clean and locked in."
2. The subagent must explicitly trigger and run the `/grill-with-docs` skill.
3. Once the subagent reports that the issue is "clean" via `send_message`, proceed to the next step.

### 3. Spawn TDD Subagent
To prevent context bloat in the main orchestrator, spawn a separate subagent to implement the code changes:
1. Call `invoke_subagent` with:
   - **Role**: "TDD Developer for Issue #<number>"
   - **TypeName**: "self"
   - **Prompt**: "Implement Issue #<number> using the `/tdd` skill. Target 100% test coverage, strict type hints, and full Ruff/Mypy compliance. Report back by sending a message to parent ID containing `{\"status\": \"success\"}` or `{\"status\": \"failed\", \"error\": \"...\"}`."
2. The subagent follows the strict Red-Green-Refactor loop.

### 4. Handle Subagent Outcomes
Asynchronous messages from subagents trigger the orchestrator's wake up:
- **Success**: Close the GitHub issue:
  ```bash
  gh issue close <number> --comment "Successfully resolved via TDD subagent."
  ```
  Update progress.md and move to next issue/layer.
- **Failure**: Pause execution, collect error details/test logs from the message payload, and present options to the USER for guidance.

### 5. Interruptions & Pausing
The orchestrator must check for user intervention at the start of every wakeup/invocation:
- If the USER sends any message containing "stop", "pause", or "abort":
  1. Immediately halt launching new tasks or layers.
  2. Kill active subagents using `manage_subagents` tool with `Action="kill"`.
  3. Report current status and ask the USER for instructions.
