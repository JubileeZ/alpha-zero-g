# Alpha-Zero-G — Agent Build Prompt
**Version:** MVP-1.0 | **Date:** 2026-06-01
**Reference:** `ALPHA-ZERO-G-RESEARCH.md` (companion file — read before acting)

---

## What You Are Building

**Alpha-Zero-G** is a minimal, cross-device harness for Python & R analytics projects.
Its job: let AI agents (Antigravity CLI, Cursor, Claude Code) work autonomously across
sessions and devices without regression — by defining global rules, skills, folder
conventions, and setup/scaffold scripts in one place.

This is the **MVP build**. Focus on correctness and completeness over polish.
Each task below is independently testable. Build in order; tasks 1–3 are blockers for 5–7.

---

## Constraints

- **Primary agent surface:** Antigravity CLI (`agy`) only for now.
- **Cross-platform required:** macOS (zsh) and Windows (native PowerShell 5+, no WSL).
- **Zero extra dependencies** on a clean device: Python 3 stdlib only for scripts.
- **No Google Drive sync.** Git + GitHub is the only sync mechanism.
- **CLAUDE.md must be a symlink to AGENTS.md** (not a copy) until Claude Code adds
  native AGENTS.md support. On Windows use a file reference pattern instead (see task 1).
- Every agent instruction file must stay **under 100 lines**. Lean > verbose.

---

## Task 1 — Agent Instruction Files

### Global (machine-level, applies to all projects)

Create template files for global install at:
```
~/.gemini/AGENTS.md          # cross-tool rules (Antigravity + Cursor + Claude Code)
~/.gemini/GEMINI.md          # Antigravity-only overrides (minimal; sources AGENTS.md)
~/.claude/CLAUDE.md          # Claude Code global; sources global AGENTS.md via @-import
```

**Global AGENTS.md must contain:**
- Personal style: concise responses, prefer explicit over implicit
- Safety rails: never delete files without explicit approval, never push to main directly
- Testing habit: always write tests before marking a task done
- Session discipline: write a `docs/handoff.md` before ending a session (feeds `/handoff`)
- Language defaults: Python 3, R 4+; use `uv` for Python deps, `renv` for R

**Global GEMINI.md must contain:**
```markdown
# Antigravity-Specific Overrides
@~/.gemini/AGENTS.md

## Antigravity CLI
- Default model: Gemini 3.1 Pro (High) for architecture; Gemini 3.5 Flash (High) for boilerplate
- Statusline: enabled (config via ~/.gemini/antigravity-cli/settings.json)
- Trust: auto-approve git read, git status, pytest, Rscript read-only
```

**Global CLAUDE.md must contain:**
```markdown
@~/.gemini/AGENTS.md
```
(Single-line @-import. Claude Code merges this automatically.)

### Per-project (scaffold these in Task 6)

```
AGENTS.md       # project rules — inherits intent from global, adds domain constraints
GEMINI.md       # one line: @~/.gemini/GEMINI.md, then project overrides
CLAUDE.md       # symlink → AGENTS.md (Mac/Linux) OR contains: @./AGENTS.md (Windows)
```

**Rules for all agent files:**
- Every line must answer: "Would removing this cause the agent to make a recoverable mistake?"
- If no: remove the line.
- Version-control all agent files. Treat them as code.

---

## Task 2 — Skills: Clone and Install mattpocock/skills

Clone `https://github.com/mattpocock/skills` to `~/.agent-skills/mattpocock/`.

### Skills to activate globally (`~/.gemini/antigravity-cli/skills/`)

Symlink or copy the following into the global skills directory:

**From `skills/engineering/`** — install ALL:
```
diagnose
improve-codebase-architecture
setup-matt-pocock-skills
tdd
to-issues
to-prd
zoom-out
```
(Plus any additional folders found in `skills/engineering/` — install everything that has a `SKILL.md`.)

**From `skills/productivity/`** — install these three only:
```
caveman
handoff
write-a-skill
```

### Skill path mapping

