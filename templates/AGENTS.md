# Agent Harness — {{PROJECT_NAME}}

This file is the primary entry point and cognitive map for AI agents working in this repository.

## What This Project Is
{{PROJECT_DESCRIPTION}}

---

## System Pointers (Where to Find Information)

| Query / Need                             | File Path                                                 | Scope & Contents                                      |
| ---------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------- |
| **Domain Jargon & Glossary**             | [CONTEXT.md](CONTEXT.md)                                 | Domain definitions and foundational terms             |
| **Feature Requirements Status**          | [features.json](features.json)                           | List of core deliverables and their test states       |
| **Session State Log**                    | [progress.md](progress.md)                               | Running log of what was built and current priorities  |
| **Project Overview & Setup**             | [README.md](README.md)                                     | Developer onboarding and quick start guide            |

---

## Core Rules & Operating Protocols

### 1. Environment & Execution
- **Deterministic Python:** [HARD] Do not use raw system Python or pip commands. Always execute scripts and test runners via `uv run` (e.g. `uv run python script.py` or `uv run pytest`) to ensure virtualenv consistency.
- **Log Data Shapes:** [HARD] Always explicitly inspect and print input and output shapes for every numerical, matrix, or DataFrame transformation to guarantee validation correctness.

### 2. Session & Link Portability
- **Orientation & Continuity:** [HARD] You must orient immediately by reading `progress.md` at start, and update it at the end of every active work session.
- **Portable Markdown Linking (ADR-0007):** [HARD] Never write absolute `file:///` URLs or local filesystem paths in rule files (`AGENTS.md`, `GEMINI.md`) or documentation. All references and guide links must use standard, relative Markdown paths (e.g., `[glossary](CONTEXT.md)`).

### 3. Safety & Coding Standards
- **Explicit Imports & Typings:** [HARD] Write typed python code. Prefer explicit over implicit: no magic imports, strict type hints on all new function signatures.
- **Interactive Gates:** [HARD] Respect the hooks in `.agents/hooks.json`. Never push to Git or perform high-risk state modifications without confirmation.
