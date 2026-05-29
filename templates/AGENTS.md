# Agent Harness — {{PROJECT_NAME}}

This file is the primary entry point and cognitive map for AI agents working in this repository. Read it first and strictly follow all instructions and paths.

## What This Project Is
{{PROJECT_DESCRIPTION}}

---

## System Pointers (Where to Find Information)

| Query / Need | File Path | Scope & Contents |
|---|---|---|
| **Domain Jargon & Jargon Meanings** | [CONTEXT.md](CONTEXT.md) | Domain glossary and foundational concepts |
| **System Layers & Architecture** | [docs/architecture.md](docs/architecture.md) | Technical stack, rule file mappings, layout |
| **Philosophical Guidelines & Decisions** | [docs/beliefs.md](docs/beliefs.md) | High-level agent principles and design justifications |
| **Component Sanity & Quality** | [docs/quality.md](docs/quality.md) | Quality checklists and coverage gap tracking |
| **Configuration Columns & Variables** | [docs/DATA_DICT.md](docs/DATA_DICT.md) | Variable listings, data formats, units |
| **Modeling Log & Assumptions** | [docs/MODEL_NOTES.md](docs/MODEL_NOTES.md) | Model experiments, assumptions, metric logs |
| **Feature Requirements Status** | [features.json](features.json) | List of core deliverables and their test states |
| **Session Session State Log** | [progress.md](progress.md) | Running log of what was built and current priorities |

---

## Preferred Workflows

For any analytical, modeling, or coding task taking longer than 30 minutes, you MUST follow the **Golden Path Developer Workflow** documented in [DEVELOPER_WORKFLOW.md](DEVELOPER_WORKFLOW.md):
1. **Boot:** Run `bash init.sh` immediately at session start.
2. **Grill:** Invoke `/grill-with-docs` (general logic) or `/grill-analytics` (data/stats audits) to refine domain terms in `CONTEXT.md` and ADRs.
3. **Spec:** Invoke `/spec-model` to compile a formal design spec in `docs/design/` or `docs/MODEL_NOTES.md`.
4. **Slice:** Invoke `/to-issues` on your spec to compile independent vertical slices in `features.json`.
5. **Ship (TDD):** Invoke `/tdd` to execute and build tests first (Red-Green-Refactor). If debugging, use `/diagnose`.
6. **Verify:** Invoke `/validate-output` for statistical validation.
7. **Refactor:** Invoke `/improve-codebase-architecture` to deepen modules and decouple layers.
8. **Handoff:** Invoke `/handoff` to summarize session status in `progress.md`.

---

## Operating Protocols & Hard Rules

- **Orient Immediately:** Read `progress.md` at session start to understand the immediate state.
- **Run Bootstrapper:** Run `bash init.sh` immediately at session start. Do not change files if `init.sh` fails on the baseline.
- **No System Python:** Never execute direct unmanaged system `python`, `python3`, `pip`, or `pytest`. You must consistently run Python commands and test runners via `uv run` (e.g. `uv run python script.py`, `uv run pytest`) to ensure deterministic package loading from the managed virtual environment.
- **Log Transformations:** Every numerical or data frame transformation must print/log input and output shapes to the console.
- **Maintain Continuity:** Update `progress.md` at the end of every session detailing changes, files modified, and next actions.
- **Documentation Synchronisation Protocol:** Upon completing any implementation phase, model run, or feature slice:
  - Update `progress.md` and `features.json` to reflect the new state.
  - Sync architectural decisions to `docs/beliefs.md`.
  - Update any new variables or data schemas in `docs/DATA_DICT.md`.
  - Log model assumptions or backtest performance metrics in `docs/MODEL_NOTES.md`.
  - Keep `README.md` updated if directory layouts, bootstrapping steps, or main features change.
