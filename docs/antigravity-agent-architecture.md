# Agent Architecture: Building AI-Powered Development Harnesses for Antigravity CLI

> **TL;DR:** Antigravity CLI (`agy`) is not Gemini CLI with a new name. It is a programmable agent runtime backed by the same harness as Antigravity 2.0 — supporting JSON lifecycle hooks, dynamic subagents, agent skills, MCP servers, and plugins. Stack hooks into dispatchers, skills into reusable expertise, and subagents into parallel workflows, and you get a terminal-native development harness that enforces constraints, delegates work, and scales with automation. Unlike Claude Code's exit-code hook contract, Antigravity hooks use a **JSON in / JSON out** decision protocol. Unlike Gemini CLI's static agent config files, Antigravity spawns subagents **dynamically at runtime**. This guide covers every layer of that stack: from a single hook to a multi-agent verification pipeline. Zero frameworks required.

---

## Key Takeaways

- **JSON hooks guarantee execution; prompts do not.** Use `PreToolUse` hooks for safety gates. Return `{"decision":"deny"}` to block, `{"decision":"allow"}` to pass. No exit codes.
- **Skills encode domain expertise that auto-activates.** The `description` field in `SKILL.md` determines when the agent applies the skill. Write it like the trigger phrase a human would use.
- **Subagents are dynamic, not static.** Drop the static `agents/` directory. Prompt the orchestrator to spawn subagents on demand. It creates `agent.json` files at runtime.
- **Memory lives in the filesystem.** `GEMINI.md`, `AGENTS.md`, and skill files persist across context windows. The `.agents/` directory is your harness on disk.
- **The shared harness compounds.** Every improvement Google ships to the Antigravity 2.0 harness reaches your `agy` workflow automatically — no backport wait.
- **Multi-agent deliberation catches blind spots.** Parallel subagents with independent contexts catch structural failures single agents miss.

---

## How to Use This Guide

| Experience | Start Here | Then Explore |
|---|---|---|
| **Migrating from Gemini CLI** | [The Harness Pattern](#the-harness-pattern) | [Hook Architecture](#hook-architecture), [Skills System](#skills-system) |
| **Building autonomous workflows** | [Subagent Patterns](#subagent-patterns) | [Multi-Agent Orchestration](#multi-agent-orchestration) |
| **Setting up a project harness** | [GEMINI.md Design](#geminimd-design) | [Hook Architecture](#hook-architecture), [Quick Reference](#quick-reference-card) |
| **Coming from Claude Code** | [Key Differences vs Claude Code](#key-differences-vs-claude-code) | All sections |

---

## Five-Minute Golden Path

One hook, one skill, one subagent, one outcome.

### Step 1: Create a safety hook (2 minutes)

Create `.agents/hooks/block-secrets.sh`:

```bash
#!/usr/bin/env bash
input=$(cat)

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)
fi
[ -z "$cmd" ] && cmd=$(printf '%s' "$input" | \
  sed -n 's/.*"CommandLine"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

haystack="$cmd $input"

if printf '%s' "$haystack" | grep -qEi '(AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{32}|ghp_[a-zA-Z0-9]{36}|password=)'; then
  printf '{"decision":"deny","reason":"Potential secret detected in command."}\n'
  exit 0
fi

printf '{"decision":"allow"}\n'
```

Wire it in `.agents/hooks.json`:

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
            "command": "./hooks/block-secrets.sh"
          }
        ]
      }
    ]
  }
}
```

**Result:** Every shell command `agy` runs is screened for leaked credentials before execution.

### Step 2: Create a code review skill (1 minute)

Create `.agents/skills/reviewer/SKILL.md`:

```markdown
---
name: reviewer
description: Review code for security vulnerabilities, performance issues, and
  correctness. Use when examining code changes, reviewing PRs, or auditing code
  quality. Triggers on: review, audit, check, inspect.
---

# Code Review Expertise

## Security Checks
- SQL injection, XSS, hardcoded secrets, missing input validation
- Auth checks on every protected endpoint

