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

  # core+fable treatment (experimental)
  fout=$(bash "${ROOT}/evals/run-pair.sh" bug-fix core+fable)
  fdir=$(echo "${fout}" | sed -n 's/^WORKDIR=//p' | head -n1)
  if [ -n "${fdir}" ] && [ -f "${fdir}/.agents/skills/fable/.fable-installed" ]; then
    pass "run-pair core+fable installs fable marker"
    ft=$(jq -r '.treatment' "${fdir}/scorecard.json")
    if [ "${ft}" = "core+fable" ]; then
      pass "scorecard treatment=core+fable"
    else
      fail "core+fable scorecard treatment wrong" "got ${ft}"
    fi
    rm -rf "${fdir}"
  else
    fail "run-pair core+fable incomplete" "out: ${fout}"
  fi

  # compare-core-fable prepares both arms for one fixture
  assert_file_executable "compare-core-fable.sh" "${ROOT}/evals/compare-core-fable.sh"
  cout=$(bash "${ROOT}/evals/compare-core-fable.sh" bug-fix)
  croot=$(echo "${cout}" | sed -n 's/^COMPARE_ROOT=//p' | head -n1)
  if [ -n "${croot}" ] && [ -f "${croot}/compare-matrix.json" ]; then
    pass "compare-core-fable writes matrix"
    if jq -e '.pairs[0].arms["core+fable"].workdir' "${croot}/compare-matrix.json" >/dev/null \
      && jq -e '.experimental == true' "${croot}/compare-matrix.json" >/dev/null; then
      pass "compare matrix has core+fable arm + experimental flag"
    else
      fail "compare matrix missing core+fable arm"
    fi
    # Cleanup prepared workdirs referenced by matrix
    while IFS= read -r wd; do
      [ -n "${wd}" ] && [ -d "${wd}" ] && rm -rf "${wd}"
    done < <(jq -r '.pairs[].arms[].workdir' "${croot}/compare-matrix.json")
    rm -rf "${croot}"
  else
    fail "compare-core-fable incomplete" "out: ${cout}"
  fi

  assert_file_executable "run-compare-smoke.sh" "${ROOT}/evals/run-compare-smoke.sh"
  SMOKE_JSON="${ROOT}/evals/pilot/compare-core-fable-smoke.json"
  if [ -f "${SMOKE_JSON}" ]; then
    if jq -e '.not_a_claim == true and .promote_default == false and (.pairs | length) == 6' "${SMOKE_JSON}" >/dev/null; then
      pass "compare smoke artifact is non-claim with 6 scored arms"
    else
      fail "compare smoke artifact missing required non-claim shape"
    fi
  else
    skip "compare smoke artifact not present (run evals/run-compare-smoke.sh)"
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

section "5. Long-Horizon scaffold + clean clone"

assert_file_exists "long-horizon README" "${ROOT}/evals/long-horizon/README.md"
assert_file_exists "long-horizon checklist" "${ROOT}/evals/long-horizon/checklist.md"
assert_file_executable "run-long-horizon.sh" "${ROOT}/evals/run-long-horizon.sh"

if ! command -v jq >/dev/null 2>&1; then
  skip "long-horizon tests need jq"
