# Agent Architecture: Building AI-Powered Development Harnesses for Antigravity CLI

> The complete system for building production AI agent harnesses. Skills, hooks, memory, subagents, multi-agent orchestration, and the patterns that make AI coding agents reliable infrastructure.

> **TL;DR:** Antigravity CLI (`agy`) is not a chat box with file access. It is a programmable runtime backed by the same harness as Antigravity 2.0 — supporting JSON lifecycle hooks, dynamic subagents, agent skills, MCP servers, and plugins. Stack hooks into dispatchers, skills into reusable expertise, and subagents into parallel workflows, and you get a terminal-native development harness that enforces constraints, delegates work, and scales with automation. Unlike Claude Code's exit-code hook contract, Antigravity hooks use a **JSON in / JSON out** decision protocol. Unlike Gemini CLI's static agent config files, Antigravity spawns subagents **dynamically at runtime**. This guide covers every layer of that stack: from a single hook to a multi-agent verification pipeline. Zero frameworks required. All bash and JSON.

Andrej Karpathy coined a term for what grows around an LLM agent: _claws_. The hooks, scripts, and orchestration that let the agent grip the world outside its context window. Most developers treat AI coding agents as interactive assistants. They type a prompt, watch it edit a file, and move on. That framing caps productivity at whatever you can personally oversee.

The infrastructure mental model is different: an AI coding agent is a programmable runtime with an LLM kernel. Every action the model takes passes through hooks you control. You define policies, not prompts. The model operates within your infrastructure the same way a web server operates within nginx rules. You do not sit at nginx and type requests. You configure it, deploy it, and monitor it.

The distinction matters because infrastructure compounds. A hook that blocks credentials in shell commands protects every session, every agent, every autonomous run. A skill that encodes your evaluation rubric applies consistently whether you invoke it or an agent does. An agent that reviews code for security runs the same checks whether you are watching or not.

* * *

### Key Takeaways

*   **JSON hooks guarantee execution; prompts do not.** Use hooks for linting, formatting, security checks, and anything that must run every time regardless of model behavior. Hooks output `{"decision":"deny", "reason":"..."}` to block actions.
*   **Skills encode domain expertise that auto-activates.** The `description` field determines everything. `agy` uses LLM reasoning (not keyword matching) to decide when to apply a skill.
*   **Subagents prevent context bloat.** Isolated context windows for exploration and analysis keep the main session lean. Spawn parallel subagents dynamically on demand — no static agent files required.
*   **Memory lives in the filesystem.** Files persist across context boundaries. `GEMINI.md`, `AGENTS.md`, and skill files form a structured external memory system.
*   **Multi-agent deliberation catches blind spots.** Single agents cannot challenge their own assumptions. Two independent agents with different evaluation priorities catch structural failures that quality gates cannot address.
*   **The harness pattern is the system.** `GEMINI.md`, hooks, skills, and memory are not independent features. They compose into a deterministic layer between you and the model that scales with automation.

* * *

### How to Use This Guide

Experience | Start Here | Then Explore  
---|---|---  
**Migrating from Gemini CLI** | [The Harness Pattern](harness-pattern.md) | [Hook Architecture](hook-architecture.md), [Skills System](skills-system.md)  
**Building autonomous workflows** | [Subagent Patterns](subagent-patterns.md) | [Multi-Agent Orchestration](multi-agent-orchestration.md), [Production Patterns](production-patterns.md)  
**Evaluating agent architecture** | [Why Agent Architecture Matters](why-agent-architecture.md) | [Decision Framework](decision-framework.md), [Security Considerations](security-considerations.md)  
**Setting up a team harness** | [GEMINI.md Design](gemini-md-design.md) | [Hook Architecture](hook-architecture.md), Quick Reference Card  
  
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
- [GEMINI.md Design](gemini-md-design.md)
- [Production Patterns](production-patterns.md)
- [Security Considerations](security-considerations.md)
- [Decision Framework](decision-framework.md)
- [References](references.md)

---

## Five-Minute Golden Path

Before the deep dive, here is the shortest path from zero to a working harness. One hook, one skill, one subagent, one outcome.

### Step 1: Create a safety hook (2 minutes)

Create `.agents/hooks/block-secrets.sh`:

```bash
#!/usr/bin/env bash
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)
if printf '%s' "$cmd" | grep -qEi '(AKIA|sk-|ghp_|password=)'; then
  printf '{"decision":"deny","reason":"Potential secret in command"}\n'
  exit 0
fi
printf '{"decision":"allow"}\n'
exit 0
``` 

Wire it in `.agents/hooks.json`:

```json
{
  "safety-gate": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [{ "type": "command", "command": ".agents/hooks/block-secrets.sh" }]
      }
    ]
  }
}
``` 

**Result:** Every shell command `agy` runs is now screened for leaked credentials. The model cannot skip this check.

### Step 2: Create a code review skill (1 minute)

