# Active Task: Phase 10 Fable

- **Status:** In Progress
- **Objective:** Compare core vs core+Fable on Evaluation Suite (after live claim or with --experimental pairs labeled non-claim)
- **Acceptance:** Documented treatment arm + at least one recorded exploratory/experimental pair note for core+fable (reliability_claim still false until held-out claim)
- **Issue/Ticket:** Phase 10 ROADMAP · #52–55 still paused for default promotion

## Work Packet (SFDBN)

- **Status:** `azg fable sync` opt-in shipped (stubs + --experimental gate); held-out tooling green; claim still false
- **Files:** `lib/fable.sh`, `templates/optional/fable/`, `tests/test-fable.sh`
- **Decisions:** No global default; refuse sync without --experimental until apply-claim; ADR 0005 stands
- **Blocked:** Live confirmation+held-out for claim; real Fable upstream (AZG_FABLE_UPSTREAM TBD)
- **Next:** Wire core+fable treatment into evals/run-pair or pilot notes

## Todo
- [x] azg fable sync opt-in
- [ ] core vs core+Fable comparison harness
