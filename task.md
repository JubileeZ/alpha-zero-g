# Active Task: Phase 10 Fable — live agent compare

- **Status:** In Progress · paused for device handoff
- **Objective:** Live agent core vs core+fable pairs; promote only after held-out claim
- **Acceptance:** Logged live pairs + deltas; no default Fable until claim + better success/cost
- **Issue/Ticket:** Phase 10 · #52–55 paused

## Work Packet (SFDBN)

- **Status:** Reference smoke green; live pairs not started. Continue guide written.
- **Files:** `evals/pilot/LIVE-AGENT-COMPARE.md` ← **open this first on other device**
- **Decisions:** Smoke ≠ promote; Fable skill still stub; SWE-bench deferred
- **Blocked:** Live agent time; held-out claim for default
- **Next:** At home — `git pull` → follow `evals/pilot/LIVE-AGENT-COMPARE.md` starting `bug-fix`

## Resume (other device / other IDE)

1. `git pull origin main`
2. Open **`evals/pilot/LIVE-AGENT-COMPARE.md`** (full step-by-step)
3. Follow §2 core → §3 core+fable for `bug-fix`
4. Log row in `evals/pilot/live-compare-log.md`

## Todo
- [x] azg fable sync opt-in
- [x] compare harness + reference smoke
- [x] handoff doc for home/other IDE
- [ ] Live agent pairs (bug-fix → scoped-change → regression-feature)
- [ ] Promote decision (only after claim + live deltas)
