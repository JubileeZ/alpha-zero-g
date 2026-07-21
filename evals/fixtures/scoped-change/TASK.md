# Task: Add --json without breaking text mode

## Objective

`tools/greet.sh` prints `hello, <name>`. Add `--json` so it prints `{"greeting":"hello","name":"<name>"}` instead. Default (no flag) must stay identical.

## Acceptance

- `bash assertions/check.sh` exits 0
- Text mode unchanged for: `greet.sh world` → `hello, world`

## Out of scope

Config files, i18n, extra fields in JSON.
