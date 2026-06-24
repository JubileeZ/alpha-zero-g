# Current Implementation State

**Read this first** if you have no prior context. `ROADMAP.md` describes the target; this file describes **what exists today** (Phase 9/Production Ready).

**Active phase:** All Phases Complete (Phase 9/Production Ready).

---

## What exists

| Area | Path | Notes |
|------|------|-------|
| CLI Entrypoint | `azg` | The main executable dispatcher script for setup, new, apply, update, and uninstall commands |
| Implementation Lib | `lib/` | Shared common logging, OS-handling, setup, scaffolding, retrofit, updates, uninstallation, and skill synchronization scripts |
| Scaffolding Templates | `templates/` | Global and project settings/MCP/skills files utilized during setup and new workspace scaffolding |
| Test Suite | `tests/` | Integrated testing suites (`test-azg.sh`, `test-phase0.sh` to `test-phase9.sh`, document link verification, and lightweight teamwork tests) |
| Local Agent Harness | `.agents/` | Local config, hook triggers, and custom skills directory configured for retrofitting workspaces |
| Project Scaffold | `AGENTS.md` | Local rule configuration file outlining identity, commands, structure, and safety rules for agents |

---

## What does NOT exist yet (do not assume)

| Item | Planned phase | Notes |
|------|---------------|-------|
| (None) | N/A | All planned v3 features, tests, and CLI commands are fully implemented on disk. |

---

## Safe commands today

| Command | What it does |
|---------|-------------|
| `shellcheck azg lib/*.sh tests/*.sh` | Lint Bash scripts |
| `bash tests/test-azg.sh` | Run general integration tests |
| `bash tests/test-phase<0-9>.sh` | Run phase-specific integration/TDD tests |
| `python3 tests/verify_docs.py` | Verify markdown documentation links |
| `python3 -m unittest tests/test_verify_lightweight_teamwork.py` | Run subagent spawn compliance tests |
| `./azg setup --dry-run` | Preview setup installation plan |

---

## Agent pitfalls

1. Local testing of `azg setup` will modify/pollute the active developer configuration (e.g. `~/.gemini/antigravity-cli/`) unless the home directory is mocked (as done in `tests/test-azg.sh`).
2. Custom hooks must be configured and merged carefully; direct changes to `hooks.json` will be blocked by the `block-destructive-ops.sh` safety guardrail unless bypassed.

---

## Doc map

| Question | Read |
|----------|------|
| Glossary | `CONTEXT.md` |
| Phases & checklist | `ROADMAP.md` |
| Agent rules | `AGENTS.md` |
| How to update progress | `docs/agents/progress.md` |
