# Alpha-Zero-G

**The Foundational Agentic Harness for Python & R Analytics (MVP Edition)**

Alpha-Zero-G is a highly engineered, minimal, and cross-tool development environment (a "harness") designed for building analytics and statistical modeling projects alongside Agentic AIs (such as Antigravity, Cursor, and Claude Code). 

Rather than serving as a software codebase, it defines the structures, rules, and safety parameters that allow AI agents to work autonomously, safely, and continuously across sessions without regression.

---

## Harness Rule Hierarchy

This harness is built around a streamlined hierarchy of rule files that guide the AI's actions:

```
  SYSTEM RULES (Immutable Deepmind rules)
       ↓
  GEMINI.md (Antigravity-specific local/global overrides)
       ↓
  AGENTS.md (Cross-tool standard rules for Cursor/Claude/Gemini)
```

---

## Directory Structure (MVP)

When cloned to start a new project, this harness establishes a clean, minimal structure:

```
<project-root>/
│
├── AGENTS.md                    # Core cross-tool navigation map & rules
├── GEMINI.md                    # Antigravity session-specific overrides
├── CONTEXT.md                   # Project glossary (domain-specific jargon)
│
├── features.json                # Structured feature requirements and status
├── progress.md                  # Human & Agent session state log
├── init.sh                      # Deterministic project bootstrap script
├── pyproject.toml               # Python dependencies (managed by uv)
├── Makefile                     # Standard development commands (lint, test, format)
│
└── .agents/
    └── hooks.json               # Hard safety enforcement rules (blocking/confirmations)
```

---

## The Golden Path Developer Workflow

To ensure high-performance, deterministic development and perfect session continuity when pair-programming with AI agents, always follow the exact multi-phase cycle below:

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  1. BOOT  │ ──> │ 2. GRILL  │ ──> │  3. SPEC  │ ──> │ 4. SLICE  │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
                                                            │
┌───────────┐     ┌───────────┐     ┌───────────┐           ▼
│8. HANDOFF │ <── │7.REFACTOR │ <── │ 6. VERIFY │ <── │  5. SHIP  │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
```

1. **BOOT:** CD into the workspace and run `bash init.sh` to sync the virtual environment and verify a green smoke-test baseline.
2. **GRILL:** Stress-test ideas, identify edge cases, and align on goals with the user before writing any code. Update the domain glossary `CONTEXT.md` inline.
3. **SPEC:** Propose and compile design specifications in scratch files or inline before starting implementation.
4. **SLICE:** Break approved designs into thin, independent vertical slices listed in `features.json`.
5. **SHIP (TDD):** Implement behavior-driven tests, watch them fail, write minimal code to pass, and refactor. Always run python executions and tests via `uv run`.
6. **VERIFY:** Conduct post-modeling/post-computation checks (assert shapes, nulls, print matrices).
7. **REFACTOR:** Clean up code, remove duplication, and verify tests remain green.
8. **HANDOFF:** Update `progress.md` with active states and next steps before ending the session.

---

## Getting Started

To initialize the project environment (whether on a local machine, or a fresh container / remote workspace), run:

```bash
bash init.sh
```

This bootstrap script will:
1. Detect and install the `uv` package manager if missing.
2. Synchronize Python virtual environments matching `pyproject.toml` (targeting Python 3.12).
3. Execute smoke tests to verify the system works before letting the agent make changes.

---

## Bootstrapping a New Project

Alpha-Zero-G comes with an automated project generator script `create-project.sh` located at the root. This script copies templates, builds the workspace directories, and automatically customizes paths and names for your new project.

### Quick Start: Bootstrapping a New Project

To create a new workspace (e.g., your FPL Model or Crypto Bot), run the following command from the root of the Alpha-Zero-G project:

```bash
bash create-project.sh <destination-path> "[Project Name]"
```

#### Example:
```bash
bash create-project.sh ../FPL-Model "Fantasy Premier League Score Projections"
```

Once bootstrapped, navigate to the directory and boot the environment:
```bash
cd ../FPL-Model
bash init.sh
```
