# Product Requirement Document (PRD) — Alpha-Zero-G Revamp to MVP Spec

## Problem Statement

The developer harness in `Alpha-Zero-G` has become over-engineered, messy, and drifted from the simple, elegant, and cross-device MVP design. It relies on complex symlinks, custom Google Drive settings, and bash-only status lines, making cross-device (macOS/Windows) synchronisation and debugging hard to maintain for a senior engineer.

## Solution

Revamp and clean the repository to strictly match the MVP specification outlined in `ALPHA-ZERO-G-AGENT-PROMPT.md` and `ALPHA-ZERO-G-RESEARCH.md`. The revamped harness will feature:
1. Organized global and project rule templates in `templates/global/` and `templates/project/`.
2. Fully portable, zero-link configurations (physical copies for skills, `@./AGENTS.md` references for Claude Code).
3. Cross-platform Python-based TUI statusline script (`statusline.py`).
4. Native, dual-platform setup, scaffolding, and upgrade scripts in both Bash (`.sh`) and PowerShell (`.ps1`).
5. Modular rules files under `.agents/rules/` (`code-style.md`, `safety.md`).

---

## User Stories

1. As a senior engineer, I want to run `setup-device.sh` on macOS, so that all my global agent configurations (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`), statusline script, and global skills are set up cleanly with zero broken links.
2. As a senior engineer, I want to run `setup-device.ps1` on Windows, so that my global configurations are set up natively without needing Admin rights, WSL, or symlink elevation.
3. As a senior engineer, I want the setup script to patch `settings.json` robustly using standard Python libraries, so that the custom statusline config is safely merged without regex or parser errors.
4. As a senior engineer, I want a custom Python-based statusline script, so that my Antigravity CLI status bar displays real-time project name, git branch, model, and date consistently across macOS and Windows.
5. As a senior engineer, I want to scaffold a new Python, R, or hybrid project using `scaffold-project.sh` (or `.ps1` on Windows), so that a canonical structure is instantly generated with local rules, starter ADR-001, Git, and physical skill copies.
6. As an AI agent working in the revamped project, I want `data/raw/` to be strictly protected by local safety rules, so that I never accidentally overwrite or delete raw data.
7. As a senior engineer, I want to upgrade an existing project using `upgrade-project.sh` (or `.ps1` on Windows), so that my older workspace gets the latest canonical harness folders and a dynamic upgrade ADR without losing existing custom instructions.

---

## Implementation Decisions

- **Messy File Cleanup:** Explicitly delete legacy files (`create-project.sh`, `init.sh`, `setup-harness.sh`, `global/statusline.sh`, `global/settings.json`, and all messy harness ADRs) to ensure a clean starting point.
- **Template Isolation:**
  - Store machine-level templates in `templates/global/` (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`).
  - Store project-level skeletons in `templates/project/` (`AGENTS.md`, `GEMINI.md`, `CLAUDE.md`, `.agents/rules/code-style.md`, `.agents/rules/safety.md`, `docs/adr/ADR-001-project-init.md`, `gitignore.template`, `skillsrc.template`, `README.md`).
- **No Symlinks Constraint:**
  - To prevent broken paths when folders are moved, all skill installations (both global and per-project) will copy directories physically from the cloned `mattpocock/skills` repository.
  - `CLAUDE.md` will contain the text `@./AGENTS.md` (no symlink) on both macOS and Windows.
- **Dynamic Placeholders:** Use `{{PROJECT_NAME}}` inside templates, dynamically replacing it during scaffolding.
- **Cross-Platform Statusline:** The statusline script (`scripts/statusline.py`) will be written in Python 3 standard library only, traversing directories upwards to find the nearest `# Project: <name>` inside `AGENTS.md`, and robustly handling non-git or missing config fallbacks.

---

## Testing Decisions

- **Test Seams:**
  - **Script Exit Codes:** All scripts must exit with `0` on success and non-zero on failure.
  - **Statusline Outputs:** Test `statusline.py` directly under mock workspace configurations (e.g. inside a temporary git repository, outside a git repository, and with missing settings).
  - **Scaffold Integrity:** Verify `scaffold-project` output by running mock scaffolding on a temporary folder and asserting all canonical files, folders, ADR-001, and Git history exist.
  - **Upgrade Safety:** Test `upgrade-project` on a simulated legacy project, verifying it appends missing blocks without destroying custom `AGENTS.md` rules.

---

## Out of Scope

- Automated synchronization via Google Drive or other external cloud drives (Git + GitHub is the only sync mechanism).
- Supporting platforms other than macOS (zsh) and Windows (native PowerShell 5+).
- Support for editors/TUI clients other than Antigravity CLI and Claude Code.

---

## Further Notes

- Once the revamp is complete, running `/setup-matt-pocock-skills` inside the revamped repository will align the triage labels and issue workflows perfectly.
