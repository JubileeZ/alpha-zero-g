# Agent Architecture: Building AI-Powered Development Harnesses

> The complete system for building production AI agent harnesses. Skills, hooks, memory, subagents, multi-agent orchestration, and the patterns that make AI coding agents reliable infrastructure.

> **TL;DR:** Claude Code is not a chat box with file access. It is a programmable runtime with 29 documented lifecycle events, each hookable with shell scripts the model cannot skip. Stack hooks into dispatchers, dispatchers into skills, skills into agents, agents into workflows, and you get an autonomous development harness that enforces constraints, delegates work, persists memory across sessions, and orchestrates multi-agent deliberation. Claude Code v2.1.147 added the off-by-default `Workflow` tool (`CLAUDE_CODE_WORKFLOWS=1`), moving deterministic multi-agent orchestration from pure userland scripts toward a first-party runtime primitive; v2.1.149 reinforces the same lesson from the security side with PowerShell permission-bypass fixes and a git-worktree sandbox allowlist fix. Hooks and evidence gates still own correctness. This guide covers every layer of that stack: from a single hook to a 10-agent consensus system. Zero frameworks required. All bash and JSON.

Andrej Karpathy coined a term for what grows around an LLM agent: _claws_. The hooks, scripts, and orchestration that let the agent grip the world outside its context window. Most developers treat AI coding agents as interactive assistants. They type a prompt, watch it edit a file, and move on. That framing caps productivity at whatever you can personally oversee.

The infrastructure mental model is different: an AI coding agent is a programmable runtime with an LLM kernel. Every action the model takes passes through hooks you control. You define policies, not prompts. The model operates within your infrastructure the same way a web server operates within nginx rules. You do not sit at nginx and type requests. You configure it, deploy it, and monitor it.

The distinction matters because infrastructure compounds. A hook that blocks credentials in bash commands protects every session, every agent, every autonomous run. A skill that encodes your evaluation rubric applies consistently whether you invoke it or an agent does. An agent that reviews code for security runs the same checks whether you are watching or not.

* * *

### Key Takeaways

  * **Hooks guarantee execution; prompts do not.** Use hooks for linting, formatting, security checks, and anything that must run every time regardless of model behavior. Exit code 2 blocks actions. Exit code 1 only warns.
  * **Skills encode domain expertise that auto-activates.** The `description` field determines everything. Claude uses LLM reasoning (not keyword matching) to decide when to apply a skill.
  * **Subagents prevent context bloat.** Isolated context windows for exploration and analysis keep the main session lean. Run independent subagents in parallel, and use agent teams when workers need sustained coordination.
  * **Memory lives in the filesystem.** Files persist across context windows. CLAUDE.md, MEMORY.md, rules directories, and handoff documents form a structured external memory system.
  * **Multi-agent deliberation catches blind spots.** Single agents cannot challenge their own assumptions. Two independent agents with different evaluation priorities catch structural failures that quality gates cannot address.
  * **The harness pattern is the system.** CLAUDE.md, hooks, skills, agents, and memory are not independent features. They compose into a deterministic layer between you and the model that scales with automation.



* * *

### How to Use This Guide

Experience | Start Here | Then Explore  
---|---|---  
**Using Claude Code daily, want more** | [The Harness Pattern](harness-pattern.md) | [Skills System](skills-system.md), [Hook Architecture](hook-architecture.md)  
**Building autonomous workflows** | [Subagent Patterns](subagent-patterns.md) | [Multi-Agent Orchestration](multi-agent-orchestration.md), [Production Patterns](production-patterns.md)  
**Evaluating agent architecture** | [Why Agent Architecture Matters](why-agent-architecture.md) | [Decision Framework](decision-framework.md), [Security Considerations](security-considerations.md)  
**Setting up a team harness** | [CLAUDE.md Design](claude-md-design.md) | [Hook Architecture](hook-architecture.md), Quick Reference Card  
  
