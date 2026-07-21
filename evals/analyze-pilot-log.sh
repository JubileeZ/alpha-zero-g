#!/usr/bin/env bash
# evals/analyze-pilot-log.sh — score a phase log against prereg thresholds
#
# Usage: bash evals/analyze-pilot-log.sh <exploratory|confirmation|held-out>
# Prints JSON summary to stdout. Exit 0 always if log parses; gate pass is in JSON.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PILOT_DIR="${AZG_PILOT_DIR:-${ROOT}/evals/pilot}"
PHASE="${1:-}"

if [ -z "${PHASE}" ]; then
  echo "usage: analyze-pilot-log.sh <exploratory|confirmation|held-out>" >&2
  exit 2
fi

case "${PHASE}" in
  exploratory|confirmation|held-out) ;;
  *) echo "bad phase" >&2; exit 2 ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

PREREG="${PILOT_DIR}/prereg.json"
LOG="${PILOT_DIR}/${PHASE}-log.jsonl"

if [ ! -f "${PREREG}" ]; then
  PREREG="${ROOT}/evals/pilot/prereg.json"
fi

if [ ! -f "${LOG}" ]; then
  jq -n --arg phase "${PHASE}" '{phase:$phase,error:"missing_log",primary_pass:false,ready:false}'
  exit 0
fi

# Drop empty lines
tmp=$(mktemp)
grep -v '^[[:space:]]*$' "${LOG}" > "${tmp}" || true
n=$(wc -l < "${tmp}" | tr -d ' ')

required=0
case "${PHASE}" in
  exploratory) required=1 ;;
  confirmation) required=$(jq -r '.confirmation.sample_size.total_paired_runs' "${PREREG}") ;;
  held-out) required=$(jq -r '.held_out.sample_size.total_paired_runs' "${PREREG}") ;;
esac

primary_thresh=$(jq -r '.confirmation.primary_endpoint.success_threshold' "${PREREG}")
cost_max=$(jq -r '.confirmation.secondary_endpoints[0].success_threshold_max' "${PREREG}")
interv_max=$(jq -r '.confirmation.secondary_endpoints[1].success_threshold_max' "${PREREG}")

if [ "${n}" -eq 0 ]; then
  jq -n \
    --arg phase "${PHASE}" \
    --argjson required "${required}" \
    '{phase:$phase,n:0,required:$required,ready:false,primary_pass:false,cost_pass:false,interventions_pass:false,error:"empty_log"}'
  rm -f "${tmp}"
  exit 0
fi

# Aggregate with jq
summary=$(jq -s --argjson primary_thresh "${primary_thresh}" --argjson cost_max "${cost_max}" --argjson interv_max "${interv_max}" --argjson required "${required}" --arg phase "${PHASE}" '
  def median:
    sort | if length == 0 then null
           elif length % 2 == 1 then .[length/2|floor]
           else (.[length/2-1] + .[length/2]) / 2 end;
  def num(x): if x == null then 0 else (x|tonumber) end;
  (map(select(.core_success == true)) | length) as $core_ok
  | (map(select(.baseline_success == true)) | length) as $base_ok
  | (length) as $n
  | (if $n == 0 then 0 else ($core_ok / $n) end) as $core_rate
  | (if $n == 0 then 0 else ($base_ok / $n) end) as $base_rate
  | ($core_rate - $base_rate) as $delta
  | (map(.core.delivery_cost | num(.)) | median) as $med_core_cost
  | (map(.baseline.delivery_cost | num(.)) | median) as $med_base_cost
  | (if $med_base_cost == null or $med_base_cost == 0 then null
     else ($med_core_cost / $med_base_cost) end) as $cost_ratio
  | (map(.core.interventions | num(.)) | median) as $med_core_iv
  | (map(.baseline.interventions | num(.)) | median) as $med_base_iv
  | (($med_core_iv // 0) - ($med_base_iv // 0)) as $iv_delta
  | ($delta >= $primary_thresh) as $primary_pass
  | (if $cost_ratio == null then true else ($cost_ratio <= $cost_max) end) as $cost_pass
  | ($iv_delta <= $interv_max) as $interventions_pass
  | ($n >= $required) as $enough
  | {
      phase: $phase,
      n: $n,
      required: $required,
      enough: $enough,
      core_success_rate: $core_rate,
      baseline_success_rate: $base_rate,
      primary_delta: $delta,
      primary_threshold: $primary_thresh,
      primary_pass: $primary_pass,
      median_delivery_cost_ratio: $cost_ratio,
      cost_threshold_max: $cost_max,
      cost_pass: $cost_pass,
      interventions_delta: $iv_delta,
      interventions_threshold_max: $interv_max,
      interventions_pass: $interventions_pass,
      ready: ($enough and $primary_pass and $cost_pass and $interventions_pass),
      reliability_claim: false
    }
' "${tmp}")

rm -f "${tmp}"
printf '%s\n' "${summary}"
