#!/usr/bin/env bash
# spawn-budget.sh — enforce spawn depth and count limits
input=$(cat)

STATE_FILE=".agents/spawn-state.json"
mkdir -p .agents

if [ "${1:-}" = "--reset" ]; then
  printf '{"total_spawns": 0, "sessions": {}}' > "$STATE_FILE"
  printf '{"decision":"allow"}\n'
  exit 0
fi

max_spawns=3
max_depth=2
if [ -f .agents/spawn-budget.json ]; then
  if command -v jq >/dev/null 2>&1; then
    max_spawns=$(jq -r '.max_spawns // 3' .agents/spawn-budget.json 2>/dev/null)
    max_depth=$(jq -r '.max_depth // 2' .agents/spawn-budget.json 2>/dev/null)
  fi
fi

if [ ! -f "$STATE_FILE" ]; then
  printf '{"total_spawns": 0, "sessions": {}}' > "$STATE_FILE"
fi

session_id=""
subagent_id=""

if command -v jq >/dev/null 2>&1; then
  session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
  subagent_id=$(printf '%s' "$input" | jq -r '.subagent_id // .subagent.session_id // empty' 2>/dev/null)
fi

if [ -z "$session_id" ]; then
  session_id="${AGY_SESSION_ID:-${SESSION_ID:-default}}"
fi

if [ -z "$subagent_id" ]; then
  subagent_id="subagent_$(date +%s)_$RANDOM"
fi

parent_depth=0
total_spawns=0
if command -v jq >/dev/null 2>&1; then
  parent_depth=$(jq -r --arg sid "$session_id" '.sessions[$sid].depth // 0' "$STATE_FILE" 2>/dev/null)
  total_spawns=$(jq -r '.total_spawns // 0' "$STATE_FILE" 2>/dev/null)
fi

child_depth=$((parent_depth + 1))

if [ "$total_spawns" -ge "$max_spawns" ]; then
  printf '{"decision":"deny","reason":"Spawn budget exceeded: maximum spawns (%d) reached"}\n' "$max_spawns"
  exit 0
fi

if [ "$child_depth" -gt "$max_depth" ]; then
  printf '{"decision":"deny","reason":"Spawn budget exceeded: maximum depth (%d) reached"}\n' "$max_depth"
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  new_spawns=$((total_spawns + 1))
  jq --argjson ts "$new_spawns"      --arg sid "$subagent_id"      --argjson cd "$child_depth"      '.total_spawns = $ts | .sessions[$sid] = {depth: $cd}'      "$STATE_FILE" > "${STATE_FILE}.tmp"
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
fi

printf '{"decision":"allow"}\n'
exit 0
