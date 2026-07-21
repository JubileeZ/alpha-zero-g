#!/usr/bin/env bash
# evals/run-compare-smoke.sh — fill core vs core+fable matrix using reference solutions
#
# Operator stand-in smoke (not a reliability claim; does not exercise Fable skills).
# Proves the compare pipeline end-to-end and that both arms stay assertion-green
# after the same correct fix (portability / overlay sanity).
#
# Usage: bash evals/run-compare-smoke.sh
# Writes: evals/pilot/compare-core-fable-smoke.json

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT}/evals/pilot"
OUT="${OUT_DIR}/compare-core-fable-smoke.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

# Prepare all fixtures
prep=$(bash "${ROOT}/evals/compare-core-fable.sh")
COMPARE_ROOT=$(echo "${prep}" | sed -n 's/^COMPARE_ROOT=//p' | head -n1)
COMPARE_ROOT="${COMPARE_ROOT%$'\r'}"
MATRIX="${COMPARE_ROOT}/compare-matrix.json"
if [ ! -f "${MATRIX}" ]; then
  echo "compare prepare failed: ${prep}" >&2
  exit 1
fi

tool_for() {
  case "$1" in
    bug-fix) echo "tools/clamp.sh" ;;
    scoped-change) echo "tools/greet.sh" ;;
    regression-feature) echo "tools/price.sh" ;;
    *) return 1 ;;
  esac
}

pairs='[]'
n=$(jq '.pairs | length' "${MATRIX}")
i=0
while [ "${i}" -lt "${n}" ]; do
  id=$(jq -r ".pairs[${i}].fixture_id" "${MATRIX}")
  tool=$(tool_for "${id}")
  ref="${ROOT}/evals/fixtures/${id}/reference/${tool}"

  for arm in core "core+fable"; do
    wd=$(jq -r --arg a "${arm}" ".pairs[${i}].arms[\$a].workdir" "${MATRIX}")
    sc="${wd}/scorecard.json"
    start=$(date +%s)

    cp "${ref}" "${wd}/${tool}"
    chmod +x "${wd}/${tool}"

    if ! bash "${wd}/assertions/check.sh" >/dev/null 2>&1; then
      echo "FAIL assertions: ${id} ${arm} @ ${wd}" >&2
      exit 1
    fi

    end=$(date +%s)
    wall=$((end - start))
    # ponytail: delivery_cost = wall seconds; upgrade = token/tool accounting when live agents run
    cost="${wall}"
    [ "${cost}" -lt 1 ] && cost=1

    bash "${ROOT}/evals/record-scorecard.sh" "${sc}" \
      --task-success 1 \
      --delivery-cost "${cost}" \
      --wall-time-sec "${wall}" \
      --interventions 0 \
      --model "operator-reference" \
      --ide "none" \
      --operator "azg-compare-smoke" \
      --notes "Reference fix applied; experimental smoke — not Fable-skill utilization; not a reliability claim"

    ts=$(jq -r '.task_success' "${sc}")
    dc=$(jq -r '.delivery_cost' "${sc}")
    pairs=$(jq -n -c \
      --argjson pairs "${pairs}" \
      --arg id "${id}" \
      --arg arm "${arm}" \
      --argjson ts "${ts}" \
      --argjson dc "${dc}" \
      --argjson wt "${wall}" \
      '$pairs + [{fixture_id:$id,treatment:$arm,task_success:$ts,delivery_cost:$dc,wall_time_sec:$wt,assertions_pass:true}]')
  done

  i=$((i + 1))
done

# Summary deltas per fixture (core+fable − core on delivery_cost; task_success both 1)
summary=$(jq -n -c --argjson pairs "${pairs}" '
  [$pairs | group_by(.fixture_id)[] | {
    fixture_id: .[0].fixture_id,
    core: (.[] | select(.treatment=="core")),
    fable: (.[] | select(.treatment=="core+fable")),
  } | {
    fixture_id,
    task_success_both_ok: ((.core.task_success == 1) and (.fable.task_success == 1)),
    delivery_cost_delta_fable_minus_core: (.fable.delivery_cost - .core.delivery_cost),
    core_delivery_cost: .core.delivery_cost,
    fable_delivery_cost: .fable.delivery_cost
  }]
')

mkdir -p "${OUT_DIR}"
jq -n \
  --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  --arg claim "$(jq -r '.reliability_claim_allowed // false' "${ROOT}/evals/pilot/prereg.json")" \
  --argjson pairs "${pairs}" \
  --argjson summary "${summary}" \
  '{
    kind: "core_vs_core_fable_smoke",
    experimental: true,
    reliability_claim_allowed: ($claim == "true"),
    method: "operator applied fixture reference solutions to both arms",
    not_a_claim: true,
    note: "Does not measure Fable skill benefit — only pipeline + overlay portability. Live agent+Fable runs required before promotion.",
    started_at: $started,
    pairs: $pairs,
    per_fixture: $summary,
    promote_default: false
  }' > "${OUT}"

echo "WROTE=${OUT}"
jq -r '.per_fixture[] | "\(.fixture_id): both_ok=\(.task_success_both_ok) cost_delta(fable-core)=\(.delivery_cost_delta_fable_minus_core)"' "${OUT}"
