# Current Implementation State

**Read this first** after `docs/AGENT-ONBOARDING.md`. `ROADMAP.md` is plan; this file is **what exists on disk today**.

**Active phase:** Phase 10 **parked** — Fable opt-in/experimental; no default promote (cost untracked + claim false)

---

## What exists

| Area | Path | Notes |
|------|------|-------|
| CLI | `azg`, `lib/` | setup, new, apply, fable sync, update, uninstall |
| Evaluation Suite | `evals/` | 3 fixtures · core/baseline/`core+fable` · Blind Judge · compare |
| Fable opt-in | `templates/optional/fable/`, `lib/fable.sh` | Stub skills; `--experimental` until claim |
| Live compare | `evals/pilot/LIVE-AGENT-COMPARE.md` | How-to; resume when cost trackable |
| Live log | `evals/pilot/live-compare-log.md` | bug-fix both arms OK; cost n/a |
| Smoke artifact | `evals/pilot/compare-core-fable-smoke.json` | Reference fix; not a claim |
| Aggregate / CI | `tests/run-all.sh`, `.github/workflows/ci.yml` | AZG_STRICT matrix; LF + shellcheck -S error |
| Portable gate | `templates/project/tests/verify.sh` | Harness integrity |
| ADRs 0004–0006 | `docs/adr/` | Repo-native · evidence-gated Fable · spawn-budget |
| Glossary | `CONTEXT.md` | Reliable Delivery terms |

---

## What does NOT exist yet

| Item | Notes |
|------|-------|
| Reliability claim | Need confirmation+held-out + `--apply-claim` |
| Fable default in core profile | Parked — need Delivery Cost + claim + live deltas |
| Real Fable upstream | Stub `fable-loop` only; `AZG_FABLE_UPSTREAM` TBD |
| Delivery Cost capture | Operator has no token/spend tracking yet |

---

## Safe commands today

| Command | What it does |
|---------|-------------|
| `bash tests/run-all.sh` | Full aggregate gate |
| `bash evals/run-pair.sh <id> core\|baseline\|core+fable` | Prepare eval workdir |
| `bash evals/compare-core-fable.sh [id]` | Prepare core vs core+fable |
| `bash evals/run-compare-smoke.sh` | Reference smoke (non-claim) |
| `bash tests/test-evals.sh` | Suite structural tests |
| `./azg fable sync DIR --experimental` | Opt-in Fable stubs into project |
| `./azg setup --dry-run` | Preview global install (needs `jq`) |

---

## Agent pitfalls

1. Mock `HOME` in tests — setup writes under `~/.gemini/`.
2. `jq` required for setup/apply; Windows Git Bash may need WinGet Links on `PATH`.
3. Do not promote Fable without Delivery Cost + held-out claim (ADR 0005).
4. Live solves: open `run-pair` WORKDIR, not harness repo root.
5. `azg apply` refreshes AZG-owned files; custom hooks/skills not in template stay.
6. Spawn-budget enforce is PreToolUse (ADR 0006), not SubagentStart.
