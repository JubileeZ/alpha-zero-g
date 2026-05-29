# Alpha-Zero-G: Agent Setup Guide
> **Type:** Operational Guide — Give this to agents to set up new projects
> **Version:** 1.0 | **Date:** 2026-05-29
> **Scope:** Directory structure, agent behavior rules, cross-platform config,
>            project bootstrapping, and FPL project example

---

## Purpose of This Document

This guide tells an agent exactly how to:
1. Set up a new analytics project from the Alpha-Zero-G template
2. Behave correctly throughout the project lifecycle
3. Manage memory and documentation automatically
4. Work consistently across Windows and macOS
5. Automate its own feedback loop

**If you are an agent reading this:** Follow every section in order.
Do not skip sections. Do not assume — ask if unclear.

---

## Part 1: Core Principles for Agent Behavior

### Principle 1: Files Are Your Memory

You have no memory between sessions. Every important decision, progress update,
and design choice MUST be written to a file before the session ends.

```
Rule: If it happened but wasn't written to a file, it didn't happen.
```

Required files you must always maintain:
- `AGENTS.md` — Your rulebook (read at start of every session)
- `PROGRESS.md` — What was done and what is next
- `DECISIONS.md` — Why design choices were made
- `ARCHITECTURE.md` — How the system is structured
- `DATA_CONTRACTS.md` — All data schemas and sources

### Principle 2: Context Window is Finite — Protect It

- Never paste full DataFrames into context
- Use `.head(5)`, `.describe()`, `.dtypes` for data inspection
- Reference file paths instead of embedding full file content
- Keep context below 70% full at all times
- When context fills up, summarize and compress

### Principle 3: Validate Before You Proceed

- Always validate data schema before writing transformation code
- Always write tests alongside implementation code (not after)
- Always check output makes domain sense before returning
- Never assume a previous step succeeded — verify it

### Principle 4: Ask Before Acting on Irreversible Operations

These operations REQUIRE explicit user confirmation before proceeding:
- Deleting files or data
- Executing financial orders (crypto trading)
- Modifying production configurations
- Overwriting model artifacts with new versions

### Principle 5: One Task Per Session

- Each session should have ONE primary goal, stated upfront
- If a task is too large for one session, break it into subtasks
- Update PROGRESS.md with subtask breakdown before starting
- End the session by writing the next session's starting point

---

## Part 2: Standard Directory Structure

When creating a new project, ALWAYS use this structure:

```
{project-name}/
│
├── AGENTS.md                    ← PRIMARY: Agent rulebook (ALWAYS READ FIRST)
├── ARCHITECTURE.md              ← System design and decisions
├── PROGRESS.md                  ← Session-by-session work log
├── DECISIONS.md                 ← Design decision rationale
│
├── .antigravity/                ← Antigravity CLI configuration
│   ├── skills/                  ← Reusable agent skills
│   │   ├── data-profiling.md
│   │   ├── eda-summary.md
│   │   ├── model-evaluation.md
│   │   └── test-generation.md
│   ├── hooks/                   ← Pre/post action automation
│   │   ├── pre-session.md       ← Always read AGENTS.md + PROGRESS.md
│   │   └── post-session.md      ← Always update PROGRESS.md + git commit
│   └── config.yaml              ← CLI settings
│
├── .env.example                 ← Environment variable template (never .env)
├── pyproject.toml               ← Single source of truth for packages
├── Makefile                     ← Common commands (cross-platform)
├── .pre-commit-config.yaml      ← Automated quality gates
├── .gitignore                   ← Standard Python + data ignores
│
├── src/
│   └── {project_name}/
│       ├── __init__.py
│       ├── config.py            ← Pydantic settings (reads from .env)
│       ├── data/
│       │   ├── __init__.py
│       │   ├── ingestion.py     ← Data fetching with retry logic
│       │   ├── validation.py    ← Pandera schemas
│       │   └── transformation.py
│       ├── models/
│       │   ├── __init__.py
│       │   ├── features.py      ← Feature engineering
│       │   ├── training.py      ← Model training pipeline
│       │   └── evaluation.py    ← Metrics and validation
│       ├── utils/
│       │   ├── __init__.py
│       │   ├── logging.py       ← Structured logging setup
│       │   └── io.py            ← File I/O utilities
│       └── contracts/
│           ├── __init__.py
│           └── schemas.py       ← Pydantic models for data contracts
│
├── tests/
│   ├── conftest.py              ← Shared fixtures
│   ├── unit/
│   │   ├── test_validation.py
│   │   ├── test_features.py
│   │   └── test_models.py
│   └── integration/
│       └── test_pipeline.py
│
├── notebooks/                   ← Exploration only (never production code)
│   └── .gitkeep
│
├── data/
│   ├── raw/                     ← Never modified after ingestion
│   ├── processed/               ← Transformed data
│   └── .gitkeep
│
├── artifacts/
│   ├── models/                  ← Saved model files
│   └── reports/                 ← Generated analysis outputs
│
└── docs/
    ├── DATA_CONTRACTS.md        ← All data schemas documented here
    └── MODEL_REGISTRY.md        ← All models, versions, performance
```

