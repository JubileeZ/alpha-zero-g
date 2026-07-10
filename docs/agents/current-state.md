# Current Implementation State

**Read this first** after `docs/AGENT-ONBOARDING.md`. `ROADMAP.md` is the plan; this file is **what exists on disk today** vs what v4 still needs.

**Active phase:** None (v4 Revamp complete)

---

## What exists (v3 — keep & extend)

| Area | Path | Notes |
|------|------|-------|
| CLI dispatcher | `azg` | setup, new, apply, update, uninstall |
| Implementation | `lib/` | common, setup, scaffold, apply, update, vendor-sync, apply-overlay |
| Templates | `templates/global/`, `templates/project/` | Global skills vendor tree, ponytail managed block, partial project harness |
| Vendor sync | `lib/vendor-sync.sh`, `VENDOR.lock` | Pins mattpocock + ponytail upstream |
| Core setup profile | `lib/setup.sh` | `azg setup --profile core` (default) installs 11 core skills |
| Smart setup sync | `lib/setup.sh` | Skips skill copying if `VENDOR.lock` commits unchanged |
| apply --tracker flag | `lib/apply.sh` | `--tracker github|gitlab|local|none` selects issue adapter template |
| Safety hook | `templates/project/.agents/hooks/block-destructive-ops.sh` | Shipped |
| Tests | `tests/test-azg.sh`, `test-phase0`–`test-phase9` | v3 phase coverage |
| Agent docs | `docs/agents/progress.md`, issue-tracker, triage-labels, domain | Present for **this** repo; now pre-seeded in project template |
| Revamp spec | `docs/REVAMP-SPEC.md`, `docs/AGENT-ONBOARDING.md` | v4 canonical docs |
| Harness-only `azg new` | `lib/scaffold.sh` | Non-interactive project scaffolding with no stack questions |
| Project templates | `templates/project/` | New `task.md.tmpl`, `.agents/session-handoff.md.tmpl`, `docs/agents/CONTEXT.md.tmpl` templates |
| VSCode Workspace Settings | `templates/project/.vscode/settings.json` | Windows-safe terminal profile configuration |
| Project self-check harness | `templates/project/tests/test-harness.sh` | Verification self-check for client project |
| Thin project `AGENTS.md.tmpl` | `templates/project/AGENTS.md.tmpl` | Split user prose and updated managed block (~80 lines) |
| commit-gate.sh hook | `templates/project/.agents/hooks/commit-gate.sh` | Intercepts git commit and runs tests |
| checkpoint.sh hook | `templates/project/.agents/hooks/checkpoint.sh` | Stop event hook checking for work-state updates |
| spawn-budget.sh hook | `templates/project/.agents/hooks/spawn-budget.sh` | subagentStart event hook enforcing spawns & depth |
| pre-compact.sh hook | `templates/project/.agents/hooks/pre-compact.sh` | PreCompact context compaction notice |

---

## What does NOT exist yet (v4 gaps — do not assume built)

| None | - | All v4 spec features implemented |

---

## Safe commands today

| Command | What it does |
|---------|-------------|
| `shellcheck azg lib/*.sh tests/*.sh` | Lint Bash |
| `bash tests/test-azg.sh` | General integration tests |
| `bash tests/test-phase<N>.sh` | Phase-specific tests |
| `python3 tests/verify_docs.py` | Doc link verification |
| `./azg setup --dry-run` | Preview global install |
| `./azg apply --dry-run <dir>` | Preview project apply (if supported) |

---

## Agent pitfalls

1. Mock `HOME` in tests — `azg setup` writes `~/.gemini/antigravity-cli/`.
2. Do not assume v4 hooks exist — only `block-destructive-ops.sh` is in the project template today.
3. `docs/antigravity-agent-architect/hook-architecture.md` lists PreCompact for Antigravity — **wrong** per official docs; v4 uses Stop checkpoint instead.
4. README still describes v3 stack wizard — trust `REVAMP-SPEC.md` over README until Phase 6.

---

## Doc map

| Question | Read |
|----------|------|
| Zero context | `docs/AGENT-ONBOARDING.md` |
| What to build | `docs/REVAMP-SPEC.md` |
| Phases | `ROADMAP.md` |
| This file | `docs/agents/current-state.md` |
| Progress ritual | `docs/agents/progress.md` |
| Glossary | `CONTEXT.md` (this repo) |
