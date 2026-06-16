## Hook Architecture

Hooks are shell commands triggered by Claude Code lifecycle events. They run outside the LLM as plain scripts, not prompts interpreted by the model. The model wants to run `rm -rf /`? A 10-line bash script checks the command against a blocklist and rejects it before the shell ever sees it. The hook fires whether the model wants it to or not.

### Available Events

Claude Code exposes 29 documented lifecycle events across eight categories as of this guide update. The event list grows with releases, so treat the reference docs as the source of truth and check the [cheat sheet](</guides/claude-code-cheatsheet>) for the current full table before wiring production hooks:

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
  
### Exit Code Semantics

Exit codes determine whether hooks block actions:

Exit Code | Meaning | Action  
---|---|---  
**0** | Success | Operation proceeds. Stdout shown in verbose mode.  
**2** | Blocking error | Operation stops. Stderr becomes error message fed to Claude.  
**1, 3, etc.** | Non-blocking error | Operation continues. Stderr shown in verbose mode only (Ctrl+O).  
  
**Critical:** Every security hook must use `exit 2`, not `exit 1`. Exit 1 is a non-blocking warning. The dangerous command still executes. This is the most common hook mistake across teams.

### Hook Configuration

Hooks live in settings files. Project-level (`.claude/settings.json`) for shared hooks. User-level (`~/.claude/settings.json`) for personal hooks:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/validate-bash.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
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

The `matcher` field filters an event-specific value. For tool events, it matches `tool_name` values such as `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, MCP tool names like `mcp__server__tool`, or `*` for all tools. Simple names and `|`-separated lists are exact matches; values with other characters are JavaScript regular expressions. Some events do not support matchers and always fire when configured.

### Hook Input/Output Protocol

Hooks receive JSON on stdin with full context:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test",
    "description": "Run test suite"
  },
  "session_id": "abc-123",
  "agent_id": "main",
  "agent_type": "main"
}
``` 

For advanced control, PreToolUse hooks can output JSON to modify tool input, inject context, or make permission decisions. Use the `hookSpecificOutput` wrapper — the older top-level `decision`/`reason` format is deprecated for PreToolUse:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Command validated and modified",
    "updatedInput": {
      "command": "npm test -- --coverage --ci"
    },
    "additionalContext": "Note: This database has a 5-second query timeout."
  }
}
``` 

### Three Types of Guarantees

Before writing any hook, ask: what kind of guarantee do I need?

**Formatting guarantees** ensure consistency after the fact. PostToolUse hooks on Write/Edit run your formatter after every file change. The model’s output does not matter because the formatter normalizes everything.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
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

**Safety guarantees** prevent dangerous actions before they execute. PreToolUse hooks on Bash inspect commands and block destructive patterns with exit code 2:

```bash
#!/bin/bash
# validate-bash.sh — block dangerous commands
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')

if echo "$CMD" | grep -qE "rm\s+-rf\s+/|git\s+push\s+(-f|--force)\s+(origin\s+)?main|git\s+reset\s+--hard|DROP\s+TABLE"; then
    echo "BLOCKED: Dangerous command detected: $CMD" >&2
    exit 2
fi
``` 

**Quality guarantees** validate state at decision points. PreToolUse hooks on `git commit` commands run your linter or test suite and block the commit if quality checks fail:

```bash
#!/bin/bash
# quality-gate.sh — lint before commit
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')

if echo "$CMD" | grep -qE "^git\s+commit"; then
    if ! LINT_OUTPUT=$(ruff check . --select E,F,W 2>&1); then
        echo "LINT FAILED -- fix before committing:" >&2
        echo "$LINT_OUTPUT" >&2
        exit 2
    fi
fi
``` 

### Hook Types Beyond Shell Commands

Claude Code supports five hook types:

**Command hooks** (`type: "command"`) run shell scripts. Fast, deterministic, no token cost.

**MCP tool hooks** (`type: "mcp_tool"`) call a tool on an already-connected MCP server. Use them when validation logic already lives behind an MCP boundary and does not need a separate shell script.

**Prompt hooks** (`type: "prompt"`) send a single-turn prompt to a fast Claude model. The model returns `{ "ok": true }` to allow or `{ "ok": false, "reason": "..." }` to block. Use for nuanced evaluation that regex cannot express.

**Agent hooks** (`type: "agent"`) spawn a subagent with tool access (Read, Grep, Glob) for multi-turn verification. They are experimental; prefer command hooks for production gates and reserve agent hooks for checks that genuinely require inspecting actual files or test output:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify all unit tests pass. Run the test suite and check results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
``` 

