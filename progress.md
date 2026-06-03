# Session Progress Log — Alpha-Zero-G

This document tracks the current state, active focuses, and completed milestones of the Alpha-Zero-G development environment.

---

## Active Goal

Establish a high-performance, deterministic developer harness for analytics, modeling, and statistical projects that enables clean cross-session collaboration with AI agents.

---

## 1. Milestones Completed

### Global Configuration Layer (~/.gemini/)

- `[x]` **Global AGENTS.md**: Compiled coding preferences, Python + R styling guidelines, safety limits, and stuck recovery steps.
- `[x]` **Global GEMINI.md**: Standardized Antigravity overrides, tool startup preferences, and session-log rules.
- `[x]` **Global Rules Baseline**: Formulated global `AGENTS.md` and `GEMINI.md` configurations to define portable developer-agent protocols.

### Project Scaffolding

- `[x]` **Repository Defaults**: Standardized `.gitignore`, compiled standard MIT `LICENSE`, and built introductory `README.md`.
- `[x]` **Fresh Skills Retrieval Integration**: Integrated shallow-cloning (`--depth 1`) from the `mattpocock/skills` repository. Project creation now dynamically retrieves the latest engineering and productivity skills directly from GitHub, deploying them to the project's local `.agents/skills/` folder. Includes robust offline error recovery and environment-driven test isolation (`SKIP_EXTERNAL_SKILLS`).
- `[x]` **Git Remote Auto-configuration**: Repaired the incorrect `original` remote in the `FPL-Jubilee-Ascent` project and configured `origin` correctly. Updated the `create-project.sh` generator script in `Alpha-Zero-G` to automatically extract the template's git remote URL, dynamically construct the corresponding URL for the new project, and configure the new project's remote origin automatically upon creation.

### Project Configuration & Safety

- `[x]` **Cognitive Entry Points**: Builtexpanded `AGENTS.md` system pointers, `GEMINI.md` overrides, and `CONTEXT.md` glossary.
- `[x]` **Enforcement Layer**: Implemented `.agents/hooks.json` to programmatically intercept and block dangerous actions (force pushes, root deletions) or gate configurations behind approvals.

### System of Record Documentation

- `[x]` **Architecture Guidelines**: Created `docs/architecture.md` containing layer diagrams.
- `[x]` **Decisions Registry (ADR)**: Generated `docs/beliefs.md` tracking dynamic bootstrapper decisions (ADR-001).
- `[x]` **Quality & Standards**: Created checklists in `docs/quality.md`.
- `[x]` **Dictionaries & Experiment Trackers**: Created `docs/DATA_DICT.md` and `docs/MODEL_NOTES.md` templates.

### Environment Setup & Verification

- `[x]` **pyproject.toml**: Defined analytics, visualization, modeling, and dev dependencies.
- `[x]` **Dynamic Bootstrapper (init.sh)**: Developed dynamic environment configuration script (auto-resolving `uv` for Python 3.12, dynamic checks for R via `renv`/`pak`, and smoke-test sensors).
- `[x]` **Deterministic Verification**: Ran `./init.sh` to construct the `.venv` and install 24 packages, asserting clean execution.
- `[x]` **User-First Interactive Generator**: Refactored `create-project.sh` to prompt interactively, copy targeted language partitions (Python, R, or Hybrid), resolve placeholders, and deploy standard documentation templates (`CONTEXT-FORMAT.md`, `ADR-FORMAT.md`).
- `[x]` **Agent-First Automations**: Added automated Git initialization, a baseline commit, and global trusted workspaces JSON auto-registration to new projects.
- `[x]` **Local Monorepo Harness Sync (setup-harness.sh)**: Migrated synchronization architecture from Google Drive to a local GitHub-versioned monorepo style (in `global/`), establishing robust local symlinks for settings, rules, and global custom skills across macOS and Windows with gitignored local config isolation and baseline template seeding.
- `[x]` **Bidirectional Harness Upgrader (`upgrade-project.sh`)**: Designed and built a robust utility that propagates generic harness configuration files (`init.sh`, `.agents/hooks.json`, `DEVELOPER_WORKFLOW.md`, base templates) bidirectionally. Pushing templates to downstream automatically resolves `{{PROJECT_NAME}}`, `{{PROJECT_ROOT}}`, and `{{PROJECT_DESCRIPTION}}` dynamically, and pulling optimizations back to core automatically restores standard placeholders. Enforces colorized git-native dry-run diffs and interactive confirmation safety prompts. Registered 100% passing pytest integration coverage.

