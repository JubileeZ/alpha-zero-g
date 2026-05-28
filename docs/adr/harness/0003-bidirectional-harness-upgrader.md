# ADR-0003: Bidirectional Harness Upgrader Utility

## Context

As the developer harness is deployed to downstream projects, optimizations made in individual projects (such as safety hooks, environment checks, or workflow scripts) need to be backported to the core template. Conversely, new standard templates from the core need to be distributed to existing downstream projects without manual copy-pasting.

A standard Git upstream remote (`git merge upstream/main`) is not feasible because the core repository stores assets in a nested template layout (e.g. `templates/init.sh`) while downstream projects place them directly at the root (e.g. `./init.sh`). Git is unable to map these paths cleanly, leading to merge conflicts and duplicate files.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-28

We will build a custom, bidirectional shell utility `upgrade-project.sh` in the root of the core repository. 

The utility will support:
1. **Pushes (`--push`):** Propagates generic template files (`init.sh`, `.agents/hooks.json`, `DEVELOPER_WORKFLOW.md`, standard template docs) from the core `templates/` folder to target downstream projects.
2. **Pulls (`--pull`):** Backports generic improvements made within active projects back into the core `templates/` folder.
3. **Safety Guardrails:**
   - Dry-runs (`--diff` / `--dry-run`) showing standard colorized `diff` output before any file writes.
   - Hardcoded boundaries: Only interacts with defined "Project Infrastructure Files", never touching "Project Domain Files" (`src/`, `tests/`, `CONTEXT.md`, etc.).
   - Interactive confirmation prompts by default (`Apply change? [y/N]`) unless overridden with a `-y`/`--yes` flag.
   - Verification of a clean Git working tree in the target repository before modifying any files.

## Consequences

* **Positive:**
  - Standardizes how optimizations are synchronized across all analytics repositories.
  - Avoids manual copypasting and Git path-mismatch errors.
  - Zero lock-in or extra Git configuration required for downstream projects.
* **Negative:**
  - Requires maintaining the target-to-source file mappings list in `upgrade-project.sh`.
