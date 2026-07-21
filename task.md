# Active Task: Phase 9 Core Pilot

- **Status:** In Progress
- **Objective:** Blind Judge wiring (fixed independent model; human calibration notes)
- **Acceptance:** Documented judge prompt/rubric + script/stub that scores a fixture delivery without seeing treatment label
- **Issue/Ticket:** Phase 9 ROADMAP

## Work Packet (SFDBN)

- **Status:** Eval Suite fixtures + paired runner/scorecard shipped (`evals/`, `tests/test-evals.sh` 36/36)
- **Files:** `evals/suite.json`, `evals/fixtures/*`, `evals/run-pair.sh`, `evals/record-scorecard.sh`
- **Decisions:** Three bash mini-apps; hidden `assertions/check.sh`; treatments `core`|`baseline`; scorecard fields match CONTEXT.md
- **Blocked:** None
- **Next:** Blind Judge wiring

## Todo
- [x] Evaluation Suite fixtures
- [x] Paired runner + scorecard
- [ ] Blind Judge wiring