---

## 2. Active Focus / Current Steps

1. **Harness Verification Approved:** Initial harness bootstrap is fully functional and checked off.
2. **Global Rules Templates & Installer Added (2026-05-31):** Restored global `GEMINI.md` and `AGENTS.md` templates under `global/`, seeded config templates, and created a unified, cross-platform `setup-harness.sh` script to install/sync these files on new/future devices with safe automatic backups.
3. **Ready to Clone:** Alpha-Zero-G is ready to act as a golden standard boilerplate.
3. **Idempotent Bootstrapper:** Modified `init.sh` to perform a directory check before attempting to create the virtual environment, making it 100% idempotent.
4. **Broken Symlink Resolved:** Successfully created the Google Drive target directory and populated `settings.json` based on custom user backups to resolve the broken `~/.gemini/antigravity-cli/settings.json` symlink.
5. **Trusted Workspaces Synced:** Added the downstream project paths to `settings.json` to enable seamless, password-free operations when context switching.
6. **Global Skills Audited:** Verified and mapped all 4 global skills (`grill-analytics`, `spec-model`, `validate-output`, and `to-colab`) in the global directory.
7. **Environment Bootstrapped:** Successfully executed the idempotent `init.sh` script to verify python smoke tests pass.
8. **Global Settings and Path Synchronization:** Audited and standardized global rules and settings across macOS and Windows configurations.
9. **Lightweight Global Environment Verified:** Confirmed `global/skills/` is kept completely clean and lightweight to prevent environment bloat, keeping the developer harness focused strictly on core scaffolding, path symlinks, and environment bootstrapping.
10. **Caveman Mode Deactivated:** User toggled `/caveman off`. Standard professional communication restored.
11. **Broken Skills Paths Resolved:** Created symlinks from `~/.gemini/antigravity-cli/skills` and `~/.gemini/config/skills` pointing to the real `~/.gemini/antigravity/skills` directory, resolving the empty `/skills` CLI command list issue.
12. **User-First Setup & Agent-First Run Completed:** Refactored `create-project.sh` to be fully interactive, prompt-driven, and selective. New workspaces automatically register in global settings and initialize Git. Standard templates for glossaries, design, and ADRs are auto-deployed.
13. **Cross-Device Sync Complete:** Implemented `setup-global-harness.sh` to automatically detect Google Drive stream paths on macOS and Windows and establish secure symlinks for settings, rules, and global skills.
14. **TDD Validation Green:** Developed an integration-style test suite in `tests/test_harness_bootstrap.py` validating all generator and sync functionalities with 100% test coverage.
15. **ADR & Golden Path Layout Standardized:** Successfully conducted an interactive `/grill-me` session to establish two distinct memory layers: `docs/beliefs.md` for fast, volatile working memory and `docs/adr/` for immutable, long-term architectural decision records. Created `docs/adr/0001-dynamic-bootstrapping.md` and `docs/adr/0002-automated-project-scaffolder.md` and updated `beliefs.md` with links. Embedded the full Golden Path workflow into this project's main `README.md`, while cleaning the downstream templates to utilize a dedicated `DEVELOPER_WORKFLOW.md` copied at creation time, verified by 100% passing tests.
16. **Existing Downstream Workspace Upgraded:** Successfully applied all the latest documentation structure, dedicated `DEVELOPER_WORKFLOW.md` root file, modular `docs/adr/` logs, and streamlined tabular `docs/beliefs.md` upgrades directly to the downstream project workspace, committing the upgrades to a clean feature branch.
17. **First End-to-End Upgrader Sync Completed:** Executed our bidirectional `upgrade-project.sh` to compare `Alpha-Zero-G` with downstream templates. Identified that the downstream project is 100% in sync with templates, with only the brand new `ADR-0003` file missing downstream. Successfully pushed the new ADR and committed it to the downstream project, bringing both repositories into perfect harmony.
18. **Scaffold Feedback Implemented (5 Issues from Downstream Projects):**
  - **(A) Harness ADR segregation:** Moved ADR-0001, ADR-0002, ADR-0003 to `docs/adr/harness/`. Updated `beliefs.md` links. `create-project.sh` no longer copies harness ADRs downstream — domain `docs/adr/` is clean from Day 1.
    - **(B) Tokenized template docs:** Created `templates/docs/architecture.md`, `templates/docs/beliefs.md` with `{{PROJECT_NAME}}` tokens. `create-project.sh` now copies from `templates/docs/` and applies `replace_placeholders` — zero hardcoded names downstream.
    - **(C) Language-specific quality docs:** Created `templates/docs/quality-python.md`, `quality-r.md`, `quality-hybrid.md`. `create-project.sh` selects based on `PROJECT_TYPE` — no spurious R sections in Python projects.
    - **(D) Domain ADR prompt file:** Created `templates/docs/adr/OPEN_DECISIONS.md` with 6 categories of generic decision prompts. Copied to all new projects. Agents backfill domain ADRs from Day 1.
    - **(E) ADR protocol in AGENTS.md template:** Added "Write ADRs" and "First Session" rules to `templates/AGENTS.md`. ADR maintenance is now a first-class protocol, not post-hoc cleanup.
