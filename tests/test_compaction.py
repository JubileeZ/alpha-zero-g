import os
import sys
import re
import tempfile
from datetime import datetime
from pathlib import Path

# Add templates/skills/compact-memory/scripts/ to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../templates/skills/compact-memory/scripts")))

def test_compaction_logic():
    from compact import compact_progress_content
    
    mock_content = """# Session Progress Log — Alpha-Zero-G

This document tracks the current state, active focuses, and completed milestones of the Alpha-Zero-G development environment.

---

## Active Goal

Establish a high-performance, deterministic developer harness.

---

## 1. Milestones Completed

### Category A

- [x] **Milestone 1**: Details 1.
- [x] **Milestone 2**: Details 2.
- [x] **Milestone 3**: Details 3.

### Category B

- [x] **Milestone 4**: Details 4.
- [x] **Milestone 5**: Details 5.
- [x] **Milestone 6**: Details 6.

---

## 2. Active Focus / Current Steps

1. Working on something active.
2. Another active task.

---

## 3. Next Session Priorities

1. Next task 1.
"""

    archived, kept_content = compact_progress_content(mock_content, keep_last=3)
    
    # Assert correct split
    assert len(archived) == 3
    assert "Milestone 1" in archived[0]
    assert "Milestone 2" in archived[1]
    assert "Milestone 3" in archived[2]
    
    # Assert kept milestones in updated progress.md content
    assert "Milestone 4" in kept_content
    assert "Milestone 5" in kept_content
    assert "Milestone 6" in kept_content
    
    # Assert archived milestones are NOT in updated progress.md content
    assert "Milestone 1" not in kept_content
    assert "Milestone 2" not in kept_content
    assert "Milestone 3" not in kept_content
    
    # Assert Active Goal, Active Focus and Next Priorities are preserved
    assert "Active Goal" in kept_content
    assert "Establish a high-performance" in kept_content
    assert "Active Focus" in kept_content
    assert "Working on something active" in kept_content
    assert "Next Session Priorities" in kept_content
    assert "Next task 1" in kept_content