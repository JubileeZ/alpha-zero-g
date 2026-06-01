# Session Handoff — Revamp Architecture Aligned & Setup Done
**Date:** 2026-06-01

This document summarizes the current alignment and setup accomplishments so the next AI agent can proceed directly to building the revamped Alpha-Zero-G MVP harness.

## Context & Accomplishments
We completed the preliminary design, grilling, and repository-level configurations for the Alpha-Zero-G revamp.

1. **Harness Dependency Flow**: Analyzed the task dependency graph in the session brain.
2. **Arch Decisions Aligned**: Conducted a thorough `/grill-with-docs` across all 7 revamp tasks, resolving the critical **No-Symlink Portability** strategy.
3. **Glossary Synced**: Updated the main [CONTEXT.md](CONTEXT.md) with technical definitions.
4. **Skills Standard Configured**: Ran the `/setup-matt-pocock-skills` command. Added the `## Agent skills` block to [AGENTS.md](AGENTS.md) and created `issue-tracker.md`, `triage-labels.md`, and `domain.md` under [docs/agents/](docs/agents/).
5. **Session Logs Updated**: Recorded progress in [progress.md](progress.md).

## What to Focus on Next
The next agent can begin directly with coding tasks 1-7 in order:
1. **Task 1 — Instruction Files**: Create templates under `templates/global/` and `templates/project/` using clean `@-import` syntax (no symlinks). Ensure files are lean (under 100 lines).
2. **Task 4 — Statusline Script**: Code `scripts/statusline.py` using Python 3 stdlib, with upward directory searching, git branch fallback, and robust `try/except` wrappers.
3. **Task 5 — Device Setup Scripts**: Write `scripts/setup-device.sh` and `setup-device.ps1` utilizing standard Python libraries to read, merge, and write `settings.json` resilience paths.
4. **Task 6 — Project Scaffolder**: Implement `scripts/scaffold-project.sh` and `.ps1` featuring selective source folder creation and non-empty folder safeguards.
5. **Task 7 — Project Upgrader**: Implement `scripts/upgrade-project.sh` and `.ps1` with audit, dry-run, and upgrade ADR triggers.

## Suggested Skills
- `/tdd` — Use test-driven development when building `statusline.py` and script utilities.
- `/improve-codebase-architecture` — Run after code build completion to ensure clean structural health.
