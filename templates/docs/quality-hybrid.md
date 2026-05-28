# Quality Grades & Compliance Tracking — {{PROJECT_NAME}}

This document defines the quality metrics, coding guidelines, and environment standards required to pass quality checks within {{PROJECT_NAME}}.

---

## 1. Quality Checklist & Rules

### Python Quality Standards
- `[ ]` **Type Annotations:** All public interfaces, function parameters, and return types must be fully annotated.
- `[ ]` **Documentation:** Every class, module, and function must contain descriptive docstrings detailing input parameters, types, and return descriptions.
- `[ ]` **Logging Conventions:** Major data structures, pipelines, and dataframes must print or log input and output dimensions (shapes) before and after transformations.
- `[ ]` **Error Handling:** Bare `except:` blocks are forbidden. Use explicit exception categories and tracebacks.
- `[ ]` **Test Coverage:** All new features or functions must have at least one corresponding unit test in the `tests/` directory.

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
| **A (Production Ready)** | 100% test coverage, comprehensive docstrings/Roxygen, no lint warnings, all range/boundary assertions implemented. | Safe for live statistical execution or solver API routing. |
| **B (Research Complete)** | Comprehensive docs, passing tests, key statistical assumptions documented, minimal lint warnings. | Safe for integration, backtesting, and validation runs. |
| **C (Draft / Scratch)** | Basic logic functional, some functions lack docs or tests. | Restricted to sandboxed interactive notebooks or temporary scratch directories. |
