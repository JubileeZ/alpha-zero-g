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

Non-trivial, hard-to-reverse architectural decisions are captured as separate, immutable Architectural Decision Records (ADRs) inside `docs/adr/`. 

| ADR ID | Decision Title | Status | Date | File Link |
|---|---|---|---|---|
| **ADR-0001** | Dynamic R & Python Environment Bootstrapping | `accepted` | 2026-05-20 | [0001-dynamic-bootstrapping.md](file:///Users/jubilee/Library/CloudStorage/GoogleDrive-z.jubilee.z@gmail.com/My%20Drive/Projects/Alpha-Zero-G/docs/adr/0001-dynamic-bootstrapping.md) |
| **ADR-0002** | Automated Project Scaffolder and Parameterizer | `accepted` | 2026-05-25 | [0002-automated-project-scaffolder.md](file:///Users/jubilee/Library/CloudStorage/GoogleDrive-z.jubilee.z@gmail.com/My%20Drive/Projects/Alpha-Zero-G/docs/adr/0002-automated-project-scaffolder.md) |

