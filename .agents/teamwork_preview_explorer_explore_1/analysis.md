# Analysis: Translating Claude Harness Architecture to Antigravity CLI (agy)

This document provides a comprehensive analysis of the 13 modular markdown documentation files under `docs/claude-agent-architect/` and maps their Claude-specific concepts and files to their Antigravity CLI (`agy`) counterparts.

---

## 1. Directory Walk & Core File Assessments

Below is a detailed analysis of all 13 modular documentation files, detailing the purpose of each, occurrences of Claude-specific terms/concepts, and their corresponding translations to the Antigravity architecture.

### 1. `claude-md-design.md` (to be renamed to `gemini-md-design.md`)
*   **Purpose**: Outlines the guidelines for creating operational policy files (`CLAUDE.md` and rules), detailing precedence hierarchies, structure conventions (command-first instructions, definition of done, escalation rules), and cross-tool compatibility.
*   **Claude-specific Terms**:
    *   `CLAUDE.md`, `./CLAUDE.md`, `./.claude/CLAUDE.md`, `~/.claude/CLAUDE.md`, `./CLAUDE.local.md` (precedence scopes)
    *   `.claude/rules/` and `~/.claude/rules/`
    *   `claude` command line tool, specifically `claude --print`
    *   Exit codes contract (e.g. exit code 2 blocks, exit code 1 warns)
    *   `.claude/skills/<name>/SKILL.md` and `.claude/settings.json`
*   **Antigravity Mappings**:
    *   `CLAUDE.md` -> `GEMINI.md` + `AGENTS.md` (split: `GEMINI.md` holds Antigravity overrides and metadata; `AGENTS.md` remains the cross-tool shared standard).
    *   `.claude/` -> `.agents/`
    *   `~/.claude/` -> `~/.gemini/antigravity-cli/`
    *   `claude` -> `agy`
    *   `claude --print` -> `agy --print` (or direct evaluation prompt in `agy`)
    *   Exit code 2 blocking contract -> JSON hooks contract: output `{"decision":"deny", "reason":"..."}` to stdout with exit code 0.
    *   `.claude/skills/<name>/SKILL.md` -> `.agents/skills/<name>/SKILL.md`
    *   `.claude/settings.json` -> `.agents/hooks.json`

### 2. `decision-framework.md`
*   **Purpose**: Provides a matrix mapping software engineering problems (like auto-formatting, blocking commands, codebase exploration, architectural decisions) to the correct agent mechanism (hooks, skills, subagents, handoffs).
*   **Claude-specific Terms**:
    *   PreToolUse hook, PostToolUse hook, Stop hook
    *   Exit code 2
    *   Explore subagent
    *   MEMORY.md
    *   Project CLAUDE.md + `.claude/rules/`
    *   Skills vs Hooks vs Subagents dimensions (token budgets, etc.)
*   **Antigravity Mappings**:
    *   `PreToolUse`/`PostToolUse`/`Stop` hook types -> Retained in `.agents/hooks.json` but execute via JSON stdout contract.
    *   Exit code 2 -> `{"decision":"deny"}` on stdout.
    *   Explore subagent -> Parallel subagent with a read-only mandate.
    *   MEMORY.md / `.claude/rules/` -> `GEMINI.md` + `.agents/skills/`.
    *   `CLAUDE.md` -> `GEMINI.md`.

### 3. `harness-pattern.md`
*   **Purpose**: Explains the Harness Pattern (Instruction, Extension, and Orchestration layers) wrapping AI agents in deterministic infrastructure, comparing self-hosted harnesses with managed ones (Claude Managed Agents, OpenAI Agents SDK).
*   **Claude-specific Terms**:
    *   `CLAUDE.md` + `.claude/rules/` + `MEMORY.md`
    *   Claude Managed Agents (Public Beta, April 2026)
    *   `claude-agent-sdk-python` library
    *   `~/.claude/` and `.claude/` directory listings
*   **Antigravity Mappings**:
    *   Harness on disk: Map `~/.claude/` to `~/.gemini/antigravity-cli/` and `.claude/` to `.agents/`.
    *   `CLAUDE.md` -> `GEMINI.md` + `AGENTS.md`.
    *   `settings.json` -> `.agents/hooks.json`.
    *   Claude Managed Agents -> Antigravity CLI (`agy`) runs local orchestrator loops natively; no managed premium token-hour rate is required for baseline harnesses.