else
  lh_out=$(bash "${ROOT}/evals/run-long-horizon.sh" bug-fix baseline)
  s1=$(echo "${lh_out}" | sed -n 's/^SESSION1=//p' | head -n1)
  s2=$(echo "${lh_out}" | sed -n 's/^SESSION2=//p' | head -n1)
  if [ -n "${s1}" ] && [ -f "${s1}/TASK.md" ] && [ -f "${s1}/long-horizon-log.json" ]; then
    pass "long-horizon init creates SESSION1 + log"
  else
    fail "long-horizon init incomplete" "${lh_out}"
  fi
  if [ -f "${s1}/LONG-HORIZON-CHECKLIST.md" ]; then
    pass "checklist copied to SESSION1"
  else
    fail "missing checklist in SESSION1"
  fi
  # Checkpoint commit then sync-clone
  (
    cd "${s1}"
    echo "session1-note" >> TASK.md
    git add -A
    git -c user.email=lh@azg -c user.name=lh commit -m "checkpoint: session1" -q
  )
  sync_out=$(bash "${ROOT}/evals/run-long-horizon.sh" bug-fix baseline --sync-clone "${s1}")
  s2b=$(echo "${sync_out}" | sed -n 's/^SESSION2=//p' | head -n1)
  head=$(echo "${sync_out}" | sed -n 's/^HEAD=//p' | head -n1)
  if [ -n "${s2b}" ] && [ -d "${s2b}/.git" ] && [ -f "${s2b}/TASK.md" ]; then
    pass "sync-clone created SESSION2 git worktree"
  else
    fail "sync-clone failed" "${sync_out}"
  fi
  h1=$(git -C "${s1}" rev-parse HEAD)
  h2=$(git -C "${s2b}" rev-parse HEAD)
  if [ "${h1}" = "${h2}" ] && [ "${h1}" = "${head}" ]; then
    pass "SESSION1 and SESSION2 share Checkpoint HEAD"
  else
    fail "HEAD mismatch" "h1=${h1} h2=${h2} head=${head}"
  fi
  # Distinct paths (clean device simulation)
  if [ "${s1}" != "${s2b}" ]; then
    pass "SESSION2 path differs from SESSION1"
  else
    fail "SESSION2 must not be SESSION1"
  fi
  if [ "$(jq -r '.phases.clean_clone.status' "${s1}/long-horizon-log.json")" = "ok" ] \
     && [ "$(jq -r '.phases.checkpoint.status' "${s1}/long-horizon-log.json")" = "ok" ]; then
    pass "log marks checkpoint + clean_clone ok"
  else
    fail "log phases not updated" "$(cat "${s1}/long-horizon-log.json")"
  fi
  # SESSION2 must not be the same inode workdir — editing s1 after clone shouldn't be required
  if grep -q 'session1-note' "${s2b}/TASK.md"; then
    pass "clone contains Checkpoint content"
  else
    fail "clone missing session1 edits"
  fi
  rm -rf "${s1}" "${s2b}" "$(jq -r '.base // empty' "${s1}/long-horizon-log.json" 2>/dev/null)" 2>/dev/null || true
  # s1 may already be deleted — best-effort cleanup via sync paths
  rm -rf "${s2}" 2>/dev/null || true
fi

section "6. Pilot prereg + exploratory log"

assert_file_exists "prereg.json" "${ROOT}/evals/pilot/prereg.json"
assert_file_exists "PREREG.md" "${ROOT}/evals/pilot/PREREG.md"
assert_file_executable "record-pilot-pair.sh" "${ROOT}/evals/record-pilot-pair.sh"
assert_file_executable "run-exploratory-smoke.sh" "${ROOT}/evals/run-exploratory-smoke.sh"

if ! command -v jq >/dev/null 2>&1; then
  skip "pilot prereg tests need jq"
else
  if [ "$(jq -r '.confirmation.sample_size.total_paired_runs' "${ROOT}/evals/pilot/prereg.json")" = "9" ]; then
    pass "prereg confirmation N=9 pairs"
  else
    fail "prereg sample_size wrong"
  fi
  if [ "$(jq -r '.confirmation.primary_endpoint.success_threshold' "${ROOT}/evals/pilot/prereg.json")" = "0" ] \
     || [ "$(jq -r '.confirmation.primary_endpoint.success_threshold' "${ROOT}/evals/pilot/prereg.json")" = "0.0" ]; then
    pass "prereg primary threshold ≥0 delta"
  else
    fail "primary threshold missing"
  fi
  if [ "$(jq -r '.reliability_claim_allowed' "${ROOT}/evals/pilot/prereg.json")" = "false" ]; then
    pass "prereg forbids reliability claim until held-out"
  else
    fail "reliability_claim_allowed should be false"
  fi

  # Use record-pilot-pair on temp scorecards (avoid full core apply in CI loop)
  td="$(azg_mktemp_d "tmp_azg_pilotrec-XXXXXX")"
  jq -n '{task_success:0,delivery_cost:0,wall_time_sec:0,interventions:0,treatment:"core",model:"",ide:""}' > "${td}/core.json"
  jq -n '{task_success:0,delivery_cost:0,wall_time_sec:0,interventions:0,treatment:"baseline",model:"",ide:""}' > "${td}/base.json"
  before=$(wc -l < "${ROOT}/evals/pilot/exploratory-log.jsonl" | tr -d ' ')
  bash "${ROOT}/evals/record-pilot-pair.sh" exploratory \
    --fixture bug-fix \
    --core-scorecard "${td}/core.json" \
    --baseline-scorecard "${td}/base.json" \
    --notes "test-evals exploratory append"
  after=$(wc -l < "${ROOT}/evals/pilot/exploratory-log.jsonl" | tr -d ' ')
  if [ "${after}" -gt "${before}" ]; then
    pass "exploratory smoke appends log line"
  else
    fail "exploratory log not appended"
  fi
  last=$(tail -n1 "${ROOT}/evals/pilot/exploratory-log.jsonl")
  if echo "${last}" | jq -e '.phase=="exploratory" and .reliability_claim==false and .fixture_id=="bug-fix"' >/dev/null; then
    pass "exploratory log line is non-claim bug-fix pair"
  else
    fail "bad exploratory log line" "${last}"
  fi
  # Still ensure run-exploratory-smoke.sh is executable / --help path exists (already asserted)
