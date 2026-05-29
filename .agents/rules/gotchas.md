---
name: gotchas
description: Critical pitfalls and common AI mistakes to avoid in this repository harness.
activation: Model Decision
---
# Repository Pitfalls & Gotchas

This file tracks the most frequent mistakes made by AI agents when modifying this codebase. Review these rules during any implementation.

## 1. Downstream Context & Naming Leakage
- [HARD] Never reference downstream project names (e.g., FPL-Jubilee-Ascent, crypto-analytics-live, etc.) in the progress logs, commit messages, or harness documentation. Alpha-Zero-G is a pure, generic boilerplate harness. All files must remain 100% agnostic.

## 2. Direct Modifications of Symlinked Paths
- [HARD] Never modify files directly in the active home configuration directory `~/.gemini/` or `C:\Users\Jubilee\.gemini\`.
- [HARD] All changes to global rules, settings, or custom skills must be made in the monorepo source directory `global/` (e.g., `global/GEMINI.md`, `global/config/config.json`) and synchronized via `setup-harness.sh`. Direct modifications in home will break the git-native tracking model.

## 3. Direct Python or R Invocations
- [HARD] Do not use raw system python or pip commands. Always run them via `uv run` to ensure virtualenv consistency.

## 4. ADR Formatting & Registration
- [HARD] Any architectural decision must be registered in the ADR directory (`docs/adr/`) using the sequential ID format `docs/adr/000N-short-title.md` and using the template `docs/adr/0000-adr-template.md`.
- [HARD] You must list/register any new ADR in `docs/beliefs.md` immediately upon creation.

## 5. Session State Tracking
- [HARD] You must update `progress.md` at the end of every active work session, capturing the precise state, files changed, and next steps for the incoming agent.

## 6. Portable Markdown Linking
- [HARD] NEVER use absolute `file:///` URLs or local filesystem paths in rule files (`AGENTS.md`, `GEMINI.md`) or documentation.
- [HARD] All references, guides, and pointer links must use standard, relative Markdown links (e.g., `[workflows.md](.agents/rules/workflows.md)`) to maintain platform portability across different operating systems, folder hierarchies, and devices, strictly conforming to ADR-0007.
