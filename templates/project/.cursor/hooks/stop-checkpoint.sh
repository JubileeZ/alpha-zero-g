#!/usr/bin/env bash
# Cursor adapter: remind to Checkpoint via Work Packet (stop cannot hard-deny)
set -euo pipefail

input=$(cat)
# unused payload reserved for future freshness checks
: "${input}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '{}\n'
  exit 0
fi

has_code_changes=false
has_workstate_update=false

while IFS= read -r line; do
  [ -z "${line}" ] && continue
  file_path=$(printf '%s' "${line}" | cut -c 4-)
  file_path="${file_path#\"}"
  file_path="${file_path%\"}"
  case "${file_path}" in
    .agents/spawn-state.json|.agents/session-handoff.md.tmpl) continue ;;
  esac
  if [ "${file_path}" = "task.md" ] || [ "${file_path}" = "docs/agents/current-state.md" ]; then
    has_workstate_update=true
  elif [ "${file_path}" != "ROADMAP.md" ]; then
    has_code_changes=true
  fi
done < <(git status --porcelain 2>/dev/null)

if [ "${has_code_changes}" = true ] && [ "${has_workstate_update}" = false ]; then
  printf '{"followup_message":"Code changes are uncommitted without a Work Packet update. Update task.md SFDBN fields, run bash tests/verify.sh, then create a Checkpoint commit before stopping."}\n'
  exit 0
fi

printf '{}\n'
exit 0
