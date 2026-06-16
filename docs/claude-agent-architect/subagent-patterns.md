## Subagent Patterns

Subagents are specialized Claude instances that handle complex tasks independently. They start with a clean context (no pollution from the main conversation), operate with specified tools, and return results as summaries. The exploration results do not bloat your main conversation; only the conclusions return.

### Built-In Subagent Types

Type | Model | Mode | Tools | Use For  
---|---|---|---|---  
**Explore** | Haiku (fast) | Read-only | Glob, Grep, Read, safe bash | Codebase exploration, finding files  
**General-purpose** | Inherits | Full read/write | All available | Complex research + modification  
**Plan** | Inherits (or Opus) | Read-only | Read, Glob, Grep, Bash | Planning before execution  
  
### Creating Custom Subagents

Define subagents in `.claude/agents/` (project) or `~/.claude/agents/` (personal):

```yaml
---
name: security-reviewer
description: Expert security code reviewer. Use PROACTIVELY after any code
  changes to authentication, authorization, or data handling.
tools: Read, Grep, Glob, Bash
model: opus
permissionMode: plan
---

You are a senior security engineer reviewing code for vulnerabilities.

When invoked:
1. Identify the files that were recently changed
2. Analyze for OWASP Top 10 vulnerabilities
3. Check for secrets, hardcoded credentials, SQL injection
4. Report findings with severity levels and remediation steps

Focus on actionable security findings, not style issues.
``` 

### Subagent Configuration Fields

Field | Required | Purpose  
---|---|---  
`name` | Yes | Unique identifier (lowercase + hyphens)  
`description` | Yes | When to invoke (include “PROACTIVELY” to encourage auto-delegation)  
`tools` | No | Comma-separated. Inherits all tools if omitted. Supports `Agent(agent_type)` to restrict spawnable agents  
`disallowedTools` | No | Tools to deny, removed from inherited or specified list  
`model` | No | `sonnet`, `opus`, `haiku`, `inherit` (default: `inherit`)  
`permissionMode` | No | `default`, `acceptEdits`, `delegate`, `dontAsk`, `bypassPermissions`, `plan`  
`maxTurns` | No | Maximum agentic turns before the subagent stops  
`memory` | No | Persistent memory scope: `user`, `project`, `local`  
`skills` | No | Auto-load skill content into subagent context at startup. As of v2.1.133, subagents also discover project, user, and plugin skills via the `Skill` tool the same way the parent session does. Earlier versions silently dropped these from subagent context.  
`hooks` | No | Lifecycle hooks scoped to this subagent’s execution  
`background` | No | Always run as background task  
`isolation` | No | Set to `worktree` for isolated git worktree copy  
  
### Worktree Isolation

Subagents can operate in temporary git worktrees, providing a complete isolated copy of the repository:

```yaml
---
name: experimental-refactor
description: Attempt risky refactoring in isolation
isolation: worktree
tools: Read, Write, Edit, Bash, Grep, Glob
---

You have an isolated copy of the repository. Make changes freely.
If the refactoring succeeds, the changes can be merged back.
If it fails, the worktree is discarded with no impact on the main branch.
``` 

Worktree isolation is essential for experimental work that might break the codebase.

### Parallel Subagents

Use parallel subagents for independent research tasks that do not need to coordinate with each other:

```
> Have three explore agents search in parallel:
> 1. Authentication code
> 2. Database models
> 3. API routes
``` 

Each agent runs in its own context window, finds relevant code, and returns a summary. The main context stays clean.

### The Recursion Guard

Without spawn limits, agents delegate to agents that delegate to agents, each one losing context and burning tokens. The recursion guard pattern enforces budgets:

```bash
#!/bin/bash
# recursion-guard.sh — enforce spawn budget
CONFIG_FILE="${HOME}/.claude/configs/recursion-limits.json"
STATE_FILE="${HOME}/.claude/state/recursion-depth.json"

MAX_DEPTH=2
MAX_CHILDREN=5
DELIB_SPAWN_BUDGET=2
DELIB_MAX_AGENTS=12

# Read current depth
current_depth=$(jq -r '.depth // 0' "$STATE_FILE" 2>/dev/null)

if [[ "$current_depth" -ge "$MAX_DEPTH" ]]; then
    echo "BLOCKED: Maximum recursion depth ($MAX_DEPTH) reached" >&2
    exit 2
fi

# Increment depth using safe arithmetic (not ((VAR++)) with set -e)
new_depth=$((current_depth + 1))
jq --argjson d "$new_depth" '.depth = $d' "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"
``` 

**Critical lesson:** Use spawn budgets, not just depth limits. Depth-based limits track parent-child chains (blocked at depth 3) but miss width: 23 agents at depth 1 is still “depth 1.” A spawn budget tracks total active children per parent, capped at a configurable maximum. The budget model maps to the actual failure mode (too many total agents) rather than a proxy metric (too many nesting levels).

**Recursive delegation is now a first-party depth.** As of Claude Code v2.1.172 (June 10, 2026), sub-agents can spawn their own sub-agents, nesting up to 5 levels deep — where delegation was previously effectively one level. This makes the recursion guard above more important, not less: the platform now permits exactly the agents-delegating-to-agents chains that burn context and tokens, so the spawn budget and depth cap are the thing keeping a 5-level tree from fanning out into hundreds of active agents. Treat 5 levels as a ceiling the platform allows, not a default to reach for.

### Agent Teams (Research Preview)

Agent Teams coordinate multiple Claude Code instances that work independently, communicate via a shared mailbox and task list, and can challenge each other’s findings:

Component | Role  
---|---  
**Team lead** | Main session that creates the team, spawns teammates, coordinates work  
**Teammates** | Separate Claude Code instances working on assigned tasks  
**Task list** | Shared work items that teammates claim and complete (file-locked)  
**Mailbox** | Messaging system for inter-agent communication  
  
Enable with: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

**When to use agent teams vs subagents:**

| Subagents | Agent Teams  
---|---|---  
**Communication** | Report results back only | Teammates message each other directly  
**Coordination** | Main agent manages all work | Shared task list with self-coordination  
**Best for** | Focused tasks where only result matters | Complex work requiring discussion and collaboration  
**Token cost** | Lower | Higher (each teammate = separate context window)  
  
### Agent View and Goal Loops (May 2026)

Claude Code v2.1.139 added **Agent View** , a research-preview interface started with `claude agents` that shows running, blocked, and completed Claude Code sessions from one screen. The official docs frame it as a way to dispatch and manage many sessions, see what each session is doing, and identify which ones need operator input. This gives multi-agent work an operations view that final summaries cannot provide.

Use Agent View when promoting a subagent or team pattern: inspect which sessions are blocked, which are still running, and whether the work distribution matches the intended architecture. Do not treat it as proof of quality. It is observability; tests, review gates, and evidence reports still decide whether the work is sound.

The same release added `/goal`, which sets a completion condition and lets Claude continue across turns until the condition is met, including interactive, `-p`, and Remote Control use. Treat `/goal` as a session-scoped completion loop, not a substitute for deterministic gates. It is useful for keeping an agent focused on a target, but tests, citation checks, deploy checks, and security hooks should remain command- or script-backed where failure must block.

### Workflow Tool (v2.1.147+)

Claude Code v2.1.147 adds an off-by-default `Workflow` tool for deterministic multi-agent orchestration. Enable it with `CLAUDE_CODE_WORKFLOWS=1`. Architecturally, this is important because it gives Claude Code a first-party orchestration primitive for flows that previously required custom dispatch scripts, mailbox state, and subagent coordination conventions.

Do not delete the harness around it. A Workflow can structure execution, but it does not replace your safety model. Keep PreToolUse and PostToolUse hooks as the blocking layer, keep spawn budgets or workflow step budgets to prevent runaway width, keep filesystem state auditable, and keep final evidence reports outside the model’s self-assessment. In practice: use Workflow for orchestration shape; use hooks, tests, and review gates for truth.

* * *