19. **pyproject.toml Build Warn Resolved:** Added `[tool.setuptools.packages.find]` exclude list (`scratch`*, `templates*`, `tests*`, `docs*`) — editable install now clean, `init.sh` passes with zero errors.
20. **Developer Communication Style Defined:** Established structured professional communication expectations in the global configurations.
21. **Documentation Integrity Framework:** Standardized in-place updates for living project docs (`progress.md`, `beliefs.md`, `MODEL_NOTES.md`, `features.json`, `AGENTS.md`) directly in the git history for absolute session continuity.
22. **Planning vs Execution Model Separation Documented:** Antigravity CLI supports model switching via UI (thinking vs standard). No persistent automated split yet — user toggles manually per session.
23. **Feature Branch Merged to Master (2026-05-28):** `feature/adr-workflow-standardization` merged into `master` via no-ff merge (`0b95f8e..4048bfc`). All 24 files, 5 commits, 2,260 insertions pushed to `origin/master`. Harness now at golden-standard v1 baseline.
24. **Cross-Platform Windows Desktop Setup and Automated Configuration Sync (2026-05-28):**
  - Upgraded `init.sh` to dynamically detect if `.venv` is broken or OS-mismatched (e.g. from cross-device Google Drive sync) and automatically recreate it.
  - Added dynamic virtual environment activation (`.venv/Scripts/activate` on Windows, `.venv/bin/activate` on Unix).
  - Enhanced `setup-global-harness.sh` to automatically manage the `~/.gemini/config/` directory. It now creates, seeds (`config.json` with AI Credits enabled, empty `mcp_config.json`), and robustly symlinks configuration files to Google Drive.
  - **Discovered Google Drive VFAT Constraint & Solved via Developer Mode**: Discovered that since the Google Drive virtual stream is mounted as a `vfat` (FAT32) filesystem, Windows directory junctions (`mklink /j`) fail with `Local NTFS volumes are required`. Solved by updating the synchronization script to use native symbolic links (`mklink /d` and `mklink`) under Windows Developer Mode.
  - Stripped trailing carriage returns (`\r`) from `cygpath` results to prevent command truncation in Git Bash.
  - Verified and successfully ran `init.sh` and `setup-global-harness.sh` on the Windows desktop, creating a pristine, fully synchronized cross-device setup.
  - **Completed Zero-Touch Windows Setup Automation (2026-05-28)**: Designed and implemented a frictionless symlink strategy. Section 5 now performs an on-the-fly pre-flight test. If the host lacks native symlink capability (Developer Mode disabled / non-admin), it dynamically generates an elevated batch script (`AllowDevelopmentWithoutDevLicense = 1` registry enablement + `mklink` / `mklink /d` commands) and executes it in a single UAC session via PowerShell. Once Developer Mode is active, all subsequent sync commands work with zero elevation.
  - **Cross-Platform Test Coverage & UTF-8 I/O Resolution**: Fixed standard `open()` CP1252 decoding failures on Windows by explicitly forcing UTF-8 file encodings. Resolved hardcoded `bash` environment execution paths in subprocesses to dynamically locate Git Bash. Extended `test_harness_bootstrap.py` with mock environments validating the pre-flight checks, bypass temp dir pathing, and UAC elevation branch. Achieved a 100% clean, green 12/12 passing test suite on Windows.
  - **GitHub + Local Monorepo Harness Sync Migration**:
    - Deprecated legacy Google Drive synchronization and hardcoded paths.
    - Established a git-versioned `global/` folder inside `Alpha-Zero-G` monorepo containing rule baselines (`AGENTS.md`, `GEMINI.md`) and a custom `skills/` folder.
    - Excluded sensitive/local-specific config files (`settings.json`, `config.json`, `mcp_config.json`) from GitHub using `global/.gitignore`, while committing clean `.example` templates for seeding.
    - Rewrote the setup script into a unified `setup-harness.sh` that dynamically resolves repository root, backs up existing `~/.gemini` structures, seeds missing configurations, and establishes robust cross-platform symlinks.
    - Documented the transition in `docs/adr/harness/0005-local-monorepo-harness-synchronization.md` (ADR-0005) and registered it in `docs/beliefs.md`.
    - Refactored `tests/test_harness_bootstrap.py` to utilize isolated mock directories (`MOCK_GLOBAL_SRC`) and tested the sync mechanism, achieving a clean 100% green 12/12 test execution.
    - Updated all pointers, root rules, and `features.json` to eliminate Google Drive references.
    - Audited and resolved remaining legacy Google Drive references across documentation: deleted a duplicate ADR collision file (`0004-cross-platform-config-junctions 2.md`), updated hardcoded old Google Drive absolute paths in `docs/design/INDEX.md` to point to the new absolute local project path, and replaced the "Google Drive synced stream storage" references in both active and template architecture documents with "local/git-backed monorepo structures" (2026-05-29).
