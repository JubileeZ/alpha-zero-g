#!/usr/bin/env bash
# tests/test-phase9.sh — TDD suite for Phase 9: vendor skill pruning
#
# Run from repo root:  bash tests/test-phase9.sh
#
# What is tested:
#   1.  _prune_vendor_skills is defined in apply-overlay.sh
#   2.  No ((VAR++)) in apply-overlay.sh _prune_vendor_skills
#   3.  Vendor-managed skill (has ANTIGRAVITY-NOTE.md) missing from vendor → pruned
#   4.  Custom skill (no ANTIGRAVITY-NOTE.md) missing from vendor → NOT pruned
#   5.  Vendor-managed skill still in vendor → NOT pruned
#   6.  Prune counter increments correctly
#   7.  azg setup --force prunes deleted-upstream vendor skills
#   8.  azg setup prunes deleted-upstream vendor skills even on first install
#   9.  Custom skills survive azg setup with vendor prune active
#  10.  azg setup summary message mentions removed skills when pruned
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

# ---------------------------------------------------------------------------
# Temp environment
# ---------------------------------------------------------------------------
TEMP_DIR="$(mktemp -d "${PWD}/tmp_azg_phase9-test-XXXXXX")"
trap 'rm -rf "${TEMP_DIR}"' EXIT

# ---------------------------------------------------------------------------
# Helper: run _prune_vendor_skills in isolation
# ---------------------------------------------------------------------------
run_prune() {
  local skills_dir="$1" vendor_dir="$2"
  bash -c "
    source '${REPO_ROOT}/lib/common.sh'
    source '${REPO_ROOT}/lib/apply-overlay.sh'
    count=0
    _prune_vendor_skills '${skills_dir}' '${vendor_dir}' count
    echo \"\${count}\"
  "
}

# ---------------------------------------------------------------------------
# Build test fixtures
# ---------------------------------------------------------------------------
SKILLS_DIR="${TEMP_DIR}/skills"
VENDOR_DIR="${TEMP_DIR}/vendor/mattpocock-skills"

mkdir -p "${SKILLS_DIR}"
mkdir -p "${VENDOR_DIR}/engineering"
mkdir -p "${VENDOR_DIR}/productivity"

# Vendor tree has: tdd (engineering), handoff (productivity)
mkdir -p "${VENDOR_DIR}/engineering/tdd"
mkdir -p "${VENDOR_DIR}/productivity/handoff"

# Installed: tdd (still in vendor), diagnose (removed upstream), caveman (custom)
mkdir -p "${SKILLS_DIR}/tdd"
printf 'vendored\n' > "${SKILLS_DIR}/tdd/ANTIGRAVITY-NOTE.md"
printf 'SKILL.md for tdd\n' > "${SKILLS_DIR}/tdd/SKILL.md"

mkdir -p "${SKILLS_DIR}/diagnose"
printf 'vendored\n' > "${SKILLS_DIR}/diagnose/ANTIGRAVITY-NOTE.md"
printf 'SKILL.md for diagnose\n' > "${SKILLS_DIR}/diagnose/SKILL.md"

mkdir -p "${SKILLS_DIR}/caveman"
printf 'SKILL.md for caveman (custom)\n' > "${SKILLS_DIR}/caveman/SKILL.md"
# No ANTIGRAVITY-NOTE.md → custom, must never be pruned

# ---------------------------------------------------------------------------
section "1. _prune_vendor_skills defined in apply-overlay.sh"

if bash -c "
  source '${REPO_ROOT}/lib/common.sh' 2>/dev/null
  source '${REPO_ROOT}/lib/apply-overlay.sh' 2>/dev/null
  declare -f _prune_vendor_skills
" > /dev/null 2>&1; then
  pass "_prune_vendor_skills() is defined and apply-overlay.sh sources cleanly"
else
  fail "_prune_vendor_skills() must be defined in apply-overlay.sh"
fi

section "2. No ((VAR++)) in _prune_vendor_skills"

if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/apply-overlay.sh" | grep -qE '\(\([A-Za-z_]+\+\+\)\)'; then
  fail "apply-overlay.sh must NOT use ((VAR++)) — breaks under set -e"
else
  pass "apply-overlay.sh does not use ((VAR++))"
fi

section "3. Vendor-managed skill absent from vendor → pruned"

prune_out="$(run_prune "${SKILLS_DIR}" "${VENDOR_DIR}")"

assert_dir_not_exists \
  "diagnose/ removed (has ANTIGRAVITY-NOTE.md, not in vendor tree)" \
  "${SKILLS_DIR}/diagnose"

section "4. Custom skill absent from vendor → NOT pruned"

assert_dir_exists \
  "caveman/ preserved (no ANTIGRAVITY-NOTE.md = custom skill)" \
  "${SKILLS_DIR}/caveman"