### 4. `hook-architecture.md`
*   **Purpose**: Deep-dive into event-driven hooks executed outside the model, detailing the 29 lifecycle events, JSON inputs/outputs, sequential dispatching, async executions, and administrative/OTel configurations.
*   **Claude-specific Terms**:
    *   29 lifecycle events (e.g. `PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`, `Stop`, `SubagentStart`, `TeammateIdle`, `PreCompact`)
    *   Matcher filters: `Bash`, `Write`, `Edit`, `Read`, `Glob`, `Grep`, `Agent`
    *   JSON Input payload keys: `.tool_name` (e.g. `Bash`), `.tool_input.command`, `.session_id`, `.agent_id`, `.agent_type`
    *   JSON Output payload: `hookSpecificOutput` block (with `permissionDecision`, `permissionDecisionReason`, `updatedInput`, `additionalContext`)
    *   `claude-agent-sdk-python` and `HookEventMessage` streaming
    *   `effort.level` / `$CLAUDE_EFFORT` / `CLAUDE_CODE_SESSION_ID`
    *   `settings.autoMode.hard_deny` non-negotiable governance setting
    *   `CLAUDE_PROJECT_DIR` and `--safe-mode` / `CLAUDE_CODE_SAFE_MODE`
    *   `claude agents` background view and wait events
*   **Antigravity Mappings**:
    *   Lifecycle events -> Map to Antigravity CLI lifecycle events: `PreToolUse`, `PostToolUse`, `SessionStart`, `SessionEnd`.
    *   Matchers -> `Bash` -> `run_command`, `Write`/`Edit` -> `write_file`/`edit_file`, `Read` -> `read_file`.
    *   JSON Input structure -> Map `.tool_name` to `.toolCall.name`, `.tool_input.command` to `.toolCall.args.CommandLine`, and `.session_id` to `.session_id`.
    *   JSON Output structure -> Instead of nesting inside `hookSpecificOutput`, output `{"decision":"deny", "reason":"..."}` or `{"decision":"allow"}` directly.
    *   PowerShell/Safe Mode -> Use clean configs (`agy --safe-mode` equivalent commands).
    *   `effort.level` -> Handled through hook input parameter mapping.
    *   `CLAUDE_CODE_SESSION_ID` -> `session_id` in hooks payload.
    *   `settings.autoMode.hard_deny` -> Custom safety-gate script block rules registered in `.agents/hooks.json`.

### 5. `index.md`
*   **Purpose**: Landing page containing guide takeaways, lookup matrices, quick-start golden paths, FAQ, quick reference cards, and guide changelogs.
*   **Claude-specific Terms**:
    *   Claude Code, `.claude/hooks/block-secrets.sh`, `.claude/settings.json`, PreToolUse, matcher: "Bash"
    *   `.claude/skills/reviewer/SKILL.md`
    *   MEMORY.md, rules directories, `~/.claude/CLAUDE.md`, `.claude/CLAUDE.md`
    *   Slash commands: `/compact`, `/context`, `/agents`, `/goal`, `/memory`
    *   CLI commands: `claude agents`, `claude -c`, `claude --print`
    *   Exit codes contract
*   **Antigravity Mappings**:
    *   Folder mappings: `.claude/` -> `.agents/`, `~/.claude/` -> `~/.gemini/antigravity-cli/`.
    *   Golden Path: Update Step 1 to write to `.agents/hooks/block-secrets.sh` returning `{"decision":"allow"}` or `{"decision":"deny"}` via bash JSON output. Wire in `.agents/hooks.json`.
    *   Step 2: Skill path `.agents/skills/reviewer/SKILL.md`.
    *   Step 3: Spawn subagent dynamically via prompt (no static agent files).
    *   Slash commands -> Map to `agy` slash commands: `/compact`, `/agents`, `/goal`, `/skills` (instead of `/context` and `/memory`).
    *   Exit codes -> JSON hooks decision contract.

