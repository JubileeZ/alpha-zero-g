## Agent skills

### Issue tracker

Issues and PRDs for this repo live as GitHub issues. See `docs/agents/issue-tracker.md`.

### Triage labels

The triage skill maps roles to GitHub labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout with one `CONTEXT.md` and `docs/adr/` at the root. See `docs/agents/domain.md`.


<!-- AZG:MANAGED:START -->
# Alpha-Zero-G
# Read by all AI agents (Claude, Gemini, Cursor, Copilot, etc.) working in this repo.
---

## Project Identity

Alpha-Zero-G is a complete system for building and managing production-ready AI agent environments within the Antigravity CLI (`agy`) ecosystem. It provides orchestration tools, templates, hooks, and global configurations (including terminal statusline scripts) to run agent harnesses reliably. It enables developers to scaffold new AI agent projects or retroactively install the agent harness in existing repositories.

**Stack:** Bash (>= 4.0) · jq · Python (3.x) · Git · agy (Antigravity CLI)

**Monorepo:** no

---

## Key Commands

| Command | What it does |
|---------|-------------|
| `shellcheck azg lib/*.sh tests/*.sh` | Lint Bash scripts |
| `bash tests/test-azg.sh` | Run general integration tests |
| `bash tests/test-phase<0-9>.sh` | Run phase-specific integration/TDD tests |
| `python3 tests/verify_docs.py` | Verify markdown documentation links |

**Pre-commit gate:** agents must run test and lint commands and confirm both pass before proposing any commit.

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

## Safety Rules

**Universal (keep always):**
- Never commit secrets, tokens, or credentials to any file.
- Destructive operations (delete, overwrite, truncate, drop) require an inline comment:
  `# DESTRUCTIVE: <reason this is safe to proceed>`
- Never add a new top-level dependency without flagging it explicitly in your response.
- Prefer reversible actions. When an irreversible action is required, state it clearly before executing.
- If a tool call is blocked by a safety hook (returns decision: deny), clearly explain the block to the user and suggest the next manual action (providing the exact shell command or file content to write manually).

**Project-specific:**
- Never modify files in `templates/` or `lib/` without running the corresponding phase tests afterwards to ensure no regressions.
- Do not commit changes that break backward compatibility of retrofitted client workspaces.

---

## Code Conventions

- All CLI implementation scripts in `lib/` must source `lib/common.sh` to reuse shared logging helpers (`info`, `warn`, `die`) and cross-platform helpers rather than implementing custom ones.
- Shell scripts should pass Shellcheck validation. Avoid global shellcheck disable directives; use inline bypasses only when technically necessary.

---

## Known Footguns

- The global statusline script and templates expect `~/.gemini/antigravity-cli/` to exist. When testing setup/CLI actions locally, use the test harness custom `HOME` logic (as seen in `tests/test-azg.sh`) to avoid polluting or overwriting your active developer configuration.

---

## Agent Behavior Overrides

- ponytail: Bash and jq are pre-approved stack requirements.
- clean-temp: Temporary files created during tests must be cleaned up properly using traps or explicit or automatic cleanup.
- When user requests changes to devices on agent harness, implement scalably. Design for current device and repo, ensuring compatibility with future devices and new repositories 
<!-- AZG:MANAGED:END -->
