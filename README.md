# Alpha-Zero-G

Alpha-Zero-G is an **outer agent harness installer and template system** designed to make AI agents (specifically **Cursor** and **Antigravity (`agy`)**) reliable and budget-conscious for solo developers and small teams. It does not replace your IDE's agent loops; instead, it provides essential guardrails, skills, and project scaffolding.

It ships the following capabilities out-of-the-box across macOS, Linux, and Windows:
- **Harness-Only Project Templates**: Automatically scaffolds `AGENTS.md`, `ROADMAP.md`, `task.md`, and issue-tracker adapters so agents can maintain cross-device context without relying on expensive chat history or full MCP schemas.
- **Global Config & Skills**: Installs a core profile of 11 global skills and a cross-platform statusline script directly to your machine's global configuration (`~/.gemini/antigravity-cli/`).
- **Safety Hooks**: Provides local `.agents/hooks/` for your repositories to block destructive operations, enforce commit gates, manage subagent spawn budgets, and verify work-state checkpoints.
- **Brownfield & Greenfield Support**: Easily apply the harness to new projects (`azg new`) or safely retrofit existing repositories (`azg apply`).

**v4 revamp in progress.** Start here:

| Doc | Purpose |
|-----|---------|
| [Agent onboarding](docs/AGENT-ONBOARDING.md) | Zero-context start for AI agents |
| [v4 design spec](docs/REVAMP-SPEC.md) | Canonical — what we are building |
| [Roadmap](ROADMAP.md) | Phase checklist |
| [Current state](docs/agents/current-state.md) | What exists vs gaps |

## Quick start

```bash
git clone <this-repo>
cd Alpha-Zero-G
./azg setup                    # once per machine
./azg new my-app               # greenfield harness (v4: harness-only)
# OR
cd existing-repo && /path/to/azg apply .

bash tests/test-harness.sh     # v4: meta-harness gate (project template)
```

## Updating

```bash
git pull
./azg update --vendor          # refresh pinned skills + ponytail block
./azg setup                    # push to ~/.gemini/antigravity-cli/ if VENDOR.lock changed
./azg apply --dry-run .        # preview harness upgrade in a project repo
./azg apply .
```

## Legacy

- v3 implementation plan: [docs/archive/V3-PLAN.md](docs/archive/V3-PLAN.md)
- Agent architecture guides: `docs/antigravity-agent-architect/` (reference; v4 spec wins on conflict)

## Uninstall

```bash
./azg uninstall
```
