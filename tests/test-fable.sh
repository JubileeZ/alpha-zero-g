#!/usr/bin/env bash
# tests/test-fable.sh — opt-in azg fable sync (Phase 10)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

section "1. Bundled optional Fable stubs"

assert_dir_exists "templates/optional/fable" "${ROOT}/templates/optional/fable"
assert_file_exists "fable-loop SKILL" "${ROOT}/templates/optional/fable/skills/fable-loop/SKILL.md"
assert_file_exists "FABLE.lock.json" "${ROOT}/templates/optional/fable/FABLE.lock.json"
assert_file_executable "lib/fable.sh" "${ROOT}/lib/fable.sh"

section "2. Refuses without --experimental when claim false"

WORK="$(azg_mktemp_d "tmp_azg_fable-XXXXXX")"
mkdir -p "${WORK}/proj"
# Ensure claim is false for this test (read real prereg — should be false on main)
if command -v jq >/dev/null 2>&1; then
  claim=$(jq -r '.reliability_claim_allowed // false' "${ROOT}/evals/pilot/prereg.json")
  if [ "${claim}" != "false" ]; then
    skip "prereg claim already true — skip refuse test"
  else
    assert_exit "fable sync refuses without --experimental" 1 \
      "${AZG}" fable sync "${WORK}/proj"
    if [ ! -d "${WORK}/proj/.agents/skills/fable" ]; then
      pass "no fable dir after refused sync"
    else
      fail "fable dir should not exist after refuse"
    fi
  fi
else
  skip "jq missing"
fi

section "3. --experimental installs into project skills"

assert_exit "fable sync --experimental exits 0" 0 \
  "${AZG}" fable sync "${WORK}/proj" --experimental
assert_file_exists "fable-loop installed" "${WORK}/proj/.agents/skills/fable/fable-loop/SKILL.md"
assert_file_exists "fable marker" "${WORK}/proj/.agents/skills/fable/.fable-installed"
assert_file_exists "lock copied" "${WORK}/proj/.agents/skills/fable/FABLE.lock.json"
assert_exit "fable status exits 0 when installed" 0 \
  "${AZG}" fable status "${WORK}/proj"

section "4. Core profile untouched"

if [ ! -d "${ROOT}/templates/global/skills/vendor/fable" ]; then
  pass "no fable under global vendor tree"
else
  fail "fable must not land in global vendor by default"
fi

test_summary