Each section builds on the previous. The [Decision Framework](decision-framework.md) at the end provides a lookup table for choosing the right mechanism for each problem type.

* * *

## Detailed Sections

To explore the guide's topics in detail, browse the following sections:
- [Why Agent Architecture Matters](why-agent-architecture.md)
- [The Harness Pattern](harness-pattern.md)
- [Skills System](skills-system.md)
- [Hook Architecture](hook-architecture.md)
- [Memory and Context](memory-and-context.md)
- [Subagent Patterns](subagent-patterns.md)
- [Multi-Agent Orchestration](multi-agent-orchestration.md)
- [CLAUDE.md Design](claude-md-design.md)
- [Production Patterns](production-patterns.md)
- [Security Considerations](security-considerations.md)
- [Decision Framework](decision-framework.md)
- [References](references.md)

---

## Five-Minute Golden Path

Before the deep dive, here is the shortest path from zero to a working harness. One hook, one skill, one subagent, one outcome.

### Step 1: Create a security hook (2 minutes)

Create `.claude/hooks/block-secrets.sh`:

```bash
#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if echo "$CMD" | grep -qEi '(AKIA|sk-|ghp_|password=)'; then
    echo "BLOCKED: Potential secret in command" >&2
    exit 2
fi
``` 

Wire it in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": ".claude/hooks/block-secrets.sh" }]
      }
    ]
  }
}
``` 

**Result:** Every bash command Claude runs is now screened for leaked credentials. The model cannot skip this check.

### Step 2: Create a code review skill (1 minute)

Create `.claude/skills/reviewer/SKILL.md` with frontmatter (`name: reviewer`, `description: Review code for security issues, bugs, and quality problems. Use when examining changes, reviewing PRs, or auditing code.`, `allowed-tools: Read, Grep, Glob`) and a checklist: SQL injection, XSS, hardcoded secrets, missing error handling, functions over 50 lines.

**Result:** Claude auto-activates this expertise whenever you mention review, check, or audit.

### Step 3: Spawn a subagent (30 seconds)

In any Claude Code session, ask Claude to review the last 3 commits for security issues using a separate agent. Claude spawns an Explore agent that reads the diff, applies your review skill, and returns a summary. Your main context stays clean.

### What you now have

A three-layer harness: a deterministic security gate (hook), domain expertise that auto-activates (skill), and isolated analysis that protects your context (subagent). Every section below expands one of these three layers.

* * *

## FAQ

### How many hooks is too many?

Performance, not count, is the constraint. Each hook runs synchronously, so total hook execution time adds to every matched tool call. 95 hooks across user-level and project-level settings run without noticeable latency when each hook completes in under 200ms. The threshold to watch: if a PostToolUse hook adds more than 500ms to every file edit, the session feels sluggish. Profile your hooks with `time` before deploying them.

### Can hooks block Claude Code from running a command?

Yes. PreToolUse hooks block any tool action by exiting with code 2. Claude Code cancels the pending action and shows the hook’s stderr output to the model. Claude sees the rejection reason and suggests a safer alternative. Exit 1 is a non-blocking warning where the action still proceeds.

### Where should I put hook configuration files?

Hook configurations go in `.claude/settings.json` for project-level hooks (committed to your repository, shared with your team) or `~/.claude/settings.json` for user-level hooks (personal, applied to every project). Project-level hooks take precedence when both exist. Use absolute paths for script files to avoid working-directory issues.

### Does every decision need deliberation?

No. The confidence module scores decisions across four dimensions (ambiguity, complexity, stakes, context dependency). Only decisions scoring below 0.70 overall confidence trigger deliberation, roughly 10% of total decisions. Documentation fixes, variable renames, and routine edits skip deliberation entirely. Security architecture, database schema changes, and irreversible deployments trigger it consistently.

### How do I test a system designed to produce disagreement?

Test both success paths and failure paths. Success: agents disagree productively and reach consensus. Failure: agents converge too quickly, never converge, or exceed spawn budgets. End-to-end tests simulate each scenario with deterministic agent responses, verifying that both validation gates catch every documented failure mode. A production deliberation system runs 141 tests across three layers: 48 bash integration tests, 81 Python unit tests, and 12 end-to-end pipeline simulations.

### What is the latency impact of deliberation?

A 3-agent deliberation adds 30-60 seconds of wall-clock time (agents run sequentially through the Agent tool). A 10-agent deliberation adds 2-4 minutes. The consensus and pride check hooks each run in under 200ms. The primary bottleneck is LLM inference time per agent, not orchestration overhead.

### How long should a CLAUDE.md file be?

Keep each section under 50 lines and the total file under 150 lines. Long files get truncated by context windows, so front-load the most critical instructions: commands and closure definitions before style preferences.

### Can this work with tools other than Claude Code?

The architectural principles (hooks as deterministic gates, skills as domain expertise, subagents as isolated contexts, filesystem as memory) apply conceptually to any agentic system. The specific implementation uses Claude Code’s lifecycle events, matcher patterns, and Agent tool. AGENTS.md carries the same patterns to Codex, Cursor, Copilot, Amp, and Windsurf. The harness pattern is tool-agnostic even if the implementation details are tool-specific.

* * *

## Quick Reference Card

### Hook Configuration

```json
{
  "hooks": {
    "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "script.sh"}]}],
    "PostToolUse": [{"matcher": "Write|Edit", "hooks": [{"type": "command", "command": "format.sh"}]}],
    "Stop": [{"matcher": "", "hooks": [{"type": "agent", "prompt": "Verify tests pass. $ARGUMENTS"}]}],
    "SessionStart": [{"matcher": "", "hooks": [{"type": "command", "command": "setup.sh"}]}]
  }
}
``` 

### Skill Frontmatter

```yaml
---
name: my-skill
description: What it does and when to use it. Include trigger phrases.
allowed-tools: Read, Grep, Glob
---
``` 

### Subagent Definition

```yaml
---
name: my-agent
description: When to invoke. Include PROACTIVELY for auto-delegation.
tools: Read, Grep, Glob, Bash
model: opus
permissionMode: plan
---

