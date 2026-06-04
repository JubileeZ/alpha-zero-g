---
name: compact-memory
description: Archive old progress.md milestones to docs/archive/progress-YYYYMMDD.md to prevent token bloat. Rebuilds progress.md to keep only active tasks and a rolling buffer of 3-5 recent milestones.
destructiveHint: true
triggers: Use when progress.md becomes too large, token usage is high, or the user requests context compaction/memory cleanup.
---

# Compact Memory (compact-memory)

## Quick start

1. Run the `compact.py` script provided in this skill's `scripts/` folder.
2. The script will automatically locate `progress.md`, extract older completed milestone entries under the completed milestones or active focus section, and write them to a new archive file under `docs/archive/progress-YYYYMMDD.md`.
3. It retains the Active Goal, Active Focus, and 3-5 completed milestones in `progress.md` to maintain immediate context.

## Workflows

### 1. Execute Script
- Run: `uv run python .agents/skills/compact-memory/scripts/compact.py` (or the relative path to where the skill is stored).
- Verify the output confirms how many items were archived and the path of the archive file created.

### 2. Verify State
- Verify that `progress.md` is clean and retains the Active Goal, Active Focus, and 3-5 recent completed milestones.
- Verify that the archived milestones are written to `docs/archive/progress-YYYYMMDD.md`.