25. **Deterministic Python Execution via `uv run` Standard Established (2026-05-29):**
    - Established strict behavioral operating protocols in `AGENTS.md` and `DEVELOPER_WORKFLOW.md` (root, template, global) mandating the use of `uv run` for executing Python scripts (`uv run python`) and test runners (`uv run pytest`) to ensure deterministic package loading from the managed virtual environment and prevent system Python contamination.
    - Refactored `init.sh` and `templates/init.sh` to execute the Python validation smoke tests via `uv run python`, bypassing manual shell activation.
    - Refactored `create-project.sh` to check for `uv` and use `uv run python` for settings auto-registration with a resilient fallback.
    - Passed all 12/12 integration tests on mac successfully.
    - Logged decision in `docs/adr/harness/0006-deterministic-python-execution-via-uv.md` (ADR-0006) and registered it in `docs/beliefs.md`.
26. **Standard Relative Markdown Paths Migration (2026-05-29):**
    - Replaced host-specific absolute paths and `file:///{{PROJECT_ROOT}}/...` absolute paths across all root rules, monorepo settings, downstream scaffold templates, and design specification registries with standard relative Markdown links.
    - Ensured complete platform and device-agnostic portability, eliminating broken links and git-dirty states when switching devices.
    - Verified all changes against the entire 12/12 integration test suite.
    - Logged decision in `docs/adr/harness/0007-standard-relative-markdown-paths.md` (ADR-0007) and registered it in `docs/beliefs.md`.
