# Open Architectural Decisions — {{PROJECT_NAME}}

This file is a **backfill prompt checklist** for the first agent sessions on this project.
Work through each category and write an ADR in `docs/adr/` for every decision that is hard-to-reverse, surprising without context, or the result of a genuine trade-off.

Use `docs/adr/0000-adr-template.md` as your template. Register each ADR in `docs/beliefs.md`.

---

## How to Use This File

1. Read each category below.
2. If your project has made a decision in that category → write the ADR now.
3. If the decision is still open → leave a note or defer.
4. Delete resolved items from this file as ADRs are written.

---

## Decision Categories

### Data & Inputs
- [ ] What is your primary data source? Why this source over alternatives?
- [ ] How do you handle missing or delayed data?
- [ ] How do you prevent lookahead bias in your data pipeline?
- [ ] What is the grain (row = ?) of your primary analytical dataset?

### Modelling Approach
- [ ] What modelling family did you choose (regression, probabilistic, RL, etc.) and why?
- [ ] What distributional assumptions are you making? Are they tested?
- [ ] How do you handle class imbalance or sparse targets?
- [ ] What is your train / validation / test split strategy? Is it time-aware?

### Optimization & Solvers
- [ ] What solver or optimization library are you using and why?
- [ ] What are the key constraints in your optimization problem?
- [ ] How do you handle infeasibility or degenerate solutions?

### Evaluation & Validation
- [ ] What is your primary evaluation metric? Why this metric over alternatives?
- [ ] How do you define "good enough" for promotion to production?
- [ ] What backtesting or cross-validation approach are you using?

### Infrastructure & Environment
- [ ] What Python / R version and why?
- [ ] What package manager and why (`uv`, `pip`, `renv`)?
- [ ] How are credentials and secrets managed?
- [ ] How are reproducible runs guaranteed across machines?

### Architecture & Interfaces
- [ ] What is the primary entry point for a run (script, notebook, CLI)?
- [ ] How are outputs stored and versioned?
- [ ] Is there a clear boundary between data acquisition, feature engineering, modelling, and reporting layers?

---

*Once all decisions are documented as ADRs, this file may be archived or deleted.*