section "5. Vendor-managed skill still in vendor → NOT pruned"

assert_dir_exists \
  "tdd/ preserved (has ANTIGRAVITY-NOTE.md AND exists in vendor tree)" \
  "${SKILLS_DIR}/tdd"

section "6. Prune counter is correct"

# Reset fixtures for a clean count test
SKILLS_C="${TEMP_DIR}/skills_count"
VENDOR_C="${TEMP_DIR}/vendor_count/mattpocock-skills"
mkdir -p "${SKILLS_C}" "${VENDOR_C}/engineering"

# 3 vendor-managed installed, 2 absent from vendor, 1 still present
for sk in alpha beta gamma; do
  mkdir -p "${SKILLS_C}/${sk}"
  printf 'vendored\n' > "${SKILLS_C}/${sk}/ANTIGRAVITY-NOTE.md"
done
mkdir -p "${VENDOR_C}/engineering/gamma"  # gamma survives

count_out="$(run_prune "${SKILLS_C}" "${VENDOR_C}")"
if [ "${count_out}" = "2" ]; then
  pass "prune counter = 2 (alpha + beta removed, gamma kept)"
else
  fail "prune counter wrong" "expected 2, got '${count_out}'"
fi

section "7. azg setup --force prunes deleted-upstream vendor skills"

TEMP_REPO="$(mktemp -d "${PWD}/tmp_azg_phase9-repo-XXXXXX")"
TEMP_HOME="$(mktemp -d "${PWD}/tmp_azg_phase9-home-XXXXXX")"
trap 'rm -rf "${TEMP_DIR}" "${TEMP_REPO}" "${TEMP_HOME}"' EXIT

# Copy repo
tar -cf - --exclude=.git --exclude='tmp_azg*' -C "${REPO_ROOT}" . | tar -xf - -C "${TEMP_REPO}"

# Populate vendor with ONLY tdd (not diagnose — it's "deleted upstream")
TEMP_VENDOR="${TEMP_REPO}/templates/global/skills/vendor/mattpocock-skills"
mkdir -p "${TEMP_VENDOR}/engineering/tdd"
printf -- "---\nname: tdd\ntools: [read_file]\n---\n# tdd\n" \
  > "${TEMP_VENDOR}/engineering/tdd/SKILL.md"

TEMP_OVERLAY="${TEMP_REPO}/templates/global/skills/overlay/mattpocock-skills"
TEMP_SKILLS="${TEMP_HOME}/.gemini/config/skills"
mkdir -p "${TEMP_SKILLS}"

# Pre-install diagnose with sentinel (simulates old install)
mkdir -p "${TEMP_SKILLS}/diagnose"
printf 'vendored\n' > "${TEMP_SKILLS}/diagnose/ANTIGRAVITY-NOTE.md"
printf 'SKILL.md\n' > "${TEMP_SKILLS}/diagnose/SKILL.md"

# Run azg setup --force
SETUP_EXIT=0
HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_REPO}/azg" setup --force \
  > /dev/null 2>&1 || SETUP_EXIT=$?

if [ "${SETUP_EXIT}" -eq 0 ]; then
  pass "azg setup --force exits 0"
else
  fail "azg setup --force exited ${SETUP_EXIT}"
fi

assert_dir_not_exists \
  "diagnose/ pruned by azg setup (not in vendor tree)" \
  "${TEMP_SKILLS}/diagnose"

assert_dir_exists \
  "tdd/ installed by azg setup" \
  "${TEMP_SKILLS}/tdd"

section "8. Custom skills survive azg setup with prune active"

# Pre-install caveman WITHOUT sentinel (custom skill)
mkdir -p "${TEMP_SKILLS}/caveman"
printf 'SKILL.md for caveman\n' > "${TEMP_SKILLS}/caveman/SKILL.md"

HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_REPO}/azg" setup --force \
  > /dev/null 2>&1 || true

assert_dir_exists \
  "caveman/ (custom, no ANTIGRAVITY-NOTE.md) survives azg setup" \
  "${TEMP_SKILLS}/caveman"

section "9. azg setup summary mentions removed skills"

# Pre-install another stale vendored skill
mkdir -p "${TEMP_SKILLS}/zoom-out"
printf 'vendored\n' > "${TEMP_SKILLS}/zoom-out/ANTIGRAVITY-NOTE.md"

SETUP_OUT="$(HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_REPO}/azg" setup --force 2>&1)" || true

if echo "${SETUP_OUT}" | grep -qi "removed"; then
  pass "setup output mentions 'removed' when skills are pruned"
else
  fail "setup output should mention 'removed' when pruning" \
    "got: $(echo "${SETUP_OUT}" | tail -5)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
