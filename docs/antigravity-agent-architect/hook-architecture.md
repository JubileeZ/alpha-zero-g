## Hook Architecture

Hooks are shell commands triggered by Antigravity CLI lifecycle events. They run outside the LLM as plain scripts, not prompts interpreted by the model. The model wants to run `rm -rf /`? A 10-line bash script checks the command against a blocklist and rejects it before the shell ever sees it. The hook fires whether the model wants it to or not.

Unlike other platforms that rely on exit codes to block execution, Antigravity CLI uses a **JSON in / JSON out decision protocol** over stdin/stdout, and hooks always exit with code 0.

### Available Events

Antigravity CLI exposes documented lifecycle events. The event list grows with releases, so treat the reference docs as the source of truth and check the [cheat sheet](https://cloud.google.com/antigravity-cli/cheatsheet) for the current full table before wiring production hooks:

Category | Events | Can Block?  
---|---|---  
**Session** | `SessionStart`, `Setup`, `SessionEnd` | No  
**User / completion** | `UserPromptSubmit`, `UserPromptExpansion`, `Stop`, `StopFailure`, `TeammateIdle` | Prompt/expansion/stop/idle can block; `StopFailure` cannot  
**Tool** | `PreToolUse`, `PermissionRequest`, `PermissionDenied`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch` | Pre/permission/batch can block; post events cannot  
**Subagent / task** | `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted` | Stop/task events can block; start cannot  
**Context** | `PreCompact`, `PostCompact`, `InstructionsLoaded` | `PreCompact` can block; post/load cannot  
**Filesystem / workspace** | `CwdChanged`, `FileChanged`, `WorktreeCreate`, `WorktreeRemove` | Worktree creation can block; others cannot  
**Configuration / notification** | `ConfigChange`, `Notification` | Config changes can block except policy settings; notifications cannot  
**MCP** | `Elicitation`, `ElicitationResult` | Yes  
  
### The Hook Contract

Antigravity hooks use a structured JSON protocol:

*   **Input (stdin):** Receives JSON containing details of the event and the pending tool call:
    ```json
    {
      "toolCall": {
        "name": "run_command",
        "args": {
          "CommandLine": "git push origin main --force"
        }
      },
      "session_id": "abc-123"
    }
    ```
*   **Output (stdout):** Must output a valid JSON decision object:
    *   To allow: `{"decision":"allow"}`
    *   To block: `{"decision":"deny", "reason":"Force-push to main is blocked."}`
*   **Exit code:** Always exit with code `0`. The decision is carried by the stdout JSON, not by the exit status.

**Critical:** If your hook outputs anything other than a valid JSON object, or if it exits with a non-zero code, the runtime will handle it as an error and block the action. Do not use exit codes for blocking.

### Hook Configuration

Hooks live in `.agents/hooks.json` (project-level) or user-level settings at `~/.gemini/antigravity-cli/hooks.json`:

```json
{
  "safety-gate": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [
          {
            "type": "command",
            "command": "./hooks/validate-shell.sh"
          }
        ]
      }
    ]
  },
  "auto-lint": {
    "enabled": true,
    "PostToolUse": [
      {
        "matcher": "write_file",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if [[ \"$FILE_PATH\" == *.py ]]; then black --quiet \"$FILE_PATH\" 2>/dev/null; fi'"
          }
        ]
      }
    ]
  }
}
``` 

The `matcher` field filters by tool name. Key tool names include `run_command` (shell), `write_file` (writing), `read_file` (reading), and `*` for all tools. Matchers can also filter by custom MCP tool names or regular expressions.

### Three Types of Guarantees

Before writing any hook, ask: what kind of guarantee do I need?

**Formatting guarantees** ensure consistency after the fact. PostToolUse hooks on `write_file` run your formatter after every file change. The model’s output does not matter because the formatter normalizes everything.

```json
{
  "auto-format": {
    "enabled": true,
    "PostToolUse": [
      {
        "matcher": "write_file",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'if [[ \"$FILE_PATH\" == *.py ]]; then black --quiet \"$FILE_PATH\" 2>/dev/null; elif [[ \"$FILE_PATH\" == *.js ]] || [[ \"$FILE_PATH\" == *.ts ]]; then npx prettier --write \"$FILE_PATH\" 2>/dev/null; fi'"
          }
        ]
      }
    ]
  }
}
``` 

**Safety guarantees** prevent dangerous actions before they execute. PreToolUse hooks on `run_command` inspect commands and block destructive patterns:

```bash
#!/bin/bash
# validate-shell.sh — block dangerous commands
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.toolCall.args.CommandLine // empty')

