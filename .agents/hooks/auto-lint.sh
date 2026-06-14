#!/usr/bin/env bash
# auto-lint.sh
input=$(cat)

file=""
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$input" | jq -r '.toolCall.args.path // empty' 2>/dev/null)
fi
[ -z "$file" ] && file=$(printf '%s' "$input" | \
  sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

if [[ "$file" == *.py ]]; then
  ruff format --quiet "$file" 2>/dev/null
elif [[ "$file" == *.ts ]] || [[ "$file" == *.js ]]; then
  npx prettier --write "$file" 2>/dev/null
fi

printf '{"decision":"allow"}\n'