| Platform | Global skills directory                               |
|----------|-------------------------------------------------------|
| Mac/Linux | `~/.gemini/antigravity-cli/skills/`                  |
| Windows   | `%USERPROFILE%\.gemini\antigravity-cli\skills\`      |

For per-project skills (Task 6), copy into `.agents/skills/` in the project root.

### Post-install

After installing, run `/setup-matt-pocock-skills` in `agy` for each new repo to configure
issue tracker (GitHub), triage labels, and domain doc layout per the skill's guided flow.

---

## Task 3 — Canonical Folder Architecture

This is the standard layout for every new project scaffolded by Alpha-Zero-G.

```
project-root/
├── AGENTS.md                       # Project agent rules (source of truth)
├── GEMINI.md                       # Antigravity overrides (@-imports global + adds project rules)
├── CLAUDE.md                       # Symlink → AGENTS.md (Mac) | @./AGENTS.md (Windows)
│
├── .agents/
│   ├── rules/                      # Supplemental rule files (loaded by Antigravity)
│   │   ├── code-style.md           # Language/formatting conventions
│   │   └── safety.md               # What agents must never do in this project
│   └── skills/                     # Project-scoped skills (symlinks to global or custom)
│
├── docs/
│   ├── adr/                        # Architecture Decision Records
│   │   └── ADR-001-project-init.md # Auto-created at scaffold time
│   ├── research/                   # Research spikes (written BEFORE ADRs)
│   └── handoff.md                  # Session handoff notes (updated by /handoff skill)
│
├── data/
│   ├── raw/                        # NEVER modified by agents (AGENTS.md must enforce this)
│   ├── interim/                    # Agent-safe intermediate outputs
│   └── processed/                  # Final outputs
│
├── src/                            # Python source (or R/ for R projects, both for hybrid)
├── R/                              # R source (hybrid projects only)
├── tests/                          # All tests; mirrors src/ or R/ structure
├── notebooks/                      # Exploration only; never imported by src/
│
├── scripts/
│   ├── setup-device.sh             # Task 5: Mac/Linux setup
│   ├── setup-device.ps1            # Task 5: Windows setup
│   ├── scaffold-project.sh         # Task 6: new project scaffold
│   ├── scaffold-project.ps1        # Task 6: Windows version
│   ├── upgrade-project.sh          # Task 7: upgrade existing project
│   └── statusline.py               # Task 4: cross-platform statusline script
│
├── .skillsrc                       # Points to global skills path
├── .gitignore
└── README.md
```

### ADR trigger rules (encode in AGENTS.md):

An agent MUST write an ADR when:
- Choosing a library or tool dependency
- Changing data schema or output format
- Modifying project folder structure
- Adopting or changing a testing strategy
- Any decision that would be hard to reverse

Workflow before an ADR:
1. Write research spike → `docs/research/YYYY-MM-DD-topic.md`
2. Write ADR → `docs/adr/ADR-NNN-slug.md`
3. Tag affected source files with `# ADR-NNN` in a comment

ADR template (use this exactly):
```markdown
# ADR-NNN: [Short Title]
**Status:** Proposed | Accepted | Superseded by ADR-NNN
**Date:** YYYY-MM-DD
**Depends on:** ADR-NNN (if any)

## Context
[What problem are we solving? What forces are at play?]

## Decision
[What did we decide?]

## Alternatives Considered
- [Alt A]: [Why rejected]
- [Alt B]: [Why rejected]

## Consequences
- Good: ...
- Bad: ...
```

---

## Task 4 — Antigravity CLI Statusline

The statusline is configured via `~/.gemini/antigravity-cli/settings.json`.

### Config entry to write during device setup:

```json
{
  "statusLine": {
    "type": "custom",
    "command": "python3 ~/.agent-config/statusline.py",
    "enabled": true
  }
}
```

On Windows, the command field should be:
```json
"command": "python %USERPROFILE%\\.agent-config\\statusline.py"
```

### Statusline script: `scripts/statusline.py`

Write a **Python 3, stdlib-only** script at `scripts/statusline.py` (copied to
`~/.agent-config/statusline.py` during device setup).

**It must:**
- Output exactly one line to stdout
- Work on Mac and Windows with no external packages
- Never crash silently (wrap all calls in try/except, fallback to plain text)

**Output format:**
```
[<project>] <branch> | <model-hint> | <date>
```

**Data sources (stdlib only):**
- `project`: read from nearest `AGENTS.md` first line `# Project: <name>`, else git remote name, else folder name
- `branch`: `git branch --show-current` via `subprocess.run`
- `model-hint`: read from `~/.gemini/antigravity-cli/settings.json` key `.model`, else `"Gemini"`
- `date`: `datetime.now().strftime("%Y-%m-%d %H:%M")`

**Platform detection:**
```python
import platform
IS_WINDOWS = platform.system() == "Windows"
```

Use `/statusline enable` or `/statusline disable` inside `agy` to toggle.
Use `/statusline reset` to revert to default if the script errors.

---

## Task 5 — Device Setup Scripts

Two scripts: `scripts/setup-device.sh` (Mac/Linux) and `scripts/setup-device.ps1` (Windows).

Each script must perform these steps **in order** and print `[OK]` / `[SKIP]` / `[FAIL]`
for each:

```
Step 1  Clone mattpocock/skills → ~/.agent-skills/mattpocock/  (skip if exists)
Step 2  Symlink/copy skills to ~/.gemini/antigravity-cli/skills/
Step 3  Write ~/.gemini/AGENTS.md from template (prompt before overwrite if exists)
Step 4  Write ~/.gemini/GEMINI.md from template (same guard)
Step 5  Write ~/.claude/CLAUDE.md (single @-import line) (same guard)
Step 6  Copy statusline.py → ~/.agent-config/statusline.py
Step 7  Patch ~/.gemini/antigravity-cli/settings.json with statusLine config
        (use Python json stdlib to read/merge/write, not sed/regex)
Step 8  Verify: run python3 ~/.agent-config/statusline.py and print output
Step 9  Print summary: N/8 steps OK
```

**Windows notes:**
- Use PowerShell 5+ syntax only. No WSL, no bash.
- `CLAUDE.md` cannot be a symlink on Windows without admin rights; write `@./AGENTS.md`
  as file content instead.
- Use `$env:USERPROFILE` not `~` for paths in PowerShell scripts.
- `settings.json` patch: use `python` not `python3` on Windows path.

---

## Task 6 — New Project Scaffold Function

Script: `scripts/scaffold-project.sh` / `scripts/scaffold-project.ps1`

Usage:
```bash
./scripts/scaffold-project.sh <project-name> [--type python|r|hybrid]
```

Steps:
1. Create the full canonical folder structure from Task 3.
2. Write `AGENTS.md` from template — include a `# Project: <name>` header line (required
   by statusline.py) and a `data/raw/` protection rule.
3. Write `GEMINI.md` (single `@~/.gemini/GEMINI.md` line + empty project overrides block).
4. On Mac/Linux: `ln -s AGENTS.md CLAUDE.md`. On Windows: write `@./AGENTS.md` to `CLAUDE.md`.
5. Symlink `.agents/skills/` to `~/.gemini/antigravity-cli/skills/` (reuse global skills).
6. Write `docs/adr/ADR-001-project-init.md` using the ADR template (Status: Accepted,
   decision = "Project bootstrapped via Alpha-Zero-G scaffold").
7. Write starter `.gitignore` (Python/R standard + `data/raw/` + `.agents/` local overrides).
8. Write `.skillsrc` pointing at global skills path.
9. `git init` and make initial commit with message: `chore: scaffold via alpha-zero-g`.
10. Print: `Alpha-Zero-G scaffold complete. Run /setup-matt-pocock-skills in agy next.`

---

## Task 7 — Upgrade Existing Project

Script: `scripts/upgrade-project.sh` / `scripts/upgrade-project.ps1`

Usage (run from inside an existing project root):
```bash
./scripts/upgrade-project.sh [--dry-run]
```

Steps:
1. **Audit**: check for each item in the canonical structure (Tasks 1 + 3). Print what exists
   and what is missing. In `--dry-run` mode, stop here.
2. **Confirm**: print diff, ask for confirmation before writing anything.
3. **Add missing files only**: never overwrite existing `AGENTS.md`, `GEMINI.md`, or source
   code. Append a `## Alpha-Zero-G` section to existing `AGENTS.md` if the section is absent.
4. Create any missing folders (`docs/adr/`, `docs/research/`, `.agents/rules/`).
5. Write an upgrade ADR: `docs/adr/ADR-NNN-alpha-zero-g-upgrade.md`
   (auto-detect next ADR number by scanning `docs/adr/`).
6. Print: `Upgrade complete. N items added, M items skipped (already present).`

---

## Acceptance Checklist

Before marking the build done, verify:

- [ ] `~/.gemini/AGENTS.md` exists and is under 100 lines
- [ ] `agy` starts and `/skills` lists all 10 installed skills
- [ ] `scripts/statusline.py` runs cleanly on both platforms, outputs one line
- [ ] `settings.json` statusLine entry is present and `enabled: true`
- [ ] `/statusline` in `agy` TUI shows the custom output
- [ ] `scripts/setup-device.sh` runs cleanly on a fresh Mac; all 8 steps pass
- [ ] `scripts/setup-device.ps1` runs cleanly on a fresh Windows machine
- [ ] `scripts/scaffold-project.sh new-test-project --type python` creates the full structure
- [ ] Scaffolded project has `AGENTS.md`, `CLAUDE.md`, `docs/adr/ADR-001-*.md`
- [ ] `scripts/upgrade-project.sh --dry-run` in an existing repo prints audit without writing
- [ ] All scripts exit with code 0 on success, non-zero on failure

---

## Reference

Read `ALPHA-ZERO-G-RESEARCH.md` for context on:
- Why AGENTS.md is the cross-tool standard (not GEMINI.md or CLAUDE.md)
- Antigravity CLI install paths, `settings.json` structure, known issues
- mattpocock/skills philosophy and skill install patterns
- ADR best practices and trigger conditions
- Harness engineering principles (keep lean, encode constraints, not descriptions)
