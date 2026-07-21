# Active Task: Phase 10 Fable

- **Status:** In Progress
- **Objective:** Live core vs core+Fable score deltas (experimental); no default promotion until held-out claim
- **Acceptance:** Filled compare-matrix deltas from operator runs; promote gate still blocked while claim false
- **Issue/Ticket:** Phase 10 ROADMAP · #52–55 still paused for default promotion

## Work Packet (SFDBN)

- **Status:** CI LF/+x fixed; `core+fable` treatment + `compare-core-fable.sh` shipped
- **Files:** `evals/run-pair.sh`, `evals/compare-core-fable.sh`, `tests/test-evals.sh`
- **Decisions:** Comparison is experimental scaffolding; reliability claim still false (ADR 0005)
- **Blocked:** Live confirmation+held-out for claim; real Fable upstream (AZG_FABLE_UPSTREAM TBD)
- **Next:** Run compare matrix with agents; promote only if deltas win without portability regression

## Todo
- [x] azg fable sync opt-in
- [x] core vs core+Fable comparison harness
- [ ] Operator-filled score deltas / promote decision
