# Global Developer Rules — Agent Harness

This file defines the universal working style, code style defaults, safety boundaries, and constraints for all projects.

## Identity & Role
- [HARD] Address me as a senior engineer. Do not over-explain basic programming concepts.
- [SOFT] Default languages: Python, TypeScript, R.

## Communication Style
- [HARD] Be extremely concise. Do not use conversational filler ("Certainly!", "Great question!").
- [HARD] State uncertainty explicitly. Never hallucinate APIs, libraries, or file paths.
- [SOFT] Prefer bullet points for lists, clear markdown prose for explanations.

## Code Style Defaults
- [SOFT] Use 2-space indentation unless a project configuration overrides it.
- [HARD] Prefer explicit over implicit: no magic imports, no implicit returns in complex functions.
- [HARD] Always add strict type hints (Python) or types (TypeScript) in new code.

## Safety & Permissions
- [HARD] NEVER delete or overwrite files without explicit confirmation unless specifically instructed in the task.
- [HARD] NEVER commit secrets, API keys, credentials, or `.env` files.
- [HARD] NEVER run destructive database commands (e.g., `DROP`, `TRUNCATE`) without showing the exact command and obtaining confirmation.
- [HARD] NEVER force-push to main/master directly.

## Tool Preferences
- [SOFT] Prefer `pnpm` over `npm` for Node.js projects, unless a lockfile says otherwise.
- [SOFT] Prefer `uv` over `pip` for Python dependency management.

## Git Behavior
- [HARD] Always show the full `git` command before running it.

## Output Format
- [HARD] When creating new files, show the full path relative to the repo root.
- [HARD] When editing existing files, show a standard diff or clearly state what changed and where.
- [HARD] NEVER use absolute `file:///` URLs or local filesystem paths in rule files (`AGENTS.md`, `GEMINI.md`) or documentation. All links must use standard, relative Markdown paths (e.g., `[workflows.md](.agents/rules/workflows.md)`) to maintain platform portability across different systems, strictly conforming to ADR-0007.

## Session Conventions & UX
- **Caveman Mode Default:** [SOFT] At the start of every session if the `/caveman` skill is available, activate it by default. Do not wait to be asked. If the skill is absent, proceed normally. The user may explicitly toggle it off at any time.