# Agent Harness — Alpha-Zero-G

This file is the primary entry point and cognitive map for AI agents working in this repository.

## What This Project Is
Alpha-Zero-G is a foundational meta-project designed to test and establish the golden standard for AI-assisted software and analytics development workflows. It contains reference settings, custom skills, hooks, and documentation intended to be cloned as a boilerplate for future analytical and trading pipelines.

---

## System Pointers (Where to Find Information)

| Query / Need                             | File Path                                                 | Scope & Contents                                      |
| ---------------------------------------- | --------------------------------------------------------- | ----------------------------------------------------- |
| **Domain Jargon & Glossary**             | [CONTEXT.md](CONTEXT.md)                                 | Domain definitions and foundational terms             |
| **System Layers & Architecture**         | [docs/architecture.md](docs/architecture.md)             | Rules priority flow, layout rationale, and directory mappings |
| **Philosophical Guidelines**            | [docs/beliefs.md](docs/beliefs.md)                       | High-level agent principles and design ADR registers  |
| **Component Sanity & Quality**           | [docs/quality.md](docs/quality.md)                       | Quality checklists and coverage gap tracking          |
| **Configuration Columns & Schema**        | [docs/DATA_DICT.md](docs/DATA_DICT.md)                   | Variable listings, formats, and data schemas          |
| **Modeling Log & Metrics**               | [docs/MODEL_NOTES.md](docs/MODEL_NOTES.md)               | Model experiments, assumptions, metric logs           |
| **Feature Requirements Status**          | [features.json](features.json)                           | List of core deliverables and their test states       |
| **Session Session State Log**            | [progress.md](progress.md)                               | Running log of what was built and current priorities  |

---

## Workspace Rules Activation (.agents/rules/)
We have migrated concern-specific execution rules to the modular rule system inside `.agents/rules/` to ensure clean, actionable, and context-aware execution:

1. **Workflows Loop** ([workflows.md](.agents/rules/workflows.md)): The strict Grill-Spec-Slice-Ship-Refactor loop. `Always On`.
2. **Environment & Testing** ([python-r-rules.md](.agents/rules/python-r-rules.md)): Standards for Python (`uv run`), testing, data transformations, and R. Activated on python/R file extensions (`Glob`).
3. **Common Pitfalls** ([gotchas.md](.agents/rules/gotchas.md)): A dynamic gotchas list to prevent common AI failures. Activated by `Model Decision`.

---

## Harness Isolation Boundary
- [HARD] Never reference downstream project instances, user-specific directories, or local domain data runs in this harness's progress logs or code. All harness examples and code must remain strictly generic, modular, and host-agnostic.
