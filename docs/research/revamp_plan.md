# Implementation Plan — Revamp Alpha-Zero-G Harness to MVP Spec

This plan details the step-by-step revamp of the Alpha-Zero-G repository to conform strictly to the MVP specification defined in [ALPHA-ZERO-G-AGENT-PROMPT.md](file:///Users/jubilee/Projects/Alpha-Zero-G/ALPHA-ZERO-G-AGENT-PROMPT.md), using [ALPHA-ZERO-G-RESEARCH.md](file:///Users/jubilee/Projects/Alpha-Zero-G/ALPHA-ZERO-G-RESEARCH.md) as a technical reference.

---

## 1. Clean Messy Files (Explicitly Approved)

To eliminate legacy harness complexity, the following messy files will be removed:
- `create-project.sh`
- `init.sh`
- `setup-harness.sh`
- `global/statusline.sh`
- `global/settings.json` (and `global/settings.json.example`)
- `docs/adr/harness/` (all existing developer ADRs to be archived or removed, keeping a clean repo)

---

## 2. Template Structure (`templates/`)

We will store templates cleanly in `templates/global/` and `templates/project/` to separate machine-level settings from project scaffolding.

```
templates/
├── global/
│   ├── AGENTS.md                  # Machine-level cross-tool rules
│   ├── GEMINI.md                  # Antigravity CLI overrides
│   └── CLAUDE.md                  # Claude Code @-import
└── project/
    ├── AGENTS.md                  # Project rules template
    ├── GEMINI.md                  # Project Antigravity template
    ├── CLAUDE.md                  # CLAUDE.md file-ref template
    ├── .agents/
    │   └── rules/
    │       ├── code-style.md      # Python/R formatting rules
    │       └── safety.md          # Safety rules (data/raw protection)
    ├── docs/
    │   └── adr/
    │       └── ADR-001-project-init.md  # First ADR template
    ├── README.md                  # README skeleton
    ├── gitignore.template         # Starter .gitignore
    └── skillsrc.template          # Starter .skillsrc
```

---

## 3. Task Steps

### Task 1 — Agent Instruction Files
- Deploys templates to `templates/global/` and `templates/project/`.
- Ensures all instruction files remain **under 100 lines** (lean and concise).

### Task 2 — Skills Integration
- The setup scripts will run `git clone https://github.com/mattpocock/skills.git ~/.agent-skills/mattpocock/` if missing.
- Installs skills by **copying** (no symlinks) to:
  - Global: `~/.gemini/antigravity-cli/skills/`
  - Per-project: `.agents/skills/`

### Task 3 — Canonical Folder Architecture
- Standardizes folders for python, r, or hybrid projects:
  - `data/raw/` (Read-only, protected in safety rules)
  - `data/interim/`
  - `data/processed/`
  - `src/` (Python)
  - `R/` (R)
  - `tests/`
  - `notebooks/`

### Task 4 — Statusline Script (`scripts/statusline.py`)
- Python 3 standard library-only script.
- Outputs exactly one line to stdout: `[<project>] <branch> | <model-hint> | <date>`.
- Searches upward for nearest `AGENTS.md` to find `# Project: <name>`.
- Calls `git branch --show-current` with shell fallbacks.
- Reads `model` from `~/.gemini/antigravity-cli/settings.json`.

### Task 5 — Device Setup (`scripts/setup-device.sh` & `.ps1`)
- Runs 9 sequential steps.
- Uses inline python commands to parse and merge JSON settings in `settings.json`.
- Prompts before overwriting existing files in user's home directories.

### Task 6 — Project Scaffolding (`scripts/scaffold-project.sh` & `.ps1`)
- Creates canonical folder structures based on project type (`python`, `r`, or `hybrid`).
- Replaces `{{PROJECT_NAME}}` in templates during copy.
- Performs physical copies of global skills to `.agents/skills/`.
- Initializes Git and commits scaffolding.

### Task 7 — Project Upgrade (`scripts/upgrade-project.sh` & `.ps1`)
- Inspects target project structures.
- Detects whether inside a valid project.
- Appends `## Alpha-Zero-G` section to `AGENTS.md` if missing, without overwriting existing instructions.
- Auto-detects next ADR number and creates an upgrade ADR.

---

## 4. Verification and Acceptance

We will verify every task matches the acceptance checklist:
- [ ] Global `AGENTS.md` under 100 lines.
- [ ] `statusline.py` outputs one line cleanly, handles errors, and runs on macOS/Windows.
- [ ] Setup script runs successfully and patches `settings.json`.
- [ ] Scaffold script successfully builds python/r/hybrid directories, copies skills, writes ADR-001, and initializes git.
- [ ] Upgrade script correctly identifies missing elements, performs dry-run audit, and runs safely.