---

## Part 3: AGENTS.md Template

Create this file at the project root. Fill in the bracketed sections:

```markdown
# AGENTS.md — {Project Name}
> Last Updated: {date}
> Project Status: {active/planning/maintenance}

## READ THIS FIRST
This is your primary reference. Read it completely at the start of every session.
Read PROGRESS.md next to understand where work left off.

---

## Project Identity

**Name:** {project name}
**Purpose:** {one sentence description}
**Phase:** {current phase}
**Key Constraint:** {most important constraint, e.g., "FPL API rate limit: 100 req/min"}

---

## Technology Stack

**Python:** 3.11+
**Package Manager:** pip with pyproject.toml
**Environment:** .env file (never committed) loaded via pydantic-settings

### Core Packages (always available)
- pandas / polars — data manipulation
- pydantic v2 — data validation and settings
- pandera — DataFrame schema validation
- pytest — testing framework
- ruff — linting and formatting
- mypy — type checking
- httpx + tenacity — API calls with retry

### Project-Specific Packages
{list packages specific to this project}

### DO NOT USE
{list packages to avoid and why}

---

## Architecture Overview

{Brief description of how data flows through the system}

```
[Data Source] → [Ingestion] → [Validation] → [Transform] → [Model] → [Output]
```

Key files:
- Entry point: `src/{name}/main.py`
- Config: `src/{name}/config.py`
- Data contracts: `src/{name}/contracts/schemas.py`

---

## Coding Conventions

### Style
- Line length: 88 characters (ruff default)
- Imports: grouped (stdlib, third-party, local) with ruff isort
- Formatting: ruff format (replaces black)

### Type Hints
- ALL function parameters must have type hints
- ALL function return values must have type hints
- Use `Optional[T]` for nullable, NOT `T | None` (compatibility)
- Use Pydantic models for complex data structures

### Docstrings
- All public functions require docstrings
- Format: Google style
- Include: Args, Returns, Raises, Example

### Example function signature
```python
def calculate_projected_points(
    player_id: int,
    fixture_difficulty: float,
    historical_stats: pd.DataFrame,
    n_gameweeks: int = 5,
) -> dict[str, float]:
    """Calculate projected FPL points for a player.

    Args:
        player_id: FPL player identifier.
        fixture_difficulty: FDR score (1-5).
        historical_stats: Player stats for last N gameweeks.
        n_gameweeks: Number of gameweeks to project.

    Returns:
        Dictionary with keys: 'expected_points', 'lower_bound', 'upper_bound'.

    Raises:
        ValueError: If fixture_difficulty not between 1 and 5.
    """
