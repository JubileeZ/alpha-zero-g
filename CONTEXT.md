# Domain Glossary — Alpha-Zero-G

This file defines the primary terminology and vocabulary used throughout the Alpha-Zero-G framework to ensure semantic consistency across development tools.

---

## Foundational Terms

### Harness
The environmental context surrounding an AI agent (composed of tools, permissions, standards, and memory files). Unlike a codebase, the harness guides and restricts the agent's behavior.

### System of Record
The centralized markdown documents located in `docs/` (such as `architecture.md`, `beliefs.md`, `DATA_DICT.md`, `MODEL_NOTES.md`) representing the current state, metrics, assumptions, and constraints of the project.

### Session Continuity
The practice of maintaining persistent log files (`progress.md` and `features.json`) across distinct chat windows or sessions so the agent can resume progress seamlessly without repeated orientation or regression.

### Feedforward
Guidance files (like `AGENTS.md` and `SKILL.md` instructions) that define protocols *before* the agent starts work.

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

### Harness Upgrader (`upgrade-project.sh`)
A bidirectional synchronization utility in the template core repository that pushes core template updates to existing downstream projects or pulls local optimizations back to the core template.

### Project Infrastructure File
Standard, generic developer utility files (such as `init.sh`, `.agents/hooks.json`, `DEVELOPER_WORKFLOW.md`, or base documentation templates) that are identical across workspaces and managed by the Harness Upgrader.

### Project Domain File
Workspace-specific source code, tests, or session tracking files (like `src/`, `tests/`, `CONTEXT.md`, `progress.md`, `beliefs.md`, `features.json`) that are completely owned by the downstream project and must never be modified by the Harness Upgrader.

