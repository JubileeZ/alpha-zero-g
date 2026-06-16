# Project: Antigravity Agent Architecture Translation

## Architecture
- Source files: `docs/claude-agent-architect/*.md` (13 files)
- Target files: `docs/antigravity-agent-architect/*.md` (13 files, renaming `claude-md-design.md` to `gemini-md-design.md`)
- Router file: `docs/antigravity-agent-architecture.md` (Update to clean index/router page)
- Verification script: `tests/verify_docs.py` (Run this to verify link and content integrity)

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Exploration & Planning | Analyze the 13 Claude modular files and map translation rules | None | DONE |
| 2 | Translating Modular Docs | Translate 13 files from Claude to Antigravity, placing them in `docs/antigravity-agent-architect/` | M1 | DONE |
| 3 | Updating Router Page | Update `docs/antigravity-agent-architecture.md` to serve as a clean index linking to all new files | M2 | DONE |
| 4 | Verification & Hardening | Run `tests/verify_docs.py`, fix any link/content issues, and confirm 0 warnings/errors | M3 | DONE |

## Interface Contracts / Mapping Rules
- File mappings:
  - `docs/claude-agent-architect/claude-md-design.md` -> `docs/antigravity-agent-architect/gemini-md-design.md`
  - All other files keep their names under `docs/antigravity-agent-architect/`
- Translation terminology mappings:
  - Claude -> Antigravity / Gemini / agy (depending on context, e.g. "Claude Code" -> "Antigravity CLI")
  - `.claude/` -> `.agents/`
  - `CLAUDE.md` -> `GEMINI.md` / `AGENTS.md` (check context)
  - `claude` command -> `agy`
  - `Bash` tool -> `run_command`
  - Hook structure -> JSON hooks / `hooks.json` formats
  - `exit code` hooks contract -> `{"decision": "allow"}` / `{"decision": "deny"}` JSON protocol
- Ensure all relative markdown links between the translated docs resolve correctly.
