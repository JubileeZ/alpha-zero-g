## Subagent Patterns

Subagents in Antigravity CLI are specialized agent instances that handle complex tasks independently. They start with a clean context (no pollution from the main conversation), operate with specified tools, and return results as summaries. The exploration results do not bloat your main conversation; only the conclusions return.

### Built-In Subagent Modes

Mode | Mode Type | Tools | Use For  
---|---|---|---  
**Explore** | Read-only | `find_by_name, grep_search, read_file` | Codebase exploration, finding files  
**General-purpose** | Full read/write | All available | Complex research + modification  
**Plan** | Read-only | `read_file, find_by_name, grep_search, run_command` | Planning before execution  
  
### Dynamic Subagent Spawning

Antigravity CLI has **no static agents configuration directory**. Unlike other platforms where subagents require YAML file definitions, Antigravity spawns subagents **dynamically at runtime** via prompts. 

When a subagent is spawned, `agy` creates dynamic `agent.json` artifacts at runtime (viewable via `/artifact`).

#### Spawning Subagents via Prompt

The orchestrator spawns subagents when you describe the parallel work in your prompt:

```
Run these as parallel subagents:

1. SECURITY AUDIT: Review all new code for input validation, financial
   calculation precision, and data handling. Produce a security report.

2. TEST SUITE: Write tests for the new feature. Run them and iterate
   until everything passes. Keep test files in the repo.

3. DOCUMENTATION: Update README.md to document the new features.

These tasks are independent. Run them in parallel.
```

Monitor progress with `/agents` in the active session.

### Worktree Isolation

Dynamic subagents can be instructed to run in temporary git worktrees to isolate experimental changes:

```
Spawn a subagent in an isolated git worktree to attempt this refactoring.
If it succeeds, merge the changes back. If it fails, discard the worktree.
```

### Parallel Subagents

Use parallel subagents for independent research tasks that do not need to coordinate with each other. Each agent runs in its own context window, finds relevant code, and returns a summary. The main context stays clean.

### The Recursion Guard

Without spawn limits, subagents can spawn further subagents, fanning out into hundreds of active processes that burn context and tokens. Guard against this with a PreToolUse hook on subagent spawning:

```bash
#!/usr/bin/env bash
# recursion-guard.sh — enforce spawn budget
STATE_FILE="${HOME}/.gemini/antigravity-cli/state/recursion-depth.json"

MAX_DEPTH=2

# Read current depth
current_depth=$(jq -r '.depth // 0' "$STATE_FILE" 2>/dev/null)

if [[ "$current_depth" -ge "$MAX_DEPTH" ]]; then
    printf '{"decision":"deny","reason":"Maximum recursion depth reached"}\n'
    exit 0
fi

# Increment depth safely
new_depth=$((current_depth + 1))
jq --argjson d "$new_depth" '.depth = $d' "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"

printf '{"decision":"allow"}\n'
exit 0
``` 

**Critical lesson:** Use spawn budgets, not just depth limits. A spawn budget tracks total active children per parent, capped at a configurable maximum. Pair this with a PreToolUse hook that tracks active subagent count in a state file.

### Agent View and Goal Loops

*   **Agent View (`/agents` command):** Displays active, blocked, and completed subagents in the session dashboard. Use it to monitor the work distribution.
*   **Goal Loop (`/goal` command):** Sets a completion condition and lets the agent continue across turns until the condition is met.

* * *
