# Security Rules — {{PROJECT_NAME}}

This document details absolute safety and sandboxing policies to prevent credentials exposure or unauthorized state changes.

## Standard Analytics Project
- **Credentials:** Never commit API keys, passwords, or secrets (use `.env` and `settings` only).
- **Data Privacy:** Never expose raw sensitive data in logs, printouts, or source code.
- **Data Validation:** Validate all external API payloads and source files before consumption.

## External Action Execution (e.g., Trading, CLI Solvers)
- **RULE OF TWO:** Never allow an agent all three simultaneously:
  1. Process untrusted external input
  2. Access sensitive credentials/systems
  3. Modify state (execute orders, delete data)
- **Human-in-the-loop:** Any action modifying external state requires explicit, interactive user approval.
- **Sandbox Testing:** Always test in dry-run, simulation, or paper-trading modes before real execution.
