# Token & Context Management — {{PROJECT_NAME}}

This document details guidelines to optimize context size and manage interaction health during development sessions.

## Core Guidelines
- **Reference, Don't Embed:** Reference files and lines; do not copy-paste full file contents into the chat context.
- **Summarize Data:** Use schemas, data shapes, and summary statistics rather than printing entire dataframes or matrices.
- **Decompose Tasks:** Keep your focus narrow. Build one feature, model, or helper function at a time.

## Context Health Thresholds
- **< 40%:**  ✅ Healthy — continue normally.
- **40-60%:** ⚠️ Watch — start summarizing completed work to prepare for transition.
- **60-70%:** 🔶 High — compress history, work from files, avoid repeating previous outputs.
- **> 70%:**  🔴 Critical — output quality degrading; end session soon or request compaction.
