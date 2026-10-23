# Active Task: statusline-multi-quota

- **Status:** In Progress
- **Objective:** Implement dynamic multi-quota discovery, Argon weekly quota support, active-first cluster display, pace-aware/use-it-or-lose-it weekly surfacing, context trim, and timer-preserving truncation in statusline.sh.
- **Acceptance:** Statusline script dynamically parses quota buckets from stdin JSON, places active model first with ▸ marker, renders compact timers across all models, and passes unit test suite (tests/test-statusline.sh) and aggregate gate (tests/run-all.sh).
- **Issue/Ticket:** ADR 0001 amendment (2026-10)

## Work Packet (SFDBN)

- **Status:** Complete
- **Files:** templates/global/statusline.sh, tests/test-statusline.sh, tests/run-all.sh, CONTEXT.md, docs/adr/0001-adaptive-single-line-statusline.md
- **Decisions:** Layout 1 (Unified cluster with ▸ active marker); dynamic .quota iteration; pace-aware weekly coloring; Smart Dual-Window rule; Ctx (↓/↑) token trim.
- **Blocked:** None
- **Next:** Await test run completion, then stage and commit Checkpoint.

## Todo
- [x] Agree test seam with user
- [x] Write failing test suite tests/test-statusline.sh (red)
- [x] Implement dynamic multi-quota discovery and active-first formatting in templates/global/statusline.sh (green)
- [x] Verify width truncation cascade
- [x] Add tests/test-statusline.sh to tests/run-all.sh and verify all tests pass
- [x] Run code-review
- [x] Sync statusline via ./azg setup
- [ ] User review and checkpoint commit

## Blockers / Notes
- None
