# Alpha-Zero-G — Roadmap

**Status:** v4 scaffolding complete · Phases 7–8 done · **Active: Phase 9 — Core Pilot**

> Zero-context: [`docs/AGENT-ONBOARDING.md`](docs/AGENT-ONBOARDING.md) · Spec: [`docs/REVAMP-SPEC.md`](docs/REVAMP-SPEC.md) · Reality: [`docs/agents/current-state.md`](docs/agents/current-state.md) · Glossary: [`CONTEXT.md`](CONTEXT.md)

---

## Vision

Reliable Delivery: higher Task Success per Delivery Cost than No-Harness Baseline, with Minimal Setup, across devices and Cursor/Antigravity. Repo-native gates own guarantees; IDE hooks are thin adapters. Fable optional until evidence.

ADRs: [`0004-repo-native-reliability-boundary`](docs/adr/0004-repo-native-reliability-boundary.md) · [`0005-evidence-gated-fable-adoption`](docs/adr/0005-evidence-gated-fable-adoption.md)

---

## Phase 0–6 — v4 Revamp (complete)

Harness-only templates, hooks, apply/setup profiles, tests, VERSION 4.0.x. Details: archived checklists in git history / REVAMP-SPEC.

---

## Phase 7 — Portable Core (complete)

`tests/verify.sh` gate · Work Packet + Checkpoint freshness · setup `jq` preflight · Cursor `.mdc` + hooks adapters · `azg apply` creates task/Cursor + refreshes AZG-owned hooks/rules/verify. Tests: `bash tests/test-phase10.sh` (+ `test-phase7.sh`).

---

## Phase 8 — Evidence Trustworthy (complete)

Aggregate `tests/run-all.sh` + CI matrix · host-contract smoke (`tests/host-contract-smoke.sh` + manual doc) · spawn-budget on PreToolUse (ADR 0006) · mutation verify (`tests/test-mutation-verify.sh`).

---

## Phase 9 — Core Pilot

- [x] Evaluation Suite fixtures: 3 fixed tasks (bugfix, scoped change, regression-prone feature)
- [x] Paired No-Harness Baseline runner + scorecard (Task Success, Delivery Cost, wall time, interventions)
- [x] Blind Judge wiring (fixed independent model; human calibration notes)
- [x] Long-Horizon Task script: fresh context + clean-device clone + Cursor↔Antigravity handoff
- [x] Pilot run (exploratory only) + preregister confirmation thresholds/sample size
- [ ] Held-out confirmation before any reliability claim

---

## Phase 10 — Fable (optional treatment)

Blocked until Phase 9 held-out confirmation green.

- [ ] Bundle Fable skills as opt-in project skills (`azg fable sync`)
- [ ] Compare core vs core+Fable on same Evaluation Suite
- [ ] Promote to default only if Task Success / Delivery Cost improves without portability regression
- [ ] Issues #52–#55 reopened/retargeted only after this gate

---

## Explicitly deferred

Stack wizard · full GitHub MCP default · blocking PreCompact · statistical Fable mandate · SWE-bench as primary signal

---

> **Pre-commit gate:** `bash tests/run-all.sh` (or `shellcheck` + `test-azg` + affected phase tests) must pass before proposing commits. Project clients: `bash tests/verify.sh`.