### 6. `memory-and-context.md`
*   **Purpose**: Describes context limits, conversational degradation (multi-turn collapse), filesystem memory storage, proactive compaction `/compact` commands, mid-session directory switching `/cd`, session handoffs, and background curation (Dreaming).
*   **Claude-specific Terms**:
    *   `CLAUDE.md`, `MEMORY.md`, `~/.claude/`
    *   Auto Memory (writes to `~/.claude/projects/{project-path}/memory/MEMORY.md`)
    *   Compaction commands: `/compact`, custom CLAUDE.md compaction instructions
    *   `/cd` command (Claude Code v2.1.169 directory switching)
    *   `claude -c` command to continue sessions
    *   Dreaming / Managed Memory curation
*   **Antigravity Mappings**:
    *   Auto Memory -> Deleted. Antigravity does not automatically append to global `MEMORY.md` directories; state is managed through explicitly updated `GEMINI.md` files and version-controlled handoff documents.
    *   `CLAUDE.md` -> `GEMINI.md` + `AGENTS.md`.
    *   `/compact` -> `/compact` (exists in `agy`).
    *   `claude -c` -> No direct equivalent; `agy` resumes context through filesystem read-ins.
    *   Dreaming -> Suppressed. Keep handoffs entirely filesystem-centric.

### 7. `multi-agent-orchestration.md`
*   **Purpose**: Frameworks for mitigating single-agent tunnel vision via multi-agent debate, confidence triggers, state machines (Idle -> Research -> Deliberation -> Ranking -> PRD -> Complete), consensus gates, and Conformity Detection.
*   **Claude-specific Terms**:
    *   Scion multi-agent hypervisor
    *   Gemini CLI (legacy)
    *   Claude Managed Agents Multiagent Orchestration (Public Beta, May 2026) and Outcomes (rubric grading)
    *   PostToolUse hook / Stop hook gates
    *   Opus model pricing
*   **Antigravity Mappings**:
    *   Gemini CLI -> Antigravity CLI (`agy`).
    *   Consensus validation -> Replaced by parallel dynamic subagents spawned on demand with output verified by hooks returning stdout JSON.
    *   PostToolUse / Stop hooks -> Map to Antigravity JSON hooks contract.
    *   Opus pricing -> Gemini quota limits.

### 8. `production-patterns.md`
*   **Purpose**: Production operational blueprints, covering Opus 4.7 capabilities (effort levels, task budgets), git worktree refs (`worktree.baseRef`), Bubblewrap sandboxing binaries (`sandbox.bwrapPath`), OTel telemetry, quality loops, evidence gates, and blast radius classification.
*   **Claude-specific Terms**:
    *   Opus 4.7, `xhigh` effort tier, `output_config.task_budget`
    *   `worktree.baseRef` setting revert
    *   `sandbox.bwrapPath`, `sandbox.socatPath`, `parentSettingsBehavior`
    *   `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL`
    *   `((VAR++))` bash exit-code trap in hook scripts
    *   PreToolUse / PostToolUse / Stop hooks
    *   Remote Control (browser interface)
*   **Antigravity Mappings**:
    *   Opus 4.7 / `xhigh` -> Gemini 3.5 Flash / Gemini 3.1 Pro (specified via `--model`).
    *   `task_budget` -> Google Cloud API quotas.
    *   OTel and admin settings -> Mapped into local `agy` configuration profiles.
    *   PowerShell/sandbox settings -> Managed by Antigravity OS sandboxing.
    *   `((VAR++))` bash trap -> Remains highly relevant for hooks scripted in bash.

### 9. `references.md`
*   **Purpose**: Citation index listing GitHub discussions, release changelogs, research papers (arXiv), blogs, and documentation links.
*   **Claude-specific Terms**:
    *   URLs referencing `code.claude.com`, `@anthropic-ai/claude-code`, `claude-agent-sdk-python`, etc.
*   **Antigravity Mappings**:
    *   Convert Claude legacy references to Antigravity CLI deep dives (e.g. `agentpedia.codes/blog/antigravity-cli-deep-dive`), Google Developer guides, and Google Cloud release notes.

