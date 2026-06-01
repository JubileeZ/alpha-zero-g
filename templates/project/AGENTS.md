# Project: {{PROJECT_NAME}}

Project-scoped agent rules and domain constraints.

## System Pointers
- **Session Log**: [progress.md](progress.md)
- **Domain Context**: [CONTEXT.md](CONTEXT.md)
- **Feature Status**: [features.json](features.json)

## Core Rules
- **No Symlink Portability**: All project rules are physical copies and use relative links.
- **Deterministic Python**: Always execute via `uv run` (`uv run pytest`, `uv run python`).
- **Data Protection**:
  - NEVER write, modify, or delete files in `data/raw/`.
  - Treat all files under `data/raw/` as read-only.
- **Explicit Typings**: Require strict type hints in Python.

## ADR Trigger Conditions
An agent MUST write an ADR when:
- Choosing a library or tool dependency.
- Changing data schema or output format.
- Modifying project folder structure.
- Adopting or changing a testing strategy.
- Any decision that would be hard to reverse.

## ADR Workflow
1. Write research spike -> `docs/research/YYYY-MM-DD-topic.md`
2. Write ADR -> `docs/adr/ADR-NNN-slug.md` (use project ADR template)
3. Tag affected source files with `# ADR-NNN` in a comment.
