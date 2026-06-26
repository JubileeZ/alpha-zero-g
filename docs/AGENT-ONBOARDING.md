# Agent Onboarding — Zero Context Start

You have **no chat history**. Use **only** the files below to understand what Alpha-Zero-G is and what to build.

## Read order

1. **This file** — orientation (you are here)
2. [`docs/REVAMP-SPEC.md`](REVAMP-SPEC.md) — **canonical** v4 design (what we are building)
3. [`ROADMAP.md`](../ROADMAP.md) — phased checklist (in what order)
4. [`docs/agents/current-state.md`](agents/current-state.md) — what already exists vs gaps

Optional during implementation:

- [`docs/agents/progress.md`](agents/progress.md) — how to update work-state files
- [`AGENTS.md`](../AGENTS.md) — commands, safety, pre-commit gate for **this repo**

## One-paragraph summary

Alpha-Zero-G v4 revamps the project from a **v3 production-complete CLI** into a **budget-conscious, multi-IDE agent harness** that ships harness-only project templates (no app stack), filesystem work-state for cross-device continuity, GitHub-as-default issue adapter (with `gh`, not MCP by default), nine curated global skills + ponytail global rule, and four project hooks (safety, commit-gate, Stop checkpoint, spawn budget). Implementation follows `ROADMAP.md` phases; spec details are in `REVAMP-SPEC.md`.

## Before writing code

1. Read `current-state.md` — do not rebuild what exists.
2. Pick the **first unchecked** item in the active `ROADMAP.md` phase.
3. Run verify commands from `AGENTS.md` before proposing commits.

## What NOT to read for orientation

- `docs/archive/*` — historical only
- `docs/antigravity-agent-architect/*` — reference material; may contradict v4 spec
- `docs/ALPHA-ZERO-G-V3-PLAN.md` — moved to archive; superseded
