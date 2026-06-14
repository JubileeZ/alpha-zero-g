#!/usr/bin/env bash
# tests/test-phase1.sh — TDD suite for Phase 1: azg setup
#
# Run from repo root:  bash tests/test-phase1.sh
#
# What is tested:
#   1. azg setup exits 0 and is no longer a stub
#   2. ~/.gemini/antigravity-cli/ directory is created
#   3. skills/ and mcp_config.json are installed
#   4. Vendor skills are NOT required (Phase 2 handles vendoring); any skills
#      found under templates/global/skills/vendor/ are copied.
#   5. mcp_config.json is installed correctly (byte-identical to template)
#   6. Idempotency: running azg setup a second time produces exit 0 with no
#      diff in installed files
#   7. Cross-platform guards: no sed -i in setup.sh
#   8. setup.sh does not use ((VAR++)) (set -e incompatibility)
#   9. azg setup --dry-run prints what would be done without writing files
#  10. azg setup --force flag re-installs even if already installed
#
# All tests run against a TEMP_HOME to avoid polluting the real ~/.gemini/.
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AZG="${REPO_ROOT}/azg"

# ---------------------------------------------------------------------------
# Tiny test harness (same as test-phase0.sh)
# ---------------------------------------------------------------------------
PASS=0
FAIL=0
SKIP=0

_clr_reset="\033[0m"
_clr_green="\033[0;32m"
_clr_red="\033[0;31m"
_clr_yellow="\033[0;33m"
_clr_bold="\033[1m"
_clr_dim="\033[2m"
_clr_cyan="\033[0;36m"

pass() { PASS=$((PASS + 1)); printf "  ${_clr_green}✓${_clr_reset} %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  ${_clr_red}✗${_clr_reset} %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${_clr_dim}%s${_clr_reset}\n" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf "  ${_clr_yellow}–${_clr_reset} %s ${_clr_dim}(skipped)${_clr_reset}\n" "$1"; }

section() { printf "\n${_clr_bold}${_clr_cyan}▶ %s${_clr_reset}\n" "$1"; }

assert_exit() {
  local desc="$1" expected_exit="$2"; shift 2
  local actual_exit=0
  "$@" > /dev/null 2>&1 || actual_exit=$?
  if [ "${actual_exit}" -eq "${expected_exit}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "expected exit ${expected_exit}, got ${actual_exit}  (cmd: $*)"
  fi
}

assert_output_contains() {
  local desc="$1" pattern="$2"; shift 2
  local out
  out="$("$@" 2>&1)" || true
  if echo "${out}" | grep -qF "${pattern}"; then
    pass "${desc}"
  else
    fail "${desc}" "pattern not found: '${pattern}'"
  fi
}

assert_output_not_contains() {
  local desc="$1" pattern="$2"; shift 2
  local out
  out="$("$@" 2>&1)" || true
  if echo "${out}" | grep -qF "${pattern}"; then
    fail "${desc}" "pattern should NOT be present: '${pattern}'"
  else
    pass "${desc}"
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -e "${path}" ]; then pass "${desc}"; else fail "${desc}" "missing: ${path}"; fi
}

assert_file_not_exists() {
  local desc="$1" path="$2"
  if [ -e "${path}" ]; then fail "${desc}" "should not exist: ${path}"; else pass "${desc}"; fi
}

assert_dir_exists() {
  local desc="$1" path="$2"
  if [ -d "${path}" ]; then pass "${desc}"; else fail "${desc}" "directory missing: ${path}"; fi
}

assert_files_identical() {
  local desc="$1" file_a="$2" file_b="$3"
  if diff -q "${file_a}" "${file_b}" > /dev/null 2>&1; then
    pass "${desc}"
  else
    fail "${desc}" "'${file_a}' and '${file_b}' differ"
  fi
}

assert_file_contains() {
  local desc="$1" path="$2" pattern="$3"
  if [ -f "${path}" ] && grep -qF "${pattern}" "${path}"; then
    pass "${desc}"
  else
    fail "${desc}" "pattern '${pattern}' not found in ${path}"
  fi
}

# ---------------------------------------------------------------------------
# Temp HOME setup — all setup tests run with HOME overridden
# ---------------------------------------------------------------------------
TEMP_HOME="$(mktemp -d /tmp/azg-phase1-test-XXXXXX)"
trap 'rm -rf "${TEMP_HOME}"' EXIT

