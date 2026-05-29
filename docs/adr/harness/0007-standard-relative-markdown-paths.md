# ADR-0007: Standard Relative Markdown Paths for Harness Rules & Specs

This document records the decision to migrate all harness rules, templates, and design specification indexes from host-specific absolute paths (`file:///Users/jubilee/...`) to standard relative Markdown links.

## Context

The Alpha-Zero-G developer harness and its downstream templates previously relied on absolute `file:///` URLs in rule files (such as `AGENTS.md`) and index lists. 
In the templates, this was managed by the templating engine replacing `{{PROJECT_ROOT}}` with the absolute folder path during generation or upgraders (`upgrade-project.sh`). 

However, this absolute-path approach introduced severe friction when running in a multi-device environment (e.g. sharing the same codebase between a macOS workstation and a Windows PC, or context-switching between different folder paths). Every time the repo was checked out or opened on a different machine:
1. Git reported rule files as modified (`dirty` working tree) because the username or root path had changed.
2. In-repository clicked links broke on other platforms unless they were programmatically re-written at every bootstrap.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-29

We will transition the harness files, design specifications, and templates to utilize standard relative Markdown paths:
1. **Remove Absolute URLs**: Replaced host-specific `file:///Users/jubilee/Projects/Alpha-Zero-G/` and `file:///{{PROJECT_ROOT}}/` style URLs in `AGENTS.md`, `global/AGENTS.md`, `templates/AGENTS.md`, `templates/README.md`, and `docs/design/INDEX.md` with relative links (e.g., `[CONTEXT.md](CONTEXT.md)`).
2. **Preserve Clickability**: Relative paths resolve natively inside VS Code, Cursor, and GitHub relative to the file containing the link, preserving click-to-open capability.
3. **Keep Script Backwards Compatibility**: Retain `{{PROJECT_ROOT}}` replacement logic in `create-project.sh` and `upgrade-project.sh` to ensure backwards compatibility for any custom downstream templates that may require absolute path resolution, while keeping core templates clean and fully relative.

## Consequences

* **Positive:**
  - **100% Platform Portability**: Harness rules work out-of-the-box on any host OS, folder hierarchy, or username.
  - **Zero Git Dirty-Tree Issues**: Switching devices no longer generates git modifications due to local path expansion differences.
  - **Simplified Upgrader**: Eliminates dynamic substitution complexity for standard rule files during bidirectional syncs.
* **Negative:**
  - None. Standard relative markdown links are universally supported in modern development tools.
