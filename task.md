# Active Task: Phase 10 Fable — live agent compare

- **Status:** In Progress
- **Objective:** Live agent core vs core+fable pairs; promote only after held-out claim
- **Acceptance:** Logged live pairs + deltas; no default Fable until claim + better success/cost
- **Issue/Ticket:** Phase 10 · #52–55 paused

## Work Packet (SFDBN)

- **Status:** First live pair done — bug-fix both arms assertion OK
- **Files:** `evals/pilot/live-compare-log.md`, `evals/pilot/live-pairs/bug-fix-2026-07-22/`
- **Decisions:** Both success=1; Delivery Cost not measured (0 placeholder); stub Fable; no promote
- **Blocked:** Real delivery_cost/model ids; held-out claim; remaining fixtures
- **Next:** Optional fill model+cost for bug-fix; then live pair `scoped-change`

## Todo
- [x] azg fable sync opt-in
- [x] compare harness + reference smoke
- [x] handoff doc
- [x] Live pair bug-fix (assertions)
- [ ] Fill bug-fix delivery_cost + model id
- [ ] Live pairs scoped-change, regression-feature
- [ ] Promote decision (only after claim + live deltas)
