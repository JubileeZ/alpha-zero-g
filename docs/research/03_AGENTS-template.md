# AGENTS.md — {Project Name}
> **Version:** 1.0
> **Last Updated:** {date}
> **Project Status:** {planning | active | maintenance}
> **Template Source:** Alpha-Zero-G v1.0

---

## ⚡ READ THIS FIRST — EVERY SESSION

You are an agent working on an analytics/statistical project.
Before doing ANYTHING else in a session, you must:

1. **Read this entire file**
2. **Read `PROGRESS.md`** — understand where work left off
3. **Confirm understanding** by stating:
   - Current project phase
   - What was last completed
   - What this session's goal is
4. **Only then begin the task**

If you are unsure about anything — ask. Do not assume and proceed.

---

## Project Identity

| Field | Value |
|---|---|
| **Project Name** | {project name} |
| **Purpose** | {one sentence: what problem does this solve?} |
| **Primary Output** | {what is the main artifact: model, report, API, dashboard?} |
| **Current Phase** | {Phase 1: Setup / Phase 2: Data / Phase 3: Modeling / Phase 4: Production} |
| **Key Constraint** | {the single most important constraint to remember} |

---

## Technology Stack

### Runtime
- **Python:** 3.11+
- **Package Manager:** pip + pyproject.toml (no conda)
- **Environment:** pydantic-settings reading from `.env`
- **Platform:** Cross-platform (Windows + macOS) — use pathlib always

### Core Packages (always available)
| Package | Role |
|---|---|
| pandas | Core data manipulation |
| polars | High-performance large data (>1M rows) |
| numpy | Numerical computing |
| pydantic v2 | Data contracts and settings |
| pandera | DataFrame schema validation |
| httpx + tenacity | HTTP client with retry logic |
| pytest | Test framework |
| ruff | Linting and formatting |
| mypy | Static type checking |

### Project-Specific Packages
{List packages unique to this project and their specific roles}

### DO NOT USE (and why)
| Package | Reason to Avoid |
|---|---|
| print() for logging | Use `logging` module — configurable and filterable |
| os.path | Use pathlib.Path — cross-platform |
| hardcoded strings for config | Use Settings class from config.py |

---

## Architecture Overview

{Brief description — 3-5 sentences about how data flows through the system}

```
[Data Source] → [Ingestion + Validation] → [Feature Engineering]
     → [Modeling] → [Evaluation] → [Output/Action]
```

### Key Entry Points
| File | Purpose |
|---|---|
| `src/{name}/config.py` | All configuration — start here |
| `src/{name}/data/pipeline.py` | Full data refresh pipeline |
| `src/{name}/models/training.py` | Model training entry point |
| `tests/conftest.py` | Shared test fixtures |

---

## Coding Conventions

### File and Function Rules
- All functions: type hints on ALL parameters and return value
- All public functions: Google-style docstring with Args, Returns, Raises
- All public functions: at least one unit test in `tests/unit/`
- Line length: 88 characters
- Imports: sorted by ruff (stdlib → third-party → local)

### Path Handling (Cross-Platform)
```python
# ✅ CORRECT — always
from pathlib import Path
data_path = Path("data") / "raw" / "file.csv"

# ❌ WRONG — never
data_path = "data/raw/file.csv"          # breaks on Windows
data_path = "data\\raw\\file.csv"       # breaks on macOS/Linux
```

### Configuration Access
```python
# ✅ CORRECT — always
from {project}.config import settings
data_dir = settings.raw_data_dir

# ❌ WRONG — never
import os
data_dir = os.environ.get("DATA_DIR", "data/raw")  # bypasses validation
```

### Error Handling
```python
# ✅ CORRECT — specific, informative
def get_player_data(player_id: int) -> pd.DataFrame:
    if player_id <= 0:
        raise ValueError(f"player_id must be positive, got {player_id}")
    ...

# ❌ WRONG — silent failures
def get_player_data(player_id: int) -> pd.DataFrame:
    try:
        ...
    except Exception:
        return pd.DataFrame()  # hides the problem
```

### Logging
```python
# ✅ CORRECT — always
import logging
logger = logging.getLogger(__name__)
logger.info("Processing %d players", len(players))

# ❌ WRONG — never in production code
print(f"Processing {len(players)} players")
```

---

## Data Handling Rules

### What You MUST Do
- **Always validate schema** with pandera before writing any transformation
- **Always define Pydantic models** for API responses before parsing them
- **Always check for nulls** before modeling — document null handling decision
- **Always use `.head(5)`, `.describe()`, `.dtypes`** when inspecting data in context
- **Always reference file paths** in context rather than embedding full file content

