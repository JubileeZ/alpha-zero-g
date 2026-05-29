# Permissions & Safety Policies — {{PROJECT_NAME}}

This document details standard programmatic access levels and safety constraints enforced at the harness layer.

*Note: Behavioral policy below is strictly enforced programmatically by `.agents/hooks.json` interceptors.*

- **Allowed Freely:** Reading any project files. Writing to `src/`, `notebooks/`, `tests/`, and temporary directories.
- **Requires Approval:** Deleting files, modifying `.agents/` or `config/` paths, installing system packages, and performing network requests.
- **Forbidden:** Force-pushing to main (`git push --force`), modifying `.git/` internals, and exposing `.env` secrets.
