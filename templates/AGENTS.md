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
| **Coding Conventions** | [docs/conventions.md](docs/conventions.md) | Guidelines, types, docstrings, cross-platform code examples |
| **Data Handling Rules** | [docs/data-rules.md](docs/data-rules.md) | Numerical and DataFrame schema validations and checks |
| **Statistical Modeling Rules** | [docs/modeling-rules.md](docs/modeling-rules.md) | Testing baselines, splits, assumptions, metric evaluation |
| **Token & Context Management** | [docs/context-management.md](docs/context-management.md) | Token optimizations and context health limits |
| **Session Protocols** | [docs/session-protocols.md](docs/session-protocols.md) | Protocols for beginning and ending isolated active sessions |
| **Testing Requirements** | [docs/testing-requirements.md](docs/testing-requirements.md) | Testing tables, matrices, coverages, and commands |
| **Security Rules** | [docs/security-rules.md](docs/security-rules.md) | Payload isolation, credentials, and rule of two policies |
| **Domain Rules** | [docs/domain-rules.md](docs/domain-rules.md) | Custom downstream modeling boundaries |
| **Permissions & Safety Policies** | [docs/safety-policies.md](docs/safety-policies.md) | Allowed, gated, or forbidden execution levels |

---

## Preferred Workflows

For any analytical, modeling, or coding task taking longer than 30 minutes, you MUST follow the **Golden Path Developer Workflow** documented in [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md):
1. **Boot:** Run `bash init.sh` immediately at session start.
2. **Grill:** Stress-test ideas using `/grill-with-docs` or `/grill-analytics`.
3. **Spec:** Propose formal design specification inside `docs/design/` or `docs/MODEL_NOTES.md`.
4. **Slice:** Break the approved design down into vertical slices in `features.json`.
5. **Ship (TDD):** Execute test-driven development loop one slice at a time.
6. **Verify:** Perform post-modeling validation checks.
7. **Refactor:** Deepen modules, decouple layers, and ensure green tests.
8. **Handoff:** Update `progress.md` to summarize milestones and next steps.

---

## Workspace Rules Activation (.agents/rules/)

We utilize concern-specific rules inside `.agents/rules/` for context-aware execution:
1. **Workflows Loop** ([workflows.md](.agents/rules/workflows.md)): The strict Grill-Spec-Slice-Ship-Refactor loop.
2. **Environment & Testing** ([python-r-rules.md](.agents/rules/python-r-rules.md)): Standards for Python (`uv run`), testing, data transformations, and R.
3. **Common Pitfalls** ([gotchas.md](.agents/rules/gotchas.md)): Pitfalls list to prevent common AI failures.

---

## Operating Protocols & Hard Rules

- **Orient Immediately:** Read `progress.md` at session start to grasp the current state.
- **Run Bootstrapper:** Run `bash init.sh` at session start and abort if it fails.
- **No System Python:** Always run Python commands and test runners via `uv run` to ensure virtual environment isolation.
- **Log Transformations:** Print input and output shapes for every numerical or dataframe transformation.
- **Maintain Continuity:** Update `progress.md` with detailed changes and next steps before ending the session.
- **Documentation Sync:** Keep `progress.md`, `features.json`, `docs/beliefs.md`, `docs/DATA_DICT.md`, `docs/MODEL_NOTES.md`, and `README.md` continuously synchronized.
- **R Requirements:** Adhere to tidyverse conventions and include Roxygen2 comments for all new R functions.
- **Write ADRs:** Document irreversible design choices in `docs/adr/` and register them in `docs/beliefs.md`.
- **First Session:** Read `docs/adr/OPEN_DECISIONS.md` on your first session to backfill domain ADRs.
- **Portable Markdown Linking (ADR-0007):** [HARD] Never write absolute `file:///` URLs or local filesystem paths in rule files (`AGENTS.md`, `GEMINI.md`) or documentation; always use relative Markdown links.
