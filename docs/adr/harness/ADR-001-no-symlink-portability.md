# ADR-001: No-Symlink Portability & Mappings Strategy
**Status:** Accepted
**Date:** 2026-06-01
**Depends on:** None

## Context
The legacy developer harness in `Alpha-Zero-G` relied heavily on symbolic links (`ln -s` on macOS/Linux and directory junctions on Windows) to reference global agent configurations, rule definitions, and skills from a central repository. This created several issues:
1. Moving project folders or switching between devices (macOS and Windows) frequently broke path references.
2. Windows environments required elevated administrative privileges or Developer Mode registry modifications to create symlinks, creating a high-friction setup.
3. Troubleshooting broken links across platforms wasted significant developer cycles.

## Decision
We decide to adopt a **No-Symlink Portability** architecture:
1. **Physical Copying for Skills:** All engineering and productivity skills (both global under `~/.gemini/antigravity-cli/skills/` and per-project under `.agents/skills/`) will be copied physically from the cloned `mattpocock/skills` repository. No symlinks will be used for skill mapping.
2. **Pure File References for CLAUDE.md:** `CLAUDE.md` files at both global (`~/.claude/CLAUDE.md`) and project levels (`CLAUDE.md`) will use `@-import` syntax or standard file references (`@~/.gemini/AGENTS.md` and `@./AGENTS.md`) instead of symlinks.
3. **Selective Scaffold Directory Generation:** Source folders (`src/` and `R/`) will be selectively created based on `--type` to maintain a lean structure without dead directories.

## Alternatives Considered
- **Symlink Mappings:** Rejected due to OS permissions, directory junction constraints, and high breakage risk on cross-device sync.
- **Copying Entire Skills Repository:** Rejected due to context window bloat and loading of unused/unsupported skills.

## Consequences
- **Good:** Complete path independence, zero-elevation setup on Windows, extremely robust cross-device syncing, and predictable file resolution.
- **Bad:** Slightly higher disk space usage due to physical copies of skills (negligible for text assets).
