# Coding Conventions — {{PROJECT_NAME}}

This document details the coding guidelines and cross-platform standards required for {{PROJECT_NAME}}.

## File and Function Rules
- **Type Hints:** All functions must have type hints on ALL parameters and return value.
- **Docstrings:** All public functions must have a Google-style docstring with `Args`, `Returns`, and `Raises` (if any).
- **Line Length:** 88 characters max, enforced by Ruff formatting.
- **Imports:** Sorted by Ruff (stdlib → third-party → local).

## Path Handling (Cross-Platform)
- **Pathlib always:** NEVER use hardcoded path strings or bare concatenations. Always use `pathlib.Path`.

```python
# ✅ CORRECT — always
from pathlib import Path
data_path = Path("data") / "raw" / "file.csv"

# ❌ WRONG — never
data_path = "data/raw/file.csv"          # breaks on Windows
data_path = "data\\raw\\file.csv"       # breaks on macOS/Linux
```

## Configuration Access
- **Settings Singleton:** NEVER use `os.environ` or direct configuration files in source code. Use the centralized `settings` object.

```python
# ✅ CORRECT — always
from {{PACKAGE_NAME}}.config import settings
data_dir = settings.raw_data_dir

# ❌ WRONG — never
import os
data_dir = os.environ.get("DATA_DIR", "data/raw")  # bypasses validation
```

## Error Handling
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

## Logging
- **Standard Logging:** NEVER use raw `print()` for logging or trace outputs in library/source code. Use standard `logging`.

```python
# ✅ CORRECT — always
import logging
logger = logging.getLogger(__name__)
logger.info("Processing %d players", len(players))

# ❌ WRONG — never
print(f"Processing {len(players)} players")
```
