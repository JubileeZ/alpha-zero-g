# Current Implementation State

**Read this first** after `docs/AGENT-ONBOARDING.md`. `ROADMAP.md` is plan; this file is **what exists on disk today**.

**Active phase:** Phase 10 — Fable (opt-in sync; claim blocked)

---

## What exists

| Area | Path | Notes |
|------|------|-------|
| Evaluation Suite | `evals/` | 3 fixtures · core/baseline/`core+fable` · Blind Judge · compare-core-fable |
| CLI | `azg`, `lib/` | setup, new, apply, fable sync, update, uninstall |
| Eval tests | `tests/test-evals.sh` | Manifest + assertion sanity (workspace fail / reference pass) |
| Aggregate runner | `tests/run-all.sh` | shellcheck + Python verifiers + test-azg + host-contract + mutation + evals + phase suites |
| CI | `.github/workflows/ci.yml` | Ubuntu / macOS / Windows Git Bash · `AZG_STRICT=1` |
| Host-contract smoke | `tests/host-contract-smoke.sh` + `docs/agents/host-contract-smoke.md` | Deny→no side effect simulator + manual Cursor/agy steps |
| Mutation verify | `tests/test-mutation-verify.sh` | Each required path removed → verify fails |
| Portable gate | `templates/project/tests/verify.sh` | Harness integrity + optional project validation; denies `tmp_azg*` leaks |
| Work Packet | `templates/project/task.md.tmpl` | Objective, acceptance, SFDBN |
| Setup preflight | `lib/setup.sh` | `require_jq` before install |
| Cursor rules | `templates/project/.cursor/rules/*.mdc` | alwaysApply |
| Cursor hooks | `templates/project/.cursor/hooks.json` + adapters | beforeShellExecution → verify; failClosed |
| Antigravity hooks | `templates/project/.agents/hooks/` | commit-gate + spawn-budget on PreToolUse `START_SUBAGENT` |
| Checkpoint freshness | `commit-gate.sh` + Cursor `commit-verify.sh` | Code commits must stage `task.md` |
| Apply owned refresh | `lib/apply.sh` `azg_owned_refresh` | Hooks, Cursor adapters, verify.sh, spawn-budget; customs untouched |
| ADRs 0004–0006 | `docs/adr/` | Repo-native boundary; evidence-gated Fable; spawn-budget PreToolUse |
| Glossary | `CONTEXT.md` | Reliable Delivery terms |

---

## What does NOT exist yet

| Item | Phase | Notes |
|------|-------|-------|
| Evaluation Suite + paired pilot | 9 | Fixtures+runner+Blind Judge+Long-Horizon script exist; Phase 9 tooling complete; live held-out pairs + --apply-claim still required for claims |
| Fable as measured treatment | 10 | `azg fable sync` + `core+fable` compare matrix; default promotion blocked until claim |

---

## Safe commands today

| Command | What it does |
|---------|-------------|
| `bash tests/run-all.sh` | Full aggregate gate |
| `bash tests/run-all.sh --list` | Suite inventory |
| `bash evals/run-pair.sh <id> core\|baseline\|core+fable` | Prepare paired eval workdir |
| `bash evals/compare-core-fable.sh [id]` | Prepare core vs core+fable matrix |
| `bash tests/test-evals.sh` | Evaluation Suite structural tests |
| `bash tests/host-contract-smoke.sh` | Deny→no side-effect contract |
| `bash tests/test-mutation-verify.sh` | verify.sh mutation checks |
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
6. `SubagentStart` deny is observe-only on Antigravity — budget enforce is PreToolUse (ADR 0006).
