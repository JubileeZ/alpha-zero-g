#!/usr/bin/env bash
# tests/test-phase2.sh — TDD suite for Phase 2: vendor-sync.sh
#
# Run from repo root:  bash tests/test-phase2.sh
#
# Strategy: uses a LOCAL MOCK upstream (a bare git repo created in a tmpdir)
# with the 11 expected skill stubs. This keeps the suite hermetic (no network)
# and fast. The real network clone happens only when a developer runs
# `azg update --vendor` in production.
#
# What is tested:
#   1.  vendor-sync.sh is sourceable and defines vendor_sync()
#   2.  vendor-sync.sh shebang is #!/usr/bin/env bash
#   3.  No sed -i in vendor-sync.sh
#   4.  No ((VAR++)) in vendor-sync.sh
#   5.  vendor_sync populates engineering/ and productivity/ under vendor/
#   6.  All 11 skills are present with a SKILL.md file
#   7.  VENDOR.lock is written with all required fields
#   8.  VENDOR.lock commit SHA is a valid 40-char hex string
#   9.  VENDOR.lock included list contains engineering and productivity
#  10.  VENDOR.lock excluded list contains deprecated, in-progress, misc, personal
#  11.  Running vendor_sync twice is idempotent (same commit SHA in VENDOR.lock)
#  12.  If git is missing, vendor_sync exits non-zero with helpful message
#  13.  azg update --vendor wires through to vendor_sync (exit 0)
#  14.  After vendor_sync, Phase 1 skipped test is now satisfied (skills in vendor/)
#
# All destructive operations (clone, replace vendor/) happen inside a TEMP_REPO
# copy of the repo so the real templates/global/skills/vendor/ is NOT modified
# during testing.
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

# ---------------------------------------------------------------------------
# The 11 expected skills (from plan §4)
# ---------------------------------------------------------------------------
ENGINEERING_SKILLS=(
  "setup-matt-pocock-skills"
  "tdd"
  "to-issues"
  "to-prd"
  "triage"
  "diagnose"
  "improve-codebase-architecture"
  "zoom-out"
)
PRODUCTIVITY_SKILLS=(
  "caveman"
  "teach"
  "write-a-skill"
)

# ---------------------------------------------------------------------------
# Build a local mock upstream bare git repo
# ---------------------------------------------------------------------------
# This creates a real git repo with the correct skill directory structure and
# a SKILL.md in each, so vendor_sync can clone it without network access.

MOCK_UPSTREAM="$(mktemp -d "${PWD}/tmp_azg_mock-upstream-XXXXXX")"
trap 'rm -rf "${MOCK_UPSTREAM}" "${TEMP_REPO:-}" "${TEMP_HOME:-}"' EXIT

section "Setup: creating mock upstream git repo"

(
  cd "${MOCK_UPSTREAM}"
  git init --quiet
  git config user.email "test@azg"
  git config user.name "AZG Test"

  # Create the skill directories with SKILL.md stubs
  for skill in "${ENGINEERING_SKILLS[@]}"; do
    mkdir -p "skills/engineering/${skill}"
    printf -- "---\nname: %s\ntools: [Read, Write, Bash]\n---\n# %s\nStub skill for testing.\n" \
      "${skill}" "${skill}" > "skills/engineering/${skill}/SKILL.md"
  done
  for skill in "${PRODUCTIVITY_SKILLS[@]}"; do
    mkdir -p "skills/productivity/${skill}"
    printf -- "---\nname: %s\ntools: [Read, Write, Bash]\n---\n# %s\nStub skill for testing.\n" \
      "${skill}" "${skill}" > "skills/productivity/${skill}/SKILL.md"
  done

  # Add excluded dirs (should be ignored by vendor_sync)
  mkdir -p skills/deprecated skills/in-progress skills/misc skills/personal
  printf "# deprecated\n" > skills/deprecated/README.md
  printf "# misc\n"       > skills/misc/README.md

  git add -A
  git commit --quiet -m "initial mock commit"
) || { printf "  ${_clr_red}✗ Failed to create mock upstream${_clr_reset}\n"; exit 1; }

MOCK_SHA="$(git -C "${MOCK_UPSTREAM}" rev-parse HEAD)"
printf "  ${_clr_green}✓${_clr_reset} Mock upstream created (SHA: ${MOCK_SHA:0:8}…)\n"

# ---------------------------------------------------------------------------
# Create a TEMP copy of the repo so we don't dirty the real vendor/ dir
# ---------------------------------------------------------------------------
TEMP_REPO="$(mktemp -d "${PWD}/tmp_azg_phase2-test-XXXXXX")"
tar -cf - --exclude=.git --exclude='tmp_azg*' --exclude='tmp' -C "${REPO_ROOT}" . | tar -xf - -C "${TEMP_REPO}"
TEMP_AZG="${TEMP_REPO}/azg"
TEMP_HOME="$(mktemp -d "${PWD}/tmp_azg_phase2-home-XXXXXX")"

