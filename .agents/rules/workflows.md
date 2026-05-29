---
name: workflows
description: Strict loop workflows for any analytical, modeling, or coding task taking longer than 30 minutes.
activation: Always On
---
# Preferred Workflows Loop

For any analytical, modeling, or coding task taking longer than 30 minutes, you MUST execute the following strict loop:

1. **Grill:** Invoke `/grill-analytics` (either globally or locally) to stress-test ideas.
2. **Spec:** Invoke `/spec-model` to compile a formal specification in `docs/design/` or `docs/MODEL_NOTES.md`.
3. **Slice:** Break the spec down into tiny, verifiable vertical slices.
4. **Ship:** Execute slices step-by-step. All Python functions require docstrings and type hints.
5. **Refactor:** Clean up code while verifying tests remain fully passing.

## Verification & Alignment
- [HARD] Update `progress.md` and `features.json` to reflect the new state upon completing any implementation phase, model run, or feature slice.
- [SOFT] Sync architectural decisions to `docs/beliefs.md`.
- [SOFT] Update any new variables or data schemas in `docs/DATA_DICT.md`.
- [SOFT] Log model assumptions or backtest performance metrics in `docs/MODEL_NOTES.md`.
- [SOFT] Keep `README.md` updated if directory layouts, bootstrapping steps, or main features change.
