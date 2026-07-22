# Alpha-Zero-G — Roadmap

**Status:** v4 complete · Phases 7–9 tooling done · **Phase 10 parked** (Fable opt-in only; no default promote)

> Zero-context: [`docs/AGENT-ONBOARDING.md`](docs/AGENT-ONBOARDING.md) · Spec: [`docs/REVAMP-SPEC.md`](docs/REVAMP-SPEC.md) · Reality: [`docs/agents/current-state.md`](docs/agents/current-state.md) · Glossary: [`CONTEXT.md`](CONTEXT.md)

---

## Vision

Reliable Delivery: higher Task Success per Delivery Cost than No-Harness Baseline, with Minimal Setup, across devices and Cursor/Antigravity. Repo-native gates own guarantees; IDE hooks are thin adapters. Fable optional until evidence.

ADRs: [`0004-repo-native-reliability-boundary`](docs/adr/0004-repo-native-reliability-boundary.md) · [`0005-evidence-gated-fable-adoption`](docs/adr/0005-evidence-gated-fable-adoption.md)

---

## Phase 0–9 — complete

v4 harness · Portable Core · Evidence (`run-all` + CI) · Core Pilot suite (fixtures, Blind Judge, Long-Horizon, prereg/held-out gate). Claim only after confirmation+held-out + `--apply-claim`.

---

## Phase 10 — Fable (parked)

Opt-in only. **No default promotion** until Delivery Cost measurable + held-out claim (`reliability_claim_allowed`) + live deltas favor core+fable (ADR 0005).

Done: `azg fable sync --experimental` · `core+fable` treatment · compare/smoke · one live `bug-fix` pair (assertions OK, cost n/a).

Parked: promote to default · further live pairs optional (process only).

Issues **#52–#55** closed as not planned (parked); reopen or new ticket when resuming.

Handoff if resumed: [`evals/pilot/LIVE-AGENT-COMPARE.md`](evals/pilot/LIVE-AGENT-COMPARE.md) · log [`evals/pilot/live-compare-log.md`](evals/pilot/live-compare-log.md)

---

## Explicitly deferred

Stack wizard · full GitHub MCP default · blocking PreCompact · statistical Fable mandate · SWE-bench as primary signal

---

> **Pre-commit gate:** `bash tests/run-all.sh` (or `shellcheck` + `test-azg` + affected phase tests) must pass before proposing commits. Project clients: `bash tests/verify.sh`.
