# Domain Glossary — Alpha-Zero-G

This file defines the primary terminology and vocabulary used throughout the Alpha-Zero-G framework to ensure semantic consistency across development tools.

---

## Foundational Terms

### Harness
The environmental context surrounding an AI agent (composed of tools, permissions, standards, and memory files). Unlike a codebase, the harness guides and restricts the agent's behavior.

### Session Continuity
The practice of maintaining persistent log files (`progress.md` and `features.json`) across distinct chat windows or sessions so the agent can resume progress seamlessly without repeated orientation or regression.

### Feedforward
Guidance files (like `AGENTS.md` and custom instructions) that define protocols *before* the agent starts work.

### Feedback Sensors
Automated tools and processes (such as linters, test runners, and validation scripts in `init.sh`) that verify the correctness of the agent's changes *after* execution.

---

## Technical Stack & Configuration Terms

### uv
A fast, modern Python package installer and resolver. Used as the default virtual environment manager for Python in this harness.

### py:percent format
A format for writing Python scripts using `# %%` cell markers, which are compatible with Jupyter, VS Code notebooks, and standard python runners. This represents the single source of truth for research notebooks.

### renv
A dependency manager for the R programming language. When R components are detected, `init.sh` spins up `renv` to sync local libraries.

### Hooks
Programmatic interceptors defined in `.agents/hooks.json` that capture tool invocations and block, prompt, or allow them deterministically based on defined pattern matches.

### Project Utility Files
Standard, generic developer utility files (such as `init.sh`, `.agents/hooks.json`, `DEVELOPER_WORKFLOW.md`, `Makefile`, and base templates) that are identical across workspaces.
