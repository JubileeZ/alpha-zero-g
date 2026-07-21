# Task: Fix clamp upper bound

## Objective

`tools/clamp.sh` should return `n` when `lo <= n <= hi`, else the nearest bound. Today values above `hi` are returned unchanged (upper bound not applied).

## Acceptance

- `bash assertions/check.sh` exits 0
- Do not change the CLI flags (`--lo`, `--hi`, positional `n`)

## Out of scope

Refactors unrelated to the bound bug; new features.
