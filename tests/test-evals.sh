#!/usr/bin/env bash
# tests/test-evals.sh — Evaluation Suite structural + assertion sanity

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

section "1. Suite manifest"

assert_file_exists "evals/suite.json" "${ROOT}/evals/suite.json"
assert_file_exists "evals/README.md" "${ROOT}/evals/README.md"
assert_file_exists "evals/scorecard.json.tmpl" "${ROOT}/evals/scorecard.json.tmpl"
assert_file_executable "run-pair.sh" "${ROOT}/evals/run-pair.sh"
assert_file_executable "record-scorecard.sh" "${ROOT}/evals/record-scorecard.sh"

if ! command -v jq >/dev/null 2>&1; then
  skip "jq missing — suite field checks skipped"
else
  count=$(jq '.fixtures | length' "${ROOT}/evals/suite.json")
  if [ "${count}" = "3" ]; then
    pass "suite.json lists 3 fixtures"
  else
    fail "suite.json should list 3 fixtures" "got ${count}"
  fi
  for id in bug-fix scoped-change regression-feature; do
    if jq -e --arg id "${id}" '.fixtures[] | select(.id==$id)' "${ROOT}/evals/suite.json" >/dev/null; then
      pass "suite contains ${id}"
    else
      fail "suite missing ${id}"
    fi
  done
  for field in task_success delivery_cost wall_time_sec interventions; do
    if jq -e --arg f "${field}" '.scorecard_fields | index($f)' "${ROOT}/evals/suite.json" >/dev/null; then
      pass "scorecard field ${field}"
    else
      fail "missing scorecard field ${field}"
    fi
  done
fi

section "2. Fixture layout + assertions fail on workspace, pass on reference"

for id in bug-fix scoped-change regression-feature; do
  base="${ROOT}/evals/fixtures/${id}"
  assert_file_exists "${id} TASK.md" "${base}/TASK.md"
  assert_file_exists "${id} check.sh" "${base}/assertions/check.sh"
  assert_dir_exists "${id} workspace" "${base}/workspace"
  assert_dir_exists "${id} reference" "${base}/reference"

  WORK="$(azg_mktemp_d "tmp_azg_eval_${id}-XXXXXX")"
  # Broken workspace should fail
  cp -R "${base}/workspace/." "${WORK}/"
  mkdir -p "${WORK}/assertions"
  cp "${base}/assertions/check.sh" "${WORK}/assertions/check.sh"
  chmod +x "${WORK}/assertions/check.sh"
  find "${WORK}" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
  if bash "${WORK}/assertions/check.sh" >/dev/null 2>&1; then
    fail "${id}: check.sh should fail on broken workspace"
  else
    pass "${id}: check.sh fails on workspace"
  fi

  # Reference should pass
  rm -rf "${WORK:?}/"*
  cp -R "${base}/reference/." "${WORK}/"
  mkdir -p "${WORK}/assertions"
  cp "${base}/assertions/check.sh" "${WORK}/assertions/check.sh"
  chmod +x "${WORK}/assertions/check.sh"
  find "${WORK}" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true
  if bash "${WORK}/assertions/check.sh" >/dev/null 2>&1; then
    pass "${id}: check.sh passes on reference"
  else
    fail "${id}: check.sh should pass on reference"
  fi
done

section "3. run-pair baseline prepares scorecard"

if ! command -v jq >/dev/null 2>&1; then
  skip "run-pair smoke needs jq"
else
  out=$(bash "${ROOT}/evals/run-pair.sh" bug-fix baseline)
  workdir=$(echo "${out}" | sed -n 's/^WORKDIR=//p' | head -n1)
  if [ -n "${workdir}" ] && [ -f "${workdir}/scorecard.json" ] && [ -f "${workdir}/TASK.md" ]; then
    pass "run-pair baseline creates workdir + scorecard"
    treatment=$(jq -r '.treatment' "${workdir}/scorecard.json")
    if [ "${treatment}" = "baseline" ]; then
      pass "scorecard treatment=baseline"
    else
      fail "scorecard treatment wrong" "got ${treatment}"
    fi
    # Broken seed still fails check
    if bash "${workdir}/assertions/check.sh" >/dev/null 2>&1; then
      fail "prepared baseline should still be broken"
    else
      pass "prepared baseline still fails assertions"
    fi
    rm -rf "${workdir}"
  else
    fail "run-pair baseline incomplete" "out: ${out}"
  fi

  # record-scorecard
  stub="$(azg_mktemp_d "tmp_azg_score-XXXXXX")/scorecard.json"
  mkdir -p "$(dirname "${stub}")"
  cp "${ROOT}/evals/scorecard.json.tmpl" "${stub}"
  assert_exit "record-scorecard updates fields" 0 \
    bash "${ROOT}/evals/record-scorecard.sh" "${stub}" \
    --task-success 1 --delivery-cost 2.5 --wall-time-sec 60 --interventions 1
  if [ "$(jq -r '.task_success' "${stub}")" = "1" ] && [ "$(jq -r '.interventions' "${stub}")" = "1" ]; then
    pass "record-scorecard wrote numeric fields"
  else
    fail "record-scorecard field values wrong" "$(cat "${stub}")"
  fi
fi

test_summary
