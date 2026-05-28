# Quality Grades & Compliance Tracking — {{PROJECT_NAME}}

This document defines the quality metrics, coding guidelines, and environment standards required to pass quality checks within {{PROJECT_NAME}}.

---

## 1. Quality Checklist & Rules

### R Quality Standards
- `[ ]` **Roxygen2 Documentation:** R scripts and libraries must be documented using Roxygen format above every function header.
- `[ ]` **Pipeline Clarity:** Avoid nested sub-function calls. Use tidyverse pipelines (`%>%` or native `|>`) cleanly.
- `[ ]` **Dimensions Logging:** Print data frame dimensions (`dim()`) and structures (`str()` or `glimpse()`) before and after data processing steps.
- `[ ]` **Test Coverage:** All new features or functions must have at least one corresponding unit test in `tests/`.

---

## 2. Quality Grading Framework

We evaluate project readiness using a strict tiered grading structure:

| Grade | Criteria | Target Action |
|---|---|---|
| **A (Production Ready)** | 100% test coverage, comprehensive Roxygen docs, no lint warnings, all range/boundary assertions implemented. | Safe for live statistical execution. |
| **B (Research Complete)** | Comprehensive Roxygen docs, passing tests, key statistical assumptions documented, minimal lint warnings. | Safe for integration, backtesting, and validation runs. |
| **C (Draft / Scratch)** | Basic logic functional, some functions lack documentation or tests. | Restricted to sandboxed interactive notebooks. |
