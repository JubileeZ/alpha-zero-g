# Active Task: Phase 8 Evidence Trustworthy

- **Status:** In Progress
- **Objective:** Host-contract smoke — real Cursor + Antigravity hook fire (deny must prevent action)
- **Acceptance:** Documented smoke procedure + at least one automated/host check proving deny blocks the action
- **Issue/Ticket:** Phase 8 ROADMAP

## Work Packet (SFDBN)

- **Status:** Aggregate runner + CI matrix added; Windows `AZG_OS` detection fixed
- **Files:** `tests/run-all.sh`, `.github/workflows/ci.yml`, `lib/common.sh`
- **Decisions:** `AZG_STRICT=1` on CI; soft-skip missing tools locally
- **Blocked:** None (CI green pending first Actions run after push)
- **Next:** Host-contract smoke for Cursor + Antigravity

## Todo
- [x] Aggregate runner
- [x] CI matrix
- [ ] Host-contract smoke
