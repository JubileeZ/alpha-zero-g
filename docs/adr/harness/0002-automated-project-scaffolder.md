# ADR-0002: Automated Project Scaffolder and Parameterizer

## Context

Standardizing the starting point of new projects (FPL, Crypto, etc.) requires copying, establishing directory structures, and manually editing configuration file parameters (e.g. workspace paths, project names), which causes friction and configuration errors.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-25

We will build a lightweight, native bash project generator (`create-project.sh`) at the root of the harness. The script will:
1. Programmatically set up standard directories (`src/`, `notebooks/`, `tests/`, `.agents/`).
2. Deploy all standard configuration and system of record templates.
3. Use portable stream-editing (`sed`) to find and replace customized properties like project name, description, and absolute directory roots automatically.
4. Auto-register the new path in the global trusted workspaces JSON.
5. Initialize local git and establish an initial baseline commit.

## Consequences

* **Positive:** Reduces the developer setup time for fresh, compliant agentic workspaces down to a single terminal command.
* **Negative:** Bash-dependent `sed` scripting requires extra portability care to work seamlessly across macOS (BSD sed) and Linux (GNU sed).
