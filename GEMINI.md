# Alpha-Zero-G Override Rules — Antigravity

This file layers project-specific overrides onto the global `~/.gemini/GEMINI.md` configuration.

## Scope of Work & Harness Isolation
- [HARD] Alpha-Zero-G is a **meta-project** (a developer harness / golden standard framework). All code, examples, logs, and docs must remain generic, modular, and focused strictly on the harness itself.
- [HARD] Never reference specific downstream project instances, user-specific filesystem paths, or domain-specific development progress (such as particular FPL or crypto model runs, downstream folders, or machine-specific Google Drive roots) in this repository's progress logs or core documentation.

## Local Skills & Rules Setup
- [SOFT] If testing or modifying custom skills, keep them in `.agents/skills/` locally first to verify behavior before migrating them to global storage (`~/.gemini/antigravity/skills/`). Local skills override global skills of the same name.
- [SOFT] Supplemental workspace rules are organized modularly under `.agents/rules/*.md`. Refer to them for specific execution protocols.
