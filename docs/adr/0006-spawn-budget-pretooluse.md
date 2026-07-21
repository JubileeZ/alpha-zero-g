# ADR 0006 — Spawn-budget blocks on PreToolUse, not SubagentStart

## Status

Accepted

## Context

Antigravity hook table: `SubagentStart` **cannot** block. Deny JSON on that event is observe-only. Template previously wired `spawn-budget.sh` only on `SubagentStart`, so budget limits could not prevent spawns on hosts that follow that table.

Subagent spawn appears as tool `START_SUBAGENT` (Antigravity SDK); `PreToolUse` **can** deny.

## Decision

1. Enforce `spawn-budget.sh` on `PreToolUse` matcher `START_SUBAGENT` (and aliases `task|Task|spawn_subagent` for host variance).
2. Keep `SubagentStart` hook as optional observe/compat — same script may run, but **blocking guarantee** is PreToolUse only.
3. `SessionStart` still resets via `spawn-budget.sh --reset`.

## Consequences

- Deny on budget exceed is host-enforceable where PreToolUse is honored.
- Double-fire (Start + PreToolUse) may increment twice on some hosts — accept for now; prefer PreToolUse-only increment if observed in smoke (`ponytail:` ceiling → single-event accounting).
- Manual host-contract smoke should include a spawn-over-budget case when agy available.