```

---

## Data Handling Rules

- NEVER load full DataFrame into context — use .head(5), .describe(), .dtypes
- NEVER hardcode file paths — use settings from config.py
- NEVER assume data quality — always validate schema with pandera first
- NEVER skip null analysis before modeling
- ALWAYS define data contracts (Pydantic or Pandera) before writing transforms
- ALWAYS validate API responses against Pydantic models before using

---

## Testing Requirements

- Every public function requires at least one unit test
- Every data transformation requires schema validation test
- Every model requires performance regression test
- Use hypothesis for statistical and mathematical functions
- Minimum coverage: 80% for src/, 100% for contracts/

Run tests: `make test`
Run with coverage: `make test-cov`

---

## Agent Behavior Rules

### Always Do
- Read this file and PROGRESS.md at session start
- Write type hints for every function you create
- Write a test alongside every function you create
- Run `make lint` and `make test` before declaring a task complete
- Update PROGRESS.md before ending the session
- Git commit at end of session with descriptive message

### Always Ask Before
- Deleting any file or data
- Changing existing test behavior
- Adding a new dependency (check pyproject.toml first)
- Modifying configuration that affects production

### Never Do
- Paste full DataFrame contents into context
- Write code without tests
- Use print() for logging (use the logging module)
- Commit .env files or API keys
- Hardcode credentials or paths

---

## Skills Available (Lazy-Loaded)

The following skills are available. Request them by name when needed:
- `data-profiling` — Schema inspection, quality report generation
- `eda-summary` — Statistical EDA with key visualizations
- `feature-engineering` — Standard transform and encode pipeline
- `model-evaluation` — Metrics, plots, statistical significance tests
- `test-generation` — Write pytest tests for existing functions
- `code-review` — Review for analytics-specific issues
- `refactor` — Improve structure without changing behavior

---

## Current Session Context

**Last Completed:** {what was done in last session}
**In Progress:** {what is currently being worked on}
**Next Steps:** {what to do next session}
**Known Issues:** {any blockers or problems discovered}
```

---

## Part 4: Cross-Platform Configuration

### The Problem

Agents behave differently on Windows vs macOS when:
- File paths use `\` vs `/`
- Python environment activation differs
- Line endings differ (CRLF vs LF)
- Shell commands differ (cmd/PowerShell vs bash)

### Solution: Abstract Everything Through Configuration

**Step 1: Use `pathlib.Path` everywhere (never string paths)**

```python
# BAD — breaks on Windows
data_path = "/data/raw/players.csv"

# GOOD — works everywhere
from pathlib import Path
data_path = Path("data") / "raw" / "players.csv"
```

**Step 2: Pydantic Settings for all configuration**

Create `src/{project}/config.py`:

```python
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Project paths (resolved relative to project root)
    project_root: Path = Path(__file__).parent.parent.parent
    data_dir: Path = Path("data")
    artifacts_dir: Path = Path("artifacts")

    # API Configuration
    api_timeout: int = 30
    api_max_retries: int = 3

    # Model Configuration
    random_seed: int = 42
    test_size: float = 0.2

    @property
    def raw_data_dir(self) -> Path:
        return self.project_root / self.data_dir / "raw"

    @property
    def processed_data_dir(self) -> Path:
        return self.project_root / self.data_dir / "processed"


# Singleton — import this everywhere
settings = Settings()
```

**Step 3: `.env.example` template (commit this, not `.env`)**

```bash
# .env.example — Copy to .env and fill in values
# Never commit .env to git

# API Keys (fill in your own)
FPL_API_BASE_URL=https://fantasy.premierleague.com/api
EXCHANGE_API_KEY=your_key_here
EXCHANGE_SECRET=your_secret_here

# Data paths (override defaults if needed)
# DATA_DIR=data
# ARTIFACTS_DIR=artifacts

# Model settings
# RANDOM_SEED=42
# TEST_SIZE=0.2
```

**Step 4: Makefile with cross-platform targets**

```makefile
# Makefile — Works on macOS and Windows (with make installed)
.PHONY: install test lint format type-check clean setup

