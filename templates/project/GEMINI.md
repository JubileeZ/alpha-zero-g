# Project Overrides
@~/.gemini/GEMINI.md

## Project Antigravity Rules
- Trust: auto-approve git read, git status, pytest

## Local Skills & Rules Setup
- [SOFT] If testing or modifying custom skills, keep them in `.agents/skills/` locally first to verify behavior before migrating them to global storage (`~/.gemini/antigravity-cli/skills/`). Local skills override global skills of the same name.
- [SOFT] Supplemental workspace rules are organized modularly under `.agents/rules/*.md`. Refer to them for specific execution protocols.