Instructions for the subagent.
``` 

### Exit Codes

Code | Meaning | Use For  
---|---|---  
0 | Success | Allow the operation  
2 | Block | Security gates, quality gates  
1 | Non-blocking warning | Logging, advisory messages  
  
### Key Commands

Command | Purpose  
---|---  
`/compact` | Compress context, preserve decisions  
`/context` | View context allocation and active skills  
`/agents` | Manage subagents  
`/goal <condition>` | Keep Claude working toward a completion condition  
`claude agents` | Open Agent View for running, blocked, and completed sessions  
`CLAUDE_CODE_WORKFLOWS=1` | Enable the Workflow tool for deterministic multi-agent orchestration  
`claude -c` | Continue most recent session  
`claude --print` | One-shot CLI invocation (no conversation)  
`# <note>` | Add note to memory file  
`/memory` | View and manage auto-memory  
  
### File Locations

Path | Purpose  
---|---  
`~/.claude/CLAUDE.md` | Personal global instructions  
`.claude/CLAUDE.md` | Project instructions (git-shared)  
`.claude/settings.json` | Project hooks and permissions  
`~/.claude/settings.json` | User hooks and permissions  
`~/.claude/skills/<name>/SKILL.md` | Personal skills  
`.claude/skills/<name>/SKILL.md` | Project skills (git-shared)  
`~/.claude/agents/<name>.md` | Personal subagent definitions  
`.claude/agents/<name>.md` | Project subagent definitions  
`.claude/rules/*.md` | Project rule files  
`~/.claude/rules/*.md` | User rule files  
`~/.claude/projects/{path}/memory/MEMORY.md` | Auto-memory  
  
* * *

## Changelog

