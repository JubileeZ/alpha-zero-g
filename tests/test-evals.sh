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

section "4. Blind Judge packet + stub score"

assert_file_exists "judge RUBRIC" "${ROOT}/evals/judge/RUBRIC.md"
assert_file_exists "judge PROMPT" "${ROOT}/evals/judge/PROMPT.md"
assert_file_exists "judge CALIBRATION" "${ROOT}/evals/judge/CALIBRATION.md"
assert_file_exists "judge config" "${ROOT}/evals/judge/config.json"
assert_file_executable "prepare-judge-packet.sh" "${ROOT}/evals/prepare-judge-packet.sh"
assert_file_executable "judge-score.sh" "${ROOT}/evals/judge-score.sh"

if ! command -v jq >/dev/null 2>&1; then
  skip "blind judge tests need jq"
else
  out=$(bash "${ROOT}/evals/run-pair.sh" bug-fix baseline)
  workdir=$(echo "${out}" | sed -n 's/^WORKDIR=//p' | head -n1)
  # Seed scorecard with treatment — must not leak into packet
  jq '.treatment="core"' "${workdir}/scorecard.json" > "${workdir}/scorecard.json.tmp"
  mv "${workdir}/scorecard.json.tmp" "${workdir}/scorecard.json"
  mkdir -p "${workdir}/.agents"
  echo 'leak' > "${workdir}/.agents/should-not-copy"

  packet_line=$(bash "${ROOT}/evals/prepare-judge-packet.sh" "${workdir}")
  packet="${packet_line#PACKET=}"
  if [ -d "${packet}" ] && [ ! -e "${packet}/scorecard.json" ] && [ ! -d "${packet}/.agents" ]; then
    pass "judge packet omits scorecard and .agents"
  else
    fail "judge packet leaked harness/scorecard"
  fi
  if [ -f "${packet}/TASK.md" ] && [ -d "${packet}/delivery/tools" ]; then
    pass "judge packet has TASK + delivery/tools"
  else
    fail "judge packet incomplete"
  fi

  # Broken delivery → stub judge_pass false
  unset AZG_JUDGE_CMD
  jout=$(bash "${ROOT}/evals/judge-score.sh" "${workdir}")
  if [ -f "${workdir}/judge-result.json" ]; then
    pass "judge-result.json written"
  else
    fail "missing judge-result.json" "${jout}"
  fi
  if [ "$(jq -r '.treatment_blind' "${workdir}/judge-result.json")" = "true" ]; then
    pass "judge-result marks treatment_blind"
  else
    fail "treatment_blind missing"
  fi
  if [ "$(jq -r '.assertions_pass' "${workdir}/judge-result.json")" = "false" ] \
     && [ "$(jq -r '.judge_pass' "${workdir}/judge-result.json")" = "false" ]; then
    pass "stub judge fails on broken workspace"
  else
    fail "stub should fail broken workspace" "$(cat "${workdir}/judge-result.json")"
  fi
  # Result must not contain treatment string from scorecard
  if jq -e '.treatment' "${workdir}/judge-result.json" >/dev/null 2>&1; then
    fail "judge-result must not have treatment field"
  else
    pass "judge-result has no treatment field"
  fi

  # Reference delivery → assertions + stub pass
  cp -R "${ROOT}/evals/fixtures/bug-fix/reference/tools/." "${workdir}/tools/"
  chmod +x "${workdir}/tools"/*.sh
  bash "${ROOT}/evals/judge-score.sh" "${workdir}" >/dev/null
  if [ "$(jq -r '.assertions_pass' "${workdir}/judge-result.json")" = "true" ] \
     && [ "$(jq -r '.judge_pass' "${workdir}/judge-result.json")" = "true" ]; then
    pass "stub judge passes on reference delivery"
  else
    fail "stub should pass reference" "$(cat "${workdir}/judge-result.json")"
  fi

  # External judge cmd wiring
  export AZG_JUDGE_CMD='jq -n "{correctness:5,scope_discipline:5,clarity:5,safety:5,overall:5.0,rationale:\"external\"}"'
  bash "${ROOT}/evals/judge-score.sh" "${workdir}" >/dev/null
  overall_ext=$(jq -r '.scores.overall' "${workdir}/judge-result.json")
  if [ "$(jq -r '.mode' "${workdir}/judge-result.json")" = "external" ] \
     && awk -v o="${overall_ext}" 'BEGIN { exit !(o+0 == 5) }'; then
    pass "AZG_JUDGE_CMD external mode works"
  else
    fail "external judge mode failed" "$(cat "${workdir}/judge-result.json")"
  fi
  unset AZG_JUDGE_CMD
  rm -rf "${workdir}"
fi

test_summary
