# Active Task: Phase 10 Fable

- **Status:** In Progress
- **Objective:** Live agent core vs core+fable (skills used); then promote only after held-out claim
- **Acceptance:** Agent-run deltas favoring core+fable without portability regression; `reliability_claim_allowed` still required for default
- **Issue/Ticket:** Phase 10 ROADMAP · #52–55 still paused

## Work Packet (SFDBN)

- **Status:** Reference smoke green (both arms assertion-ok all 3 fixtures); `promote_default=false`
- **Files:** `evals/run-compare-smoke.sh`, `evals/pilot/compare-core-fable-smoke.json`
- **Decisions:** Smoke ≠ Fable benefit; cost deltas noise (~±1s wall); no promotion
- **Blocked:** Live confirmation+held-out claim; agent runs using Fable skills
- **Next:** Agent-driven paired runs (or keep experimental until claim)

## Todo
- [x] azg fable sync opt-in
- [x] core vs core+Fable comparison harness
- [x] Operator reference smoke / matrix fill
- [ ] Live agent+Fable deltas → promote decision
