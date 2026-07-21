#!/usr/bin/env bash
# evals/record-scorecard.sh — fill scorecard fields after a run
#
# Usage:
#   bash evals/record-scorecard.sh path/to/scorecard.json \
#     --task-success 0|1 \
#     --delivery-cost N \
#     --wall-time-sec N \
#     --interventions N \
#     [--notes "..."] [--model M] [--ide I] [--operator O]

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: record-scorecard.sh SCORECARD.json [flags]" >&2
  exit 2
fi

SCORECARD="$1"
shift

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

task_success=""
delivery_cost=""
wall_time_sec=""
interventions=""
notes=""
model=""
ide=""
operator=""

while [ $# -gt 0 ]; do
  case "$1" in
    --task-success) task_success="$2"; shift 2 ;;
    --delivery-cost) delivery_cost="$2"; shift 2 ;;
    --wall-time-sec) wall_time_sec="$2"; shift 2 ;;
    --interventions) interventions="$2"; shift 2 ;;
    --notes) notes="$2"; shift 2 ;;
    --model) model="$2"; shift 2 ;;
    --ide) ide="$2"; shift 2 ;;
    --operator) operator="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

tmp="${SCORECARD}.tmp"
jq \
  --argjson ts "${task_success:-null}" \
  --argjson dc "${delivery_cost:-null}" \
  --argjson wt "${wall_time_sec:-null}" \
  --argjson iv "${interventions:-null}" \
  --arg notes "${notes}" \
  --arg model "${model}" \
  --arg ide "${ide}" \
  --arg operator "${operator}" \
  --arg finished "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  '
    .task_success = $ts
    | .delivery_cost = $dc
    | .wall_time_sec = $wt
    | .interventions = $iv
    | .notes = $notes
    | .model = $model
    | .ide = $ide
    | .operator = $operator
    | .finished_at = $finished
  ' "${SCORECARD}" > "${tmp}"
mv "${tmp}" "${SCORECARD}"
echo "updated ${SCORECARD}"
