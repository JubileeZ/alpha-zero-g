# Active Task: Phase 8 Evidence Trustworthy

- **Status:** In Progress
- **Objective:** Aggregate runner (shellcheck + test-azg + phase tests + Python verifiers)
- **Acceptance:** One command runs full gate; documented for CI
- **Issue/Ticket:** Phase 8 ROADMAP

## Work Packet (SFDBN)

- **Status:** Phase 7 shipped; tmp_azg root-leak fix included in same push
- **Files:** `tests/harness.sh`, `tests/test-*.sh`, `templates/project/tests/verify.sh`, `.gitignore`
- **Decisions:** Test temps under TMPDIR; harness scrub + verify deny `tmp_azg*` at project root
- **Blocked:** None
- **Next:** Implement aggregate test runner script + wire CI

## Todo
- [ ] Aggregate runner
- [ ] CI matrix