# Detect OS
ifeq ($(OS),Windows_NT)
    PYTHON = python
    VENV_ACTIVATE = .venv\Scripts\activate
    RM = rmdir /s /q
else
    PYTHON = python3
    VENV_ACTIVATE = .venv/bin/activate
    RM = rm -rf
endif

## Setup & Installation
setup:
    $(PYTHON) -m venv .venv
    $(PYTHON) -m pip install --upgrade pip
    $(PYTHON) -m pip install -e ".[dev]"
    pre-commit install
    cp .env.example .env
    @echo "✅ Setup complete. Edit .env with your values."

install:
    $(PYTHON) -m pip install -e ".[dev]"

## Quality Gates
lint:
    ruff check src/ tests/
    @echo "✅ Lint passed"

format:
    ruff format src/ tests/
    @echo "✅ Format applied"

type-check:
    mypy src/
    @echo "✅ Type check passed"

## Testing
test:
    pytest tests/ -v

test-cov:
    pytest tests/ --cov=src --cov-report=term-missing --cov-report=html

test-unit:
    pytest tests/unit/ -v

## Combined checks (run before committing)
check: lint type-check test
    @echo "✅ All checks passed"

## Cleanup
clean:
    $(RM) .pytest_cache
    $(RM) htmlcov
    $(RM) .mypy_cache
    $(RM) .ruff_cache
    find . -type d -name "__pycache__" -exec $(RM) {} + 2>/dev/null || true
```

**Step 5: `.gitignore` template**

```gitignore
# Environment
.env
.venv/
venv/
env/

# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
*.egg

# Testing & Coverage
.pytest_cache/
.coverage
htmlcov/
.mypy_cache/
.ruff_cache/

# Data (adjust based on project)
data/raw/*
data/processed/*
!data/**/.gitkeep

# Artifacts
artifacts/models/*
artifacts/reports/*
!artifacts/**/.gitkeep

