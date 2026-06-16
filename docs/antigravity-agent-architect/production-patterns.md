## Production Patterns

### Model Selection and Effort Levels

When configuring Antigravity CLI (`agy`), select the appropriate model and effort levels:

*   **Gemini Models:** Use `--model gemini-3.5-flash` for fast, cost-effective runs, and `--model gemini-3.1-pro` for complex logic or large-horizon reasoning tasks.
*   **Effort Level:** Configure effort levels (e.g. `low`, `high`) depending on task complexity. Use higher effort levels on long-running subagents where sustained reasoning is required.
*   **API Quota Control:** Monitor and set limits on Google Cloud API quotas to manage token spend and concurrency across your team's harness instances.

### Worktree Base, Sandbox Paths, and Admin Settings

Antigravity CLI supports admin-tier settings configuration:

Setting | Values | What it does  
---|---|---  
`worktree.baseRef` | `fresh` (default) \| `head` | Determines whether new worktrees branch from `origin/<default>` or local `HEAD`.  
`sandbox.bwrapPath` | absolute path | Pin the Bubblewrap binary location on Linux/WSL hosts where it is not on `$PATH` or where you ship a vendored version.  
`sandbox.socatPath` | absolute path | Same idea for the `socat` binary used by sandbox networking.  
`parentSettingsBehavior` | `'first-wins'` (default) \| `'merge'` | Control how SDK `managedSettings` compose with parent enterprise/team settings.  
  
### The Quality Loop

A mandatory review process for all non-trivial changes:

  1. **Implement** \- Write the code
  2. **Review** \- Re-read every line. Catch typos, logic errors, unclear sections
  3. **Evaluate** \- Run the evidence gate. Check patterns, edge cases, test coverage
  4. **Refine** \- Fix every issue. Never defer to “later”
  5. **Zoom Out** \- Check integration points, imports, adjacent code for regressions
  6. **Repeat** \- If any evidence gate criterion fails, return to step 4
  7. **Report** \- List what changed, how verified, cite specific evidence

### The Evidence Gate

“I believe” and “it should” are not evidence. Cite file paths, test output, or specific code.

Criterion | Required Evidence  
---|---  
Follows codebase patterns | Name the pattern and file where it exists  
Simplest working solution | Explain what simpler alternatives were rejected and why  
Edge cases handled | List specific edge cases and how each is handled  
Tests pass | Paste test output showing 0 failures  
No regressions | Name the files/features checked  
Solves the actual problem | State user’s need and how this addresses it  
  
If you cannot produce evidence for any row, return to Refine.

### Human Merge Authority

Operational agency should be separate from merge governance. Agents can start work, carry branches forward, open PRs, review work, and summarize risk, while merge authority remains a separate governance boundary.

Make that boundary explicit in the harness. Let agents prepare PRs and collect evidence; require human approval for merges, releases, and destructive repository operations.

### Error Handling Patterns

**Atomic file writes:** Multiple agents writing to the same state file simultaneously corrupts JSON. Write to `.tmp` files, then `mv` atomically. The OS guarantees `mv` is atomic on the same filesystem.

```bash
# Atomic state update
jq --argjson d "$new_depth" '.depth = $d' "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"
``` 

**State corruption recovery:** If state gets corrupted, the recovery pattern recreates from safe defaults rather than crashing:

```bash
if ! jq -e '.depth' "$RECURSION_STATE_FILE" &>/dev/null; then
    # Corrupted state file, recreate with safe defaults
    echo '{"depth": 0, "agent_id": "root", "parent_id": null}' > "$RECURSION_STATE_FILE"
    echo "- Recursion state recovered (was corrupted)"
fi
``` 

**The `((VAR++))` bash trap:** `((VAR++))` returns exit code 1 when VAR is 0 because `0++` evaluates to 0, which bash treats as false. With `set -e` enabled, this kills the script. Use `VAR=$((VAR + 1))` instead.

### Blast Radius Classification

Classify every agent action by blast radius and gate accordingly:

Classification | Examples | Gate  
---|---|---  
**Local** | File writes, test runs, linting | Auto-approve  
**Shared** | Git commits, branch creation | Warn + proceed  
**External** | Git push, API calls, deployments | Require human approval  
  
### Task Specification for Autonomous Runs

Effective autonomous tasks include three elements: objective, completion criteria, and context pointers:

```
OBJECTIVE: Implement multi-agent deliberation with consensus validation.

COMPLETION CRITERIA:
- All tests in tests/test_deliberation_lib.py pass (81 tests)
- post-deliberation.sh validates consensus above 70% threshold
- recursion-guard.sh enforces spawn budget (max 12 agents)
- No Python type errors (mypy clean)

CONTEXT:
- Follow patterns in lib/deliberation/state_machine.py
- Consensus thresholds in configs/deliberation-config.json
- Spawn budget model: agents inherit budget, not increment depth
``` 

Criteria must be machine-verifiable: test pass/fail, linter output, HTTP status codes, file existence checks.

### Failure Modes to Watch For

Failure Mode | Description | Prevention  
---|---|---  
**Shortcut Spiral** | Skipping quality loop steps to finish faster | Evidence gate requires proof for each criterion  
**Confidence Mirage** | “I’m confident” without running verification | Ban hedging language in completion reports  
**Phantom Verification** | Claiming tests pass without running them this session | Stop hook runs tests independently  
**Deferred Debt** | TODO/FIXME/HACK in committed code | PreToolUse hook on git commit scans diff  
**Filesystem Pollution** | Dead-end artifacts from abandoned iterations | Cleanup step in completion criteria  
  
### A Concrete Session Trace

A session trace from an autonomous run processing a PRD:

  1. **SessionStart fires:** Dispatcher injects active project detection, philosophy constraints, and tracking initialization.
  2. **Agent reads the PRD, plans the first story:** `UserPromptSubmit` fires. Dispatcher injects active project context.
  3. **Agent calls `run_command` to run tests:** `PreToolUse:run_command` fires, executing sandbox validation. Tests run. `PostToolUse:run_command` fires.
  4. **Agent calls `write_file` to create a file:** `PreToolUse:write_file` fires, followed by `PostToolUse:write_file` verifying lint checks.
  5. **Agent finishes the story:** `Stop` fires. Quality gate checks if the agent cited evidence, if any check fails the hook denies and the agent continues.
  6. **Independent verification:** A fresh agent runs the test suite without trusting the previous agent’s self-report.
  7. **Dynamic review subagents spawn in parallel:** Each reviews the diff independently. If any reviewer flags CRITICAL, the story goes back in the queue.

* * *
