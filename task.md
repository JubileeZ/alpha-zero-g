# Active Task: Phase 9 Core Pilot

- **Status:** In Progress
- **Objective:** Long-Horizon Task script (fresh context + clean-device clone + Cursor↔Antigravity handoff)
- **Acceptance:** Scripted procedure that forces session reset, clone on “clean” path, and IDE handoff checklist before acceptance
- **Issue/Ticket:** Phase 9 ROADMAP

## Work Packet (SFDBN)

- **Status:** Blind Judge wiring shipped (packet blind to treatment; stub + AZG_JUDGE_CMD; calibration notes)
- **Files:** `evals/judge/*`, `evals/prepare-judge-packet.sh`, `evals/judge-score.sh`, `tests/test-evals.sh`
- **Decisions:** Judge never sees scorecard/treatment/.agents; stub not for claims; fixed model id in config.json
- **Blocked:** None
- **Next:** Long-Horizon Task script

## Todo
- [x] Evaluation Suite fixtures + paired runner
- [x] Blind Judge wiring
- [ ] Long-Horizon Task script
