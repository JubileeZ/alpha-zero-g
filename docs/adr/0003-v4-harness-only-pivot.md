# 3. v4 Harness-Only Pivot

We decided to pivot the Alpha-Zero-G CLI and templates to a **harness-only** structure starting in version 4.0.0. The CLI no longer scaffolds framework/application stacks (like React, Next.js, FastAPI, etc.) or lint/testing wizards. Instead, it exclusively manages the AI agent outer harness (continuity files, hooks, cursor rules, and global skills).

Key design decisions:
- **No Stack Duplication**: AI agents are highly capable of scaffolding application stacks and code structures themselves based on direct instructions and standard tooling. Duplicating framework boilerplate generators within `azg` is redundant and hard to maintain (YAGNI).
- **Harness-Only Scope**: The CLI focuses entirely on setting up developer guardrails and agent execution state files (e.g. `task.md`, `ROADMAP.md`, hooks, and cursor rules) to maximize agent efficiency, reliability, and token safety.
- **Improved Portability**: Removing stack-specific templates makes the project highly lightweight, compatible with any stack or repository structure, and cross-platform safe out of the box.
