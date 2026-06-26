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

- ponytail: Bash and jq are pre-approved stack requirements.
- clean-temp: Temporary files created during tests must be cleaned up properly using traps or explicit or automatic cleanup.
- When user requests changes to devices on agent harness, implement scalably. Design for current device and repo, ensuring compatibility with future devices and new repositories.
- Known Footgun: The global statusline script and templates expect `~/.gemini/antigravity-cli/` to exist. When testing setup/CLI actions locally, use the test harness custom `HOME` logic (as seen in `tests/test-azg.sh`) to avoid polluting active developer configuration.

---

<!-- AZG:MANAGED:START -->
## Session start (agents)

1. Read `docs/agents/current-state.md` — what exists vs roadmap gaps
2. Read `ROADMAP.md` — first unchecked item in active phase
3. Read `task.md` (or open issue) if present
4. Run `git log -5 --oneline` and `git status`
5. Do not rely on chat history.

---

## Universal Safety Rules

- Never commit secrets, tokens, or credentials to any file.
- Destructive operations (delete, overwrite, truncate, drop) require an inline comment:
  `# DESTRUCTIVE: <reason this is safe to proceed>`
- Never add a new top-level dependency without flagging it explicitly in your response.
- Prefer reversible actions. When an irreversible action is required, state it clearly before executing.
- If a tool call is blocked by a safety hook (returns decision: deny), clearly explain the block to the user and suggest the next manual action (providing the exact shell command or file content to write manually).
- On Windows, always run CLI commands, scripts, and hooks inside Git Bash (command execution in CMD or PowerShell is not supported).

---

## Domain Vocabulary

- If domain terminology or relationships are ambiguous, check `docs/agents/domain.md`.
- Create `CONTEXT.md` at the repo root from `docs/agents/CONTEXT.md.tmpl` if you need to resolve or record new domain vocabulary.

---

## Agent Progress Updates

- Pointers to issue tracking and progress update ritual can be found in `docs/agents/progress.md`.
- Active issue tracking configuration is described in `docs/agents/issue-tracker.md`.

---

## Downstream Harness Alignment

- If working on a project that integrates with or generates downstream client repositories, ensure that the downstream `AGENTS.md` files also follow this hybrid layout (customizable Agent/Users zone above the markers, managed zone between the markers).
- Keep project-specific context lightweight in `AGENTS.md` and direct agents to `docs/agents/` or modular files rather than inlining detailed instructions.
<!-- AZG:MANAGED:END -->
