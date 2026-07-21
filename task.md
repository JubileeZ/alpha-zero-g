# Active Task: Phase 10 Fable (blocked)

- **Status:** Blocked
- **Objective:** Bundle Fable skills as opt-in (`azg fable sync`) — only after held-out green + --apply-claim
- **Acceptance:** N/A until `prereg.json` reliability_claim_allowed true from real confirmation+held-out runs
- **Issue/Ticket:** Phase 10 ROADMAP · issues #52–55 paused

## Work Packet (SFDBN)

- **Status:** Phase 9 tooling complete; reliability_claim_allowed still false until live pairs + gate
- **Files:** `evals/analyze-pilot-log.sh`, `evals/analyze-pilot-gate.sh`, `evals/pilot/HELD-OUT.md`
- **Decisions:** Held-out N=6 fresh; --apply-claim required to flip prereg; stub/synthetic logs ≠ claims
- **Blocked:** Live confirmation (9) + held-out (6) agent pairs
- **Next:** Run real pairs or wait; do not start Fable bundling until claim allowed

## Todo
- [x] Phase 9 Core Pilot tooling
- [ ] Live confirmation + held-out (operator)
- [ ] Phase 10 Fable (blocked)