# Jupyter
.ipynb_checkpoints/
notebooks/*.ipynb

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
Thumbs.db
```

**Step 6: `.pre-commit-config.yaml`**

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
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key
      - id: no-commit-to-branch
        args: [--branch, main]
```

**Step 7: AGENTS.md cross-platform section**

Add this to every project's `AGENTS.md`:

```markdown
## Cross-Platform Rules

- ALWAYS use pathlib.Path for file paths — never string concatenation
- ALWAYS import settings from config.py — never hardcode paths or values
- ALWAYS use `make {command}` for running tasks — never raw commands
- NEVER use os.path — use pathlib instead
- NEVER write platform-specific code unless explicitly needed
- When reading environment variables, ALWAYS use Settings class
- When checking if running on Windows: `import platform; platform.system() == "Windows"`
```

---

## Part 5: The Automated Agent Loop

### What Is the Agent Loop?

The agent loop is the pattern where the agent:
1. Receives a task
2. Plans steps
3. Executes step
4. Observes result
5. Validates result
6. Loops until task is complete or needs human input

### How to Instruct the Agent to Automate This

**Opening instruction for every session (paste this at the start):**

```
SESSION START PROTOCOL:
1. Read AGENTS.md completely
2. Read PROGRESS.md to understand current state
3. Confirm understanding: "I understand the project state. Current goal: [X]. I will [steps]."
4. Do not start coding until you have confirmed understanding

TASK: {your specific task for this session}

SUCCESS CRITERIA:
- {specific, measurable outcome 1}
- {specific, measurable outcome 2}
- All tests pass (make test)
- No lint errors (make lint)
- PROGRESS.md updated

LOOP BEHAVIOR:
- After each step, verify the output is correct before moving to next step
- If a step fails, diagnose the root cause before retrying
- Do not retry the same failing approach more than twice — ask for guidance
- If unsure about a design decision, ask before implementing

END OF SESSION PROTOCOL:
1. Run make check (lint + type-check + test)
2. Update PROGRESS.md with: what was done, what is next
3. Append any design decisions to DECISIONS.md
4. Git commit: git commit -m "session: {brief description}"
5. Report: "Session complete. Next session should start with: [X]"
```

### The Validation Loop Pattern

Instruct the agent to validate each output:

```
For each function you write, before moving to the next:
1. Write the function with type hints and docstring
2. Write at least one unit test
3. Run make test — if fails, fix before continuing
4. Run make lint — if fails, fix before continuing
5. Verify output makes sense for the domain
6. Only then proceed to next function
```

### The Debug Loop Pattern

When something fails:

```
Debug Protocol:
1. Read the FULL error message — do not guess
2. Identify: is this a logic error, type error, data error, or environment error?
3. Check: has this error been seen before? (look in DECISIONS.md)
4. Fix the ROOT CAUSE — not just the symptom
5. Write a test that would have caught this error
6. Document in DECISIONS.md: what the error was and how it was resolved
```

### Antigravity CLI Async Loop for Long Tasks

For tasks like model training or large data processing:

```
# Start async subagent for long-running task
/agents spawn "Run cross-validation for FPL model"

# Continue with other work
# ... work on transfer solver ...

# Check back on async task
/agents status
/agents results
```

---

## Part 6: Agent-Centric Setup Checklist

### What "Agent-Centric" Means

An agent-centric project is designed so the agent can:
- Understand the full context from files alone (no verbal explanation needed)
- Execute any task following documented conventions
- Catch its own mistakes through automated gates
- Know exactly what to do when starting a session
- Know exactly what to do when ending a session

### Setup Checklist (run through this for every new project)

```
PROJECT INITIALIZATION CHECKLIST

□ AGENTS.md created and filled (not just the template — actual content)
□ ARCHITECTURE.md created with system overview
□ PROGRESS.md created with "Project initialized" entry
□ DECISIONS.md created with initial technology choices documented
│
□ Directory structure created (Part 2 of this guide)
□ pyproject.toml created with all dependencies
□ .env.example created (and .env created locally, not committed)
□ Makefile created and tested on current platform
│
□ pre-commit installed: pre-commit install
□ ruff configured in pyproject.toml
□ mypy configured in pyproject.toml
□ pytest configured in pyproject.toml
│
□ config.py created using Pydantic Settings
│   □ All paths use pathlib.Path
│   □ All environment variables defined with types
│   □ Defaults set for all non-secret variables
│
□ conftest.py created with shared fixtures
□ First test written and passing
│
□ .gitignore verified (.env is ignored)
□ Initial commit made: "chore: initialize project structure"
│
□ Antigravity CLI configured:
│   □ .antigravity/config.yaml created
│   □ Skills registered for this project
│   □ Hooks defined for pre/post session
│
□ Agent tested:
    □ Start fresh session, give agent only AGENTS.md
    □ Verify agent understands the project
    □ Verify agent follows conventions without reminding
    □ Adjust AGENTS.md if agent made wrong assumptions
```

---

## Part 7: FPL Project Example

This section shows how to apply the Alpha-Zero-G template to a real project.

### FPL Project: fpl-optimizer

**What it does:** Scrapes FPL data, projects player points, solves for optimal transfer plan.

**AGENTS.md excerpt for FPL project:**

```markdown
# AGENTS.md — fpl-optimizer

## Project Identity
**Purpose:** Project FPL player scores for upcoming gameweeks and solve for
             optimal transfer plans within budget and transfer constraints.
**Phase:** Active Development
**Key Constraint:** FPL API is unofficial — handle 429 rate limit errors gracefully

## Data Sources
1. FPL Official API: https://fantasy.premierleague.com/api/
   - /bootstrap-static/ → all players, teams, fixtures
   - /element-summary/{player_id}/ → player history
   - Rate limit: ~1 req/sec (use tenacity with 1s delay)
2. FBref (via manual export) → xG, xA advanced stats
3. Understat (via understat Python package) → shot quality data

## Domain Rules
- Always use player_id (not player_name) as primary key
- Gameweek numbering: 1-38 (38 gameweeks per season)
- Budget is in units of 0.1 million (e.g., 100 = £10.0m)
- Formations allowed: any with exactly 2-5 defenders, 2-5 midfielders, 1-3 forwards
- Squad size: exactly 15 players (11 starters + 4 bench)
- Transfer limits: 1 free transfer per week, additional cost 4 points each
- Captain scores double — weight captain selection heavily in solver

## Statistical Rules
- Use rolling averages (last 5 GW) weighted by fixture difficulty
- Injury probability must be factored into expected points
- Blank gameweeks: set expected points to 0 for affected players
- Double gameweeks: apply 1.8x multiplier (not 2x due to rotation risk)
- Out-of-form players (last 3 GW < season average): apply 0.8x penalty

## Solver Constraints
- Use pulp or ortools for LP solver
- Objective: maximize total expected points over projection horizon
- Hard constraints: budget, squad rules, transfer limits
- Soft constraints: team concentration (max 3 from one team)
- Always show top 5 alternative plans with scores

## Model Evaluation
- Primary metric: points per million (value metric)
- Backtest: validate projections against actual GW results
- Baseline: always compare against "buy top-value XI" strategy
```

### FPL Directory Structure

```
fpl-optimizer/
├── AGENTS.md
├── ARCHITECTURE.md
├── PROGRESS.md
├── DECISIONS.md
│
├── pyproject.toml
├── Makefile
├── .env.example          # FPL_API_BASE_URL, UNDERSTAT_SEASON
├── .gitignore
├── .pre-commit-config.yaml
│
├── src/
│   └── fpl_optimizer/
│       ├── __init__.py
│       ├── config.py              # FPL-specific settings
│       │
│       ├── data/
│       │   ├── fpl_client.py      # FPL API wrapper with retry
│       │   ├── understat.py       # Understat data ingestion
│       │   ├── schemas.py         # Pandera schemas for all FPL data
│       │   └── pipeline.py        # Full data refresh pipeline
│       │
│       ├── features/
│       │   ├── player_form.py     # Rolling average calculations
│       │   ├── fixture_diff.py    # FDR-adjusted projections
│       │   ├── advanced_stats.py  # xG/xA feature engineering
│       │   └── injury_risk.py     # Availability weighting
│       │
│       ├── models/
│       │   ├── scorer.py          # Point projection model
│       │   ├── evaluator.py       # Backtest and metrics
│       │   └── registry.py        # Model versioning
│       │
│       ├── solver/
│       │   ├── optimizer.py       # LP/ILP transfer optimizer
│       │   ├── constraints.py     # FPL rule constraints
│       │   └── formatter.py       # Human-readable output
│       │
│       └── contracts/
│           ├── player.py          # Player Pydantic model
│           ├── fixture.py         # Fixture Pydantic model
│           └── squad.py           # Squad state Pydantic model
│
├── tests/
│   ├── conftest.py                # Sample FPL data fixtures
│   ├── unit/
│   │   ├── test_schemas.py
│   │   ├── test_features.py
│   │   ├── test_scorer.py
│   │   └── test_solver.py
│   └── integration/
│       └── test_pipeline.py
│
└── docs/
    ├── DATA_CONTRACTS.md          # All FPL data schemas
    └── MODEL_REGISTRY.md          # Scorer model versions
```

### FPL pyproject.toml (key sections)

```toml
[project]
name = "fpl-optimizer"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "pandas>=2.2",
    "numpy>=1.26",
    "pydantic>=2.7",
    "pydantic-settings>=2.3",
    "pandera>=0.20",
    "httpx>=0.27",
    "tenacity>=8.3",
    "scipy>=1.13",
    "scikit-learn>=1.5",
    "xgboost>=2.0",
    "lightgbm>=4.3",
    "optuna>=3.6",
    "pulp>=2.8",
    "plotly>=5.22",
    "python-dotenv>=1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.2",
    "pytest-cov>=5.0",
    "pytest-asyncio>=0.23",
    "hypothesis>=6.100",
    "ruff>=0.4",
    "mypy>=1.10",
    "pre-commit>=3.7",
    "pandas-stubs>=2.2",
    "ipykernel>=6.29",
]

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "ANN", "B", "SIM"]
ignore = ["ANN101", "ANN102"]

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"

[tool.coverage.run]
source = ["src"]
omit = ["tests/*", "**/__init__.py"]
```

### First Session Prompt (FPL Project)

Copy and paste this to start the FPL project:

```
SESSION START PROTOCOL:
1. Read AGENTS.md completely
2. Read PROGRESS.md (currently empty — this is session 1)
3. Confirm you understand: project purpose, data sources, domain rules

