# Testing Requirements — {{PROJECT_NAME}}

This document details testing coverages, contract validation expectations, and test execution runner commands.

## Testing Matrix & Minimum Requirements

| Scope | Minimum Requirement |
|---|---|
| **Every public function** | At least 1 unit test |
| **Every data transformation** | Schema validation test (`pandera` or `pydantic`) |
| **Every statistical function** | Property-based test (`hypothesis`) |
| **Every model** | Performance regression test vs baseline |
| **Data contracts** | 100% test coverage |
| **`src/` overall** | 80% minimum test coverage |

## Test Runner Commands

You must run tests using the following commands:

```bash
make test           # Run all tests
make test-cov       # Run all tests with coverage report
make test-unit      # Run unit tests only
make check          # Lint + type-check + test (run before committing)
```