Create `.agents/skills/reviewer/SKILL.md` with frontmatter:

```yaml
---
name: reviewer
description: Review code for security issues, bugs, and quality problems. Use when examining changes, reviewing PRs, or auditing code. Triggers on: review, check, audit.
allowed-tools: read_file, grep_search, find_by_name
---

# Code Review Expertise
- SQL injection, XSS, hardcoded secrets, missing input validation
- Authentication checks on protected endpoints
- Functions over 50 lines (split them)
```

**Result:** `agy` auto-activates this expertise whenever you mention review, check, or audit.

### Step 3: Spawn a subagent (30 seconds)

In any `agy` session, ask the agent to review the last 3 commits for security issues using a separate agent. `agy` dynamically spawns a subagent, applies your reviewer skill, and returns a summary. Your main context stays clean.

### What you now have

A three-layer harness: a deterministic safety gate (hook), domain expertise that auto-activates (skill), and isolated analysis that protects your context (subagent). Every section below expands one of these three layers.

* * *

## FAQ

### How many hooks is too many?

Performance, not count, is the constraint. Each hook runs synchronously, so total hook execution time adds to every matched tool call. Hooks run without noticeable latency when each hook completes in under 200ms. The threshold to watch: if a PostToolUse hook adds more than 500ms to every file edit, the session feels sluggish. Profile your hooks before deploying them.

### Can hooks block the agent from running a command?

Yes. PreToolUse hooks block any tool action by outputting `{"decision":"deny","reason":"..."}`. The agent runtime cancels the pending action and feeds the reason back to the model. The model sees the rejection reason and suggests a safer alternative.

### Where should I put hook configuration files?

Hook configurations go in `.agents/hooks.json` for project-level hooks (committed to your repository, shared with your team) or `~/.gemini/antigravity-cli/hooks.json` for user-level hooks (personal, applied to every project). Project-level hooks take precedence when both exist. Use absolute paths for script files to avoid working-directory issues.

### Does every decision need deliberation?

No. The confidence module scores decisions across four dimensions (ambiguity, complexity, stakes, context dependency). Only decisions scoring below 0.70 overall confidence trigger deliberation, roughly 10% of total decisions. Documentation fixes, variable renames, and routine edits skip deliberation entirely. Security architecture, database schema changes, and irreversible deployments trigger it consistently.

### What is the latency impact of deliberation?

A 3-agent deliberation adds 30-60 seconds of wall-clock time (agents run sequentially). A 10-agent deliberation adds 2-4 minutes. The consensus and pride check hooks each run in under 200ms. The primary bottleneck is LLM inference time per agent, not orchestration overhead.

### How long should a GEMINI.md file be?

Keep each section under 50 lines and the total file under 150 lines. Long files get truncated by context windows, so front-load the most critical instructions: commands and closure definitions before style preferences.

### Can this work with other tools?

The architectural principles (hooks as deterministic gates, skills as domain expertise, subagents as isolated contexts, filesystem as memory) apply conceptually to any agentic system. AGENTS.md carries the same patterns to Codex, Cursor, Copilot, Amp, and Windsurf. The harness pattern is tool-agnostic even if the implementation details are tool-specific.

* * *

## Quick Reference Card

### Hook Configuration (.agents/hooks.json)

```json
{
  "safety-gate": {
    "enabled": true,
    "PreToolUse": [{"matcher": "run_command", "hooks": [{"type": "command", "command": "script.sh"}]}],
    "PostToolUse": [{"matcher": "write_file", "hooks": [{"type": "command", "command": "format.sh"}]}]
  }
}
``` 

### Skill Frontmatter

```yaml
---
name: my-skill
description: What it does and when to use it. Include trigger phrases.
allowed-tools: read_file, grep_search, find_by_name
---
``` 

### Dynamic Subagent

Subagents in Antigravity CLI are spawned dynamically at runtime via prompts. No static agent files are required.

### Hook Decision Object

Key | Value | Meaning  
---|---|---  
`decision` | `"allow"` | Allow the operation  
`decision` | `"deny"` | Block the operation and report the `reason`  
  
### Key Commands

Command | Purpose  
---|---  
`/compact` | Compress context, preserve decisions  
`/skills` | View active skills and configuration  
`/agents` | Manage dynamic subagents  
`/goal <condition>` | Keep the agent working toward a completion condition  
  
### File Locations

Path | Purpose  
---|---  
`~/.gemini/antigravity-cli/GEMINI.md` | Personal global instructions  
`GEMINI.md` / `AGENTS.md` | Project instructions (git-shared)  
`.agents/hooks.json` | Project hooks config  
`~/.gemini/antigravity-cli/hooks.json` | User hooks config  
`~/.gemini/antigravity-cli/skills/<name>/SKILL.md` | Personal skills  
`.agents/skills/<name>/SKILL.md` | Project skills (git-shared)  
  
* * *