As of Claude Code v2.1.140, agent hook input includes `subagent_type`, which lets a shared hook distinguish a security-reviewer run from an explorer or generic worker without guessing from prompt text.

**HTTP hooks** (`type: "http"`) send the event’s JSON input as a POST request to a URL and receive JSON back. Use for webhooks, external notification services, or API-based validation (v2.1.63+). Not supported for `SessionStart` events:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "https://your-webhook.example.com/hook",
            "headers": { "Authorization": "Bearer $WEBHOOK_TOKEN" },
            "allowedEnvVars": ["WEBHOOK_TOKEN"],
            "timeout": 10
          }
        ]
      }
    ]
  }
}
``` 

### Async Hooks

Hooks can run in the background without blocking execution. Add `async: true` for non-critical operations like notifications and logging:

```json
{
  "type": "command",
  "command": ".claude/hooks/notify-slack.sh",
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
HOOK_DIR="$HOME/.claude/hooks/pre-tool-use.d"

for hook in "$HOOK_DIR"/*.sh; do
    [ -x "$hook" ] || continue
    echo "$INPUT" | "$hook"
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -eq 2 ]; then
        exit 2  # Propagate block
    fi
done
``` 

### Debugging Hooks

Five techniques for debugging hooks that fail silently:

  1. **Test scripts independently.** Pipe sample JSON: `echo '{"tool_input":{"command":"git commit -m test"}}' | bash your-hook.sh`
  2. **Use stderr for debug output.** Exit code 2 stderr is fed back to Claude as an error message. Non-blocking stderr (exit 1, 3, etc.) appears only in verbose mode (Ctrl+O).
  3. **Watch for jq failures.** Wrong JSON paths return `null` silently. Test `jq` expressions against real tool input.
  4. **Verify exit codes.** A PreToolUse hook that uses `exit 1` provides zero enforcement while appearing to work.
  5. **Keep hooks fast.** Hooks run synchronously. Keep all hooks under 2 seconds, ideally under 500ms.



### SDK-Side Hook Event Streaming

Self-hosted harnesses built on `claude-agent-sdk-python` (v0.1.74+, May 6, 2026) can subscribe to hook events directly from the message stream rather than going through shell-script callbacks. Set `include_hook_events=True` on `ClaudeAgentOptions` and `HookEventMessage` objects (PreToolUse, PostToolUse, Stop, and others) yield from the same iterator as assistant messages and tool results. This mirrors the TypeScript SDK’s `includeHookEvents` option; bundled CLI was bumped to v2.1.129 in the same release.

The event-stream pattern is the right fit when your harness already lives in Python and you want hook signals in the same control flow as model output. The shell-script hook contract (exit codes, stdin JSON, dispatchers) remains the right answer for harnesses that compose multiple tools, share hooks across Claude Code and Codex, or need exit-code semantics for blocking.

### Effort and Session Provenance (May 7-8, 2026)

Two additions in Claude Code v2.1.132 and v2.1.133 give hooks and subprocesses better signal about their execution context:

  * **`effort.level` in hook input.** Hooks now receive an `effort.level` JSON field on the same input that carries `tool_input` and `session_id`. The same value is exported as the `$CLAUDE_EFFORT` env var, so Bash commands can read it without parsing JSON. Use this to scale hook cost with effort tier: skip expensive validation on `low`, run the full security gate on `xhigh` or `max`.
  * **`CLAUDE_CODE_SESSION_ID` env var on Bash subprocesses.** Bash tool subprocesses now see the same `session_id` value the hooks see, exposed as `CLAUDE_CODE_SESSION_ID`. This closes the provenance gap for tools that log per-session state and were previously unable to correlate subprocess events with hook events.



Both signals are available without code changes; existing hooks that ignore the new fields keep working.

### `autoMode.hard_deny` and v2.1.136 Hook/Plugin Fixes (May 8, 2026)

Claude Code v2.1.136 added a new hard-deny tier to auto mode and fixed a cluster of plugin and MCP issues that affected long-running harnesses:

  * **`settings.autoMode.hard_deny`.** Auto mode classifier rules that block unconditionally, regardless of user intent or allow exceptions. This sits above the existing allow/deny matchers as a non-negotiable governance lever. Use it for rules that must never be overridden (force-push to main, secret-bearing files, production database access) even when an operator has approved the broader category in their personal settings.
  * **MCP servers no longer disappear after`/clear`.** Servers configured in `.mcp.json`, plugins, and claude.ai connectors had been silently dropping out of the active set after a `/clear` in the VS Code extension, JetBrains plugin, and Agent SDK. The fix lands in v2.1.136. If you saw “MCP server X went missing mid-session,” this was the cause.
  * **MCP OAuth refresh-token loss on concurrent refresh.** Users with several remote MCP servers should no longer need daily re-authentication. Concurrent refresh writes were overwriting each other.
  * **Plan mode now blocks file writes correctly.** A matching `Edit(...)` allow rule was bypassing plan-mode write protection. Plan mode is now enforced regardless of allow rules.
  * **Plugin`Stop` and `UserPromptSubmit` hooks no longer fail mid-session.** Cache cleanup was deleting plugin-version files still in use by the running session, breaking these two hook events specifically. The fix keeps in-use versions pinned.
  * **`skills` entry in `plugin.json`.** Setting `skills` was hiding the plugin’s default `skills/` directory. Now the entry composes correctly, and pointing it at a file path raises an explicit error instead of failing silently.
  * **`CLAUDE_ENV_FILE` SessionStart hook env vars going stale.** Vars exported by SessionStart hooks via `CLAUDE_ENV_FILE` were going stale after `/resume` or `/clear`. Fixed in v2.1.136. Sessions now re-source the env file on these events.



For governance harnesses, the operationally interesting line items are `autoMode.hard_deny` (new lever) and the MCP-disappearance fix (silent failure that broke long sessions). Everything else is a quality-of-life cleanup.

### Structured Hook Arguments and Block Continuation (May 11, 2026)

Claude Code v2.1.139 added two hook details that matter for production harnesses: an `args: string[]` exec form for command hooks, and `continueOnBlock` for `PostToolUse` hooks. Prefer `args` when a hook needs dynamic values or path placeholders. It spawns the command directly without a shell, which removes a whole class of quoting and injection mistakes.

Use `continueOnBlock` when a `PostToolUse` hook should feed its rejection reason back to Claude and continue the turn instead of ending the flow. Treat it as an operator-experience feature, not a security bypass. A blocking gate should still block the unsafe outcome.

The same release passes `CLAUDE_PROJECT_DIR` to MCP stdio servers and lets plugin configs reference `${CLAUDE_PROJECT_DIR}` in commands. MCP tools should resolve project-relative paths from that value rather than from whichever process working directory happened to launch the server.

Claude Code v2.1.140 is mostly a reliability release for harness operators: it fixes `ConfigChange` hooks not firing on settings changes, closes edge cases where `disableAllHooks` and `allowManagedHooksOnly` did not compose correctly across settings levels, and stops permission dialogs from exposing unintended environment variables returned by hook results. That makes the existing governance patterns in this section more dependable; it does not require a new hook architecture.

Claude Code v2.1.141 adds a hook-output `terminalSequence` field for desktop notifications, window titles, and bells without a controlling terminal. Treat that as operator signaling, not enforcement. Security and quality gates should still communicate failures through the normal blocking contract: structured hook output plus the exit behavior that prevents the unsafe action. The same release adds `claude agents --cwd <path>` for scoping Agent View to one directory, `CLAUDE_CODE_PLUGIN_PREFER_HTTPS` for plugin installs in environments without GitHub SSH keys, and `ANTHROPIC_WORKSPACE_ID` for workload-identity federation rules that cover more than one workspace. Those are architecture details for team harnesses: narrower operational views, fewer plugin-install assumptions, and explicit enterprise token scoping.

Claude Code v2.1.142 is more important for background-session orchestration than for hook semantics. `claude agents` can now dispatch background sessions with explicit directory, settings, MCP, plugin, permission, model, and effort flags instead of depending on wrapper state. Fast mode now defaults to Opus 4.7; pin `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` only if a harness has measured dependence on Opus 4.6’s behavior. Root-level plugin `SKILL.md` discovery and plugin-provided LSP visibility reduce packaging ambiguity. Fixes to `MCP_TOOL_TIMEOUT`, pre-existing background-session worktrees, daemon sleep/wake and post-upgrade cleanup, and plugin cache cleanup close reliability gaps that otherwise look like orchestration bugs.

### Stop-hook steering, cross-session authority, and multi-agent v2 (June 2026)

Four changes from early June matter for harness and multi-agent design.

**Stop/SubagentStop hooks gained a steering channel.** As of Claude Code v2.1.163, a `Stop` or `SubagentStop` hook can return `hookSpecificOutput.additionalContext` to hand Claude feedback and keep the turn going, without the response being labeled a hook error. Before this, a Stop hook’s only real lever was the exit-2 block, which reads as an error and counts toward the consecutive-block cap. For a quality-gate harness this is the cleaner primitive: a Stop hook that detects “you said done but the tests are red” can now inject “here is what is still failing, continue” instead of hard-blocking. Use the block for genuine stop conditions and `additionalContext` for “not done yet, here is why.”

**Cross-session messaging no longer carries borrowed authority.** v2.1.166 hardened the multi-session case: messages relayed via `SendMessage` from another Claude session no longer carry the originating user’s authority, so a receiving session refuses relayed permission requests and auto mode blocks them. If your orchestration has agents message each other, treat an inbound message as untrusted data, not as an authenticated instruction. This is the same principle the security section applies to tool output, extended to inter-agent messaging.

**Model resilience became a first-class setting.** The `fallbackModel` setting now chains up to three backup models, tried in order when the primary is overloaded or unavailable, and a turn auto-retries once on the fallback for unexpected non-retryable API errors. For a long-running autonomous harness, this turns a transient primary-model outage into a graceful degradation rather than a dropped run. `claude agents --json` also added a `waitingFor` field (v2.1.162) that surfaces what a blocked background session is waiting on, such as a permission prompt — an observability win for any coordinator polling a fleet of agents.

**Safe mode for clean-room governance and troubleshooting.** Claude Code v2.1.169 adds a `--safe-mode` flag (and the matching `CLAUDE_CODE_SAFE_MODE` environment variable) that starts a session with every customization disabled at once: CLAUDE.md, plugins, skills, hooks, and MCP servers. This is the inverse of the harness — a deliberate clean-room. Use it to answer the question every operator eventually asks: “is this behavior coming from the model, or from something I configured?” When a hook misfires, a skill activates when it should not, or an MCP server poisons context, `--safe-mode` gives you a known-empty baseline to diff against. It is also a governance primitive: a way to run the bare model with none of the persistent authority your harness normally grants, which matters when you need to reproduce a result without any operator-defined scaffolding influencing it.

**A note on model tiers.** This guide treats Opus 4.8 as Claude Code’s agentic default — the model that runs autonomous harnesses unless you select otherwise. As of June 9, 2026, Anthropic launched **Claude Fable 5** (`claude-fable-5`), a new tier above Opus described as its most powerful model — a “Mythos-class” system made safe for general use — selectable in Claude Code v2.1.170 via `/model claude-fable-5`. Opus 4.8 remains the agentic default; reach for the higher tier deliberately, on the decisions where raw reasoning depth justifies the cost, not as a blanket setting for a fleet.

**Codex shipped multi-agent v2.** Codex CLI v0.137.0 keeps the runtime choice with each thread, exposes cleaner follow-up and metadata defaults for spawned agents (`hide_spawn_agent_metadata` now defaults to true), and propagates raw parent events to child listeners. Its subagent model stays explicit: built-in default/worker/explorer agent types, TOML-defined custom agents, and concurrency controls (`agents.max_threads` default 6, `agents.max_depth` default 1). The same release adds a v1 skills extension with per-turn skill-catalog resolution and new thread-start/turn-error lifecycle contributor events, narrowing the gap with Claude Code’s hook/skill surface while keeping the kernel-sandbox posture as the default boundary. Codex v0.138.0–v0.139.0 then hardened multi-agent v2 for production: inter-agent message payloads are now encrypted, a v2 agent config catalog plus an agent-residency LRU manage which agents stay resident, and concurrency is counted by _active execution_ rather than by spawned threads, so idle agents no longer consume a slot. The lifecycle API matured too — `close_agent` was renamed `interrupt_agent` (v0.139.0) to reflect that it interrupts a running agent rather than merely closing a handle — and MCP startup warnings raised by a subagent now stay scoped to the owning thread instead of duplicating up into the parent’s transcript. For anyone building Codex-side orchestration, these are the difference between a demo and a fleet: encrypted message transport, bounded residency, execution-counted concurrency, and warnings that do not leak across the thread boundary.

* * *
