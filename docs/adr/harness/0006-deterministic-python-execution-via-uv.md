# ADR-0006: Deterministic Python Execution via `uv run`

This document records the decision to behaviorally prevent direct system Python executions by the agent and refactor harness bootstrappers to consistently use `uv run` to guarantee isolated, deterministic dependencies.

## Context

In complex, multi-device developer environments, relying on direct global shell commands like `python`, `python3`, or `pip` introduces severe environmental contamination risk. Agents might execute unmanaged global Python versions, fail to resolve packages from local virtual environments, or contaminate local directories with conflicting dependencies. 

While the virtual environment is built deterministically during bootstrapping, there was no behavioral safeguard preventing agents from running global/system Python in subsequent steps, nor was the harness bootloader consistently utilizing `uv run` for script checking and workspace registration.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-29

We will transition the harness and all downstream projects to prioritize `uv run` for executing Python scripts, tests, and configurations:
1. **Behavioral Agent Rules**: We updated all iterations of `AGENTS.md` and `DEVELOPER_WORKFLOW.md` (root, templates, global) to explicitly forbid unmanaged direct `python` or `python3` invocations. Agents are mandated to run Python and test runners via `uv run` (e.g. `uv run python script.py` and `uv run pytest`).
2. **Setup Script Refactoring**:
   - `init.sh` and `templates/init.sh` are refactored to execute validation smoke tests via `uv run python`, bypassing shell activation.
   - `create-project.sh` is refactored to check for `uv` and use `uv run python` for settings auto-registration, fallback-resilient to standard `python3`.
3. **Behavioral enforcement over programmatic hooks**: Following design alignment, we rely on clear, concise behavioral operating protocols rather than active programmatic command blocks in `hooks.json` to keep development fluid yet disciplined.

## Consequences

* **Positive:**
  - 100% deterministic package loading: running scripts via `uv run` ensures packages are sourced from the project's local virtual environment.
  - Reduced environmental errors: eliminates issues caused by un-activated shells or incorrect global python versions.
  - Unified developer workflow: consistent execution standard across all setups.
* **Negative:**
  - Terse overhead: commands must prefix `uv run` (e.g. `uv run pytest`), which is slightly longer than raw `pytest`.
