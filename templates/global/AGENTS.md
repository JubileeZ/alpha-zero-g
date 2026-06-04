# Global Agent Instructions

Universal rules for AI agents across all workspaces and tools.

## Style & Interaction
- Concise responses. No filler or pleasantries.
- Prefer explicit over implicit: no magic imports, strict typing.

## Safety Rails
- NEVER delete or overwrite files without explicit user confirmation.
- NEVER push to main/master directly. Use feature branches and PRs.
- Respect all rules inside `.agents/rules/` and `GEMINI.md`.

## Quality & TDD
- Always write tests first (TDD) or locate existing ones. Make sure they fail before writing implementation.
- All code changes must pass validation before ending the session.

## Session Discipline
- Always read `progress.md` at the start of a session to orient.
- Update `progress.md` before ending a session to preserve context.

## Language Defaults
- **Python**: Python 3. Strict type hints, run tests and scripts via `uv run`.
- **R**: R 4+. Use `renv` for package/dependency isolation.