run_setup() {
  # Run azg setup with a temporary HOME so it never touches the real ~/.gemini
  HOME="${TEMP_HOME}" "${AZG}" setup "$@"
}

INSTALL_DIR="${TEMP_HOME}/.gemini/antigravity-cli"
INSTALL_SKILLS_DIR="${INSTALL_DIR}/skills"
INSTALL_MCP="${INSTALL_DIR}/mcp_config.json"

TEMPLATE_GLOBAL="${REPO_ROOT}/templates/global"
TEMPLATE_VENDOR="${TEMPLATE_GLOBAL}/skills/vendor/mattpocock-skills"
TEMPLATE_MCP="${TEMPLATE_GLOBAL}/mcp_config.json"

# ---------------------------------------------------------------------------
# T E S T S
# ---------------------------------------------------------------------------

section "1. azg setup — is no longer a stub"

assert_exit            "azg setup exits 0"                0  run_setup
assert_output_not_contains "azg setup does not say 'not yet implemented'" \
                           "not yet implemented"               run_setup

section "2. azg setup — destination directories created"

assert_dir_exists  "~/.gemini/antigravity-cli/ created"         "${INSTALL_DIR}"
assert_dir_exists  "~/.gemini/antigravity-cli/skills/ created"  "${INSTALL_SKILLS_DIR}"

section "3. azg setup — mcp_config.json installed"

assert_file_exists     "mcp_config.json installed"                    "${INSTALL_MCP}"
assert_files_identical "mcp_config.json is identical to template"     \
                       "${INSTALL_MCP}" "${TEMPLATE_MCP}"

section "4. azg setup — vendor skills copied (if any exist in vendor/)"

# Count how many skill directories exist in the vendor tree
_vendor_skill_count=0
if [ -d "${TEMPLATE_VENDOR}" ]; then
  # A skill directory is any directory directly under engineering/ or productivity/
  for category_dir in "${TEMPLATE_VENDOR}"/{engineering,productivity}; do
    [ -d "${category_dir}" ] || continue
    for skill_dir in "${category_dir}"/*/; do
      [ -d "${skill_dir}" ] || continue
      _vendor_skill_count=$((_vendor_skill_count + 1))
    done
  done
fi

if [ "${_vendor_skill_count}" -eq 0 ]; then
  skip "No vendor skills present yet (Phase 2 will populate them) — skipping copy check"
else
  # Each skill should appear under ~/.gemini/antigravity-cli/skills/<name>/
  _copied=0
  _missing=0
  for category_dir in "${TEMPLATE_VENDOR}"/{engineering,productivity}; do
    [ -d "${category_dir}" ] || continue
    for skill_dir in "${category_dir}"/*/; do
      [ -d "${skill_dir}" ] || continue
      skill_name="$(basename "${skill_dir}")"
      if [ -d "${INSTALL_SKILLS_DIR}/${skill_name}" ]; then
        _copied=$((_copied + 1))
      else
        _missing=$((_missing + 1))
        fail "skill '${skill_name}' missing from install dir"
      fi
    done
  done
  [ "${_missing}" -eq 0 ] && pass "all ${_copied} vendor skills copied to install dir"
fi

section "5. azg setup — idempotency (run twice, same result)"

# Run a second time
run_setup > /dev/null 2>&1
_second_exit=$?
if [ "${_second_exit}" -eq 0 ]; then
  pass "second azg setup run exits 0"
else
  fail "second azg setup run exited ${_second_exit} (expected 0)"
fi

# mcp_config.json should still be identical to template after second run
assert_files_identical "mcp_config.json unchanged after second setup run" \
                       "${INSTALL_MCP}" "${TEMPLATE_MCP}"

section "6. azg setup --dry-run — prints plan, writes nothing"

# Remove install dir to test clean dry-run
TEMP_HOME2="$(mktemp -d /tmp/azg-phase1-dryrun-XXXXXX)"
trap 'rm -rf "${TEMP_HOME2}"' EXIT

DRY_OUT="$(HOME="${TEMP_HOME2}" "${AZG}" setup --dry-run 2>&1)" || true
DRY_EXIT=0
HOME="${TEMP_HOME2}" "${AZG}" setup --dry-run > /dev/null 2>&1 || DRY_EXIT=$?