### 10. `security-considerations.md`
*   **Purpose**: Evaluates sandbox limitations (Bubblewrap, seatbelt, PowerShell vulnerabilities), permission boundaries, prompt injection defense, logs/guardrails security, and division of responsibility.
*   **Claude-specific Terms**:
    *   Five Principles of Trustworthy Agents (Anthropic, April 2026)
    *   MCP Linux Foundation donation
    *   SandyClaw skill sandbox
    *   Claude Code sandbox (/sandbox)
    *   PowerShell permission bypass fixes (v2.1.149)
    *   `openai-agents-python` manifest path grants
    *   PreToolUse/PostToolUse hooks, exit 2 blocking
    *   `allowedEnvVars` HTTP hook environment scrubbing
    *   `SubagentStop` recursive hook enforcement
    *   `claude --print`
*   **Antigravity Mappings**:
    *   Anthropic -> Google.
    *   Claude Code sandbox -> Native Antigravity sandboxing.
    *   exit 2 blocking -> stdout `{"decision":"deny"}`.
    *   `allowedEnvVars` -> Configured in `.agents/hooks.json`.
    *   `SubagentStop` -> Dynamic subagents inherit parent workspace safety limits.
    *   `claude --print` -> `agy --print` (or direct evaluation prompt in `agy`).

