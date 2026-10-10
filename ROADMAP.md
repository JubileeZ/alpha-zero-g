# Alpha-Zero-G — Roadmap

**Status:** v4 complete · Lite **removed** · Behavior Corpus (ADR 0019) live · vendor/`wip` fable trees gone

> Zero-context: [`docs/AGENT-ONBOARDING.md`](docs/AGENT-ONBOARDING.md) · Spec: [`docs/SPEC.md`](docs/SPEC.md) · Reality: [`docs/agents/current-state.md`](docs/agents/current-state.md) · Glossary: [`CONTEXT.md`](CONTEXT.md)

---

## Vision

Reliable Delivery: higher Task Success per Delivery Cost than No-Harness Baseline, with Minimal Setup, across devices and Cursor/Antigravity. Repo-native gates own guarantees; IDE hooks are thin adapters.

ADRs: [`0004`](docs/adr/0004-repo-native-reliability-boundary.md) · [`0012` Trap machinery](docs/adr/0012-trap-suite-process-gate.md) · [`0016` EP v1 historical](docs/adr/0016-promote-execution-protocol-v1.md) · [`0017` EP/judge/orchestrate layering](docs/adr/0017-ep-judge-orchestrate-layering.md) · [`0019` Behavior Corpus](docs/adr/0019-behavior-corpus-eval.md) · [`0020` Principles v1](docs/adr/0020-promote-principles-treatment.md) · [`0021` Principles v2](docs/adr/0021-promote-principles-v2.md) · [`0023`](docs/adr/0023-work-packet-safety-boundary.md) · [`0024`](docs/adr/0024-project-skills-safety-boundary.md)

---

## Phase 0–9 — complete

v4 harness · Portable Core · Evidence (`run-all` + CI) · legacy Core Pilot retired.

---

## Post-v4 hardening — complete

Ownership, Checkpoint, EP v1 then Principles (0020) then v2 (0021), Eval Isolation, Behavior Corpus Outcome scorers. Vendor fable tree + `wip/` removed 2026-08-14.

Live notes: `evals/traps/CAMPAIGN.md`.

---

> **Pre-commit gate:** `bash tests/run-all.sh` (or `shellcheck` + `test-azg` + affected phase tests) must pass before proposing commits. Project clients: `bash tests/verify.sh`.
