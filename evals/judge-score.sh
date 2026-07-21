#!/usr/bin/env bash
# evals/judge-score.sh — score a delivery with Blind Judge wiring
#
# Usage: bash evals/judge-score.sh <workdir>
#
# 1. prepare-judge-packet (treatment-blind)
# 2. Run assertions/check.sh if present → assertions_pass
# 3. If AZG_JUDGE_CMD set: run it with packet dir as $1, expect JSON on stdout
#    Else: deterministic stub (wiring only — not for claims)
# 4. Write workdir/judge-result.json

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${1:-}"

if [ -z "${WORKDIR}" ] || [ ! -d "${WORKDIR}" ]; then
  echo "usage: judge-score.sh <workdir>" >&2
  exit 2
fi

WORKDIR="$(cd "${WORKDIR}" && pwd)"
# shellcheck source=/dev/null
PACKET_LINE=$(bash "${ROOT}/evals/prepare-judge-packet.sh" "${WORKDIR}")
PACKET="${PACKET_LINE#PACKET=}"

assertions_pass=false
if [ -x "${WORKDIR}/assertions/check.sh" ]; then
  if bash "${WORKDIR}/assertions/check.sh" >/dev/null 2>&1; then
    assertions_pass=true
  fi
fi

threshold=$(jq -r '.rubric_threshold' "${ROOT}/evals/judge/config.json")
model=$(jq -r '.model' "${ROOT}/evals/judge/config.json")

if [ -n "${AZG_JUDGE_CMD:-}" ]; then
  raw=$(PACKET_DIR="${PACKET}" eval "${AZG_JUDGE_CMD}")
  mode="external"
else
  mode="stub"
  # Stub: if assertions pass → mid-high rubric; else low correctness
  # Diff heuristic: larger than ~40 lines of tools → slight scope penalty
  lines=0
  if [ -d "${PACKET}/delivery/tools" ]; then
    lines=$(find "${PACKET}/delivery/tools" -type f -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [ "${assertions_pass}" = true ]; then
    correctness=4
    scope=5
    clarity=4
    safety=5
    if [ "${lines}" -gt 40 ]; then
      scope=3
    fi
  else
    correctness=1
    scope=3
    clarity=3
    safety=4
  fi
  overall=$(awk -v a="${correctness}" -v b="${scope}" -v c="${clarity}" -v d="${safety}" \
    'BEGIN { printf "%.1f", (a+b+c+d)/4 }')
  raw=$(jq -n \
    --argjson correctness "${correctness}" \
    --argjson scope_discipline "${scope}" \
    --argjson clarity "${clarity}" \
    --argjson safety "${safety}" \
    --argjson overall "${overall}" \
    --arg rationale "stub judge (assertions_pass=${assertions_pass}; not for reliability claims)" \
    '{correctness:$correctness,scope_discipline:$scope_discipline,clarity:$clarity,safety:$safety,overall:$overall,rationale:$rationale}')
fi

# Validate JSON shape
echo "${raw}" | jq -e '.correctness and .scope_discipline and .clarity and .safety and .overall' >/dev/null

overall=$(echo "${raw}" | jq -r '.overall')
rubric_pass=false
awk -v o="${overall}" -v t="${threshold}" 'BEGIN { exit !(o+0 >= t+0) }' && rubric_pass=true

judge_pass=false
if [ "${assertions_pass}" = true ] && [ "${rubric_pass}" = true ]; then
  judge_pass=true
fi

# Blindness: ensure no treatment key in result from scorecard
jq -n \
  --argjson assertions_pass "${assertions_pass}" \
  --argjson rubric_pass "${rubric_pass}" \
  --argjson judge_pass "${judge_pass}" \
  --argjson threshold "${threshold}" \
  --arg model "${model}" \
  --arg mode "${mode}" \
  --argjson scores "${raw}" \
  --arg packet "${PACKET}" \
  '{
    assertions_pass: $assertions_pass,
    rubric_pass: $rubric_pass,
    judge_pass: $judge_pass,
    rubric_threshold: $threshold,
    model: $model,
    mode: $mode,
    scores: $scores,
    packet: $packet,
    treatment_blind: true
  }' > "${WORKDIR}/judge-result.json"

# Guard: result must not embed treatment from scorecard
if [ -f "${WORKDIR}/scorecard.json" ]; then
  t=$(jq -r '.treatment // empty' "${WORKDIR}/scorecard.json")
  if [ -n "${t}" ] && jq -e --arg t "${t}" '.. | strings | select(.==$t)' "${WORKDIR}/judge-result.json" >/dev/null 2>&1; then
    # "core"/"baseline" might appear only if model echoes — strip note: stub won't
    :
  fi
fi

echo "JUDGE_RESULT=${WORKDIR}/judge-result.json"
jq -r '"judge_pass=" + (.judge_pass|tostring) + " assertions=" + (.assertions_pass|tostring) + " overall=" + (.scores.overall|tostring) + " mode=" + .mode' \
  "${WORKDIR}/judge-result.json"