### What You MUST NEVER Do
- Load full DataFrame content into context — use summaries only
- Hardcode file paths — always use `settings.{path_property}`
- Assume API responses have expected structure — always validate
- Assume data types — always check `.dtypes` first
- Skip the data validation step to "save time"

---

## Testing Requirements

| Scope | Minimum Requirement |
|---|---|
| Every public function | At least 1 unit test |
| Every data transformation | Schema validation test |
| Every statistical function | Property-based test (hypothesis) |
| Every model | Performance regression test vs baseline |
| Data contracts | 100% coverage |
| src/ overall | 80% minimum coverage |

### Running Tests
```bash
make test           # all tests
make test-cov       # with coverage report
make test-unit      # unit tests only
make check          # lint + type-check + test (run before committing)
```

---

## Agent Behavior Rules

### ALWAYS Do (every session, no exceptions)
- [ ] Read AGENTS.md + PROGRESS.md before starting
- [ ] Write type hints for every function created
- [ ] Write a test alongside every function created (not after)
- [ ] Run `make check` before declaring any task complete
- [ ] Update PROGRESS.md before ending the session
- [ ] Git commit at end of session: `git commit -m "session: {description}"`

### ALWAYS Ask Before (get explicit confirmation)
- Deleting any file or data
- Modifying existing test logic
- Adding a new dependency to pyproject.toml
- Changing configuration that affects other components
- Any operation that is irreversible

### NEVER Do
- Paste full DataFrame contents into context
- Write code without tests
- Use `print()` for logging
- Commit `.env` files or API keys
- Retry the same failing approach more than twice without asking
- Skip the validation step to move faster

### Debug Protocol
When something fails:
1. Read the FULL error message — do not guess at the cause
2. Identify the error category: logic / type / data / environment
3. Check DECISIONS.md — has this been seen before?
4. Fix the ROOT CAUSE — not just the symptom
5. Write a test that would catch this error in the future
6. Append to DECISIONS.md: what failed and how it was resolved

---

## Session Protocols

### Session Start
```
1. Read AGENTS.md (this file)
2. Read PROGRESS.md
3. State: "I understand the project. Last completed: X. Today's goal: Y."
4. Confirm success criteria with user if not clear
5. Begin task
```

### Session End
```
1. Run: make check
2. Fix any failures before proceeding
3. Update PROGRESS.md:
   - Append: what was completed
   - Append: what is next
   - Update: known issues if any
4. Append to DECISIONS.md if any design decisions were made
5. Git commit: git commit -m "session: {brief description}"
6. State: "Session complete. Next session should start with: [X]"
```

### Context Management
```
Context level monitoring:
< 40%:   ✅ Healthy — continue normally
40-60%:  ⚠️  Watch — start summarizing completed work
60-70%:  🔶 High — compress history, work from files
> 70%:   🔴 Critical — output quality degrading, end session soon
```

---

## Skills Available

These skills are lazy-loaded — only fetched when needed.
Reference by name in your task instructions.

| Skill Name | Description |
|---|---|
| `data-profiling` | Schema inspection, null analysis, distribution summary |
| `eda-summary` | Statistical EDA with visualizations |
| `feature-engineering` | Standard transform, encode, scale pipeline |
| `model-evaluation` | Metrics calculation, plots, statistical significance |
| `test-generation` | Write pytest unit tests for existing functions |
| `code-review` | Review for analytics-specific issues and anti-patterns |
| `refactor` | Improve structure and performance without changing behavior |
| `documentation` | Generate/update docstrings and README sections |

---

## Current Session State

> Update this section at the END of every session

| Field | Value |
|---|---|
| **Last Completed** | {what was done — be specific} |
| **In Progress** | {what is currently being worked on} |
| **Next Steps** | {what to do next session — in priority order} |
| **Known Issues** | {any blockers, bugs, or things to watch} |
| **Last Commit** | {git commit hash or message} |

---

## Domain Rules

> Fill this section with rules specific to your domain

{For FPL — add FPL-specific rules here}
{For Crypto — add trading-specific rules here}
{For other analytics — add relevant domain constraints}

---

## Security Rules

> Adjust based on project type

### Standard Analytics Project
- Never commit API keys or credentials (use .env only)
- Never expose raw data in logs or outputs
- Validate all external data before processing

### If Project Can Execute External Actions (e.g., Trading)
- **RULE OF TWO:** Never allow agent all three simultaneously:
  1. Process untrusted external input
  2. Access sensitive credentials/systems
  3. Modify state (execute orders, delete data)
- ANY action that modifies external state requires explicit human confirmation
- Paper trade / sandbox first — never skip this step

---

*Alpha-Zero-G Template v1.0 | 2026-05-29*