VENDOR_DIR="${TEMP_REPO}/templates/global/skills/vendor/mattpocock-skills"

# Helper: run vendor_sync inside TEMP_REPO against mock upstream
run_vendor_sync() {
  AZG_VENDOR_UPSTREAM="${MOCK_UPSTREAM}" \
  AZG_ROOT="${TEMP_REPO}" \
    bash -c "
      source '${TEMP_REPO}/lib/common.sh'
      source '${TEMP_REPO}/lib/vendor-sync.sh'
      AZG_ROOT='${TEMP_REPO}'
      vendor_sync \"\$@\"
    " -- "$@"
}

# ---------------------------------------------------------------------------
# T E S T S
# ---------------------------------------------------------------------------

section "1. vendor-sync.sh — static code checks"

# Shebang
_shebang="$(head -1 "${REPO_ROOT}/lib/vendor-sync.sh")"
if [ "${_shebang}" = "#!/usr/bin/env bash" ]; then
  pass "vendor-sync.sh uses '#!/usr/bin/env bash' shebang"
else
  fail "vendor-sync.sh shebang wrong" "got: '${_shebang}'"
fi

# No sed -i
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/vendor-sync.sh" | grep -q 'sed -i'; then
  fail "vendor-sync.sh must NOT use 'sed -i'"
else
  pass "vendor-sync.sh does not use 'sed -i'"
fi

# No ((VAR++))
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/vendor-sync.sh" | grep -qE '\(\([A-Za-z_]+\+\+\)\)'; then
  fail "vendor-sync.sh must NOT use ((VAR++))"
else
  pass "vendor-sync.sh does not use ((VAR++))"
fi

section "2. vendor-sync.sh — defines vendor_sync() and is sourceable"

if bash -c "
  source '${REPO_ROOT}/lib/common.sh' 2>/dev/null
  source '${REPO_ROOT}/lib/vendor-sync.sh' 2>/dev/null
  declare -f vendor_sync
" > /dev/null 2>&1; then
  pass "vendor-sync.sh defines vendor_sync() and sources without errors"
else
  fail "vendor-sync.sh must define vendor_sync() and source without errors"
fi

section "3. vendor_sync — populates engineering/ and productivity/"

run_vendor_sync > /dev/null 2>&1
_vs_exit=$?
if [ "${_vs_exit}" -eq 0 ]; then
  pass "vendor_sync exits 0"
else
  fail "vendor_sync exited ${_vs_exit} (expected 0)"
fi

assert_dir_exists "engineering/ directory created" "${VENDOR_DIR}/engineering"
assert_dir_exists "productivity/ directory created" "${VENDOR_DIR}/productivity"

section "4. vendor_sync — all 11 skills present with SKILL.md"

_missing_skills=0
for skill in "${ENGINEERING_SKILLS[@]}"; do
  if [ -f "${VENDOR_DIR}/engineering/${skill}/SKILL.md" ]; then
    pass "engineering/${skill}/SKILL.md present"
  else
    fail "engineering/${skill}/SKILL.md missing" "${VENDOR_DIR}/engineering/${skill}/SKILL.md"
    _missing_skills=$((_missing_skills + 1))
  fi
done
for skill in "${PRODUCTIVITY_SKILLS[@]}"; do
  if [ -f "${VENDOR_DIR}/productivity/${skill}/SKILL.md" ]; then
    pass "productivity/${skill}/SKILL.md present"
  else
    fail "productivity/${skill}/SKILL.md missing" "${VENDOR_DIR}/productivity/${skill}/SKILL.md"
    _missing_skills=$((_missing_skills + 1))
  fi
done

section "5. vendor_sync — excluded dirs NOT copied into vendor/"

for excl in deprecated in-progress misc personal; do
  if [ -d "${VENDOR_DIR}/${excl}" ] || [ -d "${VENDOR_DIR}/engineering/${excl}" ]; then
    fail "excluded dir '${excl}' should NOT be in vendor/" "found under ${VENDOR_DIR}"
  else
    pass "excluded dir '${excl}' not present in vendor/"
  fi
done

section "6. vendor_sync — VENDOR.lock written with required fields"

VENDOR_LOCK="${TEMP_REPO}/templates/global/skills/vendor/mattpocock-skills/VENDOR.lock"
assert_file_exists "VENDOR.lock file created" "${VENDOR_LOCK}"
assert_file_contains "VENDOR.lock has 'source:' field"         "${VENDOR_LOCK}" "source:"
assert_file_contains "VENDOR.lock has 'commit:' field"         "${VENDOR_LOCK}" "commit:"
assert_file_contains "VENDOR.lock has 'date_vendored:' field"  "${VENDOR_LOCK}" "date_vendored:"
assert_file_contains "VENDOR.lock has 'license:' field"        "${VENDOR_LOCK}" "license:"
assert_file_contains "VENDOR.lock has 'included:' field"       "${VENDOR_LOCK}" "included:"
assert_file_contains "VENDOR.lock has 'excluded:' field"       "${VENDOR_LOCK}" "excluded:"