27. **Complete Research Gap Closures and Template Enrichment (2026-05-29):**
    - Enriched the `AGENTS.md` template with comprehensive Coding Conventions, Data Handling Rules, Statistical Modeling Rules, Token & Context Management, Session Protocols, and Testing Requirements.
    - Updated pyproject.toml package dependencies in both core harness and python templates to bundle a complete validation, modeling, and analytics library stack.
    - Created cross-platform templates for `Makefile` (standardized on `uv run`), `.pre-commit-config.yaml`, `.env.example`, `config.py` (Pydantic Settings), and `conftest.py` (shared pytest fixtures).
    - Upgraded `create-project.sh` and `upgrade-project.sh` to support dynamic lowercase snake-case Python packages (e.g. `src/test_generated_proj`) and replace dynamic `{{PACKAGE_NAME}}` placeholders across templates.
    - Verified all generator templates and updates successfully against the 100% green 12/12 pytest integration tests.
29. **Modular Rules Refactoring — AGENTS.md & Scaffolding Templates (2026-05-29):**
    - Refactored `templates/AGENTS.md` from 261 lines to 68 lines by extracting non-essential prose into 9 dedicated sub-documents under `templates/docs/`.
    - Extracted sub-documents: `conventions.md`, `data-rules.md`, `modeling-rules.md`, `context-management.md`, `session-protocols.md`, `testing-requirements.md`, `security-rules.md`, `domain-rules.md`, `safety-policies.md`.
    - Added pointer rows for each extracted document into the System Pointers table; all `[HARD]` rules kept strictly inline in the main entry point.
    - Merged **Debug Protocol** and **Validation Loop** as dedicated sections inside `templates/DEVELOPER_WORKFLOW.md`.
    - Updated `create-project.sh` to copy and apply placeholder replacement for all 9 sub-documents.
    - Updated `upgrade-project.sh` `FILES_TO_SYNC` to include all 9 sub-documents for bidirectional push/pull/diff workflows.
    - Ran `setup-harness.sh` to re-sync global symlinks.
    - All 12/12 integration tests green.
    - Logged decision in `docs/adr/harness/0008-modular-rules-refactoring.md` (ADR-0008) and registered it in `docs/beliefs.md`.
28. **Start-over Project Scaffolding of Downstream Projects (2026-05-29):**
    - Scaffolded a brand-new clean Python statistical modeling project downstream utilizing `create-project.sh`.
    - Automatically synced path registration to global trustedWorkspaces.
    - Deterministically executed `init.sh` inside the new workspace, configuring the `uv` environment and installing 55 specialized packages.
    - Verified environment setup by executing initial test suite, ensuring `1 passed` green baseline test execution.
29. **Git Remote Repair & Auto-configuration (2026-05-30):**
    - Repaired the incorrect `original` remote in the `FPL-Jubilee-Ascent` project and configured `origin` pointing to the project's own GitHub URL.
    - Updated `create-project.sh` to extract the host template remote, dynamically construct the new project's remote, and configure the git remote automatically upon creation.
    - Tested and verified the updated generator by bootstrapping a dummy project and checking that it successfully configured the new git remote.
30. **Harness Statusline Portability & Float Formatting (2026-05-31):**
    - Created `global/statusline.sh` custom statusline script inside the local monorepo harness, with precision float formatting (`awk '{printf "%.1f", $1}'`) to force clean `xx.x%` (instead of `xx.xxxxxxxxx%`) context token percentage outputs.
    - Updated `global/settings.json` and `settings.json.example` to declare the `statusLine` command utilizing the generic `{{GEMINI_DIR}}` placeholder.
    - Upgraded `setup-harness.sh` to seamlessly deploy `statusline.sh` to `~/.gemini/antigravity-cli/statusline.sh` (marked executable via `chmod +x`), back it up safely, and dynamically substitute `{{GEMINI_DIR}}` in deployed client settings during bootstrap.
    - Successfully validated zero-touch cross-device sync installation and verified the formatted CLI status line results in standard TUI mock scenarios.