fi

section "7. Held-out gate analysis"

assert_file_exists "HELD-OUT.md" "${ROOT}/evals/pilot/HELD-OUT.md"
assert_file_executable "analyze-pilot-log.sh" "${ROOT}/evals/analyze-pilot-log.sh"
assert_file_executable "analyze-pilot-gate.sh" "${ROOT}/evals/analyze-pilot-gate.sh"

if ! command -v jq >/dev/null 2>&1; then
  skip "held-out gate tests need jq"
else
  pd="$(azg_mktemp_d "tmp_azg_gate-XXXXXX")"
  cp "${ROOT}/evals/pilot/prereg.json" "${pd}/prereg.json"
  : > "${pd}/confirmation-log.jsonl"
  : > "${pd}/held-out-log.jsonl"

  pair_line() {
    local phase="$1" cs="$2" bs="$3"
    jq -nc --arg phase "${phase}" --argjson cs "${cs}" --argjson bs "${bs}" \
      '{phase:$phase,reliability_claim:false,fixture_id:"bug-fix",core_success:$cs,baseline_success:$bs,
        core:{task_success:1,delivery_cost:1,wall_time_sec:10,interventions:0,treatment:"core",model:"",ide:""},
        baseline:{task_success:0,delivery_cost:2,wall_time_sec:20,interventions:1,treatment:"baseline",model:"",ide:""}}'
  }

  i=0
  while [ "${i}" -lt 9 ]; do
    pair_line confirmation true false >> "${pd}/confirmation-log.jsonl"
    i=$((i + 1))
  done
  i=0
  while [ "${i}" -lt 6 ]; do
    pair_line held-out true false >> "${pd}/held-out-log.jsonl"
    i=$((i + 1))
  done

  export AZG_PILOT_DIR="${pd}"
  conf=$(bash "${ROOT}/evals/analyze-pilot-log.sh" confirmation)
  if [ "$(echo "${conf}" | jq -r '.ready')" = "true" ] && [ "$(echo "${conf}" | jq -r '.n')" = "9" ]; then
    pass "confirmation log analyzes ready with N=9"
  else
    fail "confirmation analyze not ready" "${conf}"
  fi
  held=$(bash "${ROOT}/evals/analyze-pilot-log.sh" held-out)
  if [ "$(echo "${held}" | jq -r '.ready')" = "true" ] && [ "$(echo "${held}" | jq -r '.n')" = "6" ]; then
    pass "held-out log analyzes ready with N=6"
  else
    fail "held-out analyze not ready" "${held}"
  fi
  bash "${ROOT}/evals/analyze-pilot-gate.sh" >/dev/null
  if [ "$(jq -r '.both_green' "${pd}/gate-status.json")" = "true" ]; then
    pass "gate both_green when conf+held ready"
  else
    fail "gate should be both_green" "$(cat "${pd}/gate-status.json")"
  fi
  if [ "$(jq -r '.reliability_claim_allowed' "${pd}/prereg.json")" = "false" ]; then
    pass "prereg claim still false before --apply-claim"
  else
    fail "should not auto-apply claim"
  fi
  assert_exit "apply-claim succeeds when green" 0 bash "${ROOT}/evals/analyze-pilot-gate.sh" --apply-claim
  if [ "$(jq -r '.reliability_claim_allowed' "${pd}/prereg.json")" = "true" ]; then
    pass "apply-claim sets reliability_claim_allowed"
  else
    fail "apply-claim did not flip prereg"
  fi

  # Insufficient held-out
  : > "${pd}/held-out-log.jsonl"
  pair_line held-out true false >> "${pd}/held-out-log.jsonl"
  # reset claim
  jq '.reliability_claim_allowed=false' "${pd}/prereg.json" > "${pd}/prereg.json.tmp" && mv "${pd}/prereg.json.tmp" "${pd}/prereg.json"
  bash "${ROOT}/evals/analyze-pilot-gate.sh" >/dev/null
  if [ "$(jq -r '.both_green' "${pd}/gate-status.json")" = "false" ]; then
    pass "gate not green when held-out N insufficient"
  else
    fail "gate should be red with N=1 held-out"
  fi
  assert_exit "apply-claim refuses when not green" 1 bash "${ROOT}/evals/analyze-pilot-gate.sh" --apply-claim
  unset AZG_PILOT_DIR
fi

test_summary
