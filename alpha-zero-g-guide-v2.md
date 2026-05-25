# Alpha-Zero-G: Foundational Guide to Agentic AI Development
**Research & Strategy Document — v0.2**
*Updated: May 2026 — Corrections & Q&A integrated*

---

## Corrections from v0.1

### Skill Path Correction (CONFIRMED)
The paths written in v0.1 were incorrect. Verified paths:

| Scope | Path |
|---|---|
| **Workspace-specific** | `<workspace-root>/.agents/skills/<skill-folder>/SKILL.md` |
| **Global (all workspaces)** | `~/.gemini/antigravity/skills/<skill-folder>/SKILL.md` |

**Inheritance rule:** Workspace skills automatically override global skills with the same name. No duplication required. Globals are inherited by all workspaces unless explicitly overridden at the workspace level.

---

## 1. The Three Disciplines — What They Actually Are

Think of these as nested layers, not competing alternatives.

```
┌─────────────────────────────────┐
│      HARNESS ENGINEERING        │  ← 2026+  System-level (the office)
│  ┌───────────────────────────┐  │
│  │    CONTEXT ENGINEERING    │  │  ← 2025   Session-level (the email attachments)
│  │  ┌─────────────────────┐  │  │
│  │  │  PROMPT ENGINEERING │  │  │  ← 2022   Message-level (the email itself)
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### 1.1 Prompt Engineering (2022–2024)
**What:** Crafting the instruction that elicits the best model response for a single turn.
**Still relevant?** Yes — it's the foundation. Alone it fails at multi-step agentic tasks.

**Key practices:**
- Be specific and positive ("do X" not "don't do Y")
- Use XML tags to delineate sections (`<context>`, `<task>`, `<format>`)
- Include negative examples alongside positive ones
- Request step-by-step reasoning before the final answer
- Specify output format explicitly

### 1.2 Context Engineering (2025)
**What:** Curating *which* information the agent sees at each step across a session.
**Key insight (Karpathy, Dec 2025):** Bigger context windows don't solve the problem — the question is always *which* information is relevant, *in what order*, *at what level of detail*.

**Key practices:**
- Maintain a `CONTEXT.md` project glossary so agents adopt domain vocabulary immediately
- Expose project state as readable files (`grep`, `find`, `read_file`) rather than injected blobs
- Label evidence clearly — agents reason better over structured, labeled context
- Skills are a context engineering tool: they load on-demand, not upfront

**For analytics projects:**
- `DATA_DICT.md` — column names, units, types, known quirks (feeds every session)
- `MODEL_NOTES.md` — assumptions, transformations, edge cases found
- `claude-progress.txt` — session state log (see §3 below)

### 1.3 Harness Engineering (2026+)
**What:** Designing the entire *environment* an agent operates in — tools, memory, constraints, feedback loops, permissions, orchestration.
**Formula:** `Agent = Model + Harness`
**Key insight:** Most "agent failures" are diagnosed in the wrong layer. Teams blame the prompt when the issue is stale context, or blame the model when the issue is a weak harness with no retries, no sensors, no evals.

**Components:**
- **Guides (feedforward):** AGENTS.md, SKILL.md — shape behavior *before* the task starts
- **Sensors (feedback):** Test runners, linters, CI checks — evaluate agent actions post-execution
- **Memory:** `claude-progress.txt` — persistent state across sessions
- **Tools:** MCP integrations, APIs, file system access
- **Permissions:** What the agent can act on (behavioral via AGENTS.md + enforced via Hooks)
- **Orchestration:** Subagent coordination, parallel vs sequential execution

---

## 2. Antigravity 2.0 — Rule File Hierarchy (Important)

Antigravity reads from multiple rule files and merges them at session start. Understanding the hierarchy prevents conflicts.

```
Priority (highest → lowest):

  SYSTEM RULES (Google Deepmind — immutable, you cannot change these)
       ↓
  GEMINI.md (Antigravity-specific overrides — highest user priority)
       ↓
  AGENTS.md (Cross-tool shared rules — read by Antigravity, Claude Code, Cursor)
       ↓
  .agent/rules/*.md (Workspace supplement files — organized by concern)
       ↓
  Nested AGENTS.md (In subdirectories — scoped to that directory)
```

**Rule:** When rules conflict, GEMINI.md wins in Antigravity. Other tools (Claude Code, Cursor) only see AGENTS.md — so AGENTS.md is your portable cross-tool standard.

### Global vs Project-Level Files

| File | Global location | Project location |
|---|---|---|
| `AGENTS.md` | `~/.gemini/AGENTS.md` | `<project-root>/AGENTS.md` |
| `GEMINI.md` | `~/.gemini/GEMINI.md` | `<project-root>/GEMINI.md` |
| Skills | `~/.gemini/antigravity/skills/` | `.agents/skills/` |
| Supplemental rules | *(not applicable)* | `.agent/rules/*.md` |

---

## 3. Q&A: Your Specific Questions Answered

### Q1: Does AGENTS.md permissions actually work? Aren't permissions controlled by config files?

**Short answer:** AGENTS.md permissions are *behavioral* (soft), not *enforced* (hard). They are different mechanisms that work together.

**The distinction:**

| Mechanism | Type | How it works | Reliability |
|---|---|---|---|
| `AGENTS.md` permissions | **Behavioral** | Tells the LLM what it *should* do | Probabilistic — the agent follows instructions, but could make mistakes |
| OS file permissions | **Enforced** | OS blocks writes at the kernel level | Deterministic — always enforced |
| Antigravity Hooks | **Enforced** | JSON interceptors that fire before/after tool calls | Deterministic — always enforced |
| Antigravity confirmation dialogs | **Enforced** | Built-in approval gates for high-risk operations | Deterministic — always enforced |

**What AGENTS.md actually does:**
When you write `Write: src/, notebooks/, tests/ only`, this gets prepended to every prompt in the session. The agent reads it as an instruction and follows it — the same way a developer reads coding standards and follows them. It is *policy*, not *enforcement*.

**What actually enforces hard limits:**
Antigravity Hooks — JSON-defined lifecycle interceptors. For example:

```json
// .agents/hooks.json
{
  "before_tool_call": [
    {
      "match": { "tool": "write_file", "path_pattern": "^config/" },
      "action": "require_approval",
      "message": "Modifying config/ — confirm before proceeding"
    }
  ],
  "before_tool_call": [
    {
      "match": { "tool": "run_command", "command_pattern": "rm -rf" },
      "action": "block",
      "message": "Recursive deletion is not permitted"
    }
  ]
}
```

**Practical guidance:** Use AGENTS.md for *policy* (what the agent should prefer to do). Use Hooks for *enforcement* (what the agent is mechanically prevented from doing). Keep both — they serve different failure modes.

---

### Q2: Agent-first framework — allow-everything-except vs. allowlist?

**Recommendation: Default-allow with a denylist of dangerous operations.** For a development/analytics workflow this is correct. Here is why:

**Allowlist (restrictive) problems:**
- You will constantly hit cases where the agent needs to read or write a file you didn't anticipate
- Breaks flow and requires you to manually expand permissions constantly
- Appropriate for production deployments, not development

**Denylist (permissive + guardrails) — recommended for development:**

The operations worth blocking deterministically (via Hooks, not just AGENTS.md):

```
BLOCK ALWAYS (deterministic, no confirmation):
  - rm -rf / or rm -rf ~ (recursive deletion of root/home)
  - git push --force (force push to remote)
  - Modification of .git/ internals directly
  - Modifying system files outside project root (/etc, /usr, /bin)
  - Exposing .env / secrets files to output

REQUIRE APPROVAL (confirmation dialog):
  - git push (any push to remote)
  - Deleting any file (except tmp/)
  - Modifying config/ or .agents/ directory
  - Installing packages globally (pip install -g, npm install -g)
  - Any network request to external APIs in production context

ALLOW FREELY:
  - Read anything in the project
  - Write to src/, notebooks/, tests/, docs/
  - Run local scripts and tests
  - git add, git commit, git status, git log
  - Install packages in virtual environment / local project
```

---

### Q3: Alignment with `harness_engineering_summary.md`

**Assessment: High-level philosophy aligned; specific artifacts were missing.**

| Component from your research | In v0.1 of Alpha-Zero-G? | Gap |
|---|---|---|
| `AGENTS.md` (~100 line map) | ✅ Yes | v0.1 AGENTS.md was too detailed — should be a *map with pointers*, not the full content |
| `features.json` | ❌ Missing | Needs to be added |
| `claude-progress.txt` | ❌ Missing | Critical for cross-session continuity — needs to be added |
| `init.sh` | ❌ Missing | Needs to be added |
| `docs/architecture.md` | Partial (docs/ existed) | Needs explicit architecture.md |
| `docs/design/` | ❌ Missing | Needs to be added |
| `docs/quality.md` | ❌ Missing | Needs to be added |
| `docs/beliefs.md` | ❌ Missing | Needs to be added |
| `CONTEXT.md` (glossary) | ✅ Yes | Not in the research summary but it's correct to include |
| `DATA_DICT.md`, `MODEL_NOTES.md` | ✅ Yes | Analytics-specific additions, correct |
| `.agents/skills/` | ✅ Yes (path corrected) | |
| `templates/` | ✅ Yes | |

The two-phase execution model from your research (Initializer Agent → Coding Agent) is the most actionable pattern that was missing. This is now incorporated into the structure below.

---

### Q4: Global AGENTS.md — what goes in it, and what are best practices?

**Rule:** Global AGENTS.md contains what you want to be true in *every project on your machine* regardless of context.

**What belongs globally:**
- Your personal coding style preferences
- Response behavior preferences (e.g., "Ask before assuming")
- Universal safety guardrails
- Your identity / context as an engineer
- Tool preferences that never change

**What does NOT belong globally:**
- Project-specific architecture rules
- Feature requirements
- Domain vocabulary
- Package preferences (these differ by project)

**Recommended global `~/.gemini/AGENTS.md`:**
```markdown
# Global Agent Rules — [Your Name]

## Identity Context
I work primarily on analytics and statistical projects in Python.
My projects live in Google Drive (stream sync). When on a new machine, 
run init.sh before any other action.

## Response Behavior
- Always ask clarifying questions before starting any task > 30 min
- State your plan before executing it
- Summarize what you changed at the end of each session
- Update claude-progress.txt at the end of every session without being asked

## Universal Code Standards
- All Python functions must have type hints and a docstring
- Never use bare except: — always catch specific exceptions
- Print input/output shapes after any data transformation

## Universal Safety Rules
- Never delete files without explicit confirmation
- Never commit to main directly — always use a feature branch
- Never expose .env contents in output or logs
- Do not install packages globally — use virtual environments

## When Stuck
If blocked for more than 2 attempts, stop and explain the obstacle rather 
than trying increasingly speculative solutions.
```

**Recommended global `~/.gemini/GEMINI.md`** (Antigravity-specific overrides only):
```markdown
# Antigravity-Specific Overrides

## Subagent Behavior
Prefer sequential execution for tasks touching shared state.
Use parallel subagents only for independent read-only research tasks.

## Tool Preferences
Always run init.sh at session start if it exists in the project root.
```

---

## 4. Revised Alpha-Zero-G Project Structure

Merging v0.1 with the harness_engineering_summary.md layout:

```
alpha-zero-g/
│
├── AGENTS.md                    # ~100 lines. A MAP — pointers to deeper sources.
│                                  Not the content itself.
├── GEMINI.md                    # Antigravity-specific behavior overrides
├── CONTEXT.md                   # Domain glossary (analytics terms)
│
├── features.json                # Requirements baseline with compliance states
│                                  { "feature": "...", "passes": true/false }
├── claude-progress.txt          # Session state log — updated every session
├── init.sh                      # Deterministic bootstrap — reproducible env setup
│
├── .agents/
│   ├── skills/                  # Workspace skills (override globals)
│   │   ├── grill-analytics/
│   │   │   └── SKILL.md         # Domain-specific grill before any model work
│   │   ├── spec-model/
│   │   │   └── SKILL.md         # How to spec a statistical/ML model
│   │   ├── validate-output/
│   │   │   └── SKILL.md         # Post-model output sanity checks
│   │   └── to-colab/
│   │       └── SKILL.md         # Convert .py → Colab-compatible notebook
│   ├── workflows/               # Multi-step orchestrated pipelines
│   │   └── new-model.md         # Full workflow: grill→spec→build→validate
│   └── hooks.json               # ENFORCEMENT layer — Hooks for hard guardrails
│
├── docs/                        # System of record — comprehensive knowledge base
│   ├── architecture.md          # Domain maps, package layering rules
│   ├── beliefs.md               # Core agent-first operating principles
│   ├── quality.md               # Quality grades per domain, gap tracking
│   ├── design/                  # Technical design documents
│   │   └── INDEX.md             # Index of all design docs + verification status
│   ├── DATA_DICT.md             # Column definitions, units, data types
│   └── MODEL_NOTES.md           # Model assumptions, transformations, edge cases
│
└── templates/                   # Copy into new projects, then customize
    ├── AGENTS.md                # Project-specific AGENTS.md template
    ├── CONTEXT.md               # Blank glossary template
    ├── DATA_DICT.md             # Blank data dictionary template
    ├── features.json            # Empty features baseline template
    ├── claude-progress.txt      # Progress log template
    └── init.sh                  # Bootstrap script template
```

### What AGENTS.md Should Look Like (~100 Lines, Map Style)

```markdown
# AGENTS.md — Alpha-Zero-G

This file is the entry point. Read it first. Follow the pointers.

## What This Project Is
[1-2 sentences describing the project and its goal]

## Where to Find Information
| Need to know... | Read this file |
|---|---|
| Domain vocabulary and terms | CONTEXT.md |
| Data columns and definitions | docs/DATA_DICT.md |
| Architecture and package rules | docs/architecture.md |
| What has been built / current state | claude-progress.txt |
| Active feature requirements | features.json |
| Model assumptions | docs/MODEL_NOTES.md |
| Core operating beliefs | docs/beliefs.md |

## Workflow to Follow
Run the grill→spec→slice→ship→refactor loop for any task > 30 min.
Use /grill-analytics before any model work.
Use /spec-model to produce a written spec before coding.

## Hard Rules
- Run init.sh at the start of every session
- Update claude-progress.txt at the end of every session
- Never modify docs/ architecture without updating docs/design/INDEX.md
- Feature work requires a corresponding entry in features.json

## Permissions (Policy — see .agents/hooks.json for enforcement)
- Read freely: everything
- Write freely: src/, notebooks/, tests/
- Require confirmation: config/, docs/, .agents/, any deletion
- Never: git push --force, rm -rf outside tmp/, expose .env contents
```

---

## 5. The Two-Phase Execution Model (From Your Research)

This is the most actionable operational pattern for analytics projects with cross-session continuity.

### Phase 1: Initializer Agent (Run Once)
Trigger: new project or machine. Produces the stable baseline.

1. Reads AGENTS.md and CONTEXT.md to understand scope
2. Generates `features.json` — structured requirements baseline
3. Initializes `claude-progress.txt` — starting state
4. Provisions `init.sh` — deterministic environment bootstrap
5. Makes an initial git commit to establish clean baseline

### Phase 2: Coding Agent (Every Session)
Strict procedural loop — enforced by AGENTS.md instructions:

1. **Orient:** Run `pwd`, read `git log`, read `claude-progress.txt`
2. **Verify:** Run `init.sh`, run smoke tests — confirm baseline before touching anything
3. **Execute:** Work on one feature from `features.json` at a time
4. **Preserve:** Commit with detailed message, update `claude-progress.txt`, leave branch clean

This loop solves the biggest analytics project problem: agents that start fresh each session and repeat work, contradict prior decisions, or break things that were previously working.

---

## 6. Skill Management — Global vs Workspace

```
~/.gemini/antigravity/skills/       ← Available in ALL your projects
.agents/skills/                     ← This project only (overrides global if same name)
```

**No duplication needed.** Global skills are inherited automatically. Workspace skills layer on top.

**Decision guide:**

| Skill type | Where to put it |
|---|---|
| Universal process (grill, TDD, diagnose) | Global |
| Analytics-domain skills (grill-analytics, spec-model) | Global — you'll use these in every analytics project |
| Project-specific (FPL-specific validation, crypto-specific signal checks) | Workspace |
| Experimental skills you're testing | Workspace (isolate until proven) |

**Workflow:** Install Pocock's `/grill-me` and `/tdd` globally. Your `/grill-analytics` and `/spec-model` go global too. Project-specific overrides go in workspace.

---

## 7. Addressing the Colab Problem

Three options, in recommended order:

1. **py:percent format (primary):** Write `.py` files using `# %%` cell markers. Compatible with Jupyter, VS Code, and AI agents. Source of truth is `.py`, Colab is a runtime.
2. **`/to-colab` skill:** On-demand conversion from `.py` to `.ipynb` when you need to share.
3. **Direct in Colab:** Use `%run script.py` to run agent-written scripts directly in Colab cells.

The agent works cleanly with `.py`. You get Colab when you need it. No friction.

---

## 8. Key Sources to Study Next

| Resource | Why |
|---|---|
| `mattpocock/skills` on GitHub | Read every SKILL.md — study the format as much as the content |
| Google Codelabs: "Autonomous AI Developer Pipelines" | Official Antigravity agents.md + skills.md codelab |
| Antigravity 2.0 blog (antigravityide.org) | Subagents, hooks, project primitives |
| `ai-boost/awesome-harness-engineering` on GitHub | Curated production harness patterns |
| Anthropic's 2026 Agentic Coding Trends Report | Harness setup benchmarks |
| Atlan: "Harness vs Context vs Prompt Engineering" | Best single-page conceptual map |

---

*Alpha-Zero-G is not a codebase. It is a harness. The agent is the engine; you are the architect of the rails it runs on.*
