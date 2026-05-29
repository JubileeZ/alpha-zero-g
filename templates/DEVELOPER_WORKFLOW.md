# The Golden Path Developer Workflow — {{PROJECT_NAME}}

To ensure high-performance, deterministic development and perfect session continuity when pair-programming with AI agents in the {{PROJECT_NAME}} workspace, always follow the exact multi-phase cycle below:

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  1. BOOT  │ ──> │ 2. GRILL  │ ──> │  3. SPEC  │ ──> │ 4. SLICE  │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
                                                            │
┌───────────┐     ┌───────────┐     ┌───────────┐           ▼
│8. HANDOFF │ <── │7.REFACTOR │ <── │ 6. VERIFY │ <── │  5. SHIP  │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
```

### 1. BOOT (Session Startup)
* **Actions:** Open this workspace and run the idempotent local bootstrapper:
  ```bash
  bash init.sh
  ```
* **Why:** This synchronizes your virtual environment and runs smoke sensors to ensure a clean, green baseline before touching any files.
* **Important:** During the session, NEVER execute unmanaged system `python`, `python3`, or `pip`. Always prepend Python executions with `uv run` to guarantee that dependencies are correctly resolved from the virtual environment.

### 2. GRILL (Domain & Plan Alignment)
* **Command:** `/grill-with-docs` (general logic) or `/grill-analytics` (for statistical audits).
* **Actions:** Relentlessly stress-test your ideas. Identify edge cases, specify model objectives, align column/feature names with `docs/DATA_DICT.md`, and update your domain glossary `CONTEXT.md` inline. Record hard trade-offs in `docs/adr/`.
* **Example:** *"grilling the feature extraction parameters for FPL prediction to ensure zero lookahead bias."*

### 3. SPEC (Formal System Design)
* **Command:** `/spec-model`
* **Actions:** Propose and compile a comprehensive design specification inside `docs/design/` or `docs/MODEL_NOTES.md`. Get explicit approval on the interface, mathematical formulations, and validation splits before writing code.

### 4. SLICE (Tracer Bullet Slicing)
* **Command:** `/to-issues`
* **Actions:** Break the approved design spec down into thin, independent vertical slices (tracer bullets) that cut end-to-end through every layer (schema, code, tests). List these in `features.json`.

### 5. SHIP (TDD Execution)
* **Command:** `/tdd`
* **Actions:** Run the test-driven development loop (Red-Green-Refactor) for one slice at a time. Write a behavior-based test in `tests/`, watch it fail (Red), write minimal code to pass (Green), then refactor.
  * **Rule:** Run the test runner using `uv run pytest` (e.g. `uv run pytest tests/test_smoke.py`). Do not execute `pytest` or `python` unmanaged.
* **Troubleshooting:** If a hard bug or regression occurs, divert immediately to `/diagnose` to systematically reproduce, instrument, and fix.

### 6. VERIFY (Statistical & Sanity Checks)
* **Command:** `/validate-output`
* **Actions:** Conduct post-modeling validation checks. Assert output shape, check null counts, verify against naive baselines, and test model predictions for stationarity or leakage.

### 7. REFACTOR (Architecture Deepening)
* **Command:** `/improve-codebase-architecture`
* **Actions:** Clean up architectural coupling, extract duplication, move complexity behind deep modules, and verify all tests remain fully green.

### 8. HANDOFF (Session Transition)
* **Command:** `/handoff`
* **Actions:** Compact the current session's milestones, modified files, and next actions into the checklist in `progress.md` so the next session can orient and resume immediately.

---

## Debug Protocol (Troubleshooting Failures)

When a test, build, or command fails, follow these steps:
1. **Read the FULL error message:** Do not guess or run commands blindly.
2. **Categorize the error:** Determine if it is a Logic, Type, Schema, Data Quality, or Environment issue.
3. **Check logs & ADRs:** Has this problem or pattern been solved before in `docs/beliefs.md` or `docs/adr/`?
4. **Solve the ROOT CAUSE:** Fix the structural problem rather than patching the symptom.
5. **Write a regression test:** Create a test that reproduces the bug and prevents future regressions.

---

## Validation Loop (Continuous Integration)

Before finalizing and concluding any code changes, perform the following validation loop:
1. **Write the code + type hints:** Ensure all types are strictly defined.
2. **Write tests:** Cover edge cases and typical inputs in your unit/integration tests.
3. **Run tests via `uv run`:** Run `uv run pytest` to assert that all tests pass perfectly.
4. **Run linters & type checkers:** Execute standard checkers (e.g. `make check`, `uv run ruff check`, `uv run mypy`).
5. **Verify data contracts:** Ensure all schemas and data constraints validate.

