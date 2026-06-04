---
name: compact-memory
description: Archive old progress.md milestones to docs/archive/ to prevent token bloat. Use when the user asks to compact memory, archive progress, or run the context compaction.
---

# Compact Memory (compact-memory)

## Quick start

1. Run the `compact.py` script provided in this skill's `scripts/` folder.
2. The script will automatically locate `progress.md`, extract older milestone entries under the Active Focus section, and append them to `docs/archive/progress-archive.md`.
3. It retains the last 5 most recent milestones in `progress.md` to maintain immediate context.

## Workflows

### 1. Execute Script
- [ ] Execute `uv run python .agents/skills/compact-memory/scripts/compact.py` (or the relative path to where the skill is stored).
- [ ] Verify the output confirms how many items were archived.

### 2. Verify State
- [ ] Use `view_file` on `progress.md` to ensure the file is clean and retains only the most recent milestones.
- [ ] Update `progress.md` with your own session logging.
