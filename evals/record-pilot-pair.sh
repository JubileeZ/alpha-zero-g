#!/usr/bin/env bash
# evals/record-pilot-pair.sh — append a paired result to a pilot log
#
# Usage:
#   bash evals/record-pilot-pair.sh exploratory|confirmation|held-out \
#     --fixture ID \
#     --core-scorecard path.json \
#     --baseline-scorecard path.json \
#     [--core-judge path.json] [--baseline-judge path.json] \
#     [--notes "..."]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PHASE="${1:-}"
shift || true

if [ -z "${PHASE}" ]; then
  echo "usage: record-pilot-pair.sh <exploratory|confirmation|held-out> ..." >&2
  exit 2
fi

case "${PHASE}" in
  exploratory|confirmation|held-out) ;;
  *) echo "phase must be exploratory|confirmation|held-out" >&2; exit 2 ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

fixture=""
core_sc=""
base_sc=""
core_j=""
base_j=""
notes=""

while [ $# -gt 0 ]; do
  case "$1" in
    --fixture) fixture="$2"; shift 2 ;;
    --core-scorecard) core_sc="$2"; shift 2 ;;
    --baseline-scorecard) base_sc="$2"; shift 2 ;;
    --core-judge) core_j="$2"; shift 2 ;;
    --baseline-judge) base_j="$2"; shift 2 ;;
    --notes) notes="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "${fixture}" ] || [ -z "${core_sc}" ] || [ -z "${base_sc}" ]; then
  echo "fixture + both scorecards required" >&2
  exit 2
fi

# Exploratory never supports reliability claims; confirmation/held-out still false until held-out green
claim=false

core_success=false
base_success=false
if [ -n "${core_j}" ] && [ -f "${core_j}" ]; then
  core_success=$(jq -r 'if .judge_pass == true then "true" else "false" end' "${core_j}")
else
  ts=$(jq -r '.task_success // 0' "${core_sc}")
  if [ "${ts}" = "1" ] || [ "${ts}" = "true" ]; then core_success=true; fi
fi
if [ -n "${base_j}" ] && [ -f "${base_j}" ]; then
  base_success=$(jq -r 'if .judge_pass == true then "true" else "false" end' "${base_j}")
else
  ts=$(jq -r '.task_success // 0' "${base_sc}")
  if [ "${ts}" = "1" ] || [ "${ts}" = "true" ]; then base_success=true; fi
fi

logfile="${ROOT}/evals/pilot/${PHASE}-log.jsonl"
mkdir -p "${ROOT}/evals/pilot"

jq -nc \
  --arg phase "${PHASE}" \
  --arg fixture "${fixture}" \
  --arg notes "${notes}" \
  --argjson reliability_claim "${claim}" \
  --argjson core_success "${core_success}" \
  --argjson baseline_success "${base_success}" \
  --argjson core_scorecard "$(jq '{task_success,delivery_cost,wall_time_sec,interventions,treatment,model,ide}' "${core_sc}")" \
  --argjson baseline_scorecard "$(jq '{task_success,delivery_cost,wall_time_sec,interventions,treatment,model,ide}' "${base_sc}")" \
  --arg recorded_at "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  '{
    phase: $phase,
    reliability_claim: $reliability_claim,
    fixture_id: $fixture,
    recorded_at: $recorded_at,
    core_success: $core_success,
    baseline_success: $baseline_success,
    core: $core_scorecard,
    baseline: $baseline_scorecard,
    notes: $notes
  }' >> "${logfile}"

echo "appended ${logfile}"