TASK FOR THIS SESSION:
Set up the foundational FPL data ingestion layer.

SUCCESS CRITERIA:
- FPL API client created with retry logic (tenacity, 1s between retries)
- Pandera schemas defined for: players, fixtures, gameweek history
- Unit tests written for schema validation
- make check passes with zero errors
- PROGRESS.md updated with what was done

LOOP BEHAVIOR:
- Write schema first, then ingestion code, then tests
- Validate each schema against a real API response sample before moving on
- Do not start on features or modeling — data layer only this session

END OF SESSION:
- Run make check
- Update PROGRESS.md
- Git commit: "feat: add FPL data ingestion layer"
- State clearly: "Next session should start with: [X]"
```

---

## Part 8: Scaling to Future Projects

### Crypto Trading Project Template

When you are ready to create the crypto project, use this AGENTS.md addition:

```markdown
## CRYPTO TRADING: SECURITY RULES (MANDATORY)

This project processes market data AND can execute orders.
The Rule of Two applies at all times:

ALLOWED without confirmation:
- Read market data (1) + Run analysis (2) = Signal generation only

REQUIRES explicit user confirmation before proceeding:
- Any operation that executes, modifies, or cancels an order
- Any operation touching live exchange credentials
- Any operation that could result in financial loss

NEVER:
- Execute orders in automated loop without approval gate
- Store exchange credentials anywhere except .env
- Run untested signal logic on live data (paper trade first)
- Skip transaction cost modeling in any backtest
- Deploy without position size limits configured
```

### Template Generalization Checklist

When creating a NEW project from Alpha-Zero-G template:

```
□ Copy directory structure
□ Rename {project-name} throughout
□ Update AGENTS.md with project-specific:
  □ Data sources and their constraints
  □ Domain rules specific to the problem
  □ Any additional security rules
  □ Performance requirements
□ Update pyproject.toml with project-specific packages
□ Update .env.example with required environment variables
□ Run through Part 6 checklist completely
□ Test agent comprehension before starting real development
```

---

## Quick Reference Card

```
STARTING A SESSION
1. Open AGENTS.md — agent must read this
2. Open PROGRESS.md — orient to current state
3. State: ONE goal, clear success criteria
4. Paste SESSION START PROTOCOL

DURING A SESSION
- Monitor: /usage (stay under 70%)
- Spawn async: /agents for long tasks
- Safety net: /rewind if agent goes wrong
- Switch model: /model if needed

ENDING A SESSION
1. make check (lint + types + tests)
2. Agent updates PROGRESS.md
3. Git commit with descriptive message
4. Agent states next session starting point

CROSS-PLATFORM RULE
Always: pathlib.Path, not strings
Always: settings from config.py, not hardcoded
Always: make {command}, not raw commands

CONTEXT HEALTH
Green:  < 40% full  (optimal)
Yellow: 40-60% full (compress soon)
Red:    > 70% full  (quality degrading — summarize now)
```

---

*This guide is part of the Alpha-Zero-G project. Version 1.0 | 2026-05-29*
*For research background, see: 01_alpha-zero-g-research.md*
