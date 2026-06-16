## Production Patterns

### Opus 4.7 Long-Horizon Patterns (April 2026)

Claude Opus 4.7 (April 16, 2026) shipped with specific capabilities that change what a harness needs to defend against:

  * **Tool-failure resilience:** Opus 4.7 continues through tool failures that halted Opus 4.6 sessions. You can reduce — but not eliminate — defensive retry wrappers in subagent code. Keep the hook-level guards; trim the in-prompt “if the tool fails, try again three times” scaffolding.
  * **`xhigh` effort tier (Opus-4.7 only):** Sits between `high` and `max`. Recommended default for coding and agentic workloads. On long-running subagents, `xhigh` meaningfully outperforms `high` with sub-proportional token cost. `max` remains the right choice for single-shot hard reasoning; `xhigh` is better for sustained tasks.
  * **Token-budget ceiling:** Configurable per agent run via `output_config.task_budget` (beta header `task-budgets-2026-03-13`). The model sees a running countdown and gracefully scopes work to the budget instead of running out unexpectedly. Use for agentic loops where you want predictable token spend without sacrificing quality on short prompts.
  * **Implicit-need awareness:** First Claude model to pass “implicit-need” tests — recognizing when the user’s literal request underspecifies what they actually need. This makes CLAUDE.md’s “clarifying rules” section less necessary. If your CLAUDE.md is 200 lines of “also consider X when the user asks for Y” guardrails, prune the ones that are now covered natively.



### Worktree Base, Sandbox Paths, and Admin Settings (May 7, 2026)

Claude Code v2.1.133 adds four admin-tier settings worth knowing about for production harnesses:

Setting | Values | What it does  
---|---|---  
`worktree.baseRef` | `fresh` (default) | `head` | New worktrees branch from `origin/<default>` again. **Breaking-default revert from v2.1.128** , which had used local `HEAD`. Set `worktree.baseRef: "head"` if your team relies on unpushed commits being available in new worktrees.  
`sandbox.bwrapPath` | absolute path | Pin the Bubblewrap binary location on Linux/WSL hosts where it is not on `$PATH` or where you ship a vendored version.  
`sandbox.socatPath` | absolute path | Same idea for the `socat` binary used by sandbox networking.  
`parentSettingsBehavior` | `'first-wins'` (default) | `'merge'` | Admin-tier control over how SDK `managedSettings` compose with parent enterprise/team settings. `'merge'` lets a child session inherit and extend; `'first-wins'` keeps the parent authoritative.  
  
The `worktree.baseRef` revert is the one to flag for users: agents that relied on the v2.1.128-v2.1.132 behavior (worktrees branching from local `HEAD`) lose access to unpushed work in fresh worktrees unless they opt back in.

### OTel Feedback Survey for Enterprise Observability (May 8, 2026)

Claude Code v2.1.136 added `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL` to re-enable the in-session quality survey for enterprises capturing the responses through OpenTelemetry. If your org sinks OTel events to a central observability stack, this env var puts the survey back into the data path so quality signal flows through the same pipeline as latency and error metrics. Treat it as opt-in: the default keeps the survey suppressed, which is correct for non-OTel deployments.

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

A May 2026 arXiv study of 29,585 AI-agent pull-request lifecycles separates operational agency from merge governance. The useful architecture lesson is simple: agents can start work, carry branches forward, open PRs, review work, and summarize risk, while merge authority remains a separate governance boundary.

Make that boundary explicit in the harness. Let agents prepare PRs and collect evidence; require human approval for merges, releases, and destructive repository operations unless the organization has a separately audited automation policy. Where automation executes a merge, preserve logs that distinguish the executor from the human or policy that authorized it.

### Error Handling Patterns

**Atomic file writes.** Multiple agents writing to the same state file simultaneously corrupts JSON. Write to `.tmp` files, then `mv` atomically. The OS guarantees `mv` is atomic on the same filesystem.

```
# Atomic state update
jq --argjson d "$new_depth" '.depth = $d' "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"
``` 

**State corruption recovery.** If state gets corrupted, the recovery pattern recreates from safe defaults rather than crashing:

```
if ! jq -e '.depth' "$RECURSION_STATE_FILE" &>/dev/null; then
    # Corrupted state file, recreate with safe defaults
    echo '{"depth": 0, "agent_id": "root", "parent_id": null}' > "$RECURSION_STATE_FILE"
    echo "- Recursion state recovered (was corrupted)"
fi
``` 

