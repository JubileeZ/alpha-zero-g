#!/usr/bin/env bash
# evals/analyze-pilot-gate.sh — confirmation + held-out must both be ready
#
# Usage:
#   bash evals/analyze-pilot-gate.sh           # write gate-status.json
#   bash evals/analyze-pilot-gate.sh --apply-claim  # also set prereg reliability_claim_allowed

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PILOT_DIR="${AZG_PILOT_DIR:-${ROOT}/evals/pilot}"
APPLY=0
if [ "${1:-}" = "--apply-claim" ]; then
  APPLY=1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

conf=$(AZG_PILOT_DIR="${PILOT_DIR}" bash "${ROOT}/evals/analyze-pilot-log.sh" confirmation)
held=$(AZG_PILOT_DIR="${PILOT_DIR}" bash "${ROOT}/evals/analyze-pilot-log.sh" held-out)

conf_ready=$(echo "${conf}" | jq -r '.ready')
held_ready=$(echo "${held}" | jq -r '.ready')
both=false
if [ "${conf_ready}" = "true" ] && [ "${held_ready}" = "true" ]; then
  both=true
fi

status="${PILOT_DIR}/gate-status.json"
jq -n \
  --argjson confirmation "${conf}" \
  --argjson held_out "${held}" \
  --argjson both_green "${both}" \
  --arg updated "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  '{
    updated_at: $updated,
    confirmation: $confirmation,
    held_out: $held_out,
    both_green: $both_green,
    reliability_claim_allowed: $both_green,
    note: (if $both_green then "Both layers green vs prereg; --apply-claim to persist in prereg.json" else "Not green — no Reliable Delivery claim" end)
  }' > "${status}"

echo "GATE_STATUS=${status}"
jq -r '"both_green=" + (.both_green|tostring) + " conf_ready=" + (.confirmation.ready|tostring) + " held_ready=" + (.held_out.ready|tostring)' "${status}"

if [ "${APPLY}" -eq 1 ]; then
  if [ "${both}" != "true" ]; then
    echo "--apply-claim refused: both layers not green" >&2
    exit 1
  fi
  tmp=$(mktemp)
  jq --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
    '.reliability_claim_allowed = true | .claim_applied_at = $at' \
    "${PILOT_DIR}/prereg.json" > "${tmp}"
  mv "${tmp}" "${PILOT_DIR}/prereg.json"
  echo "prereg.json reliability_claim_allowed=true"
fi
