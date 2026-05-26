# Core Operating Beliefs — Alpha-Zero-G

This document records the foundational operating assumptions, architectural philosophies, and design decision logs that guide the Alpha-Zero-G developer harness.

---

## 1. Operating Assumptions & Architectural Beliefs

### Harness Engineering over Prompt Engineering
Prompt engineering only shapes the immediate message turn. Context and Harness Engineering shape the entire system boundaries. A robust harness (deterministic tool hooks, environment synchronizations, and progressive session-continuity files) solves 90% of model failure points.

### Default-Allow with Programmatic Denylist
For development environments, an allowlist structure is overly restrictive and constantly breaks developer momentum. We believe in a **default-allow** framework (unrestricted reads, local project writes, local script executions) coupled with a robust, programmatically enforced **denylist** (e.g. blocking force pushes, system deletions, secret leakage, and credential modifications via `.agents/hooks.json`).

### Session Continuity > Model Context Size
Large context windows are highly susceptible to noise and circular reasoning. True development efficiency is achieved by exposing explicit state-tracking files (`progress.md` and `features.json`) that act as external memory, ensuring that new agents starting a fresh session know exactly what was done, what was tested, and where to resume.

### Percent-Format (`py:percent`) Python Scripts
Jupyter Notebooks (`.ipynb`) are notoriously difficult for AI systems to read, diff, and refactor cleanly due to their massive JSON-wrapped metadata and non-contiguous cell structures. We believe that **the single source of truth should be flat Python scripts written with `# %%` cell markers**. Jupyter notebooks should be generated *downstream* using on-demand conversion tools (like the `to-colab` skill) for visualization or Google Colab environments.

---

## 2. Design Decision Register (ADR Log)

### Decision ID: ADR-001 — Dynamic R & Python Environment Bootstrapping
- **Date:** May 2026
- **Status:** APPROVED
- **Context:** The user works across statistical projects that heavily combine Python and R. Setting up distinct virtual environments for each language manually creates friction.
- **Decision:** The bootstrapper (`init.sh`) must dynamically detect project requirements. Instead of pinning to a single environment type, the script will:
  1. Scan for Python configurations (`pyproject.toml` or `requirements.txt`) and bootstrap `uv` virtual environments if found.
  2. Scan for R scripts (`.R` files, `DESCRIPTION` files, or project directory structures containing `.Rprofile`) and bootstrap R library management via `renv` or `pak` if R is utilized.
  3. Ensure the environment is verified cleanly via test sensors before completing initialization.
- **Consequences:** Provides a single, unified entry point (`init.sh`) that scales from Python-only, R-only, to hybrid analytics configurations cleanly.

### Decision ID: ADR-002 — Automated Project Scaffolder and Parameterizer (`create-project.sh`)
- **Date:** May 2026
- **Status:** APPROVED
- **Context:** Standardizing the starting point of new projects (FPL, Crypto, etc.) requires copying, establishing directory structures, and manually editing config file parameters, which causes friction.
- **Decision:** Build a lightweight, native bash project generator (`create-project.sh`) at the root. The script will:
  1. Programmatically set up the folders (`src/`, `notebooks/`, `tests/`, `.agents/`).
  2. Deploy all configuration and system of record templates.
  3. Use portable stream-editing (`sed`) to find and replace customized properties like project name and absolute directory roots automatically.
- **Consequences:** Reduces the user setup time for fresh, compliant agentic workspaces down to a single terminal command.