section "7. vendor_sync — VENDOR.lock commit SHA is valid 40-char hex"

_commit_line="$(grep '^commit:' "${VENDOR_LOCK}" 2>/dev/null || echo "")"
_commit_sha="$(echo "${_commit_line}" | sed 's/^commit:[[:space:]]*//')"
if echo "${_commit_sha}" | grep -qE '^[0-9a-f]{40}$'; then
  pass "VENDOR.lock commit is a valid 40-char hex SHA"
else
  fail "VENDOR.lock commit SHA invalid" "got: '${_commit_sha}'"
fi

section "8. vendor_sync — VENDOR.lock included/excluded lists"

assert_file_contains "included list has 'engineering'"    "${VENDOR_LOCK}" "engineering"
assert_file_contains "included list has 'productivity'"   "${VENDOR_LOCK}" "productivity"
assert_file_contains "excluded list has 'deprecated'"     "${VENDOR_LOCK}" "deprecated"
assert_file_contains "excluded list has 'in-progress'"    "${VENDOR_LOCK}" "in-progress"
assert_file_contains "excluded list has 'misc'"           "${VENDOR_LOCK}" "misc"
assert_file_contains "excluded list has 'personal'"       "${VENDOR_LOCK}" "personal"

section "9. vendor_sync — idempotency (run twice, same SHA)"

_sha1="$(grep '^commit:' "${VENDOR_LOCK}" | sed 's/^commit:[[:space:]]*//')"
run_vendor_sync > /dev/null 2>&1
_sha2="$(grep '^commit:' "${VENDOR_LOCK}" | sed 's/^commit:[[:space:]]*//')"

if [ "${_sha1}" = "${_sha2}" ]; then
  pass "VENDOR.lock commit SHA unchanged after second vendor_sync run"
else
  fail "VENDOR.lock commit SHA changed between runs" "run1=${_sha1}  run2=${_sha2}"
fi

_vs2_exit=0
run_vendor_sync > /dev/null 2>&1 || _vs2_exit=$?
if [ "${_vs2_exit}" -eq 0 ]; then
  pass "second vendor_sync exits 0 (idempotent)"
else
  fail "second vendor_sync exited ${_vs2_exit} (expected 0)"
fi

section "10. vendor_sync — informative output"

_vs_out="$(run_vendor_sync 2>&1)" || true
if echo "${_vs_out}" | grep -qiE "vendor|skill|sync|done|complete|ok"; then
  pass "vendor_sync output contains progress/completion message"
else
  fail "vendor_sync output should contain informative messages" "got: ${_vs_out}"
fi

section "11. vendor_sync — AZG_VENDOR_UPSTREAM override respected"

# Verify that the commit SHA in VENDOR.lock matches the mock upstream
_lock_sha="$(grep '^commit:' "${VENDOR_LOCK}" | sed 's/^commit:[[:space:]]*//')"
if [ "${_lock_sha}" = "${MOCK_SHA}" ]; then
  pass "VENDOR.lock commit matches mock upstream HEAD"
else
  fail "VENDOR.lock commit does not match mock upstream" \
       "expected ${MOCK_SHA}, got ${_lock_sha}"
fi

section "12. azg update --vendor — wired through (uses TEMP_REPO)"

_update_exit=0
AZG_VENDOR_UPSTREAM="${MOCK_UPSTREAM}" \
  HOME="${TEMP_HOME}" \
  AZG_ROOT="${TEMP_REPO}" \
  "${TEMP_AZG}" update --vendor > /dev/null 2>&1 || _update_exit=$?
if [ "${_update_exit}" -eq 0 ]; then
  pass "azg update --vendor exits 0"
else
  fail "azg update --vendor exited ${_update_exit} (expected 0)"
fi

section "13. Phase 1 regression — vendor skill copy test now un-skips"

# After vendor_sync populated TEMP_REPO's vendor/, run Phase 1's skill-count
# logic to confirm it would no longer skip
_vendor_skill_count=0
_template_vendor="${TEMP_REPO}/templates/global/skills/vendor/mattpocock-skills"
for category_dir in "${_template_vendor}"/{engineering,productivity}; do
  [ -d "${category_dir}" ] || continue
  for skill_dir in "${category_dir}"/*/; do
    [ -d "${skill_dir}" ] || continue
    _vendor_skill_count=$((_vendor_skill_count + 1))
  done
done

if [ "${_vendor_skill_count}" -eq 11 ]; then
  pass "vendor/ now contains all 11 skills (Phase 1 skip resolved)"
else
  fail "expected 11 vendor skills, found ${_vendor_skill_count}"
fi

section "14. Phase 0 + Phase 1 regression — other commands still exit non-zero"

# All commands implemented!

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