- **R Requirements:** Any new R function must include Roxygen2 comments and adhere to tidyverse conventions.
- **Write ADRs:** When making a hard-to-reverse architectural decision, write an ADR in `docs/adr/` using the next sequential ID (format: `docs/adr/000N-short-title.md`). Register it in `docs/beliefs.md`. Use `docs/adr/0000-adr-template.md` as your template.
- **First Session:** On your first session in this project, read `docs/adr/OPEN_DECISIONS.md` and begin backfilling domain ADRs for any decisions already made.
- **Portable Markdown Linking (ADR-0007):** [HARD] Never write absolute `file:///` URLs or local filesystem paths in rule files (`AGENTS.md`, `GEMINI.md`) or documentation. All links must use standard, relative Markdown links (e.g., `[CONTEXT.md](CONTEXT.md)`) to maintain platform portability across different operating systems and devices.

---

## Coding Conventions

### File and Function Rules
- **Type Hints:** All functions must have type hints on ALL parameters and return value.
- **Docstrings:** All public functions must have a Google-style docstring with `Args`, `Returns`, and `Raises` (if any).
- **Line Length:** 88 characters max, enforced by Ruff formatting.
- **Imports:** Sorted by Ruff (stdlib → third-party → local).

### Path Handling (Cross-Platform)
- **Pathlib always:** NEVER use hardcoded path strings or bare concatenations. Always use `pathlib.Path`.
```python
# ✅ CORRECT — always
from pathlib import Path
data_path = Path("data") / "raw" / "file.csv"

# ❌ WRONG — never
data_path = "data/raw/file.csv"          # breaks on Windows
data_path = "data\\raw\\file.csv"       # breaks on macOS/Linux
```

### Configuration Access
- **Settings Singleton:** NEVER use `os.environ` or direct configuration files in source code. Use the centralized `settings` object.
```python
# ✅ CORRECT — always
from {{PROJECT_NAME}}.config import settings
data_dir = settings.raw_data_dir

# ❌ WRONG — never
import os
data_dir = os.environ.get("DATA_DIR", "data/raw")  # bypasses validation
```

### Error Handling
- **Specific Errors:** NEVER use broad/bare exceptions. Raise descriptive built-in or custom exceptions.
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
- **Standard Logging:** NEVER use raw `print()` for logging or trace outputs in library/source code. Use standard `logging`.
```python
# ✅ CORRECT — always
import logging
logger = logging.getLogger(__name__)
logger.info("Processing %d players", len(players))

# ❌ WRONG — never
print(f"Processing {len(players)} players")
```

---

## Data Handling Rules

### What You MUST Do
- **Always validate schema** with `pandera` before writing any transformation.
- **Always define Pydantic models** for API responses before parsing them.
- **Always check for nulls/missing values** before modeling, and document the null handling decision.
- **Always use `.head(5)`, `.describe()`, `.dtypes`** when inspecting data in context.
- **Always reference file paths** in context rather than embedding full file content.

### What You MUST NEVER Do
- **NEVER load full DataFrame** content into context — use summaries and schemas only.
- **NEVER hardcode file paths** — always use `settings.{path_property}`.
- **NEVER assume API responses** have expected structure — always validate.
- **NEVER assume data types** — always check `.dtypes` first.
- **NEVER skip data validation** to "save time".

---

## Statistical Modeling Rules

### What You MUST Do
- **ALWAYS define metrics** before running a model. Define first, evaluate second.
- **ALWAYS enforce strict temporal split** on time-series/sequential data to prevent data leakage.
- **ALWAYS perform statistical significance tests** (e.g., p-value, confidence intervals) when comparing models.
- **ALWAYS establish a baseline model** (at minimum a mean/median predictor or last-value baseline) to compare against.
- **ALWAYS document assumptions** explicitly in function docstrings (e.g., stationarity, normal distribution).
- **ALWAYS include prediction/confidence intervals** for model predictions.
- **ALWAYS validate outputs** against domain knowledge / business logic before returning them.

### What You MUST NEVER Do
- **NEVER evaluate model** without predefined, objective success criteria.
- **NEVER leak future data** into training features.
- **NEVER compare models** on raw performance metrics without statistical testing.
- **NEVER deploy** a model without comparing it against a simple, robust baseline.

---

## Token & Context Management

