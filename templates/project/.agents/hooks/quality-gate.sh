#!/usr/bin/env bash
# quality-gate.sh
input=$(cat)

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)
fi
[ -z "$cmd" ] && cmd=$(printf '%s' "$input" | \
  sed -n 's/.*"CommandLine"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

if printf '%s' "$cmd" | grep -qE '^git[[:space:]]+commit'; then
  if ! ruff check . --quiet 2>/dev/null; then
    printf '{"decision":"deny","reason":"Lint failed — fix before committing."}\n'
    exit 0
  fi
fi

printf '{"decision":"allow"}\n'