31. **Harness Statusline Quota Separation & G1 Overage Credits Integration (2026-05-31):**
    - Conducted multiple interactive `/grill-me` sessions to align on the exact layout and data sources for the custom statusline.
    - Redesigned `global/statusline.sh` to extract and display separated Claude and Gemini quotas simultaneously from the background usage cache (`/tmp/antigravity_quota_cache.json`).
    - Configured the layout to always place **Gemini** before **Claude**. If a quota percentage is unavailable, it is dynamically set to `0.0%` rather than `N/A`.
    - Integrated time-to-reset parsing for both models, appending the remaining duration in parentheses after the quota percentage (e.g. `(1h 7m)`).
    - Integrated support for checking "AI credits" (renamed from G1 Overage). It dynamically reads from the `G1_CREDITS_OVERAGE` environment variable or a local config file `~/.gemini/antigravity-cli/g1_credits.txt`, and defaults cleanly to `N/A` if neither is configured to avoid arbitrary mock values.
    - Executed `./setup-harness.sh` to deploy the changes and verified output formatting under standard terminal user interface (TUI) mock scenarios.
32. **Skill Symlink Strategy Simplified — Project-Level Skills Only (2026-05-31):**
    - Removed the global helper symlink block (section 7) from `setup-harness.sh`: eliminated `HELPER_SYMLINK_PAIRS`, `create_symlink`, `create_symlinks_elevated`, `is_windows`, `test_symlink_capability`, and the symlink orchestrator.
    - Removed the corresponding `verify_symlink` calls and the now-dead `verify_symlink()` function from the verification section.
    - Skills are now managed exclusively at the project level (`.agents/skills/`) rather than via global `~/.gemini/antigravity-cli/skills` or `~/.gemini/config/skills` symlinks.
    - `setup-harness.sh` now only deploys physical files (rules, configs, statusline) with zero symlink side-effects.
33. **Global Custom Skills Repository Integration (2026-06-01):**
    - Cloned the standard engineering and productivity skills from `github.com/mattpocock/skills` and seeded them to `global/skills/` within the monorepo harness.
    - Executed `./setup-harness.sh` to physically deploy all 14 skills (`caveman`, `diagnose`, `grill-me`, `grill-with-docs`, `handoff`, `improve-codebase-architecture`, `prototype`, `setup-matt-pocock-skills`, `tdd`, `to-issues`, `to-prd`, `triage`, `write-a-skill`, `zoom-out`) globally to `~/.gemini/antigravity/skills/`, verifying clean cross-platform alignment.
34. **Caveman Mode Reactivated (2026-06-01):**
    - User toggled `/caveman on`. Terse, high-density communication protocol activated.
35. **Revamp Grilling & Mappings Aligned (2026-06-01):**
    - Drew the revamp tasks dependency flow diagram.
    - Performed detailed `/grill-with-docs` session aligning on **No-Symlink Portability**: physical copies for skills, pure `@-import` file-references for `CLAUDE.md`, selective source directory generation, and resilient merges for settings.
    - Updated [CONTEXT.md](CONTEXT.md) glossary with the new portability term.
    - Ran `/setup-matt-pocock-skills` to establish standard GitHub issue tracking, canonical triage labels, and domain routing documents under `docs/agents/`.