Date | Change  
---|---  
2026-06-10 | Guide v1.18: **Recursive sub-agents (Claude Code v2.1.172).** Added a note to the Recursion Guard subsection: Claude Code sub-agents can now spawn their own sub-agents, nesting up to 5 levels deep — where delegation was previously effectively one level (v2.1.172, June 10). Reframed the userland spawn-budget/depth-cap pattern as the control that keeps a 5-level tree from fanning out, with 5 levels treated as a platform ceiling rather than a default.  
2026-06-09 | Guide v1.17: **Claude Code v2.1.169–v2.1.170 + Codex v0.138.0–v0.139.0 governance and multi-agent-v2 hardening.** Wove five verified harness-architecture changes into the body. [Skills System](skills-system.md) gained a **“Hiding the Bundled Surface as Governance”** subsection: the `disableBundledSkills` setting (and `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` env var) hides bundled skills, workflows, and built-in slash commands from the model as a deliberate attack-surface reduction (v2.1.169). The June Hook-Architecture subsection added the **`--safe-mode` flag** (and `CLAUDE_CODE_SAFE_MODE`), which starts a session with _all_ customizations disabled — CLAUDE.md, plugins, skills, hooks, MCP — for clean-room troubleshooting and governance (v2.1.169), plus a **model-tier note** : Anthropic’s **Claude Fable 5** (`claude-fable-5`) launched June 9 as a Mythos-class tier above Opus, selectable via `/model claude-fable-5` in v2.1.170, with Opus 4.8 remaining Claude Code’s agentic default. [Memory and Context](memory-and-context.md) added the **`/cd` command** (v2.1.169), which moves a session to a new working directory without breaking the mid-session prompt cache. [Multi-Agent Orchestration](multi-agent-orchestration.md) / Codex Parity hardened for production: **`close_agent` renamed `interrupt_agent`** (v0.139.0), **encrypted inter-agent message payloads, a v2 agent config catalog, agent-residency LRU, and concurrency counted by active execution** (v0.138.0), **AGENTS.md discovery routed through environment filesystems with preserved logical paths** for correct file selection on remote/symlinked workspaces (v0.138.0/v0.139.0), and **subagent MCP-startup warnings scoped to the owning thread** instead of duplicating into the parent (v0.139.0).  
2026-06-08 | Guide v1.16: **June agent-architecture patterns from Claude Code v2.1.162–v2.1.166 + Codex v0.137.0.** Added the **“Stop-hook steering, cross-session authority, and multi-agent v2”** subsection covering four harness-relevant changes: (1) `Stop`/`SubagentStop` hooks can return `hookSpecificOutput.additionalContext` to inject “not done yet, here is why” feedback and continue the turn without a hook-error block (v2.1.163); (2) cross-session messaging hardened so `SendMessage`-relayed messages from another session no longer carry the originating user’s authority — treat inbound inter-agent messages as untrusted data (v2.1.166); (3) the `fallbackModel` setting chains up to three backup models with a one-shot fallback retry on non-retryable API errors, and `claude agents --json` adds a `waitingFor` field for fleet observability (v2.1.162/166); (4) Codex multi-agent v2 (v0.137.0) keeps the runtime with each thread, defaults `hide_spawn_agent_metadata` to true, propagates parent events to child listeners, and adds a v1 skills extension with per-turn catalog resolution and thread-start/turn-error lifecycle contributor events. No spec change to AGENTS.md (still Agentic-AI-Foundation-stewarded, no versioned changelog).  
2026-05-31 | Guide v1.15: **Claude Code v2.1.157 + Hermes v0.15.1/v0.15.2 patches.** Added the **“Plugin and Skill Convergence in`.claude/skills/`“** subsection: Claude Code v2.1.157 makes any folder in a project’s `.claude/skills/` directory auto-load as a plugin without marketplace registration, and `claude plugin init <name>` scaffolds a fresh plugin with manifest + SKILL.md there. The harness implication is real — small-scope project tooling no longer pays the manifest tax to live in version control; plugins still own the bundled-installable ZIP shape. Same release ships `EnterWorktree` mid-session switching between Claude-managed worktrees and leaves background worktrees unlocked after the agent finishes so `git worktree remove`/`prune` work cleanly. Hermes Agent v0.15.1 (May 29) is the same-day Velocity hotfix: dashboard 401 reload-loop fix on loopback mode, Docker now requires explicit `HERMES_DASHBOARD_INSECURE=1`, MCP bare commands (`npx`, `npm`, `node`) resolve in Docker, Skills page restored, Kanban workers respond to SIGTERM cleanly, Skills.sh catalog grew 858 → 19,932 entries via sitemap. Hermes v0.15.2 (May 29) is a packaging-only hotfix that bundles `plugin.yaml` manifests in wheel and sdist distributions.  
2026-05-28 | Guide v1.14: **Claude Code v2.1.152-v2.1.154 + Codex v0.134.0-v0.135.0 + Hermes v0.15.0 architecture-pattern pass.** Claude Code shifted defaults and added orchestration primitives: **Opus 4.8 is now the default with high effort by default and a new`/effort xhigh`**; **dynamic workflows** orchestrate tens to hundreds of agents in the background via `/workflows`; lean system prompt is now default for all models except Haiku/Sonnet/Opus 4.7-and-earlier; the new `MessageDisplay` hook event lets hooks transform or hide assistant text as it is displayed; `disallowed-tools` in skill/command frontmatter removes tools while the skill is active; `/reload-skills` re-scans skill directories without restart; `SessionStart` hooks can return `reloadSkills: true` and set `hookSpecificOutput.sessionTitle`; `--fallback-model` switches mid-session when the primary is missing; **auto mode no longer requires opt-in consent** ; `pluginSuggestionMarketplaces` managed setting allowlists org marketplaces for context-aware suggestions; `claude agents` accepts `! <command>` background-shell sessions; plugins can declare `defaultEnabled: false`; stdio MCP subprocess env now includes `CLAUDE_CODE_SESSION_ID` and `CLAUDECODE=1`. Codex v0.134.0 made **`--profile` the primary profile selector** across CLI, TUI permissions, and sandbox flows (legacy configs rejected with migration guidance), added local conversation-history search, improved MCP setup with per-server environment targeting and OAuth for streamable HTTP servers, and **let read-only MCP tools run concurrently when they advertise`readOnlyHint`**; v0.135.0 added richer `codex doctor` diagnostics, `/status` remote details, vim text-object editing, named permission profiles in `/permissions`, and `Sandbox` presets in the Python SDK. Hermes Agent v0.15.0 (May 28) ships the **Velocity release** : `run_agent.py` refactored 76% across 14 modules, multi-agent Kanban v2 with auto-decomposition and swarm topology, Bitwarden Secrets Manager replacing per-provider keys with one bootstrap token, **Promptware defense** against Brainworm-class prompt injection at three security chokepoints, skill bundles, a TUI session orchestrator for multi-session management in one terminal, and a 4,500× faster `session_search` with the LLM dependency removed. Harness-architecture implications: the named-profile pattern (Codex `--profile`, Claude Code `pluginSuggestionMarketplaces`) is becoming the standard configuration primitive for multi-tenant agent runtimes; concurrent read-only MCP tools (Codex `readOnlyHint`) are the right pattern to fan out non-mutating context fetches; the `MessageDisplay` hook gives operators a first-class transformation surface that wasn’t reachable from `PostToolUse` or `Stop`; and the lean-system-prompt default removes the long-standing trade-off between operator-defined context and provider scaffolding.  
2026-05-24 | Guide v1.13: **Claude Code v2.1.150 + OpenAI Agents SDK v0.17.3 security/currentness pass.** Local `claude --version` returned `2.1.144 (Claude Code)` while npm latest for `@anthropic-ai/claude-code` returned `2.1.150` and GitHub latest release returned `v2.1.150`. Added v2.1.149 harness guidance for PowerShell permission-bypass fixes, PowerShell allow-rule/stale-variable permission-analysis fixes, and the git-worktree sandbox write-allowlist fix; noted that v2.1.150 is internal infrastructure only with no announced user-facing changes. PyPI latest for `openai-agents` returned `0.17.3`, so the OpenAI sandbox section now notes 0.17.1-0.17.3 follow-up hardening for archive extraction, GitRepo subpaths, sandbox credentials, relative workspace roots, and provider terminal-state handling.  
2026-05-21 | Guide v1.12: **Claude Code v2.1.147 Workflow pass.** Local `claude --version` returned `2.1.144 (Claude Code)` while npm latest for `@anthropic-ai/claude-code` returned `2.1.147`. Added the off-by-default `Workflow` tool as a first-party deterministic multi-agent orchestration primitive and clarified that hooks, tests, review gates, spawn budgets, and evidence reports remain the correctness boundary.  
2026-05-15 | Guide v1.11: **Claude Code v2.1.142 background-session and plugin reliability pass.** Local `claude --version` returned `2.1.141 (Claude Code)` while npm latest for `@anthropic-ai/claude-code` returned `2.1.142`. Added operator guidance for new `claude agents` dispatch flags, Opus 4.7 Fast-mode default, root-level plugin `SKILL.md` discovery, plugin LSP visibility, `MCP_TOOL_TIMEOUT` remote HTTP/SSE behavior, and background-session / daemon / plugin-cache reliability fixes.  
2026-05-14 | Guide v1.10: **Claude Code v2.1.141 operator-signaling and scoping pass.** Local `claude --version` returned `2.1.141 (Claude Code)` and npm latest for `@anthropic-ai/claude-code` returned `2.1.141`. Added hook guidance for `terminalSequence` as operator signaling rather than enforcement, noted `claude agents --cwd <path>` for directory-scoped Agent View, and documented the architecture impact of `CLAUDE_CODE_PLUGIN_PREFER_HTTPS` plus `ANTHROPIC_WORKSPACE_ID` for plugin installation and workload-identity federation scoping.  
2026-05-13 | Guide v1.9: **Claude Code v2.1.140 reliability pass.** Local `claude --version` returned `2.1.140 (Claude Code)`. Added `subagent_type` to agent-hook guidance and updated the hook governance section for v2.1.140 fixes to `ConfigChange`, `disableAllHooks`, `allowManagedHooksOnly`, permission-dialog env-var display, custom style reset after settings sync, Windows Git Bash native-package fallback, and `/scroll-speed` behavior.  
2026-05-11 | Guide v1.8: **Claude Code v2.1.139 currentness pass + focused agent-security/memory scan.** Verified local `claude --version` as 2.1.139 and added v2.1.139 operational changes: Agent View via `claude agents`, `/goal` completion loops, command-hook `args`, `PostToolUse` `continueOnBlock`, MCP `CLAUDE_PROJECT_DIR`, and OpenTelemetry active-time fix. Added memory-curation warning from “The Memory Curse” arXiv preprint, human merge-authority guidance from the PR-lifecycle arXiv preprint, and agent-log/guardrail security guidance from the Gryph Agents and LiteLLM advisories. Fixed stale Skills vs Hooks vs Subagents token-budget row from 2% to the current 1% / 8,000-character skill-description budget.  
2026-05-09 | Guide v1.7: **Day-3 follow-up on Claude Code v2.1.136 + openai-agents-python v0.17.0.** Added `autoMode.hard_deny` and v2.1.136 hook/plugin fixes subsection to [Hook Architecture](hook-architecture.md) covering the new unconditional-block tier, MCP-disappears-after-`/clear` fix across VS Code/JetBrains/Agent SDK, MCP OAuth refresh-token loss on concurrent refresh, plan-mode write-block fix when `Edit(...)` allow rule matched, plugin `Stop`/`UserPromptSubmit` cache-cleanup race, `skills` entry hiding default `skills/` dir, and `CLAUDE_ENV_FILE` SessionStart-hook env vars going stale after `/resume`/`/clear`. Added OTel Feedback Survey subsection to [Production Patterns](production-patterns.md) covering `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL`. Extended The Sandbox subsection with openai-agents-python v0.17.0 lockdown: `LocalFile.src` / `LocalDir.src` constrained to within `base_dir` unless granted via `Manifest.extra_path_grants` with `SandboxPathGrant`. Added RealtimeAgent default-model note (`gpt-realtime-2`) to Managed vs. Self-Hosted Harnesses. Changelog-only: Claude Code v2.1.137 (Win VSCode activation fix), v2.1.138 (internal fixes); `claude-agent-sdk-python` v0.1.78 (CLI v2.1.136 bundle), v0.1.79 (CLI v2.1.137 bundle), v0.1.80 (CLI v2.1.138 bundle).  
2026-05-08 | Guide v1.6: **Day-2 follow-up on Claude Code v2.1.132/v2.1.133 + SDK v0.1.77.** Added SDK Skill Surface subsection to [Skills System](skills-system.md) covering the `skills` option on `ClaudeAgentOptions` and the deprecation of `"Skill"` in `allowed_tools`. Added Effort and Session Provenance subsection to [Hook Architecture](hook-architecture.md) covering the new `effort.level` JSON field + `$CLAUDE_EFFORT` env var on hook input, and the `CLAUDE_CODE_SESSION_ID` env var on Bash subprocesses. Added Subagent skill discovery fix to the Subagent Configuration Fields table (subagents now discover project, user, and plugin skills via the `Skill` tool, silently dropped before v2.1.133). Added Worktree Base, Sandbox Paths, and Admin Settings subsection to [Production Patterns](production-patterns.md) covering `worktree.baseRef` (breaking-default revert back to `origin/<default>` from local `HEAD`), `sandbox.bwrapPath`, `sandbox.socatPath`, and `parentSettingsBehavior`.  
2026-05-07 | Guide v1.5: **Claude Managed Agents, May 6 SF expansion.** Added Strategy 5 (Managed Memory Curation: Dreaming, Research Preview) to [Memory and Context](memory-and-context.md) with table contrasting filesystem-as-memory vs. Dreaming. Added Managed Multiagent Orchestration (Public Beta) and Outcomes (Public Beta) at the top of [Multi-Agent Orchestration](multi-agent-orchestration.md) with verbatim Anthropic quotes on shared-filesystem specialists and Claude Console tracing, plus a comparison table vs. self-hosted deliberation. Added SDK-side hook event streaming subsection covering `claude-agent-sdk-python` v0.1.74’s `include_hook_events` and `HookEventMessage`. Changelog-only: Claude Code v2.1.124-v2.1.131 (`claude project purge`, `--dangerously-skip-permissions` for project dirs, `skill_activated` `invocation_trigger`, PostToolUse format-on-save fix, PreToolUse JSON+exit-2 blocking fix, `skillOverrides` settings); `claude-agent-sdk-python` v0.1.72 (CLI 2.1.126), v0.1.73 (`session_store_flush`), v0.1.75 (CLI 2.1.131), v0.1.76 (`api_error_status`); openai-agents-python v0.15.0-v0.16.1 with v0.16.0 (May 7) defaulting to gpt-5.4-mini, removing the implicit `max_turns` ceiling, and adding SDK-side tool execution concurrency.  
2026-05-07 | Guide v1.4: Refreshed Claude Code hook and skill mechanics against current official docs and local runtime evidence (`claude --version` 2.1.132, `codex --version` returned `codex-cli 0.128.0`). Updated the hook surface from 22/26+ to 29 documented events, fixed skill-description budget from 2%/16,000 to 1%/8,000, changed hook-type count from four to five with `mcp_tool`, removed the unsupported fixed “10 parallel subagents” claim, and added a public-safe Codex parity section covering AGENTS.md, skills, hooks, plugins, and explicit subagent workflows.  
2026-04-29 | Guide v1.3: Expanded the **OpenAI Agents SDK** coverage in the Managed vs. Self-Hosted Harnesses section with the named SDK surface from `openai-agents` Python v0.14.0 (April 15) — `SandboxAgent`, `Manifest`, `SandboxRunConfig`, sandbox memory with progressive disclosure, workspace mounts (S3/R2/GCS/Azure), portable snapshots, and the local/Docker/hosted client backends (Blaxel, Cloudflare, Daytona, E2B, Modal, Runloop, Vercel). Replaced the secondary Help Net Security citation with the primary v0.14.0 release-notes citation. Added a short note on **`claude-agent-sdk-python`** v0.1.69-v0.1.71 (April 28-29) as the third self-hosted option (embed Claude Code runtime as a Python library): bundled Claude CLI bumped to v2.1.123, raised `mcp` dependency floor to `>=1.19.0` (older versions silently dropped `CallToolResult` from in-process MCP tools), Trio nursery cancellation fix, and `SandboxNetworkConfig` allowlist-field parity with TS SDK. v0.14.7-v0.14.8 SDK refinements documented in ``.  
2026-04-25 | Guide v1.2: **Google Cloud Next 2026 (April 22-24)** — Vertex AI rebranded to **Gemini Enterprise Agent Platform** ; Agentspace absorbed into unified Gemini Enterprise; **Workspace Studio** (no-code agent builder); 200+ models in Model Garden including Anthropic Claude; partner agents from Box, Workday, Salesforce, ServiceNow; **ADK v1.0 stable** across four languages; **Project Mariner** (web-browsing agent); managed MCP servers with **Apigee** as API-to-agent bridge; **A2A protocol v1.0** in production at 150 organizations. **Microsoft Agent Framework 1.0 (April 2026)** : stable APIs, LTS commitment, full MCP support, .NET + Python. The browser-based DevUI that visualizes agent execution and tool calls in real time ships as a **preview** alongside the 1.0 stable surface. **Salesforce Headless 360 (April 15, TDX)** : every Salesforce capability (CRM, service, marketing, ecommerce) exposed as API/MCP tool/CLI command so agents like Claude Code, Cursor, and Codex can build on the platform without a browser. (TDX 2026 ran April 15-16; the Headless 360 announcement is dated April 15.) **MetaComp StableX KYA (April 21)** : Know Your Agent governance framework for regulated financial services (payments, compliance, wealth) — first of its kind from a licensed financial institution; available across Claude, Claude Code, OpenClaw, and other compatible AI platforms. **Claude Managed Agents pricing** : $0.08 per session-hour while a session is running, with no runtime charge while idle — on top of normal Claude model token rates. (Per Anthropic’s Claude pricing page; the public-beta launch was April 8, 2026.) **Memory for Managed Agents** entered public beta on April 23, 2026 under the `managed-agents-2026-04-01` beta header. All Managed Agents endpoints now require this beta header.  
2026-04-16 | Guide v1.1: Added Managed vs. Self-Hosted Harnesses section covering Claude Managed Agents (April 8 beta) and OpenAI Agents SDK harness/compute separation (April 16). Added Scion cross-tool multi-agent hypervisor (April 7, Google). Documented M3MAD-Bench debate plateau finding. Added The Five Principles of Trustworthy Agents (Anthropic, April 9) + MCP/AGENTS.md Linux Foundation governance. Permiso SandyClaw skill-sandbox reference. New Opus 4.7 Long-Horizon Patterns: tool-failure resilience, `xhigh` effort tier, token-budget ceiling (`task_budget` beta), implicit-need awareness reducing CLAUDE.md scaffolding.  
2026-03-24 | Initial publication  
  
* * *
