# Current Implementation State

**Read this first** after `docs/AGENT-ONBOARDING.md`. `ROADMAP.md` is plan; this file is **what exists on disk today**.

**Active phase:** Phase 8 — Evidence Trustworthy

---

## What exists

| Area | Path | Notes |
|------|------|-------|
| CLI | `azg`, `lib/` | setup, new, apply, update, uninstall |
| Portable gate | `templates/project/tests/verify.sh` | Harness integrity + optional project validation |
| Work Packet | `templates/project/task.md.tmpl` | Objective, acceptance, SFDBN |
| Setup preflight | `lib/setup.sh` | `require_jq` before install |
| Cursor rules | `templates/project/.cursor/rules/*.mdc` | alwaysApply |
| Cursor hooks | `templates/project/.cursor/hooks.json` + adapters | beforeShellExecution → verify; stop reminder |
| Antigravity hooks | `templates/project/.agents/hooks/` | commit-gate calls verify.sh |
| Checkpoint freshness | `commit-gate.sh` + Cursor `commit-verify.sh` | Code commits must stage `task.md` |
| Apply owned refresh | `lib/apply.sh` `azg_owned_refresh` | Hooks, Cursor adapters, verify.sh, spawn-budget; customs untouched |
| hooks.json merge | `lib/apply.sh` | `existing * template` — template enables safety-gate |
| Phase 10 tests | `tests/test-phase10.sh` | verify, Work Packet, preflight, Cursor, apply, Checkpoint |
| ADRs 0004–0005 | `docs/adr/` | Repo-native boundary; evidence-gated Fable |
| Glossary | `CONTEXT.md` | Reliable Delivery terms |

---

## What does NOT exist yet

| Item | Phase | Notes |
|------|-------|-------|
| Aggregate CI matrix | 8 | No workflow; install `jq` on Windows for apply tests |
| Real host hook smoke | 8 | Synthetic JSON only |
| Paired core vs no-harness pilot | 9 | No outcome evidence |
| Fable as measured treatment | 10 | Issues #52–55 paused |

---

## Safe commands today

| Command | What it does |
|---------|-------------|
| `bash tests/test-phase10.sh` | Phase 7 portable-core tests |
| `bash tests/test-azg.sh` | Integration (needs `jq` for apply paths) |
| `bash tests/test-phase<N>.sh` | Phase tests |
| `python3 tests/verify_docs.py` | Doc links |
| `./azg setup --dry-run` | Preview global install (requires `jq`) |

---

## Agent pitfalls

1. Mock `HOME` in tests — setup writes under `~/.gemini/`.
2. `jq` required for `azg setup` and `azg apply` — install before those commands.
3. Cursor Stop cannot hard-deny; Checkpoint durability is git commit + Work Packet.
4. Fable issues #52–55 paused until Phase 9 confirmation (ADR 0005).
5. `azg apply` refreshes AZG-owned files from template; custom hooks/skills not in template stay.

---
