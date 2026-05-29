# ADR-0005: GitHub + Local Monorepo Harness Synchronization

We are transitioning the synchronization mechanism of the Alpha-Zero-G developer harness configurations from Google Drive stream mounts to a git-versioned monorepo style directly inside this repository.

## Context

In our initial design (ADR-0004), the global developer configurations (settings, rules, custom agent skills) were synchronized across multiple developer devices using Google Drive stream mounts as a shared storage layer. However, this introduced several major problems:
1. **Dependency on Cloud File Streams:** The setup required an active, mounted Google Drive folder path, adding an external, non-git-native dependency and leading to path-resolution failures on fresh or offline devices.
2. **Hardcoded Google Drive Paths:** Paths in `AGENTS.md` and symlink targets had to be hardcoded to paths under `Library/CloudStorage` or specific WSL/Windows drives, which vary wildly between setups and devices.
3. **No Native Version Control History:** Changes to settings and custom skills in Google Drive lacked fine-grained Git history, making it difficult to branch, merge, or review configuration updates.

To resolve this, we are establishing a git-native monorepo layout where rules, templates, and custom skills reside directly inside the local clone of the `Alpha-Zero-G` repository in a `global/` folder, and symlinks point directly from `~/.gemini` to this directory.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-29

We will migrate the source of truth for all global configurations to a `global/` directory within the `Alpha-Zero-G` repository itself.

1. **Monorepo Directory Structure:** Create `global/` to house standard rules (`AGENTS.md`, `GEMINI.md`) and global custom `skills/` directories tracked in Git.
2. **Strict Exclusions for Credentials/Local-Only Settings:** Add `global/.gitignore` to ignore sensitive/local-only configs (`settings.json`, `config/config.json`, `config/mcp_config.json`).
3. **Template Baselines:** Commit standard template baseline files (e.g. `settings.json.example`, `config.json.example`, `mcp_config.json.example`) to Git, allowing automatic local seeding on initialization.
4. **Unified Setup Script:** Replace `setup-global-harness.sh` with a rewritten `setup-harness.sh` that establishes symlinks directly to the local repository `global/` folder.

## Consequences

* **Positive:**
  * **Zero External Dependencies:** Eliminates reliance on Google Drive, allowing harness setup on entirely offline or cloud-native developer environments.
  * **Git-Native Versioning:** Rules (`AGENTS.md`, `GEMINI.md`) and custom skills are fully versioned in Git, permitting branching, code review, and clean rollbacks.
  * **Simplified Paths:**Pointers in rules are local and robust across setups.
  * **Robust Secret Gating:** Machine-specific configs containing credentials or specific absolute paths stay gitignored and local to each environment.

* **Negative:**
  * **Manual Sync of Ignored Files:** Changes to `settings.json` (like trusted workspaces) or private `mcp_config.json` configurations are not backed up automatically via GitHub, requiring manual setup or copy/paste between devices when modified.
