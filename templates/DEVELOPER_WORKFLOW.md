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
