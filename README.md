# Alpha-Zero-G

Outer agent harness for **Cursor** and **Antigravity (`agy`)** — harness-only project templates, global skills, hooks, and cross-device work-state. Budget-conscious; multi-platform (Linux, macOS, Windows).

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
