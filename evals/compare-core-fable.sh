#!/usr/bin/env bash
# evals/compare-core-fable.sh — prepare core vs core+fable arms on the Evaluation Suite
#
# Does NOT run agents or claim reliability. Sets up paired workdirs + a matrix JSON
# for operators to fill after completing each arm (ADR 0005).
#
# Usage:
#   bash evals/compare-core-fable.sh              # all fixtures
#   bash evals/compare-core-fable.sh bug-fix     # one fixture
#
# Output: COMPARE_ROOT=... and compare-matrix.json with workdir paths per arm.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ONLY="${1:-}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

SUITE="${ROOT}/evals/suite.json"
COMPARE_ROOT="${TMPDIR:-${TEMP:-/tmp}}/azg-compare-core-fable-$$"
COMPARE_ROOT="${COMPARE_ROOT//\\//}"
mkdir -p "${COMPARE_ROOT}"

claim="$(jq -r '.reliability_claim_allowed // false' "${ROOT}/evals/pilot/prereg.json" 2>/dev/null || echo false)"

FIXTURES=()
if [ -n "${ONLY}" ]; then
  FIXTURES=("${ONLY}")
else
  while IFS= read -r _id; do
    [ -n "${_id}" ] && FIXTURES+=("${_id}")
  done < <(jq -r '.fixtures[].id' "${SUITE}")
fi

matrix='[]'
for id in "${FIXTURES[@]}"; do
  if ! jq -e --arg id "${id}" '.fixtures[] | select(.id==$id)' "${SUITE}" >/dev/null; then
    echo "unknown fixture: ${id}" >&2
    exit 1
  fi

  core_out=$(bash "${ROOT}/evals/run-pair.sh" "${id}" core)
  fable_out=$(bash "${ROOT}/evals/run-pair.sh" "${id}" core+fable)
  core_wd=$(echo "${core_out}" | sed -n 's/^WORKDIR=//p' | head -n1)
  fable_wd=$(echo "${fable_out}" | sed -n 's/^WORKDIR=//p' | head -n1)

  if [ ! -f "${fable_wd}/.agents/skills/fable/.fable-installed" ]; then
    echo "missing fable marker in ${fable_wd}" >&2
    exit 1
  fi

  # Persist pointers under compare root for operator convenience
  mkdir -p "${COMPARE_ROOT}/${id}"
  printf '%s\n' "${core_wd}" > "${COMPARE_ROOT}/${id}/core.workdir"
  printf '%s\n' "${fable_wd}" > "${COMPARE_ROOT}/${id}/core-fable.workdir"

  # -n required: jq without input file otherwise blocks on stdin (Windows WinGet jq)
  matrix=$(jq -n -c \
    --arg id "${id}" \
    --arg core "${core_wd}" \
    --arg fable "${fable_wd}" \
    --argjson matrix "${matrix}" \
    '$matrix + [{fixture_id:$id,arms:{core:{workdir:$core,scorecard:($core+"/scorecard.json"),status:"prepared"},"core+fable":{workdir:$fable,scorecard:($fable+"/scorecard.json"),status:"prepared"}},delta:{task_success:null,delivery_cost:null,notes:"Fill after both arms complete; do not claim until held-out gate"}}]')
done

jq -n \
  --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  --arg root "${COMPARE_ROOT}" \
  --arg claim "${claim}" \
  --argjson pairs "${matrix}" \
  '{
    kind: "core_vs_core_fable",
    experimental: true,
    reliability_claim_allowed: ($claim == "true"),
    started_at: $started,
    compare_root: $root,
    primary_metric: "task_success_per_delivery_cost",
    pairs: $pairs,
    next: [
      "Complete TASK.md in each arm workdir (separate sessions)",
      "bash evals/record-scorecard.sh <scorecard> --task-success N --delivery-cost X ...",
      "bash <workdir>/assertions/check.sh",
      "Optional Blind Judge: prepare-judge-packet + judge-score (treatment-blind)",
      "Compare deltas; promote Fable default only after held-out claim (ADR 0005)"
    ]
  }' > "${COMPARE_ROOT}/compare-matrix.json"

cat <<EOF
COMPARE_ROOT=${COMPARE_ROOT}
MATRIX=${COMPARE_ROOT}/compare-matrix.json
CLAIM_ALLOWED=${claim}
NOTE=experimental comparison — not a reliability claim unless prereg.reliability_claim_allowed=true
EOF
