# Long-Horizon Task procedure

CONTEXT.md: finish across **forced fresh-context** sessions, a **clean-device clone**, and a **Cursor↔Antigravity** handoff before acceptance.

Automation: `bash evals/run-long-horizon.sh <fixture-id> [core|baseline]`

## Operator day-of flow

### Session 1 — start (IDE A)

1. Run the script; open `SESSION1` path it prints.
2. New chat / new agent session (do **not** continue an old thread — fresh context).
3. Work the fixture `TASK.md` partway (or fully if short); update `task.md` Work Packet.
4. Checkpoint: commit code **with** staged `task.md` (and handoff if used).
5. Script already seeded git; you commit: `git add -A && git commit -m "checkpoint: session1"`.
6. Mark session1 complete in the log when prompted, or re-run with `--resume-after-session1` after commit.

### Clean device — Session 2 prep

Script clones Session1 repo into `SESSION2` (simulates second machine / clean tree).

1. On the “other device” (or second folder): open `SESSION2` only — no copying chat history.
2. `git log -1` / read `task.md` — resume from Checkpoint only.

### Session 2 — IDE B (other of Cursor / Antigravity)

1. Open `SESSION2` in the **other** IDE from Session 1 (if Session1 was Cursor → use Antigravity, and vice versa).
2. Fresh chat again.
3. Finish TASK acceptance; run `bash assertions/check.sh`.
4. Optional: `bash evals/judge-score.sh "$SESSION2"`.
5. Fill scorecard + set `long_horizon=true` in notes.

### Pass criteria (Long-Horizon)

- [ ] Session1 used a **new** agent context (not a continued thread)
- [ ] Checkpoint commit exists with Work Packet
- [ ] Session2 is a **clean clone** (not the same working tree)
- [ ] Session2 used the **other** IDE family (Cursor ↔ Antigravity)
- [ ] Hidden assertions pass on Session2
- [ ] `long-horizon-log.json` phases all `ok`

Human checklist copy: `evals/long-horizon/checklist.md`.
