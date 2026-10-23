# Active Task: statusline-cosmetics-aesthetics

- **Status:** In Progress
- **Objective:** Overhaul statusline aesthetics and cosmetics: 5-cell pill active quota gauge, clean context text, muted separators, standardized state glyphs, ✦ model prefix, muted timers, and 'Other' provider label.
- **Acceptance:** Statusline renders Option A with 5-cell active quota bar (`▰▰▰▰▱`), muted `│` separators, consistent state icons, dimmed timers, `Other` label, and passes unit test suite and full regression gate.
- **Issue/Ticket:** ADR 0001 aesthetic & ergonomic amendment

## Work Packet (SFDBN)

- **Status:** In Progress
- **Files:** templates/global/statusline.sh, tests/test-statusline.sh, docs/adr/0001-adaptive-single-line-statusline.md, docs/agents/current-state.md
- **Decisions:** Option A (Dedicated active quota 5-cell bar, clean text context); thin muted `│` rule; widened project name limit (16c); `✦ ` model symbol; standardized state glyphs (`●`, `◐`, `⚙`, `⏸`); muted gray timers; `Other` (`Oth`) label; standby weekly only surfaced if <20% or exhausted; active quota bold with full name; context window decimal precision (`xx.x%`) and 10-cell solid progress bar (`█████░░░░░`), omitting misleading cumulative session token totals.
- **Blocked:** None
- **Next:** Run verify.sh and run-all.sh, deploy to host ~/.gemini/antigravity-cli/statusline.sh via ./azg setup, present live rendered outputs to user, and prepare checkpoint commit.

## Todo
- [x] Implement Option A visual changes in templates/global/statusline.sh
- [x] Implement context 1-decimal percentage and 10-cell progress bar
- [x] Update test assertions in tests/test-statusline.sh (23/23 passed)
- [x] Update ADR 0001 with Option A and context bar decisions
- [ ] Run verify.sh, test-statusline.sh, run-all.sh
- [ ] Deploy to host via ./azg setup
- [ ] User review and checkpoint commit

## Blockers / Notes
- None
