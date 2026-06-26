# Alpha-Zero-G — v4 Revamp Roadmap

**Status:** v3 CLI complete on disk · **v4 revamp in progress**

> **Agents with no context:** read [`docs/AGENT-ONBOARDING.md`](docs/AGENT-ONBOARDING.md) then [`docs/REVAMP-SPEC.md`](docs/REVAMP-SPEC.md).  
> **What exists today:** [`docs/agents/current-state.md`](docs/agents/current-state.md)

---

## Vision (v4)

Ship a **clone-and-go outer harness** for solo/small teams: harness-only templates, filesystem work-state, GitHub-default adapter, nine global skills, ponytail global rule, four hooks, multi-IDE layered config — without burning tokens on MCP schemas or encyclopedic `AGENTS.md`.

---

## Personas

| Persona | Goal | Surface |
|---------|------|---------|
| Solo / small-team developer | Reliable agents across devices & IDEs | `azg setup` + `azg new` / `azg apply` |
| AI agent | Implement revamp from spec | This repo + onboarding docs |
| Alpha-Zero-G maintainer | Vendor skills, pin `VENDOR.lock` | `azg update --vendor` |

---

## Phase 0 — Documentation & alignment (complete)

- [x] Canonical v4 spec — `docs/REVAMP-SPEC.md`
- [x] Agent onboarding path — `docs/AGENT-ONBOARDING.md`
- [x] Gap analysis — `docs/agents/current-state.md`
- [x] Archive superseded v3 plan — `docs/archive/V3-PLAN.md`
- [x] Subagent comprehension test passes (two independent agents, same build plan)
- [x] `python3 tests/verify_docs.py` passes
- [x] Update root `README.md` for v4 messaging

---

## Phase 1 — Project template (harness-only) (complete)

- [x] `azg new` scaffolds **harness only** — remove stack/lint wizard questions
- [x] Add templates: `task.md.tmpl`, `session-handoff.md.tmpl`, `CONTEXT.md.tmpl`, `ROADMAP.md.tmpl` (empty phases)
- [x] Pre-seed in `templates/project/docs/agents/`: `issue-tracker.md`, `triage-labels.md`, `domain.md` (GitHub default)
- [x] Thin project `AGENTS.md.tmpl` managed block per REVAMP-SPEC §5
- [x] Add `tests/test-harness.sh` template + wire into project template
- [x] `.vscode/settings.json` in project template (terminal cwd)
- [x] Phase test: `bash tests/test-phase<N>.sh` (new or extended)

---

## Phase 2 — Hooks

- [ ] `commit-gate.sh` — block `git commit` until harness test passes
- [ ] `checkpoint.sh` — Stop hook; stale `current-state.md` / handoff → continue loop
- [ ] `spawn-budget.sh` + `.agents/spawn-budget.json` (`max_spawns: 3`, `max_depth: 2`)
- [ ] Cursor: `preCompact` observability hook (log only, no block)
- [ ] Update `hooks.json` template for Antigravity + Cursor hook paths
- [ ] shellcheck + integration tests for all hooks

---

## Phase 3 — `azg apply` / merge

- [ ] `azg apply --dry-run` shows managed-block diff
- [ ] `azg apply --tracker github|gitlab|local|none` selects adapter template
- [ ] Idempotent re-apply upgrades AZG managed sections only
- [ ] Remove scaffold Q4 dependency on manual `setup-matt-pocock-skills` for GitHub default

---

## Phase 4 — Global setup (minimal profile)

- [ ] `azg setup --profile minimal` (default) — 9 skills only
- [ ] `azg setup --profile full` — entire vendored catalog
- [ ] Smart skill sync: copy only when `VENDOR.lock` commit differs from last setup stamp
- [ ] MCP template: `gh` default docs; commented read-only GitHub MCP stub
- [ ] Document update ritual in README

---

## Phase 5 — Tests & verification

- [ ] Extend `test-azg.sh` for harness-only `azg new`
- [ ] Test commit-gate and spawn-budget hooks in isolated HOME
- [ ] `verify_docs.py` includes new doc paths
- [ ] Cross-platform note in AGENTS.md for Windows Git Bash

---

## Phase 6 — Cleanup

- [ ] README reflects v4 onboarding (two-step ritual)
- [ ] Bump `VERSION` to 4.0.0 when phases 1–5 complete
- [ ] ADR for v4 harness-only pivot if needed

---

## Explicitly deferred (v4.1+)

See REVAMP-SPEC §11: stack wizard, extra tracker adapters, full GitHub MCP default, optional skills pack, blocking PreCompact.

---

> **Pre-commit gate:** `shellcheck azg lib/*.sh tests/*.sh` and `bash tests/test-azg.sh` (plus affected phase tests) must pass before proposing commits.
