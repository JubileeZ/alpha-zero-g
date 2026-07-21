#!/usr/bin/env bash
# evals/run-exploratory-smoke.sh — one documented exploratory pair (harness smoke, not agent claim)
#
# Prepares core+baseline workdirs for bug-fix, records scorecards as failed assertions
# (broken seed), appends exploratory-log.jsonl. Explicitly not a reliability claim.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

core_out=$(bash "${ROOT}/evals/run-pair.sh" bug-fix core)
base_out=$(bash "${ROOT}/evals/run-pair.sh" bug-fix baseline)
CORE=$(echo "${core_out}" | sed -n 's/^WORKDIR=//p' | head -n1)
BASE=$(echo "${base_out}" | sed -n 's/^WORKDIR=//p' | head -n1)

# Broken seed → task_success 0 (exploratory documents the pipeline, not a win)
bash "${ROOT}/evals/record-scorecard.sh" "${CORE}/scorecard.json" \
  --task-success 0 --delivery-cost 0 --wall-time-sec 0 --interventions 0 \
  --notes "exploratory smoke: unbroken agent run not performed" --operator smoke
bash "${ROOT}/evals/record-scorecard.sh" "${BASE}/scorecard.json" \
  --task-success 0 --delivery-cost 0 --wall-time-sec 0 --interventions 0 \
  --notes "exploratory smoke: unbroken agent run not performed" --operator smoke

bash "${ROOT}/evals/record-pilot-pair.sh" exploratory \
  --fixture bug-fix \
  --core-scorecard "${CORE}/scorecard.json" \
  --baseline-scorecard "${BASE}/scorecard.json" \
  --notes "Exploratory harness smoke $(date -u +%Y-%m-%d): run-pair+scorecard+log only; reliability_claim=false; no live agent"

echo "CORE=${CORE}"
echo "BASELINE=${BASE}"
echo "LOG=${ROOT}/evals/pilot/exploratory-log.jsonl"
echo "PREREG=${ROOT}/evals/pilot/PREREG.md"
