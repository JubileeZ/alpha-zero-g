# Current Implementation State

**Read this first** after `docs/AGENT-ONBOARDING.md`. `ROADMAP.md` is plan; this file is **what exists on disk today**. Current truth only — historical dumps → `docs/archive/` (see `docs/agents/progress.md`).

**Active phase:** post-v4 — Lite **deleted**; **Behavior Corpus** live (ADR 0019, 12 Executor Traps); Principles Treatment **v2** shipped (ADR 0021); Candidate slot empty

---

## What exists

| Area | Path | Notes |
|------|------|-------|
| CLI | `azg`, `lib/` | setup (curated active core incl. `retro` + transitive deps), skill list/enable/disable, new, apply, update (--vendor), selective uninstall; **`azg_python`** |
| Statusline | `templates/global/statusline.sh` | Adaptive single-line statusline; dynamic multi-quota discovery (`argon`, `gemini`, `3p`), active-first cluster, pace-aware weekly surfacing, timer-preserving truncation (ADR 0001) |
| Skills Catalog | `templates/global/skills/vendor/` | `mattpocock-skills` only (VENDOR.lock pin `49dd158`; adds `implement-spec`, `pr`, `retro`; removes `resolving-merge-conflicts`; catalog-only by default) |
| Active Skills Manifest | `${AZG_GLOBAL_DIR}/azg-skills.json` | Declarative active set; 1:1 `~/.gemini/config/skills/` and `~/.cursor/skills/` |
| Ownership | `azg-ownership.json` under global dir | ADR 0008 |
| Checkpoint | commit-gate at `git commit` | Work Packets under `.agents/work-packets/`. Stop/PreCompact **retired**. Cursor wires `block-destructive-ops` on `beforeShellExecution` (was agy-only) |
| Cursor hook launch | `.cursor/hooks/run-hook.cmd` | Polyglot; **must be executable on Unix** (`100755`); hooks.json cites basename only |
| Cursor device setup | `azg setup` → `~/.cursor/skills` + rendered `azg-*.mdc` | ADR 0008; marker validation hard-fails; foreign-safe |
| Candidate slot | `templates/candidates/` | Empty after v2 promote (ADR 0021). Live Device Setup = Principles v2 |
| Azg-owned skills | `templates/global/skills/azg/` | `azg-domain-data-analysis` + `azg-domain-research`. `judge`/`orchestrate` deferred |
| Evaluation Suite | `evals/traps/scenarios/` + `score_outcome.py` + runners + docker | ADR 0012+0013 machinery; **0019** Behavior Corpus |
| Aggregate / CI | `tests/run-all.sh`, `.github/workflows/ci.yml` | **ubuntu + macos** only; **no** `test-lite`; `azg_python` |
| Portable gate | `templates/project/tests/verify.sh` | Harness integrity |
| ADRs | `docs/adr/` | **0024** Skills safety boundary; **0023** Work Packet safety; **0022** Work Packets + Stop retired; **0021** Principles v2; **0019** Behavior Corpus |
| Glossary | `CONTEXT.md` | |
| Lean continuity | `AGENTS.md` Session start | Always-on lean set |
| Project skills | `.agents/skills/progress-updates` + matching `.cursor/rules/*.mdc` | Agent-requestable |
| Research | `docs/research/` | Historical grill notes — not always-on |

---

## Grill decisions (done)

| Gap | Done |
|-----|------|
| Trap / eval | ADR 0012+0013 runners; **0019** Behavior Corpus (Outcome, not fable format) |
| Always-on | Principles v2 shipped (0021). Authority open-rank-edit; Twin Sweep every-hit; no Intent Tie heading |
| Lite | Removed 2026-08-07 — ADR 0007 superseded |
| EP layering | ADR 0017 — no auto-Orchestrate / no fraud catalogue in always-on |

---

## What does NOT exist yet

| Item | Notes |
|------|-------|
| Next Candidate Treatment | Slot empty. Last promote: Principles v2 ADR 0021 (`gate-principles-v2` R=5 **RECOMMEND_ADOPT**). s2 + s13 still corpus ceilings |
| `judge` / `orchestrate` Device skills | Deferred — not in global |
| SWE-bench Lite harness | **Deleted** — do not restore without new ADR |

Delivery Cost auto-capture: parked / out of scope (never a promote input).

---

## Safe commands today

| Command | What it does |
|---------|-------------|
| `bash tests/run-all.sh` | Full aggregate gate |
| `bash evals/traps/run-process-gate.sh` | Process Gate. Corpus = `evals/traps/scenarios/` (ADR 0019) |
| `./azg setup` / `./azg setup --force` | Install Device Setup |
| `bash evals/analyze-trap-ledger.sh <parent>` | `LEDGER.md` + recommend |
| `bash evals/prepare-trap-campaign.sh` | Stub N×3 scorecards |
| `bash evals/run-trap-campaign.sh --jobs 14 --arm ARM` | Parallel scenarios for one arm |
| `./azg setup --dry-run` | Preview global install (needs `jq`) |

---

## Agent pitfalls

1. Mock `HOME` in tests — setup writes under `~/.gemini/`.
2. Foreign MCP/AGENTS/custom skills skipped unless `--force`.
3. Subagent fan-out limits are host-default only (spawn-budget retired ADR 0011).
4. Harness counters do not cross Bash subshells.
5. `run-hook.cmd` without `+x` breaks Cursor `commit-verify` on macOS/Linux — restore after checkout/merge.
6. **CI macOS bash 3.2:** no Bash 4-only builtins in `lib/`.
7. Smart sync skips vendor skill copy when `VENDOR.lock` unchanged — empty skills need `./azg setup --force`.
8. **Windows `azg apply`:** CRLF-only diffs possible — `git restore` if needed.
9. Vendor prune: azg skills = dirs under `templates/global/skills/azg/`.
10. **Windows eval Python:** Store `python3` stub → use `azg_python`. Empty `TRAP_FULL` = unset for full corpus default.
11. **Windows jq manifest:** jq may emit `\r` on skill names — `_get_requested_skills` strips CR before lookup/install.
12. **Windows ledger UTF-8:** `analyze_ledger.py` must `write_text(..., encoding="utf-8")` (`≥` in LEDGER.md).
13. **No Lite** — `evals/lite/` gone. Behavior Corpus = `evals/traps/scenarios/` + `score_outcome.py`.
14. **Eval staged home** — `stage-eval-home.sh` renders Principles + cleanup + telegraphic + domain skills; `test-eval-isolation.sh` asserts that shape.
