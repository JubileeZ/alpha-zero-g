---
name: python-r-rules
description: Strict execution, environment, testing, and language standards for Python and R pipelines.
globs: ["*.py", "*.R", "pyproject.toml", "init.sh", "setup-harness.sh", "tests/**/*.py"]
activation: Glob
---
# Python & R Statistical Language Rules

This file governs the active environment, package execution, and statistical validation rules in this repository.

## Python Environment Execution
- [HARD] Never execute direct unmanaged system `python`, `python3`, `pip`, or `pytest`.
- [HARD] You must consistently run Python commands and test runners via `uv run` (e.g., `uv run python script.py` or `uv run pytest`) to ensure deterministic package loading from the managed virtual environment (`.venv`).
- [HARD] Every numerical or data frame transformation must print/log input and output shapes to the console.

## R Language Rules
- [HARD] Any new R function must include Roxygen2 comments and adhere to tidyverse conventions.
- [SOFT] Statistical environment dependencies are managed via `renv.lock`. Sync the library using `Rscript -e "renv::restore(prompt = FALSE)"` if dependencies change.

## Testing & Quality Requirements
- [HARD] All new modules, utilities, and packages must include corresponding unit tests in the `tests/` folder.
- [SOFT] Run tests via `uv run pytest` to verify a regression-free state before concluding any work session.
