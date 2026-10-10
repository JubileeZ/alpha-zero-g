# Active Task: skills-safety-boundary

- **Status:** In Progress
- **Objective:** Allow project skills under .agents/skills/ and project rules under .cursor/rules/ in safety hook while maintaining Zero Self-Modification Policy on hooks and configs
- **Acceptance:** test-phase4.sh, host-contract-smoke.sh, verify.sh pass; skills tool writes, shell ops, and script execution allowed; hooks blocked
- **Issue/Ticket:** ADR 0024

## Work Packet (SFDBN)

- **Status:** In Progress
- **Files:** .agents/hooks/block-destructive-ops.sh, templates/project/.agents/hooks/block-destructive-ops.sh, tests/test-phase4.sh, CONTEXT.md, AGENTS.md, templates/project/AGENTS.md.tmpl, docs/adr/0024-project-skills-safety-boundary.md
- **Decisions:** Allow .agents/skills/** and .cursor/rules/**; block hooks/hooks.json/work-packet.md.tmpl; anchor repo-root .agents paths
- **Blocked:** None
- **Next:** Implement hook modifications in .agents/hooks/block-destructive-ops.sh and templates

## Todo
- [x] Apply payload from scratch/block-destructive-ops.sh to .agents/hooks/ and templates/ (applied and synchronized)
- [x] Add test cases to tests/test-phase4.sh
- [x] Update CONTEXT.md, AGENTS.md, templates/project/AGENTS.md.tmpl
- [x] Add docs/adr/0024-project-skills-safety-boundary.md
- [x] Run verify.sh, test-phase4.sh, test-azg.sh, test-phase10.sh, and test-mutation-verify.sh
- [ ] Roll out updated harness to downstream repos (career-agent, fpl-jubilee-ascent, jubilee-solio-calibrate, jubilees-gambit)

## Blockers / Notes
- None
