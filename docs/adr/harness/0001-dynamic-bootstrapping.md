# ADR-0001: Dynamic R & Python Environment Bootstrapping

## Context

The user works across statistical projects that heavily combine Python and R. Setting up distinct virtual environments for each language manually creates friction.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-20

The project bootstrapper (`init.sh`) must dynamically detect project requirements. Instead of pinning to a single environment type, the script will:
1. Scan for Python configurations (`pyproject.toml` or `requirements.txt`) and bootstrap `uv` virtual environments if found.
2. Scan for R scripts (`.R` files, `DESCRIPTION` files, or project directory structures containing `.Rprofile`) and bootstrap R library management via `renv` or `pak` if R is utilized.
3. Ensure the environment is verified cleanly via test sensors before completing initialization.

## Consequences

* **Positive:** Provides a single, unified entry point (`init.sh`) that scales from Python-only, R-only, to hybrid analytics configurations cleanly.
* **Negative:** Slightly increased complexity in the shell script to handle multi-platform path detection and tool installation fallback checks.
