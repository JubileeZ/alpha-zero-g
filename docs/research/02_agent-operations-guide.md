# Alpha-Zero-G: Agent Operations Guide
**Standard Operating Procedures & Project Scaffolding — v1.0**

This document defines the standard operating procedures, repository directory layout, template specifications, and execution cycles for AI agents developing in Alpha-Zero-G projects.

---

## Part 1: Core Principles of Agent Behavior

### 1.1 Files Are Your Memory
AI agents have no memory between chat sessions. Any progress, design decision, or code structure not written to a file will be lost.
```
Rule: If it occurred but was not persisted to a file, it did not happen.
```
Every active workspace must maintain these persistent files in git:
*   `AGENTS.md` — The agent rulebook (read first at start of every session).
*   `progress.md` — Active task checklists, current focuses, and next actions.
*   `docs/beliefs.md` — Tabular index of active developer architectural beliefs.
*   `docs/adr/` — modular architectural decision records (using sequential naming `000N-short-title.md`).

### 1.2 Context Protection
*   NEVER dump complete raw dataframes or raw matrices into the context window.
*   Use `.head(5)`, `.describe()`, and `.dtypes` for data inspections.
*   Reference file paths and specific line numbers rather than copy-pasting whole code blocks.

### 1.3 Strict Procedural Loops
1.  **Orient:** Run `pwd`, check `git status`, and read `progress.md` before coding.
2.  **Verify:** Run `bash init.sh` and `uv run pytest` to ensure you are starting from a fully passing baseline.
3.  **Execute:** Implement type-hinted code and writing corresponding unit tests simultaneously.
4.  **Preserve:** Run linters (`make check`), write a detailed commit, update `progress.md` and `docs/beliefs.md`, and detail starting instructions for the next session.

---

## Part 2: Standard Workspace Directory Structure

All new projects created via `create-project.sh` follow this standard directory structure:

```
{project-name}/
│
├── AGENTS.md                    ← PRIMARY: Agent rulebook (ALWAYS READ FIRST)
├── CONTEXT.md                   ← Domain glossary and jargon mappings
├── DEVELOPER_WORKFLOW.md        ← Step-by-step developer guidelines
├── README.md                    ← User-facing documentation
├── progress.md                  ← Volatile memory: active task list
├── features.json                ← Feature deliverables checklist
├── init.sh                      ← Idempotent environment bootstrap script
├── pyproject.toml               ← Project dependencies and configuration
│
├── .agents/
│   ├── hooks.json               ← Hard safety gates and approval limits
│   └── skills/                  ← Workspace-specific custom skill files
│
├── src/
│   └── {package_name}/          ← Lowercase snake_case package folder
│       ├── __init__.py
│       └── config.py            ← Centralized Pydantic Settings singleton
│
├── tests/
│   ├── conftest.py              ← Shared fixtures and override hooks
│   └── test_smoke.py            ← Basic baseline verification tests
│
├── notebooks/                   ← Research notebooks in py:percent format
├── docs/
│   ├── architecture.md          ← Project layering layout
│   ├── beliefs.md               ← Memory registry of design decisions
│   ├── quality.md               ← Domain-specific quality checklists
│   ├── DATA_DICT.md             ← Column definitions and value units
│   ├── MODEL_NOTES.md           ← Mathematical assumptions and modeling log
│   └── adr/
│       ├── 0000-adr-template.md ← Architectural decision record template
│       └── OPEN_DECISIONS.md    ← Framework prompting domain ADRs
```

---

## Part 3: Standard Infrastructure Templates

These files are deployed into the project root by the scaffolding tools to establish robust, cross-platform environments:

### 3.1 `Makefile`
Enforces consistent testing and linting commands across platforms using deterministic `uv run` commands:
```makefile
# Makefile — Works on macOS, Linux, and Windows (with make installed)
.PHONY: setup install lint format type-check test test-cov check clean

ifeq ($(OS),Windows_NT)
    RM = rmdir /s /q
    CP = copy
else
    RM = rm -rf
    CP = cp
endif

setup:
	uv sync
	uv run pre-commit install
	$(CP) .env.example .env 2>/dev/null || $(CP) .env.example .env

install:
	uv sync

lint:
	uv run ruff check src/ tests/

format:
	uv run ruff format src/ tests/

type-check:
	uv run mypy src/

test:
	uv run pytest tests/ -v

check: lint type-check test
```

### 3.2 `.pre-commit-config.yaml`
Establishes automated local git hooks before commits can be written:
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
        additional_dependencies: [pydantic, pandas-stubs]
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: detect-private-key
```

### 3.3 Centralized Pydantic Settings (`config.py`)
Centralizes environment configuration variables to prevent `os.environ` leaks in source code:
```python
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
    project_root: Path = Path(__file__).parent.parent.parent
    data_dir: Path = Path("data")
    artifacts_dir: Path = Path("artifacts")
    random_seed: int = 42

settings = Settings()
```

---

## Part 4: The Two-Phase Agent Execution Model

To guarantee cross-session continuity when collaborating with AI assistants, projects rely on a robust **Two-Phase Execution Model**.

```
    PHASE 1: INITIALIZER (Run Once)
    - Reads AGENTS.md + CONTEXT.md to map scope
    - Syncs dependencies with init.sh
    - Seeds features.json and creates baseline commit
                     │
                     ▼
    PHASE 2: CODING AGENT (Every Session Loop)
    - Run init.sh + pytest to verify baseline
    - Pull one feature from features.json
    - Code + Test + Lint in Red-Green-Refactor loop
    - Write Git commit and write starting state for next run
```

---

## Part 5: Skill Management Hierarchy

Workspace-scoped skills allow developers to define domain-specific or project-specific instructions without bloating the global environment:

*   **Global Skills (`~/.gemini/antigravity/skills/`):** Universal behaviors shared by all repositories on the machine (e.g. general code reviews, database schema analysis).
*   **Workspace Skills (`.agents/skills/`):** Isolated strictly to the active project workspace. Workspace skills automatically override global skills of the same name. Excellent for project-specific constraints (e.g. FPL lineup rules or crypto trade validators).

---

## Part 6: Jupyter & Google Colab Synchronisation

To bridge the gap between AI agent script editing (`.py`) and researcher notebooks (`.ipynb`), projects utilize the **py:percent format**:

1.  Write standard python scripts with `# %%` cell separators:
    ```python
    # %% [markdown]
    # # Ingest Raw Data

    # %%
    import pandas as pd
    from my_project.config import settings
    df = pd.read_csv(settings.raw_data_dir / "file.csv")
    df.head()
    ```
2.  Researchers can open and execute these `.py` files directly inside VS Code's interactive editor or sync them to Google Colab.
3.  Source control remains perfectly clean and git-diffable since the source of truth is always plain python, not bloated JSON notebooks.

---
*Alpha-Zero-G Operational Guide | Compiled 2026*