### 11. `skills-system.md`
*   **Purpose**: Covers reusable agent expertise in `SKILL.md` structures, Yaml frontmatter attributes, description-based auto-activation, git-sharing, and plugin integration.
*   **Claude-specific Terms**:
    *   `~/.claude/skills/`, `.claude/skills/`
    *   allowed-tools: `Read, Grep, Glob`
    *   Frontmatter: name, description, allowed-tools, disable-model-invocation, user-invocable, model, context, hooks
    *   `/context` command and `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var
    *   `PreToolUse` hooks matching `Bash`
    *   `available_skills` system prompt segment
    *   `claude plugin init`
    *   `disableBundledSkills` / `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS`
*   **Antigravity Mappings**:
    *   Path mapping: `.claude/skills/` -> `.agents/skills/`, `~/.claude/skills/` -> `~/.gemini/antigravity-cli/skills/`.
    *   allowed-tools -> Map tool names to Antigravity equivalents (`read_file`, `write_file`, `run_command`).
    *   Frontmatter properties -> Map directly to the skills loader system.
    *   `/context` -> `/skills` lists active skills.
    *   `PreToolUse` on `Bash` -> `PreToolUse` on `run_command`.
    *   `claude plugin init` -> `agy plugin import gemini` (or plugin structure).

### 12. `subagent-patterns.md`
*   **Purpose**: Focuses on subagent execution patterns, worktree isolation, recursion guards, agent teams, and first-party workflows.
*   **Claude-specific Terms**:
    *   Subagent types: Explore, General-purpose, Plan
    *   Scopes: `.claude/agents/`, `~/.claude/agents/`
    *   Frontmatter fields: name, description, tools, disallowedTools, model, permissionMode, maxTurns, memory, skills, hooks, background, isolation
    *   State files: `recursion-limits.json` and `recursion-depth.json` under `~/.claude/`
    *   Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) and Mailbox/Task List
    *   `claude agents` / Agent View / `/goal`
    *   Workflow tool (`CLAUDE_CODE_WORKFLOWS`)
*   **Antigravity Mappings**:
    *   **CRITICAL CHANGE**: Antigravity has **no static agents directory**. Delete static agent definitions in `.claude/agents/` and `~/.claude/agents/`. Spawning is entirely **dynamic** and prompt-driven at runtime. `agy` creates `agent.json` artifacts dynamically.
    *   Agent Teams & Workflows -> Replaced by dynamic parallel subagents spawned on demand via orchestrator prompts.
    *   Agent View -> `/agents` command in-session.
    *   Recursion guard state -> Managed via `.agents/state/` or dynamic hooks.

### 13. `why-agent-architecture.md`
*   **Purpose**: Case for agentic harnesses, outlining context window collapse across turn boundaries, probabilistic prompts vs. deterministic hooks, and single-perspective limitations.
*   **Claude-specific Terms**:
    *   Claude Code, Prettier formatter, edit/write commands
*   **Antigravity Mappings**:
    *   Claude -> Gemini.
    *   edit/write commands -> `edit_file` / `write_file`.
    *   Prettier -> auto-lint script hooks.

---

## 2. Document-Specific Re-Scoping: Renaming & References

Special attention must be paid to `claude-md-design.md`, which is mapped to `gemini-md-design.md`.

*   **File Renaming**:
    *   Source File: `docs/claude-agent-architect/claude-md-design.md`
    *   Target File: `docs/antigravity-agent-architect/gemini-md-design.md`
*   **Link & Content Updates**:
    *   Inside `index.md`, the links to `claude-md-design.md` must be updated to `gemini-md-design.md`.
    *   The link text and inline references should be changed from `CLAUDE.md Design` or `claude-md-design.md` to `GEMINI.md Design` and `gemini-md-design.md`.
    *   The hierarchy details inside `claude-md-design.md` mapping Claude-specific rules to Codex must be updated to show Antigravity (`agy`) mappings.

---

## 3. Internal Link Audit

A comprehensive search of all 13 modular markdown documentation files under `docs/claude-agent-architect/` reveals that **only two files** contain relative, internal links that require updates:

### File 1: `index.md`
This file contains the primary table of contents and refers to the other 12 files relatively in the same directory.
*   **Links to Update**:
    *   `[The Harness Pattern](harness-pattern.md)` -> No change required if the relative folder is maintained, but must point to `harness-pattern.md` inside `docs/antigravity-agent-architect/`.
    *   `[Skills System](skills-system.md)` -> Remains `skills-system.md`.
    *   `[Hook Architecture](hook-architecture.md)` -> Remains `hook-architecture.md`.
    *   `[Subagent Patterns](subagent-patterns.md)` -> Remains `subagent-patterns.md`.
    *   `[Multi-Agent Orchestration](multi-agent-orchestration.md)` -> Remains `multi-agent-orchestration.md`.
    *   `[Production Patterns](production-patterns.md)` -> Remains `production-patterns.md`.
    *   `[Why Agent Architecture Matters](why-agent-architecture.md)` -> Remains `why-agent-architecture.md`.
    *   `[Decision Framework](decision-framework.md)` -> Remains `decision-framework.md`.
    *   `[Security Considerations](security-considerations.md)` -> Remains `security-considerations.md`.
    *   `[CLAUDE.md Design](claude-md-design.md)` -> **MUST BE UPDATED TO** `[GEMINI.md Design](gemini-md-design.md)`.
    *   `[Memory and Context](memory-and-context.md)` -> Remains `memory-and-context.md`.
    *   `[References](references.md)` -> Remains `references.md`.

### File 2: `hook-architecture.md`
This file references a cheatsheet relative to the website's root path.
*   **Link to Update**:
    *   `[cheat sheet](</guides/claude-code-cheatsheet>)` -> Should be updated to target the Antigravity cheatsheet URL or file path: `[cheat sheet](</guides/antigravity-cli-cheatsheet>)`.

---

## 4. Concepts Translation Summary

For a fast translation checklist, reference this summary when implementing the documentation rewrite:

| Claude Concept | Antigravity Equivalent | Notes |
|---|---|---|
| `.claude/` | `.agents/` | Root directory for project-level harness files. |
| `~/.claude/` | `~/.gemini/antigravity-cli/` | User-level global directory. |
| `CLAUDE.md` | `GEMINI.md` + `AGENTS.md` | `GEMINI.md` holds Antigravity overrides, while `AGENTS.md` remains the cross-tool specification. |
| `claude` (CLI binary) | `agy` | CLI executable name. |
| `Bash` (Tool Name) | `run_command` | The tool matching system shell commands. |
| `.tool_input.command` | `.toolCall.args.CommandLine` | Stdin JSON path to extract the executed command string. |
| Exit code `2` (Blocking Hook) | `{"decision":"deny", "reason":"..."}` | Output structure to stdout. Exit codes remain `0`. |
| Static `.claude/agents/*.md` | **DYNAMIC** | Delete the static `agents/` folder. Spawn subagents dynamically via prompts at runtime. |
| `settings.json` hook block | `.agents/hooks.json` | JSON configuration registry for PreToolUse and PostToolUse hooks. |
| `mcpServers` settings | `.agents/mcp_config.json` | Separate file for workspace MCP servers configuration. |
| `/compact` | `/compact` | Summarizes session conversation history. |
| `/context` | `/skills` | Lists active skills in context. |
| `/agents` | `/agents` | Displays active subagents. |
| `claude agents` (Agent View) | `/agents` | In-session subagent status dashboard. |
