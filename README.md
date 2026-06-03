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
├── pyproject.toml               # Python dependencies (managed by uv)
│
└── .agents/
    └── hooks.json               # Hard safety enforcement rules (blocking/confirmations)
```

---

## Getting Started

This project relies on the blazing fast `uv` package manager. To initialize the project environment (whether on a local machine, or a fresh container / remote workspace), run:

```bash
uv sync
```

This command will automatically resolve and synchronize the Python virtual environment defined in `pyproject.toml`.

---

## Bootstrapping a New Project

Alpha-Zero-G comes with automated project generator scripts located in the `scripts/` folder. These scripts copy templates, build workspace directories, and automatically customize paths and names for your new project.

### Quick Start: Bootstrapping a New Project

To create a new workspace (e.g., your FPL Model or Crypto Bot), run the following command from the root of the Alpha-Zero-G project:

```bash
bash scripts/scaffold-project.sh <destination-path> "[Project Name]"
```

*(Note: Use `scripts/scaffold-project.ps1` if you are on Windows).*

#### Example:
```bash
bash scripts/scaffold-project.sh ../FPL-Model "Fantasy Premier League Score Projections"
```

Once bootstrapped, navigate to the directory and sync the environment:
```bash
cd ../FPL-Model
uv sync
```