if [ "${DRY_EXIT}" -eq 0 ]; then
  pass "azg setup --dry-run exits 0"
else
  fail "azg setup --dry-run exited ${DRY_EXIT} (expected 0)"
fi

if echo "${DRY_OUT}" | grep -qiF "dry"; then
  pass "azg setup --dry-run output mentions 'dry'"
else
  fail "azg setup --dry-run output should mention 'dry'" "got: ${DRY_OUT}"
fi

# No files should have been written to TEMP_HOME2
if [ ! -d "${TEMP_HOME2}/.gemini" ]; then
  pass "azg setup --dry-run wrote no files"
else
  fail "azg setup --dry-run should not write any files" \
       "found: ${TEMP_HOME2}/.gemini"
fi

section "7. azg setup --force — re-installs even when already installed"

# Corrupt the mcp_config in TEMP_HOME and verify --force restores it
printf '{}' > "${INSTALL_MCP}"
run_setup --force > /dev/null 2>&1
assert_files_identical "azg setup --force restores mcp_config.json" \
                       "${INSTALL_MCP}" "${TEMPLATE_MCP}"

section "8. azg setup — output is informative"

_setup_out="$(run_setup 2>&1)" || true
if echo "${_setup_out}" | grep -qiE "install|setup|skill|done|complete|ok"; then
  pass "setup output contains progress/completion message"
else
  fail "setup output should contain informative messages" "got: ${_setup_out}"
fi

section "9. Cross-platform guards in setup.sh"

# No sed -i (strip comment lines first)
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/setup.sh" | grep -q 'sed -i'; then
  fail "setup.sh must NOT use 'sed -i' (BSD/GNU incompatible)"
else
  pass "setup.sh does not use 'sed -i'"
fi

# No ((VAR++)) with set -e
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/setup.sh" | grep -qE '\(\([A-Za-z_]+\+\+\)\)'; then
  fail "setup.sh must NOT use ((VAR++)) with set -e"
else
  pass "setup.sh does not use ((VAR++))"
fi

section "10. setup.sh — shebang and sourceable"

_shebang="$(head -1 "${REPO_ROOT}/lib/setup.sh")"
if [ "${_shebang}" = "#!/usr/bin/env bash" ]; then
  pass "setup.sh uses '#!/usr/bin/env bash' shebang"
else
  fail "setup.sh shebang is wrong" "got: '${_shebang}'"
fi

# Must be sourceable (define cmd_setup) without side-effects
if bash -c "source '${REPO_ROOT}/lib/setup.sh' 2>&1 && declare -f cmd_setup" > /dev/null 2>&1; then
  pass "setup.sh defines cmd_setup() function"
else
  fail "setup.sh must define cmd_setup() and source without errors"
fi

section "11. azg setup — summary line printed on success"

_out="$(run_setup 2>&1)" || true
if echo "${_out}" | grep -qiE "done|complete|installed|setup complete"; then
  pass "setup prints a completion/summary message"
else
  fail "setup should print a completion message" "got: ${_out}"
fi

section "12. Phase 0 regression — stub tests still respected"

# After Phase 1 implementation, setup must no longer be a stub.
# Other commands (new, apply, update, uninstall) must still be stubs.
for cmd in apply update uninstall; do
  _exit=0
  "${AZG}" "${cmd}" < /dev/null > /dev/null 2>&1 || _exit=$?
  if [ "${_exit}" -ne 0 ]; then
    pass "azg ${cmd} is still a stub (exits non-zero)"
  else
    fail "azg ${cmd} should still be a stub" "exited 0 unexpectedly"
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
TOTAL=$((PASS + FAIL + SKIP))
printf "\n${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n"
printf "  Results  ${_clr_green}%d passed${_clr_reset}  " "${PASS}"
[ "${FAIL}" -gt 0 ] && printf "${_clr_red}%d failed${_clr_reset}  " "${FAIL}"
[ "${SKIP}" -gt 0 ] && printf "${_clr_yellow}%d skipped${_clr_reset}  " "${SKIP}"
printf "/ %d total\n" "${TOTAL}"
printf "${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n\n"

[ "${FAIL}" -eq 0 ]
