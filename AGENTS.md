# Alpha-Zero-G
# Read by all AI agents (Claude, Gemini, Cursor, Copilot, etc.) working in this repo.
---

## Project Identity

Alpha-Zero-G is an **outer agent harness** installer: templates + `azg` CLI for solo/small teams using Cursor and/or Antigravity (`agy`). v4 revamp in progress — canonical spec: `docs/REVAMP-SPEC.md`.

**Stack:** Bash (>= 4.0) · jq · Python (3.x) · Git · agy (Antigravity CLI)

**Monorepo:** no

---

## Repo Structure

```
.agents/                     # Local agent configuration, hooks, and skills
  hooks/                     # Local lifecycle hooks (e.g. block-destructive-ops)
  skills/                    # Custom skill definitions for the agent
docs/                        # Architectural plans, design docs (ADRs), and agent guides
  adr/                       # Architectural Decision Records (ADRs)
  agents/                    # Guides for issue-tracking, triage labels, and domain docs
  antigravity-agent-architect/ # Source files for the Agent Architecture Guide
lib/                         # CLI implementation shell scripts (common, setup, scaffold, etc.)
templates/                   # Standard scaffolding templates for new files and projects
  global/                    # Global configurations copied during setup
  project/                   # Project-level templates copied during apply/new
tests/                       # TDD test suites (test-phase0 through test-phase9) and harness
azg                          # Main CLI entrypoint script
CONTEXT.md                   # Domain terms and vocabulary definition context
VERSION                      # File indicating the current Alpha-Zero-G release version
```

---

## Key Commands

| Command | What it does |
|---------|-------------|
| `shellcheck azg lib/*.sh tests/*.sh` | Lint Bash scripts |
| `bash tests/run-all.sh` | Aggregate gate (shellcheck + verifiers + all suites) |
| `bash evals/run-pair.sh <id> core\|baseline` | Prepare Core Pilot eval workdir |
| `bash tests/test-azg.sh` | Run general integration tests |
| `bash tests/test-phase<0-9>.sh` | Run phase-specific integration/TDD tests |
| `python3 tests/verify_docs.py` | Verify markdown documentation links |
| `docs/AGENT-ONBOARDING.md` | Zero-context entry for new agents |

**Pre-commit gate:** agents must run test and lint commands and confirm both pass before proposing any commit.

---

## Off-Limits: Never Touch Without Explicit Instruction

- `.env` and any file containing secrets or credentials
- Database migrations — always flag, never auto-apply or auto-run
- Production configuration files
- Any file marked `# DO NOT EDIT` or `# GENERATED`

---

## Project-Specific Safety Rules

- Never modify files in `templates/` or `lib/` without running the corresponding phase tests afterwards to ensure no regressions.
- Do not commit changes that break backward compatibility of retrofitted client workspaces.

---

## Code Conventions

- All CLI implementation scripts in `lib/` must source `lib/common.sh` to reuse shared logging helpers (`info`, `warn`, `die`) and cross-platform helpers rather than implementing custom ones.
- Shell scripts should pass Shellcheck validation. Avoid global shellcheck disable directives; use inline bypasses only when technically necessary.

---

## Agent Behavior Overrides
- Keep project documentation edits (AGENTS.md, ROADMAP.md, current-state.md, etc.) telegraphic: no articles, no filler, concise fragments.
- If working on a project that integrates with or generates downstream client repositories, ensure that the downstream `AGENTS.md` files also follow this hybrid layout (customizable Agent/Users zone above the markers, managed zone between the markers).
- Keep project-specific context lightweight in `AGENTS.md` and direct agents to `docs/agents/` or modular files rather than inlining detailed instructions.

---

<!-- AZG:MANAGED:START -->
## Session start

1. Read `docs/agents/current-state.md` (if unfamiliar with repo state).
2. Read `ROADMAP.md` (first unchecked item in active phase).
3. Read `task.md` / open issues (if present).
4. Run `git log -5 --oneline` + `git status` (to sync history).
5. Do not rely on chat history.

---

## Universal Safety Rules

- No secrets/tokens/credentials in any file.
- Destructive ops (delete/overwrite/truncate/drop): inline `# DESTRUCTIVE: <reason>`.
- No new top-level dependencies without flagging in response.
- Agent harness device changes: implement scalably for current/future devices and new repos.
- Prefer reversible actions. If irreversible, state clearly before executing.
- Tool blocked by safety hook? Explain block, suggest exact command/content to write manually.
- Windows: run CLI/hooks only inside Git Bash.

---

## Domain Vocabulary

- Ambiguous terminology? Read `docs/agents/domain.md`.
- New terms? Create `CONTEXT.md` at root from `docs/agents/CONTEXT.md.tmpl` to register glossary.

---

## Progress & Issues

- Progress workflow: read `docs/agents/progress.md`.
- Issue tracker setup: read `docs/agents/issue-tracker.md`.
- Compaction: collapse completed phase checklists in `ROADMAP.md` to a single header/summary line (Active-Phase Compaction).
- Cleanup: delete transient session files (`task.md`, `implementation_plan.md`, `walkthrough.md`) once milestone/task is complete.
<!-- AZG:MANAGED:END -->
