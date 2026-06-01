# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Getting Started

This project is bootstrapped and managed using the **Alpha-Zero-G** developer harness.

### Standard Directories
- `data/raw/`: Read-only raw data inputs (do not modify!).
- `data/interim/`: Intermediate work files.
- `data/processed/`: Final outputs.
- `src/`: Python source code (if Python/Hybrid).
- `R/`: R source code (if R/Hybrid).
- `tests/`: Automated test suite.

### Running with Deterministic Python
- Always use `uv run` to run scripts or tests:
  ```bash
  uv run pytest
  uv run python src/main.py
  ```