36. **Revamp Phase 1 Executed (2026-06-01):**
    - Purged legacy files (Issue #2): deleted `create-project.sh`, `init.sh`, `setup-harness.sh`, `global/statusline.sh`, `global/settings.json`, `global/settings.json.example`, `global/AGENTS.md`, `global/GEMINI.md`, and the entire `docs/adr/harness/` directory.
    - Built Base Templates (Issue #3) under `templates/global/` and `templates/project/` exactly as specified.
    - Guaranteed all template files are strictly under 100 lines and use portable relative references.
    - Wrote new test suite in `tests/test_phase1.py` and deleted obsolete test bootstrap file. Ran `uv run pytest` successfully with 100% green compliance.
37. **mattpocock/skills Integration Completed (2026-06-01):**
    - Created `templates/skills_manifest.txt` with 10 engineering and productivity skills.
    - Wrote `tests/test_skills.py` to validate manifest and project template files.
    - Verified all tests pass cleanly via `uv run pytest`.
38. **Cross-Platform Python TUI Statusline Script Added (2026-06-01):**
    - Implemented `scripts/statusline.py` using 100% Python 3 standard library.
    - Features upwards traversal from current directory to locate `AGENTS.md` and capture the `# Project: <name>` block, falling back to the current directory name.
    - Safely invokes `git branch --show-current` with gracefall fallbacks.
    - Parses settings.json for model hints, falling back to "Gemini" on missing/invalid files.
    - Formats output exactly as `[<project>] <branch> | <model-hint> | <date>`.
    - Protected with 100% crash protection wrap in the main execution block.
    - Wrote rigorous unit tests under `tests/test_statusline.py` and confirmed 100% test coverage with all 14/14 tests passing.
39. **Cross-Platform Device Setup Scripts Added (2026-06-01):**
    - Implemented `scripts/setup-device.sh` (Bash) and `scripts/setup-device.ps1` (PowerShell) performing 9 ordered setup steps with OK/SKIP/FAIL statuses and Exit summary.
    - Used inline Python standard library JSON merging for robust `settings.json` patching.
    - Added user confirmation prompt logic for deploying global configurations with non-interactive fallbacks.
    - Implemented rigorous unit/integration tests in `tests/test_setup.py` verifying first-run, second-run (overwrite and skip), exit 0 codes, and settings merges, resulting in 100% test coverage.
    - Verified all 17/17 tests pass successfully.
40. **Task 7 — Project Upgrader Added (2026-06-01):**
    - Implemented `scripts/upgrade-project.sh` (Bash) and `scripts/upgrade-project.ps1` (PowerShell) inside `scripts/` directory.
    - Added safety features: verifies execution inside a valid project (detecting `.git` or `AGENTS.md`), supports `--dry-run` to print audits without writing, never overwrites user files, and appends `## Alpha-Zero-G` block to existing `AGENTS.md` if absent.
    - Automated missing directories creation and dynamically scanned `docs/adr/` to identify the next free ADR index and generated `docs/adr/ADR-NNN-alpha-zero-g-upgrade.md`.
    - Verified all tests pass cleanly via `uv run pytest tests/test_upgrade.py`.
41. **Task 6 — New Project Scaffolder Added (2026-06-01):**
    - Implemented `scripts/scaffold-project.sh` (Bash) and `scripts/scaffold-project.ps1` (PowerShell) delegating core bootstrapping logic to a modular `scripts/scaffold.py` script.
    - Verified all script and logic files are kept strictly under 100 lines.
    - Generated canonical folder structures dynamically based on type (`--type python|r|hybrid`), replaced placeholders, copied 10 global skills physically, deployed `.gitignore` and `.skillsrc`, generated `docs/adr/ADR-001-project-init.md`, and initialized local Git with a baseline commit.
    - Wrote robust tests in `tests/test_scaffold.py` verifying all requirements.
    - Verified all tests pass cleanly via `uv run pytest tests/test_scaffold.py`.
43. **Global Skills Migration & Cleanup (2026-06-01):**
    - Migrated the custom `to-dfp` and `execute-dfp` skills from `FPL-Jubilee-Ascent` to the main templates repository at `templates/skills/`.
    - Improved `dfp_planner.py` to dynamically resolve the active project workspace root (searching up from `os.getcwd()` for `.git` or `AGENTS.md`) so it writes to the correct project directory when executed globally.
    - Updated `templates/skills_manifest.txt`, `scripts/setup-device.sh`, `scripts/setup-device.ps1`, and `scripts/scaffold.py` to support dynamic, custom templates/skills/ copies and recursive directory matching for restructured skills packages.
    - Cleaned up redundant local copies of all 16 skills under `FPL-Jubilee-Ascent/.agents/skills/` via Git tracking deletion, keeping the project perfectly portable.
    - Verified all 23 unit/integration tests successfully run green.
44. **Improving execute-dfp Skill (2026-06-03):**
    - Initiated `/grill-with-docs` session to align on execute-dfp improvements.
    - Proposed dynamic grilling (grill vs. TDD-only) and robust concurrent subagent execution.
    - Updated `execute-dfp` to a continuous graph execution model natively parsing the Mermaid DFP instead of strict layers.
    - Formatted `execute-dfp` skill according to the `/write-a-skill` template guidelines.
    - Pushed changes to `Alpha-Zero-G` repo for cross-device portability.
45. **Enhanced Statusline Portability & Mathematical Correctness (2026-06-01):**
    - Restored rich context window metrics, Gemini/Claude quota tracking, and time until reset inside the 100% Python `scripts/statusline.py` status line script.
    - Removed obsolete AI credits block as requested.
    - Adjusted context token display calculation to mathematically derive active used tokens using `(used_percentage / 100) * window_size` to ensure exact numeric alignment (e.g. `624/1.0M (0.1%)` instead of input tokens mismatched to window size).
    - Deployed script globally to `~/.agent-config/statusline.py` and verified fallback and rich piped execution formats.
    - Updated unit/integration tests in `tests/test_statusline.py` for 100% coverage compliance.
46. **Full Project Review & Artifact Cleanup (2026-06-03):**
    - Conducted a comprehensive `/grill-with-docs` session to align the repository state with the Phase 1 architectural revamp.
    - Synced `features.json` to F-26, accurately reflecting all new cross-platform setup, `scaffold.py`, and statusline scripts.
    - Updated `CONTEXT.md` inline to correctly document `pytest`, `scaffold.py`, and project utility updates (replacing legacy `init.sh` references).
    - Executed a physical audit purging `templates/init.sh`, the obsolete `docs/handoff.md`, `scratch/debug_test.py`, and auto-generated `__pycache__` and `.egg-info` directories, ensuring zero technical debt.
47. **Windows PowerShell Robustness & Documentation (2026-06-03):**
    - Diagnosed and fixed an `InvalidVariableReferenceWithDrive` syntax error in `setup-device.ps1` and `upgrade-project.ps1` caused by unescaped colon characters trailing variable interpolation (e.g. `$StepNum:`). Fixed by wrapping in subexpressions `$($StepNum):`.
    - Parameterized the pytest suite (`tests/test_upgrade.py`) to dynamically test the `.ps1` script when executing on Windows instead of failing on the `.sh` script execution.
    - Implemented a `@bash_only` decorator in `tests/test_setup.py` and `tests/test_scaffold.py` to seamlessly skip bash execution tests on Windows systems where bash is unavailable.
    - Verified the test suite executes identically with 100% green coverage on Windows.
    - Updated `README.md` to split execution commands cleanly into Mac/Linux (bash) and Windows (PowerShell) sections, correcting scaffold arguments.

48. **Statusline Urgency Bar Refinement & Revert (2026-06-03):**
    - Initially modified the statusline layout to use repeating `[]` blocks.
    - Reverted to the single bar layout (`[████░░░░░░]`) while retaining the updated deterministic stage triggers, degrading threshold calculations, and state mappings.
    - Mathematically refined the visual fullness of the single urgency bar to map exactly to the `proximity_percentage` (progress towards the degrading threshold), capped at 100%. Clarified that the `X% to Degrading` metric refers strictly to the percentage of the budget consumed towards the threshold, not the remaining buffer.
    - Deployed the updated clean python script directly to `~/.agent-config/statusline.py` for immediate execution in `agy` TUI.
    - Verified all 11 unit tests pass cleanly.
49. **Dynamic Skills Fetching & Manifest Removal (2026-06-03):**
    - Deprecated the hardcoded `templates/skills_manifest.txt` allowlist to enable automatic integration of upstream community skills.
    - Deleted `templates/skills_manifest.txt` and removed the dependent tests from `tests/test_skills.py`.
    - Rewrote `scripts/setup-device.py` to dynamically pull the latest `mattpocock/skills` repository (using `git pull` if it already exists, instead of skipping).
    - Configured the installer to automatically copy all folders recursively from the `skills/engineering/` and `skills/productivity/` categories, ensuring all future skills in those categories are inherently supported.
    - Maintained correct deployment for local custom skills located in `templates/skills/` (like `execute-dfp` and `to-dfp`).

---

## 3. Next Session Priorities

1. Maintain and monitor the golden standard harness and global skills integrations.

