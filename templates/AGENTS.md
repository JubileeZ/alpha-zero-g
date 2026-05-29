# Agent Harness — {{PROJECT_NAME}}

This file is the primary entry point and cognitive map for AI agents working in this repository. Read it first and strictly follow all instructions and paths.

## What This Project Is
{{PROJECT_DESCRIPTION}}

---

## System Pointers (Where to Find Information)

| Query / Need | File Path | Scope & Contents |
|---|---|---|
| **Domain Jargon & Jargon Meanings** | [CONTEXT.md](CONTEXT.md) | Domain glossary and foundational concepts |
| **System Layers & Architecture** | [docs/architecture.md](docs/architecture.md) | Technical stack, rule file mappings, layout |
| **Philosophical Guidelines & Decisions** | [docs/beliefs.md](docs/beliefs.md) | High-level agent principles and design justifications |
| **Component Sanity & Quality** | [docs/quality.md](docs/quality.md) | Quality checklists and coverage gap tracking |
| **Configuration Columns & Variables** | [docs/DATA_DICT.md](docs/DATA_DICT.md) | Variable listings, data formats, units |
| **Modeling Log & Assumptions** | [docs/MODEL_NOTES.md](docs/MODEL_NOTES.md) | Model experiments, assumptions, metric logs |
| **Feature Requirements Status** | [features.json](features.json) | List of core deliverables and their test states |
| **Session Session State Log** | [progress.md](progress.md) | Running log of what was built and current priorities |

---

## Preferred Workflows

For any analytical, modeling, or coding task taking longer than 30 minutes, you MUST follow the **Golden Path Developer Workflow** documented in [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md):
1. **Boot:** Run `bash init.sh` immediately at session start.
2. **Grill:** Invoke `/grill-with-docs` (general logic) or `/grill-analytics` (data/stats audits) to refine domain terms in `CONTEXT.md` and ADRs.
3. **Spec:** Invoke `/spec-model` to compile a formal design spec in `docs/design/` or `docs/MODEL_NOTES.md`.
4. **Slice:** Invoke `/to-issues` on your spec to compile independent vertical slices in `features.json`.
5. **Ship (TDD):** Invoke `/tdd` to execute and build tests first (Red-Green-Refactor). If debugging, use `/diagnose`.
6. **Verify:** Invoke `/validate-output` for statistical validation.
7. **Refactor:** Invoke `/improve-codebase-architecture` to deepen modules and decouple layers.
8. **Handoff:** Invoke `/handoff` to summarize session status in `progress.md`.

---

## Operating Protocols & Hard Rules

- **Orient Immediately:** Read `progress.md` at session start to understand the immediate state.
- **Run Bootstrapper:** Run `bash init.sh` immediately at session start. Do not change files if `init.sh` fails on the baseline.
- **No System Python:** Never execute direct unmanaged system `python`, `python3`, `pip`, or `pytest`. You must consistently run Python commands and test runners via `uv run` (e.g. `uv run python script.py`, `uv run pytest`) to ensure deterministic package loading from the managed virtual environment.
- **Log Transformations:** Every numerical or data frame transformation must print/log input and output shapes to the console.
- **Maintain Continuity:** Update `progress.md` at the end of every session detailing changes, files modified, and next actions.
- **Documentation Synchronisation Protocol:** Upon completing any implementation phase, model run, or feature slice:
  - Update `progress.md` and `features.json` to reflect the new state.
  - Sync architectural decisions to `docs/beliefs.md`.
  - Update any new variables or data schemas in `docs/DATA_DICT.md`.
  - Log model assumptions or backtest performance metrics in `docs/MODEL_NOTES.md`.
  - Keep `README.md` updated if directory layouts, bootstrapping steps, or main features change.
- **R Requirements:** Any new R function must include Roxygen2 comments and adhere to tidyverse conventions.
- **Write ADRs:** When making a hard-to-reverse architectural decision, write an ADR in `docs/adr/` using the next sequential ID (format: `docs/adr/000N-short-title.md`). Register it in `docs/beliefs.md`. Use `docs/adr/0000-adr-template.md` as your template.
- **First Session:** On your first session in this project, read `docs/adr/OPEN_DECISIONS.md` and begin backfilling domain ADRs for any decisions already made.

---

## Permissions & Safety Policies

*Note: Behavioral policy below is strictly enforced programmatically by `.agents/hooks.json` interceptors.*

- **Allowed Freely:** Reading any project files. Writing to `src/`, `notebooks/`, `tests/`, and temporary directories.
- **Requires Approval:** Deleting files, modifying `.agents/` or `config/` paths, installing system packages, and performing network requests.
- **Forbidden:** Force-pushing to main (`git push --force`), modifying `.git/` internals, and exposing `.env` secrets.