if echo "$CMD" | grep -qE "rm\s+-rf\s+/|git\s+push\s+(-f|--force)\s+(origin\s+)?main|git\s+reset\s+--hard|DROP\s+TABLE"; then
    echo '{"decision":"deny", "reason":"Dangerous command detected: '$CMD'"}'
    exit 0
fi

echo '{"decision":"allow"}'
exit 0
``` 

**Quality guarantees** validate state at decision points. PreToolUse hooks on `run_command` matching `git commit` commands run your linter or test suite and block the commit if quality checks fail:

```bash
#!/bin/bash
# quality-gate.sh — lint before commit
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.toolCall.args.CommandLine // empty')

if echo "$CMD" | grep -qE "^git\s+commit"; then
    if ! LINT_OUTPUT=$(ruff check . --select E,F,W 2>&1); then
        echo '{"decision":"deny", "reason":"Lint failed: '$LINT_OUTPUT'"}'
        exit 0
    fi
fi

echo '{"decision":"allow"}'
exit 0
``` 

### Hook Types Beyond Shell Commands

Antigravity CLI supports various hook types:

*   **Command hooks** (`type: "command"`) run shell scripts. Fast, deterministic, no token cost.
*   **MCP tool hooks** (`type: "mcp_tool"`) call a tool on an already-connected MCP server.
*   **Prompt hooks** (`type: "prompt"`) send a single-turn prompt to a fast model. The model returns a JSON response to allow or block.
*   **Agent hooks** (`type: "agent"`) spawn a dynamic subagent with tool access for multi-turn verification.
*   **HTTP hooks** (`type: "http"`) send the event’s JSON input as a POST request to a URL and receive JSON back.

### Async Hooks

Hooks can run in the background without blocking execution. Add `async: true` for non-critical operations like notifications and logging:

```json
{
  "type": "command",
  "command": ".agents/hooks/notify-slack.sh",
  "async": true
}
``` 

Use async for notifications, telemetry, and backups. Never use async for formatting, validation, or anything that must complete before the next action.

### Dispatchers Over Independent Hooks

Running seven hooks all firing on the same event, each reading stdin independently, creates race conditions. Two hooks writing to the same JSON state file concurrently will truncate the JSON. Every downstream hook that parses that file breaks.

The fix: one dispatcher per event that runs hooks sequentially from cached stdin:

```bash
#!/bin/bash
# dispatcher.sh — run hooks sequentially with cached stdin
INPUT=$(cat)
HOOK_DIR="$HOME/.gemini/antigravity-cli/hooks/pre-tool-use.d"

for hook in "$HOOK_DIR"/*.sh; do
    [ -x "$hook" ] || continue
    OUTPUT=$(echo "$INPUT" | "$hook")
    DECISION=$(echo "$OUTPUT" | jq -r '.decision // "allow"')
    if [ "$DECISION" = "deny" ]; then
        echo "$OUTPUT"
        exit 0
    fi
done

echo '{"decision":"allow"}'
exit 0
``` 

### Debugging Hooks

Five techniques for debugging hooks that fail silently:

1.  **Test scripts independently.** Pipe sample JSON: `echo '{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m test"}}}' | bash your-hook.sh`
2.  **Use stderr for debug output.** Errors output to stderr can be inspected in debug logs. Output intended to be parsed by the agent runtime must be printed to stdout as valid JSON.
3.  **Watch for jq failures.** Wrong JSON paths return `null` silently. Test `jq` expressions against real tool input.
4.  **Verify decision keys.** Ensure the stdout JSON matches exactly `{"decision":"deny", "reason":"..."}`.
5.  **Keep hooks fast.** Hooks run synchronously. Keep all hooks under 2 seconds, ideally under 500ms.

### Effort and Session Provenance

*   **`effort.level` in hook input:** Hooks receive an `effort.level` JSON field on the same input that carries `toolCall` and `session_id`. The same value is exported as the `$AGY_EFFORT` (or `$GY_EFFORT`) env var.
*   **`AGY_SESSION_ID` (or `SESSION_ID`) env var:** Subprocesses executed by the shell see the active session identifier, closing the provenance gap.

* * *
