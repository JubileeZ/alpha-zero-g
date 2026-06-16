# Original User Request

## Initial Request — 2026-06-16T16:12:47Z

Translate the modular Claude-specific agent architecture documentation to an Antigravity CLI version and update the router page.

Working directory: /Users/jubilee/Alpha-Zero-G
Integrity mode: development

## Requirements

### R1. Translate Modular Docs
Translate the 13 modular markdown files in `docs/claude-agent-architect/` into their Antigravity-specific equivalents under `docs/antigravity-agent-architect/`. Translate Claude concepts (e.g. `.claude/` directories, `CLAUDE.md` files, the `claude` command, tool name `Bash`, and hook structures) to their Antigravity counterparts (`.agents/` directories, `GEMINI.md` + `AGENTS.md` files, the `agy` command, tool name `run_command`, and `hooks.json` formats).

*Note: The file `claude-md-design.md` should be renamed to `gemini-md-design.md` in the new structure.*

### R2. Update Router Page
Update `docs/antigravity-agent-architecture.md` to be a clean index/router page (similar to `docs/agent-architecture.md`) that links to `docs/antigravity-agent-architect/index.md` and each of the new modular documents.

### R3. Verify Link and Content Integrity
Ensure that all internal relative markdown links resolve correctly and no broken references are introduced. Run the documentation verification test suite to confirm correctness.

## Acceptance Criteria

### Documentation Structure
- [ ] 13 markdown files must exist under `docs/antigravity-agent-architect/` matching the names and topics of the Claude version (with `claude-md-design.md` mapped to `gemini-md-design.md`).
- [ ] The file `docs/antigravity-agent-architecture.md` must be updated to serve as the router for the new modular documents.

### Concept Adaptation
- [ ] References to `.claude/`, `CLAUDE.md`, `claude`, and `Bash` tool in the markdown files are replaced/adapted to `.agents/`, `GEMINI.md`, `agy`, and `run_command` respectively.

### Programmatic Verification
- [ ] The script `tests/verify_docs.py` must run and exit with code 0.
- [ ] All relative links within the documents are valid and no files are missing.
