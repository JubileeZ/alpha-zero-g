#!/usr/bin/env bash
# block-destructive-ops.sh
input=$(cat)

cmd=""
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)
fi
[ -z "$cmd" ] && cmd=$(printf '%s' "$input" | \
  sed -n 's/.*"CommandLine"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

haystack="$cmd $input"

patterns=(
  'rm[[:space:]]+-r?f?[[:space:]]+/[[:space:]]*(\{| |$)'
  'git[[:space:]]+push([[:space:]].*)?--force'
  'git[[:space:]]+push([[:space:]].*)?[[:space:]]-f([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard'
  'git[[:space:]]+branch[[:space:]]+-D'
  'chmod[[:space:]]+-?R?[[:space:]]*777'
  'curl[^|]+\|[[:space:]]*(bash|sh)([[:space:]]|$)'
)

for p in "${patterns[@]}"; do
  if printf '%s' "$haystack" | grep -qE "$p"; then
    printf '{"decision":"deny","reason":"Destructive operation blocked by safety-gate policy."}\n'
    exit 0
  fi
done

printf '{"decision":"allow"}\n'
