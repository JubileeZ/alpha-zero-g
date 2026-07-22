# Active Task: Phase 10 Fable — live agent compare

- **Status:** In Progress · **no default promotion**
- **Objective:** Continue optional live pairs for process signal only; do not promote without Delivery Cost + held-out claim
- **Acceptance:** Promote blocked until measurable cost + claim gate
- **Issue/Ticket:** Phase 10 · #52–55 paused

## Work Packet (SFDBN)

- **Status:** bug-fix live pair both assertion OK; cost untracked by operator
- **Files:** `evals/pilot/live-compare-log.md`, `live-pairs/bug-fix-2026-07-22/`
- **Decisions:** **Do not promote** Fable to default without Delivery Cost tracking; stub Fable; ADR 0005 stands
- **Blocked:** Cost instrumentation / operator spend UI; held-out claim
- **Next:** Optional more fixtures for process practice only — or pause Phase 10 promote track

## Todo
- [x] Live pair bug-fix (assertions)
- [x] Explicit: no promote without cost data
- [ ] Optional: scoped-change / regression-feature (process only)
- [ ] Promote decision — blocked until cost + claim
