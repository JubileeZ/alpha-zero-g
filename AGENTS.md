# Agent Harness — Alpha-Zero-G

## Permissions

- Read: all files in project
- Write: src/, notebooks/, tests/ only
- Require approval before: deleting files, modifying config/, pushing to main

## Standards

- All new functions must have a docstring and at least one unit test
- Statistical models must document assumptions in MODEL_NOTES.md
- Data transformations must be logged to console with input/output shapes

## Context Files (load these at session start)

- CONTEXT.md — project glossary
- DATA_DICT.md — column definitions
- MODEL_NOTES.md — current model state

## Preferred Workflow

Use grill→spec→slice→ship→refactor for any task longer than ~30 min