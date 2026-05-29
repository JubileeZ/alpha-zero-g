# ADR-0008: Modular Rules Refactoring and Scaffolding Templates

This document records the decision to modularize `templates/AGENTS.md` and related rules files to streamline the cognitive footprint of the primary entry point while enforcing clean cross-session collaboration.

## Context

The `templates/AGENTS.md` file had grown to over 260 lines, bundling Coding Conventions, Data Handling, Statistical Modeling, and Token limits in a single monolith. This created a high cognitive load for incoming AI agents reading the rules at session start. 

To improve agent efficiency and reduce token overhead while preserving the strict boundaries of the harness:
1. Long prose rules needed compression.
2. Large code examples (such as `Pathlib` or `Settings` usage blocks) needed to be moved out of the main index.
3. Diagnostic protocols needed to be integrated directly into the developer workflow.
4. All programmatically active `[HARD]` rules must be kept strictly inline to ensure absolute agent compliance.

## Decision

* **Status:** `accepted`
* **Date:** 2026-05-29

We will refactor the scaffolding templates and core harness configurations into a clean modular rule system:
1. **Target length**: Compressed `templates/AGENTS.md` to 85 lines.
2. **System Pointers**: Kept the System Pointers table intact, adding new rows to point to the 9 newly extracted sub-documents (`conventions.md`, `data-rules.md`, `modeling-rules.md`, `context-management.md`, `session-protocols.md`, `testing-requirements.md`, `security-rules.md`, `domain-rules.md`, `safety-policies.md`) under `docs/`.
3. **Keep `[HARD]` Rules Inline**: Preserved all programmatically enforced `[HARD]` rules in `templates/AGENTS.md` (e.g. ADR-0007 Portable Markdown Linking).
4. **Brevity**: Compressed all prose rules in `templates/AGENTS.md` to exactly one imperative sentence each.
5. **Code Examples**: Moved all ✅/❌ code examples out of the main index and consolidated them inside `docs/conventions.md`.
6. **Workflow Integration**: Merged **Debug Protocol** and **Validation Loop** as dedicated sections inside `DEVELOPER_WORKFLOW.md`.
7. **Scaffolding and Upgrader Automation**: Updated `create-project.sh` and `upgrade-project.sh` to fully automate copying, synchronizing, and resolving placeholders within all new sub-documents.

## Consequences

* **Positive:**
  - **Drastically Reduced Cognitive Footprint**: Incoming agents can read and absorb the primary entry point rules immediately.
  - **Consolidated Coding Standard**: High-density examples are kept in a single sub-document, keeping the rule files readable.
  - **Aligned Workflow**: Integrated the debugging protocols directly where developers and agents perform task execution.
  - **100% Automated**: Generator and upgrader suites propagate these modular files downstream with zero manual setup.
* **Negative:**
  - None.