**The`((VAR++))` bash trap.** `((VAR++))` returns exit code 1 when VAR is 0 because `0++` evaluates to 0, which bash treats as false. With `set -e` enabled, this kills the script. Use `VAR=$((VAR + 1))` instead.

### Blast Radius Classification

Classify every agent action by blast radius and gate accordingly:

Classification | Examples | Gate  
---|---|---  
**Local** | File writes, test runs, linting | Auto-approve  
**Shared** | Git commits, branch creation | Warn + proceed  
**External** | Git push, API calls, deployments | Require human approval  
  
Remote Control (connecting to local Claude Code from any browser or mobile app) turns the “External” gate from a blocking wait into an async notification. The agent keeps working on the next task while you review the previous one from your phone.

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

Criteria must be machine-verifiable: test pass/fail, linter output, HTTP status codes, file existence checks. An early task that asked the agent to “write tests that pass” produced `assert True` and `assert 1 == 1`. Technically correct. Practically worthless.

Criteria Quality | Example | Outcome  
---|---|---  
Vague | “Tests pass” | Agent writes trivial tests  
Measurable but incomplete | “Tests pass AND coverage >80%” | Tests cover lines but test nothing meaningful  
Comprehensive | “All tests pass AND coverage >80% AND no type errors AND linter clean AND each test class tests a distinct module” | Production-quality output  
  
### Failure Modes to Watch For

Failure Mode | Description | Prevention  
---|---|---  
**Shortcut Spiral** | Skipping quality loop steps to finish faster | Evidence gate requires proof for each criterion  
**Confidence Mirage** | “I’m confident” without running verification | Ban hedging language in completion reports  
**Phantom Verification** | Claiming tests pass without running them this session | Stop hook runs tests independently  
**Deferred Debt** | TODO/FIXME/HACK in committed code | PreToolUse hook on git commit scans diff  
**Filesystem Pollution** | Dead-end artifacts from abandoned iterations | Cleanup step in completion criteria  
  
### A Concrete Session Trace

A session trace from an autonomous run processing a PRD with 5 stories:

  1. **SessionStart fires.** Dispatcher injects: current date, project detection, philosophy constraints, cost tracking initialization. Five hooks, 180ms total.

  2. **Agent reads the PRD, plans the first story.** `UserPromptSubmit` fires. Dispatcher injects: active project context, session drift baseline.

  3. **Agent calls Bash to run tests.** `PreToolUse:Bash` fires. Credentials check, sandbox validation, project detection. 90ms. Tests run. `PostToolUse:Bash` fires: activity heartbeat logged, drift check.

  4. **Agent calls Write to create a file.** `PreToolUse:Write` fires: file scope check. `PostToolUse:Write` fires: lint check, commit tracking.

  5. **Agent finishes the story.** `Stop` fires. Quality gate checks: did the agent cite evidence? Hedging language? TODO comments in the diff? If any check fails, exit 2 and the agent continues.

  6. **Independent verification:** A fresh agent runs the test suite without trusting the previous agent’s self-report.

  7. **Three code review agents spawn in parallel.** Each reviews the diff independently. If any reviewer flags CRITICAL, the story goes back in the queue.

  8. **Story passes. Next story loads.** The cycle repeats for all 5 stories.




Total hooks fired across 5 stories: ~340. Total time in hooks: ~12 seconds. That overhead prevented three credential leaks, one destructive command, and two incomplete implementations in a single overnight run.

### Case Study: Overnight PRD Processing

A production harness processed 12 PRDs (47 stories) across 8 overnight sessions. Metrics compare the first 4 PRDs (minimal harness: CLAUDE.md only) against the last 8 (full harness: hooks, skills, quality gates, multi-agent review).

Metric | Minimal (4 PRDs) | Full Harness (8 PRDs) | Change  
---|---|---|---  
**Credential leaks** | 2 leaked to git | 7 blocked pre-commit | Reactive to preventive  
**Destructive commands** | 1 force-push to main | 4 blocked | Exit 2 enforcement  
**False completion rate** | 35% failed tests | 4% | Evidence gate + Stop hook  
**Revision rounds/story** | 2.1 | 0.8 | Skills + quality loop  
**Context degradation** | 6 incidents | 1 incident | Filesystem memory  
**Token overhead** | 0% | ~3.2% | Negligible  
**Hook time/story** | 0s | ~2.4s | Negligible  
  
The two credential leaks required rotating API keys and auditing downstream services: roughly 4 hours of incident response. The harness overhead that prevented the equivalent was 2.4 seconds of bash per story. The false completion rate dropped from 35% to 4% because the Stop hook independently ran tests before allowing the agent to report done.

* * *
