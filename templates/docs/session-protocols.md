# Session Protocols — {{PROJECT_NAME}}

This document details standard procedures for starting and ending development sessions to ensure seamless collaboration.

## Session Start
1. **Read AGENTS.md** (the primary workspace guide).
2. **Read `progress.md`** to understand where the work left off.
3. **State clearly in your first message:**
   - Current project phase and active focus.
   - What was last completed.
   - What this session's goal and success criteria are.
4. **Confirm understanding** with the user before editing code.

## Session End
1. **Run full lint and tests** to ensure no regressions.
2. **Update `progress.md`:**
   - Mark completed items.
   - Add detailed next actions in order.
   - List any newly discovered known issues.
3. **Update `docs/beliefs.md`** and write any necessary ADRs if architectural decisions were made.
4. **State clearly:** "Session complete. Next session should start with: [X]"