## Quality Checks
- Functions over 50 lines (split them)
- Missing error handling
- TypeScript `any` types (flag them)
```

**Result:** `agy` applies this expertise whenever your prompt mentions review, audit, or check.

### Step 3: Spawn a parallel subagent (30 seconds)

In any `agy` session, prompt:

```
Review the last 3 commits for security issues using a parallel subagent.
```

`agy` spawns a subagent, applies your reviewer skill, and returns a summary. Your main context stays clean.

### What you now have

A three-layer harness: deterministic safety gate (hook), domain expertise that auto-activates (skill), and isolated analysis that protects your context (subagent). Every section below expands one of these layers.

---

## Key Differences vs Claude Code

This table is essential if you are porting a Blake Crosley-style harness from Claude Code.

| Dimension | Claude Code (`claude`) | Antigravity CLI (`agy`) |
|---|---|---|
| **Config directory** | `.claude/` | `.agents/` |
| **Instruction file** | `CLAUDE.md` | `GEMINI.md` + `AGENTS.md` |
| **Global config** | `~/.claude/` | `~/.gemini/antigravity-cli/` |
| **Skills path (workspace)** | `.claude/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md` |
| **Skills path (global)** | `~/.claude/skills/` | `~/.gemini/antigravity-cli/skills/` |
| **Hook config** | `hooks` block in `settings.json` | `.agents/hooks.json` (separate file) |
| **Hook contract** | Exit code 2 = block | `{"decision":"deny"}` on stdout |
| **Tool name for shell** | `Bash` | `run_command` |
| **Shell input path** | `.tool_input.command` | `.toolCall.args.CommandLine` |
| **Subagent config** | Static `.claude/agents/*.md` | Dynamic (no static files needed) |
| **Extensions/plugins** | Plugins (Claude Code) | Antigravity Plugins (`agy plugin import gemini`) |
| **MCP config** | `mcpServers` in `settings.json` | `.agents/mcp_config.json` (separate file) |
| **Default model** | Claude Sonnet 4.6 | Gemini 3.5 Flash (High) |
| **CLI binary** | `claude` | `agy` |

---

## The Harness Pattern

The harness is a composable set of files, scripts, and conventions that wrap `agy` in deterministic infrastructure.

```
┌──────────────────────────────────────────────────────────────┐
│                   THE ANTIGRAVITY HARNESS                     │
├──────────────────────────────────────────────────────────────┤
│  ORCHESTRATION                                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  Parallel   │  │  Dynamic   │  │  Browser   │             │
│  │  Subagents  │  │  Planning  │  │  Subagent  │             │
│  └────────────┘  └────────────┘  └────────────┘             │
│  Multi-agent parallel work, on-demand spawning               │
├──────────────────────────────────────────────────────────────┤
│  EXTENSION LAYER                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Skills   │  │  Hooks   │  │  MCP     │  │ Plugins  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  Domain expertise, deterministic gates, live context,         │
│  bundled tooling                                              │
├──────────────────────────────────────────────────────────────┤
│  INSTRUCTION LAYER                                            │
│  ┌──────────────────────────────────────────────────────┐    │
│  │       GEMINI.md  +  AGENTS.md  +  .agents/skills/    │    │
│  └──────────────────────────────────────────────────────┘    │
│  Project context, agent policy, cross-session expertise       │
├──────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │          Main Conversation Context (LLM)              │    │
│  └──────────────────────────────────────────────────────┘    │
│  Your primary interaction; finite context; costs quota        │
└──────────────────────────────────────────────────────────────┘
```

**Instruction Layer:** `GEMINI.md` and `AGENTS.md` define what the agent knows about your project. `GEMINI.md` holds project context, standards, and build commands. `AGENTS.md` is the cross-tool standard recognized by Claude Code, Cursor, Copilot, and others — keep it as the shared layer.

**Extension Layer:** Skills auto-activate from context. Hooks fire deterministically on lifecycle events. MCP servers inject live data. Plugins bundle all three into shareable packages.

**Orchestration Layer:** Dynamic subagents handle parallel research, verification, and browser testing. The main agent spawns them on demand — no static config files required.

### Harness Layout on Disk

```
~/.gemini/antigravity-cli/
├── settings/                   # Global user preferences
├── skills/                     # Personal skills (all projects)
│   ├── code-reviewer/SKILL.md
│   └── security-auditor/SKILL.md
└── mcp_config.json             # Global MCP server config

.agents/                        # Project-level harness (in repo)
├── skills/                     # Team-shared skills
│   ├── domain-expert/SKILL.md
│   └── code-review-rubric/SKILL.md
├── hooks/                      # Hook shell scripts
│   ├── block-destructive-ops.sh
│   └── auto-lint.sh
├── hooks.json                  # Hook event registration
└── mcp_config.json             # Project MCP servers

GEMINI.md                       # Project context + agent policy
AGENTS.md                       # Cross-tool instruction standard
```

---

## Skills System

Skills are the smallest unit of reusable agent expertise. `agy` discovers and applies them automatically based on context. The moment you find yourself re-explaining the same domain knowledge across sessions, build a skill.

### When to Build a Skill

| Situation | Build a... | Why |
|---|---|---|
| You paste the same checklist every session | **Skill** | Domain expertise that auto-activates |
| You run the same slash command explicitly | **Slash command / skill with trigger** | User-invoked action |
| You need isolated analysis | **Subagent** | Separate context window |
| One-time prompt | **Nothing** | Not everything needs abstraction |

### Creating a Skill

Skills live in four scopes:

| Scope | Location | Applies to |
|---|---|---|
| Personal (global) | `~/.gemini/antigravity-cli/skills/<name>/SKILL.md` | All your projects |
| Project | `.agents/skills/<name>/SKILL.md` | This project only |
| Plugin | Bundled in plugin package | Where plugin is installed |

Every skill requires a `SKILL.md` with YAML frontmatter:

```markdown
---
name: eu-mortgage-rules
description: Apply European mortgage underwriting rules and thresholds (DTI,
  LTV, employment type, +3% rate stress test). Use when evaluating mortgage
  feasibility, writing mortgage-related code, or reviewing calculations.
  Triggers on: mortgage, DTI, LTV, underwriting, stress test.
---

# EU Mortgage Rules

## DTI Threshold
Max debt-to-income ratio: 43%

## LTV Threshold
Max loan-to-value ratio: 80% (standard), 90% (first-time buyer)

## Rate Stress Test
All calculations must pass at rate + 3 percentage points.
```

### The Description Field

`agy` injects skill names and descriptions into the agent's system prompt at session start. The model uses language reasoning — not keyword matching — to decide which skills apply. Good descriptions include:

- What the skill does ("Apply EU mortgage rules...")
- When to use it ("when evaluating feasibility, writing code...")
- Natural trigger phrases ("Triggers on: mortgage, DTI, LTV...")

**Bad:**
```
description: Helps with mortgage stuff
```

**Effective:**
```
description: Apply European mortgage underwriting rules and thresholds (DTI,
  LTV, employment type, +3% rate stress test). Use when evaluating mortgage
  feasibility, writing mortgage-related tests, or reviewing financial
  calculations. Triggers on: mortgage, DTI, LTV, underwriting, stress test.
```

### Supporting Files

Skills can reference additional files in the same directory:

```
.agents/skills/eu-mortgage-rules/
├── SKILL.md                    # Required: frontmatter + core rules
└── BOUNDARY_VALUES.md          # Referenced: edge cases + boundary values
```

Reference them from `SKILL.md` with relative links. Keep `SKILL.md` under 500 lines and move detailed material to supporting files.

### Sharing Skills via Git

Project skills in `.agents/skills/` are shared automatically via version control:

```bash
mkdir -p .agents/skills/domain-expert
# write SKILL.md
git add .agents/skills/
git commit -m "feat: add domain-expert skill"
git push
```

Teammates pull and get the skill immediately. No installation step.

### Common Skill Mistakes

**Too-broad descriptions.** A security-auditor skill that fires on every file read pollutes context unnecessarily. Tighten the description to specific trigger scenarios.

**Critical info buried in supporting files.** `agy` reads `SKILL.md` immediately but only loads supporting files when the model decides it needs them. Put critical rules directly in `SKILL.md`.

**Competing skill budgets.** Many skills with similar descriptions compete for context budget. Prefer fewer, precisely described skills over many vague ones.

---

## Hook Architecture

Hooks are shell scripts triggered by Antigravity lifecycle events. They run outside the LLM — the model cannot override them. Unlike Claude Code's exit-code contract, **Antigravity hooks use a JSON protocol**: receive JSON on stdin, write a JSON decision object to stdout.

### The JSON Hook Contract

**Input (stdin):**
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

**Output (stdout) — allow:**
```json
{"decision":"allow"}
```

**Output (stdout) — deny:**
```json
{"decision":"deny","reason":"Force-push to main is blocked by safety policy."}
```

**Critical:** Exit codes are not the blocking mechanism in Antigravity. The hook must output the correct JSON on stdout. Exit 0 is the norm for both allow and deny; the `decision` field is what matters.

### Hook Configuration — hooks.json

Register hooks in `.agents/hooks.json` (project-level) or the global settings:

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
            "command": "./hooks/block-destructive-ops.sh"
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
            "command": "./hooks/auto-lint.sh"
          }
        ]
      }
    ]
  }
}
```

The `matcher` field filters by tool name. Key tool names:

| Tool | What it covers |
|---|---|
| `run_command` | All shell commands |
| `write_file` | File writes |
| `read_file` | File reads |
| `*` | All tools |

### Available Lifecycle Events

| Event | Can Block? | Use For |
|---|---|---|
| `PreToolUse` | Yes | Safety gates, credential checks, pre-flight validation |
| `PostToolUse` | No | Auto-formatting, logging, notifications |
| `SessionStart` | No | Context injection, setup |
| `SessionEnd` | No | Cleanup, reporting |

### Three Types of Guarantees

**Safety guarantees** — `PreToolUse` on `run_command` to block destructive patterns:

```bash
#!/usr/bin/env bash
# block-destructive-ops.sh
input=$(cat)

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)
fi
[ -z "$cmd" ] && cmd=$(printf '%s' "$input" | \
  sed -n 's/.*"CommandLine"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

haystack="$cmd $input"

patterns=(
  'rm[[:space:]]+-r?f?[[:space:]]+/[[:space:]]*$'
  'git[[:space:]]+push([[:space:]].*)?--force'
  'git[[:space:]]+push([[:space:]].*)?[[:space:]]-f([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard'
  'git[[:space:]]+branch[[:space:]]+-D'
  'chmod[[:space:]]+-?R?[[:space:]]*777'
  'curl[^|]+\|[[:space:]]*(bash|sh)([[:space:]]|$)'
)

for p in "${patterns[@]}"; do
  if printf '%s' "$haystack" | grep -qE "$p"; then
    printf '{"decision":"deny","reason":"Destructive operation blocked by safety-gate policy."}\n'
    exit 0
  fi
done

printf '{"decision":"allow"}\n'
```

**Quality guarantees** — `PreToolUse` on `run_command` to gate commits:

```bash
#!/usr/bin/env bash
# quality-gate.sh
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)

if printf '%s' "$cmd" | grep -qE '^git[[:space:]]+commit'; then
  if ! ruff check . --quiet 2>/dev/null; then
    printf '{"decision":"deny","reason":"Lint failed — fix before committing."}\n'
    exit 0
  fi
fi

printf '{"decision":"allow"}\n'
```

**Formatting guarantees** — `PostToolUse` on `write_file` to normalize code:

```bash
#!/usr/bin/env bash
# auto-lint.sh — PostToolUse, runs after file writes
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.toolCall.args.path // empty' 2>/dev/null)

if [[ "$file" == *.py ]]; then
  ruff format --quiet "$file" 2>/dev/null
elif [[ "$file" == *.ts ]] || [[ "$file" == *.js ]]; then
  npx prettier --write "$file" 2>/dev/null
fi

printf '{"decision":"allow"}\n'
```

### Debugging Hooks

1. **Test scripts with sample input.** Pipe a real JSON payload:
   ```bash
   echo '{"toolCall":{"name":"run_command","args":{"CommandLine":"git push origin main --force"}}}' | bash .agents/hooks/block-destructive-ops.sh
   ```
2. **Check jq paths.** Wrong paths return `null` silently. Verify against actual tool call JSON.
3. **Verify stdout.** The JSON must go to stdout, not stderr. Confusing the two causes hooks to silently allow everything.
4. **Keep hooks under 500ms.** Hooks run synchronously on every matched tool call.

---

## GEMINI.md Design

`GEMINI.md` is operational policy for an AI agent, not a README for humans. The agent does not need to understand *why* you use conventional commits — it needs the exact command and what "done" looks like.

### The Precedence Hierarchy

| Location | Scope | Shared |
|---|---|---|
| `~/.gemini/antigravity-cli/GEMINI.md` | All projects | All your sessions |
| `GEMINI.md` (project root) | This project | Via git |
| `AGENTS.md` (project root) | Cross-tool | Via git |

Use `GEMINI.md` for Antigravity-specific overrides (tool permissions, harness behavior). Use `AGENTS.md` as the canonical source of project context that also works in Claude Code, Cursor, and Copilot.

### What Gets Ignored

**Prose paragraphs.** "We value clean, well-tested code" is documentation. The agent reads it and proceeds to write untested code because there is no actionable instruction.

**Ambiguous directives.** "Be careful with migrations" is not a constraint. "Run `alembic check` before applying any migration. Stop if downgrade path is missing." is.

**Contradictory priorities.** If `GEMINI.md` says both "move fast" and "run full integration tests before every commit," the agent cannot satisfy both and defaults to skipping verification.

### What Works

**Command-first instructions:**

```markdown
## Build and Test Commands
- Install: `uv sync`
- Lint: `ruff check . --fix`
- Format: `ruff format .`
- Test: `pytest -v --tb=short`
- Type check: `mypy src/ --strict`
- Full verify: `ruff check . && pytest -v && mypy src/ --strict`
```

**Closure definitions:**

```markdown
## Definition of Done
A task is complete when ALL of the following pass:
1. `ruff check .` exits 0
2. `pytest -v` exits 0 with no failures
3. `mypy src/ --strict` exits 0
4. Changes committed with conventional format: `type(scope): description`
```

**Task-organized sections:**

```markdown
## When Writing Code
- Run `ruff check .` after every file change
- Add type hints to all new functions

## When Reviewing Code
- Check for security issues: `bandit -r src/`
- Verify test coverage: `pytest --cov=src --cov-fail-under=80`

## When Releasing
- Update version in `pyproject.toml`
- Run: `pytest -v && ruff check . && mypy src/`
```

**Escalation rules:**

```markdown
## When Blocked
- If tests fail after 3 attempts: stop and report the failing test with full output
- Never: delete files to resolve errors, force push, or skip tests
```

### Skills Table in GEMINI.md

Documenting your skills inside `GEMINI.md` helps `agy` route tasks correctly:

```markdown
## Skills

This project ships these agent skills under `.agents/skills/`:

| Skill | What it contains | When it activates |
|---|---|---|
| `eu-mortgage-rules` | DTI/LTV thresholds, boundary values | mortgage, DTI, LTV, underwriting |
| `code-review-rubric` | blocker/important/suggestion tags | review, audit, check, PR |
```

---

## Subagent Patterns

Dynamic subagents are the key architectural shift from Gemini CLI. In Gemini CLI, each subagent required a static markdown config file in `.gemini/agents/`. In Antigravity CLI, **the main agent spawns subagents on demand** from a prompt — no config files needed. `agy` creates `agent.json` artifacts at runtime, visible via `/artifact`.

### Delete the Static Agents Directory

If migrating from Gemini CLI:

```bash
rm -rf .agents/agents/  # No longer needed
```

### Spawning Subagents via Prompt

The orchestrator spawns subagents when you describe the parallel work:

```
Run these as parallel subagents:

1. SECURITY AUDIT: Review all new code for input validation, financial
   calculation precision, and data handling. Produce a security report.

2. TEST SUITE: Write tests for the new feature. Run them and iterate
   until everything passes. Keep test files in the repo.

3. DOCUMENTATION: Update README.md to document the new features.

These tasks are independent. Run them in parallel.
```

Monitor progress with `/agents` in the session.

### Built-in Browser Subagent

Antigravity includes a native browser subagent backed by headless Chrome via MCP. No configuration needed:

```
Use the browser agent to verify that the new features work
as described in FEATURE-REQUEST.md.
```

### Dynamic Subagent Configuration

While static agent files are gone, you can guide subagent behavior through the orchestrator prompt or `GEMINI.md`:

```markdown
## Subagent Behavior

When spawning security audit subagents:
- Use read-only tool access (read_file, grep, glob)
- Focus on OWASP Top 10
- Report findings with severity: BLOCKER / IMPORTANT / SUGGESTION

When spawning test subagents:
- Run tests after writing them, iterate until all pass
- Preserve test files in the repo (never delete them)
```

### The Parallel Pattern

Classic "researcher + writer" parallel pattern:

```
I need two independent subagents:

1. RESEARCHER: Search the codebase for all usages of the authentication
   module. Map every call site, argument pattern, and return value usage.
   Return a structured report — no code changes.

2. IMPLEMENTER: Refactor the authentication module following the patterns
   in REFACTOR-PLAN.md. Do not start until the researcher reports back.
```

Adjust the timing constraint ("do not start until") to control sequencing.

### Recursion Guard

Without spawn limits, subagents can spawn more subagents, burning context and quota. Guard against it in `GEMINI.md`:

```markdown
## Subagent Policy
- Maximum 3 parallel subagents per orchestration step
- Subagents must not spawn further subagents without explicit instruction
- If a subagent needs help, it reports back to the main agent
```

For programmatic enforcement, pair this with a `PreToolUse` hook that tracks active subagent count in a state file.

---

## Memory and Context

Every `agy` session operates within a finite context window. As conversation grows, earlier content is compressed or discarded. The compression is lossy. Architecture decisions from turn 3 may not survive to turn 15.

### Strategy 1: Filesystem as Memory

The most reliable memory across context boundaries lives in files. `GEMINI.md` and skill files load at every session start.

**Session handoff documents:** For tasks spanning multiple sessions:

```markdown
## Handoff: Feature X — Security Audit Pass
**Status:** Implementation complete, tests passing (47/47)
**Files changed:** src/auth.py, tests/test_auth.py
**Decision:** Used JWT over session tokens (see ADR-007.md)
**Blocked:** CORS headers not yet reviewed
**Next:** Run security subagent on CORS configuration
```

Start the next session:
```
Read HANDOFF.md and continue from where we left off.
```

### Strategy 2: Proactive Compaction

Use `/compact` after completing a distinct subtask. This summarizes the conversation and frees context while preserving key decisions.

Timing guidance:
- After implementing a feature (before starting the next)
- Before switching to a different part of the codebase
- When `agy` starts repeating itself or forgetting earlier context
- Roughly every 25-30 minutes in intensive sessions

### Strategy 3: Fresh-Context Iteration

For sessions exceeding 60-90 minutes, spawn a fresh `agy` session per major task rather than continuing one long session. State persists through files; each iteration gets a full context budget.

Compare:
```
Continuous session (120 min):
  Minute 0:   Full context → precise, multi-file edits
  Minute 60:  Half context → degraded, tunnel vision
  Minute 90:  Context compressed → errors accumulate

Fresh sessions (3 × 40 min):
  Session 1:  Full context → Task A complete, writes state to disk
  Session 2:  Full context → reads state, Task B complete
  Session 3:  Full context → reads state, Task C complete
```

The orientation overhead (reading state files at session start) is roughly 15-20% — worth it beyond 90 minutes.

### Anti-Patterns

**Reading entire files when 10 lines suffice.** A 2,000-line file read consumes ~15,000 tokens. Use grep or offset reads.

**Verbose error output left in context.** After fixing a bug, 40 stack traces from failed iterations sit dead in context. Compact after debugging.

---

## Multi-Agent Orchestration

Single agents cannot challenge their own assumptions. Multi-agent deliberation forces independent evaluation before decisions lock.

### Minimum Viable Deliberation

Start with 2 subagents and 1 rule: they must evaluate independently.

```
Decision arrives
  |
  v
Is this risky, ambiguous, or irreversible?
  |
  +-- NO  -> Single agent decides
  |
  +-- YES -> Spawn 2 subagents with different perspectives:
             Subagent A: "Argue FOR this approach"
             Subagent B: "Argue AGAINST this approach"
             |
             v
             Compare findings
             |
             +-- Agreement with different reasoning → proceed
             +-- Genuine disagreement → investigate the conflict
```

### The Confidence Trigger

Not every task needs deliberation. Evaluate four dimensions:

1. **Ambiguity** — multiple valid interpretations?
2. **Domain complexity** — specialized knowledge required?
3. **Stakes** — is the decision reversible?
4. **Context dependency** — requires understanding the broader system?

| Confidence | Threshold | Action |
|---|---|---|
| HIGH | 0.85+ | Proceed without deliberation |
| MEDIUM | 0.70–0.84 | Proceed, log confidence note |
| LOW | Below 0.70 | Trigger parallel subagent deliberation |

Security decisions require 0.85+. Documentation edits need only 0.50.

### Parallel Verification Pattern

Standard parallel verification for any non-trivial feature:

```
Run three independent subagents in parallel:

1. SECURITY AUDITOR: Review the new code for OWASP Top 10,
   input validation, hardcoded secrets, and auth checks.
   Report with severity: BLOCKER / IMPORTANT / SUGGESTION.

2. TEST WRITER: Write comprehensive tests for the new feature.
   Test happy path, edge cases, and boundary values.
   Run all tests and iterate until they pass.

3. CODE REVIEWER: Review code style, TypeScript strict compliance,
   function complexity (flag anything over 40 lines), and
   adherence to patterns in the existing codebase.
```

### Why Agreement Is Dangerous

Without structural incentives for disagreement, parallel agents converge toward the most confident-sounding initial response regardless of correctness. Counter this by giving each subagent a distinct evaluation mandate — not just "review the code" but "argue that this approach will fail."

Two agents evaluating the same deployment strategy with shared context: scores of 0.45 and 0.48. Same agents with independent context: 0.45 and 0.72. The gap is the cost of herding.

### When to Deliberate

| Deliberate | Skip |
|---|---|
| Security architecture | Documentation typos |
| Database schema changes | Variable renames |
| API contract changes | Log message edits |
| Deployment strategies | Test fixture updates |

---

## Production Patterns

### The Quality Loop

Mandatory review process for non-trivial changes:

1. **Implement** — write the code
2. **Review** — re-read every line
3. **Evaluate** — run lint, type check, tests
4. **Refine** — fix every issue now, no deferrals
5. **Zoom Out** — check integration points for regressions
6. **Repeat** — if any criterion fails, return to step 4
7. **Report** — list what changed, how verified, cite specific evidence

### The Evidence Gate

"I believe" and "it should" are not evidence. Require specific proof:

| Criterion | Required Evidence |
|---|---|
| Follows codebase patterns | Name the pattern and file where it exists |
| Tests pass | Paste test output showing 0 failures |
| No regressions | Name the files and features checked |
| Edge cases handled | List specific edge cases and how each is handled |
| Solves the actual problem | State the user's need and how this addresses it |

Enforce this in a Stop hook or via `GEMINI.md` as an explicit "never done until you can cite evidence" rule.

### Blast Radius Classification

| Classification | Examples | Gate |
|---|---|---|
| **Local** | File writes, test runs, linting | Auto-approve |
| **Shared** | Git commits, branch creation | Warn + proceed |
| **External** | Git push, API calls, deployments | Require human approval |

Encode this in `GEMINI.md` and back it up with `PreToolUse` hooks that intercept `git push` commands.

### Atomic State Writes

Multiple subagents writing to the same state file concurrently corrupts JSON. Always write atomically:

```bash
# Good — atomic
jq --argjson d "$new_value" '.key = $d' "$STATE_FILE" > "${STATE_FILE}.tmp"
mv "${STATE_FILE}.tmp" "$STATE_FILE"

# Bad — race condition
echo '{"key": 1}' > "$STATE_FILE"
```

### Failure Modes to Watch For

| Failure Mode | Description | Prevention |
|---|---|---|
| **Shortcut Spiral** | Skipping quality loop steps to finish faster | Evidence gate requires proof |
| **Phantom Verification** | Claiming tests pass without running them | Have a subagent verify independently |
| **Deferred Debt** | TODO/FIXME in committed code | `PreToolUse` hook on `git commit` scans diff |
| **Context Drift** | Agent forgetting earlier decisions | Compact after each major subtask |
| **Herding** | Parallel agents converging without genuine evaluation | Give each subagent a distinct mandate |

---

## Decision Framework

| Problem | Use | Why |
|---|---|---|
| Block dangerous shell commands | **`PreToolUse` hook on `run_command`** | Must block before execution |
| Format code after every edit | **`PostToolUse` hook on `write_file`** | Must happen every time |
| Apply domain knowledge consistently | **Skill** | Auto-activates from context |
| Explore codebase without polluting context | **Parallel subagent (read-only mandate)** | Isolated context, returns summary |
| Verify new features from multiple angles | **3-way parallel subagent pattern** | Independent evaluation |
| Browser smoke test | **Built-in browser subagent** | Native, no config needed |
| Persist decisions across sessions | **Handoff document + GEMINI.md** | Filesystem survives context |
| Share team standards | **AGENTS.md + `.agents/skills/`** | Git-distributed, auto-loaded |
| Define build/test commands | **GEMINI.md** | Command-first, agent-verifiable |
| Run long autonomous development | **Fresh-context iteration** | Full context per task |

### Skills vs Hooks vs Subagents

| Dimension | Skills | Hooks | Subagents |
|---|---|---|---|
| **Invocation** | Automatic (LLM reasoning) | Deterministic (event-driven) | Explicit prompt or auto-delegation |
| **Guarantee** | Probabilistic | Deterministic | Deterministic (isolated context) |
| **Context cost** | Description budget | Zero (outside LLM) | Separate context window |
| **Best for** | Domain expertise | Policy enforcement | Focused parallel work |

---

## Quick Reference Card

### hooks.json Structure

```json
{
  "gate-name": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "run_command",
        "hooks": [{ "type": "command", "command": "./hooks/script.sh" }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "write_file",
        "hooks": [{ "type": "command", "command": "./hooks/format.sh" }]
      }
    ]
  }
}
```

### Hook Script Template

```bash
#!/usr/bin/env bash
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)

# Your logic here

printf '{"decision":"allow"}\n'   # or "deny" with "reason"
exit 0
```

### Skill Frontmatter

```yaml
---
name: my-skill
description: What it does and when to use it. Include natural trigger phrases.
---
```

### Key agy Commands

| Command | Purpose |
|---|---|
| `agy` | Start interactive session |
| `agy --model gemini-3.1-pro` | Override default model |
| `agy changelog` | View what changed in this version |
| `/agents` | View running subagents |
| `/artifact` | View agent-generated artifacts |
| `/compact` | Summarize conversation, free context |
| `/goal <description>` | Set session completion condition |
| `/skills` | List available skills |
| `/mcp` | Manage MCP servers |
| `/logout` | Clear saved credentials |
| `agy plugin import gemini` | Migrate Gemini CLI extensions |

### Directory Structure Reference

```
GEMINI.md                         # Project context + agent policy
AGENTS.md                         # Cross-tool instruction standard
.agents/
├── skills/
│   └── <name>/
│       ├── SKILL.md              # Required: frontmatter + expertise
│       └── SUPPORTING.md        # Optional: detailed reference
├── hooks/
│   └── block-destructive-ops.sh  # Hook scripts (must be executable)
├── hooks.json                    # Hook event registration
└── mcp_config.json               # Project MCP servers

~/.gemini/antigravity-cli/
├── skills/                       # Personal global skills
└── mcp_config.json               # Personal global MCP config
```

### Migration Checklist from Gemini CLI

```
[ ] Install agy and run: agy plugin import gemini
[ ] Rename .gemini/ to .agents/ in all repos
[ ] Move global skills: ~/.gemini/skills/ → ~/.gemini/antigravity-cli/skills/
[ ] Move MCP config: mcpServers in settings.json → .agents/mcp_config.json
[ ] Update hook config: settings.json → .agents/hooks.json
[ ] Update hook scripts: exit code contract → JSON decision contract
[ ] Update shell input path: .tool_input.command → .toolCall.args.CommandLine
[ ] Remove static agents/ directory (subagents are now dynamic)
[ ] Update GEMINI.md to reflect new skills directory paths
```

---

## Cross-Tool Compatibility

`AGENTS.md` is the open standard recognized across all major AI coding tools:

| Tool | Native File | Reads AGENTS.md? |
|---|---|---|
| Antigravity CLI | `GEMINI.md` + `AGENTS.md` | Yes (native) |
| Claude Code | `CLAUDE.md` | No (separate format) |
| Cursor | `.cursor/rules` | Yes (native) |
| GitHub Copilot | `.github/copilot-instructions.md` | Yes (native) |
| Codex CLI | `AGENTS.md` | Yes (native) |
| Windsurf | `.windsurfrules` | Yes (native) |

**Pattern:** Write `AGENTS.md` as the canonical source of project context (build commands, definition of done, escalation rules). Write `GEMINI.md` for Antigravity-specific overrides (tool permissions, harness behavior, skills table). Do not maintain two instruction sets that drift apart.

---

*Sources: [Antigravity CLI Deep Dive — agentpedia.codes](https://agentpedia.codes/blog/antigravity-cli-deep-dive), [Migrating to Antigravity CLI — Google Cloud Blog](https://medium.com/google-cloud/migrating-to-antigravity-cli-a841c6964f37), [Google Developers Blog — Transitioning Gemini CLI](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/), [Blake Crosley — Agent Architecture (Claude Code reference)](https://blakecrosley.com/guides/agent-architecture)*
