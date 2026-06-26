#!/usr/bin/env bash
# checkpoint.sh — Stop hook to enforce fresh current-state.md or handoff
input=$(cat)

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '{"decision":"allow"}\n'
  exit 0
fi

has_changes=false
has_code_changes=false
has_workstate_update=false

while IFS= read -r line; do
  [ -z "$line" ] && continue
  
  file_path=$(printf '%s' "$line" | cut -c 4-)
  file_path="${file_path#\"}"
  file_path="${file_path%\"}"

  if [ "$file_path" = ".agents/spawn-state.json" ] || [ "$file_path" = ".agents/session-handoff.md.tmpl" ]; then
    continue
  fi

  has_changes=true

  if [ "$file_path" = "docs/agents/current-state.md" ] || [ "$file_path" = ".agents/session-handoff.md" ]; then
    has_workstate_update=true
  elif [ "$file_path" != "task.md" ] && [ "$file_path" != "ROADMAP.md" ]; then
    has_code_changes=true
  fi
done < <(git status --porcelain 2>/dev/null)

if [ "$has_code_changes" = true ] && [ "$has_workstate_update" = false ]; then
  printf '{"decision":"deny","reason":"Code changes detected but neither docs/agents/current-state.md nor .agents/session-handoff.md has been updated. Please document your progress before stopping."}\n'
  exit 0
fi

printf '{"decision":"allow"}\n'
exit 0
