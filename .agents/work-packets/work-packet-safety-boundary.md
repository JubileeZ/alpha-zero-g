# Active Task: Work Packet Safety Boundary & Heredoc Elimination

- **Status:** Complete
- **Objective:** Redesign safety hooks to allow Work Packet markdown writes while strictly banning code sneaking, prohibit multi-line heredocs, and enable autonomous commit and push.
- **Acceptance:** Tests in `tests/test-phase4.sh`, `tests/test-phase10.sh`, and `tests/verify.sh` pass; `.agents/work-packets/*.md` writes allowed; `.agents/work-packets/*.py` writes denied; ADR 0023, CONTEXT.md, AGENTS.md updated.
- **Issue/Ticket:** User request to redesign safety hooks

## Work Packet (SFDBN)

- **Status:** Complete
- **Files:** `.agents/hooks/block-destructive-ops.sh`, `templates/project/.agents/hooks/block-destructive-ops.sh`, `.agents/hooks/commit-scan.sh`, `templates/project/.agents/hooks/commit-scan.sh`, `.agents/hooks/commit-gate.sh`, `templates/project/.agents/hooks/commit-gate.sh`, `.cursor/hooks/commit-verify.sh`, `templates/project/.cursor/hooks/commit-verify.sh`, `AGENTS.md`, `templates/project/AGENTS.md.tmpl`, `CONTEXT.md`, `docs/adr/0023-work-packet-safety-boundary.md`, `tests/test-phase4.sh`, `tests/test-phase10.sh`
- **Decisions:** ADR 0023 whitelists `.agents/work-packets/*.md` and `.agents/handoff-pointer`; denies non-markdown files and execution in `.agents/`; forbids heredocs; enables autonomous commit & push.
- **Blocked:** None
- **Next:** Commit and clean up packet.

## Todo
- [x] Whitelist work packet markdown in block-destructive-ops.sh
- [x] Add code sneak prevention in commit-scan.sh and commit-gate.sh
- [x] Document ADR 0023 and update CONTEXT.md
- [x] Update AGENTS.md and templates to forbid heredocs and allow autonomous push
- [x] Add tests in test-phase4.sh and test-phase10.sh
- [x] Run verify.sh and full test suite
- [ ] Close packet