- **Reference, Don't Embed:** Reference files and lines; do not copy-paste full file contents into the chat context.
- **Summarize Data:** Use schemas, data shapes, and summary statistics rather than printing entire dataframes or matrices.
- **Decompose Tasks:** Keep your focus narrow. Build one feature, model, or helper function at a time.
- **Context Health Thresholds:**
  - **< 40%:**  ✅ Healthy — continue normally
  - **40-60%:** ⚠️ Watch — start summarizing completed work to prepare for transition
  - **60-70%:** 🔶 High — compress history, work from files, avoid repeating previous outputs
  - **> 70%:**  🔴 Critical — output quality degrading; end session soon or request compaction

---

## Session Protocols

### Session Start
1. **Read AGENTS.md** (this file).
2. **Read `progress.md`** to understand where the work left off.
3. **State clearly in your first message:**
   - Current project phase and active focus.
   - What was last completed.
   - What this session's goal and success criteria are.
4. **Confirm understanding** with the user before editing code.

### Debug Protocol
When a test, build, or command fails:
1. **Read the FULL error message** — do not guess or run commands blindly.
2. **Categorize the error:** Logic, Type, Schema, Data Quality, or Environment.
3. **Check `docs/beliefs.md` / `docs/adr/`** — has this problem or pattern been solved before?
4. **Solve the ROOT CAUSE** rather than patching the symptom.
5. **Write a test** that reproduces the bug and prevents future regressions.

### Validation Loop (Continuous Integration)
Before finalizing any code change:
1. **Write the code + type hints.**
2. **Write tests** covering edge cases and typical inputs.
3. **Run `uv run pytest`** to assert all tests pass.
4. **Run linters and type checkers** (e.g., `make check`, `uv run ruff check`, `uv run mypy`).
5. **Verify data contracts** and schemas.

### Session End
1. **Run full lint and tests** to ensure no regressions.
2. **Update `progress.md`:**
   - Mark completed items.
   - Add detailed next actions in order.
   - List any newly discovered known issues.
3. **Update `docs/beliefs.md`** and write any necessary ADRs if architectural decisions were made.
4. **State clearly:** "Session complete. Next session should start with: [X]"

---

## Testing Requirements

| Scope | Minimum Requirement |
|---|---|
| **Every public function** | At least 1 unit test |
| **Every data transformation** | Schema validation test (`pandera` or `pydantic`) |
| **Every statistical function** | Property-based test (`hypothesis`) |
| **Every model** | Performance regression test vs baseline |
| **Data contracts** | 100% test coverage |
| **`src/` overall** | 80% minimum test coverage |

### Test Runner Commands
```bash
make test           # Run all tests
make test-cov       # Run all tests with coverage report
make test-unit      # Run unit tests only
make check          # Lint + type-check + test (run before committing)
```

---

## Security Rules

### Standard Analytics Project
- **Credentials:** Never commit API keys, passwords, or secrets (use `.env` and `settings` only).
- **Data Privacy:** Never expose raw sensitive data in logs, printouts, or source code.
- **Data Validation:** Validate all external API payloads and source files before consumption.

### External Action Execution (e.g., Trading, CLI Solvers)
- **RULE OF TWO:** Never allow an agent all three simultaneously:
  1. Process untrusted external input
  2. Access sensitive credentials/systems
  3. Modify state (execute orders, delete data)
- **Human-in-the-loop:** Any action modifying external state requires explicit, interactive user approval.
- **Sandbox Testing:** Always test in dry-run, simulation, or paper-trading modes before real execution.

---

## Domain Rules

*(To be customized for FPL, crypto trading, or other downstream contexts by the scaffolding system)*

---

## Permissions & Safety Policies

*Note: Behavioral policy below is strictly enforced programmatically by `.agents/hooks.json` interceptors.*

- **Allowed Freely:** Reading any project files. Writing to `src/`, `notebooks/`, `tests/`, and temporary directories.
- **Requires Approval:** Deleting files, modifying `.agents/` or `config/` paths, installing system packages, and performing network requests.
- **Forbidden:** Force-pushing to main (`git push --force`), modifying `.git/` internals, and exposing `.env` secrets.
