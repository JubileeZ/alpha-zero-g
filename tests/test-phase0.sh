#!/usr/bin/env bash
# tests/test-phase0.sh — TDD suite for Phase 0: repo skeleton
#
# Tests are written to specify exact expected behavior, then run to confirm green.
# Run from repo root:  bash tests/test-phase0.sh
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AZG="${REPO_ROOT}/azg"

# ---------------------------------------------------------------------------
# Tiny test harness
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

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -e "${path}" ]; then pass "${desc}"; else fail "${desc}" "missing: ${path}"; fi
}

assert_file_executable() {
  local desc="$1" path="$2"
  if [ -x "${path}" ]; then pass "${desc}"; else fail "${desc}" "not executable: ${path}"; fi
}

assert_file_contains() {
  local desc="$1" path="$2" pattern="$3"
  if [ -f "${path}" ] && grep -qF "${pattern}" "${path}"; then
    pass "${desc}"
  else
    fail "${desc}" "pattern '${pattern}' not found in ${path}"
  fi
}

assert_dir_exists() {
  local desc="$1" path="$2"
  if [ -d "${path}" ]; then pass "${desc}"; else fail "${desc}" "directory missing: ${path}"; fi
}

assert_var_set() {
  local desc="$1" var_name="$2" val="${3:-}"
  if [ -n "${val}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "\$${var_name} is empty or unset"
  fi
}

# ---------------------------------------------------------------------------
# T E S T S
# ---------------------------------------------------------------------------

section "1. Repository structure"

assert_file_exists  "VERSION file exists"                              "${REPO_ROOT}/VERSION"
assert_file_exists  "azg dispatcher exists"                            "${AZG}"
assert_file_executable "azg is executable"                             "${AZG}"
assert_dir_exists   "lib/ directory exists"                            "${REPO_ROOT}/lib"
assert_dir_exists   "templates/ directory exists"                      "${REPO_ROOT}/templates"
assert_dir_exists   "tests/ directory exists"                          "${REPO_ROOT}/tests"
assert_dir_exists   "docs/ directory exists"                           "${REPO_ROOT}/docs"

section "2. VERSION file"

assert_file_contains "VERSION contains '3.0.0'"   "${REPO_ROOT}/VERSION"   "3.0.0"
_ver="$(cat "${REPO_ROOT}/VERSION" 2>/dev/null | tr -d '[:space:]')"
if [[ "${_ver}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  pass "VERSION is semver format (${_ver})"
else
  fail "VERSION is not semver format" "got: '${_ver}'"
fi

section "3. lib/ — all scripts present and executable"

for script in common.sh setup.sh scaffold.sh apply.sh update.sh uninstall.sh vendor-sync.sh apply-overlay.sh; do
  assert_file_exists      "lib/${script} exists"      "${REPO_ROOT}/lib/${script}"
  assert_file_executable  "lib/${script} executable"  "${REPO_ROOT}/lib/${script}"
done

section "4. common.sh — sources cleanly and exposes expected interface"

# Source in a subshell so it doesn't pollute this script's env
_common_test=$(bash -c "
  source '${REPO_ROOT}/lib/common.sh' 2>&1
  echo \"AZG_OS=\${AZG_OS:-UNSET}\"
  echo \"AZG_ARCH=\${AZG_ARCH:-UNSET}\"
  echo \"AZG_ROOT=\${AZG_ROOT:-UNSET}\"
  echo \"AZG_VERSION=\${AZG_VERSION:-UNSET}\"
  echo \"AZG_GLOBAL_DIR=\${AZG_GLOBAL_DIR:-UNSET}\"
")

_os_val=$(echo "${_common_test}"   | grep '^AZG_OS='   | cut -d= -f2)
_arch_val=$(echo "${_common_test}" | grep '^AZG_ARCH=' | cut -d= -f2)
_root_val=$(echo "${_common_test}" | grep '^AZG_ROOT=' | cut -d= -f2)
_ver_val=$(echo "${_common_test}"  | grep '^AZG_VERSION=' | cut -d= -f2)
_dir_val=$(echo "${_common_test}"  | grep '^AZG_GLOBAL_DIR=' | cut -d= -f2)

if [ "${_os_val}" = "linux" ] || [ "${_os_val}" = "macos" ]; then
  pass "AZG_OS detected correctly (${_os_val})"
else
  fail "AZG_OS not detected" "got: '${_os_val}'"
fi

if [ "${_arch_val}" = "x86_64" ] || [ "${_arch_val}" = "arm64" ]; then
  pass "AZG_ARCH detected correctly (${_arch_val})"
else
  fail "AZG_ARCH not detected" "got: '${_arch_val}'"
fi

assert_var_set "AZG_ROOT is set"         "AZG_ROOT"        "${_root_val}"
assert_var_set "AZG_VERSION is set"      "AZG_VERSION"     "${_ver_val}"
assert_var_set "AZG_GLOBAL_DIR is set"   "AZG_GLOBAL_DIR"  "${_dir_val}"

# AZG_VERSION in common.sh should match VERSION file
_ver_file="$(cat "${REPO_ROOT}/VERSION" | tr -d '[:space:]')"
if [ "${_ver_val}" = "${_ver_file}" ]; then
  pass "AZG_VERSION (${_ver_val}) matches VERSION file"
else
  fail "AZG_VERSION mismatch" "common.sh: '${_ver_val}'  VERSION file: '${_ver_file}'"
fi

# AZG_GLOBAL_DIR should be under HOME
if [[ "${_dir_val}" == "${HOME}/.gemini/antigravity-cli" ]]; then
  pass "AZG_GLOBAL_DIR is \$HOME/.gemini/antigravity-cli"
else
  fail "AZG_GLOBAL_DIR has wrong value" "got: '${_dir_val}'"
fi

section "5. common.sh — helper functions are defined"

for fn in info ok warn err die step require_cmd require_jq require_agy \
          ensure_dir atomic_write atomic_copy sed_portable prompt_yn prompt_choice; do
  if bash -c "source '${REPO_ROOT}/lib/common.sh' && declare -f ${fn}" > /dev/null 2>&1; then
    pass "function ${fn}() is defined"
  else
    fail "function ${fn}() is missing from common.sh"
  fi
done

section "6. azg dispatcher — version flags"

assert_exit             "azg version exits 0"                0  "${AZG}" version
assert_output_contains  "azg version prints version number" "3.0.0"  "${AZG}" version
assert_exit             "azg --version exits 0"              0  "${AZG}" --version
assert_output_contains  "azg --version prints version"       "3.0.0"  "${AZG}" --version
assert_exit             "azg -v exits 0"                     0  "${AZG}" -v
assert_output_contains  "azg -v prints version"              "3.0.0"  "${AZG}" -v

section "7. azg dispatcher — help flags"

assert_exit             "azg help exits 0"       0  "${AZG}" help
assert_output_contains  "help shows 'setup'"     "setup"      "${AZG}" help
assert_output_contains  "help shows 'new'"       "new"        "${AZG}" help
assert_output_contains  "help shows 'apply'"     "apply"      "${AZG}" help
assert_output_contains  "help shows 'update'"    "update"     "${AZG}" help
assert_output_contains  "help shows 'uninstall'" "uninstall"  "${AZG}" help
assert_exit             "azg --help exits 0"     0  "${AZG}" --help
assert_exit             "azg -h exits 0"         0  "${AZG}" -h
# bare azg with no args should also show help (exit 0)
assert_exit             "azg with no args exits 0"  0  "${AZG}"

section "8. azg dispatcher — unknown command exits non-zero"

assert_exit             "azg badcmd exits 1"          1  "${AZG}" badcmd
assert_output_contains  "azg badcmd prints error"     "Unknown command"   "${AZG}" badcmd

section "9. azg dispatcher — stub commands exit non-zero with 'not yet implemented'"

for cmd in setup new apply update uninstall; do
  assert_exit             "azg ${cmd} exits non-zero (stub)"    1  "${AZG}" "${cmd}"
  assert_output_contains  "azg ${cmd} prints 'not yet implemented'" \
                          "not yet implemented"   "${AZG}" "${cmd}"
done

section "10. Template directory structure"

assert_dir_exists  "templates/global/ exists"                                    "${REPO_ROOT}/templates/global"
assert_dir_exists  "templates/global/skills/ exists"                             "${REPO_ROOT}/templates/global/skills"
assert_dir_exists  "templates/global/skills/vendor/ exists"                      "${REPO_ROOT}/templates/global/skills/vendor"
assert_dir_exists  "templates/global/skills/vendor/mattpocock-skills/ exists"    "${REPO_ROOT}/templates/global/skills/vendor/mattpocock-skills"
assert_dir_exists  "templates/global/skills/overlay/ exists"                     "${REPO_ROOT}/templates/global/skills/overlay"
assert_dir_exists  "templates/global/skills/overlay/mattpocock-skills/ exists"   "${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills"
assert_file_exists "templates/global/mcp_config.json exists"                     "${REPO_ROOT}/templates/global/mcp_config.json"
assert_file_exists "tool-map.json exists"                                        "${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills/tool-map.json"
assert_file_exists "ANTIGRAVITY-NOTE.md.tmpl exists"                             "${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills/_shared/ANTIGRAVITY-NOTE.md.tmpl"
assert_dir_exists  "templates/project/ exists"                                   "${REPO_ROOT}/templates/project"
assert_dir_exists  "templates/project/.agents/ exists"                           "${REPO_ROOT}/templates/project/.agents"
assert_dir_exists  "templates/project/.agents/skills/ exists"                    "${REPO_ROOT}/templates/project/.agents/skills"

section "11. tool-map.json is valid JSON with correct keys"

_tool_map="${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills/tool-map.json"
if command -v jq > /dev/null 2>&1; then
  if jq empty "${_tool_map}" > /dev/null 2>&1; then
    pass "tool-map.json is valid JSON"
  else
    fail "tool-map.json is invalid JSON"
  fi
  for key in Read Write Edit Bash Grep Glob; do
    _val=$(jq -r ".${key} // empty" "${_tool_map}" 2>/dev/null)
    if [ -n "${_val}" ]; then
      pass "tool-map.json has key '${key}' → '${_val}'"
    else
      fail "tool-map.json missing key '${key}'"
    fi
  done
else
  skip "jq not available — skipping JSON validation (install jq to enable)"
fi

section "12. mcp_config.json is valid JSON"

_mcp="${REPO_ROOT}/templates/global/mcp_config.json"
if command -v jq > /dev/null 2>&1; then
  if jq empty "${_mcp}" > /dev/null 2>&1; then
    pass "mcp_config.json is valid JSON"
  else
    fail "mcp_config.json is invalid JSON"
  fi
  if jq -e '.mcpServers' "${_mcp}" > /dev/null 2>&1; then
    pass "mcp_config.json has 'mcpServers' key"
  else
    fail "mcp_config.json missing 'mcpServers' key"
  fi
else
  skip "jq not available — skipping JSON validation"
fi

section "13. ANTIGRAVITY-NOTE.md.tmpl contains {{SKILL_NAME}} placeholder"

assert_file_contains \
  "ANTIGRAVITY-NOTE.md.tmpl contains {{SKILL_NAME}} placeholder" \
  "${REPO_ROOT}/templates/global/skills/overlay/mattpocock-skills/_shared/ANTIGRAVITY-NOTE.md.tmpl" \
  "{{SKILL_NAME}}"

section "14. Cross-platform guards in common.sh"

# Ensure sed_portable is defined and doesn't use sed -i internally
# Strip comment lines before checking so docs like "# no sed -i" don't trigger
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/common.sh" | grep -q 'sed -i'; then
  fail "common.sh must NOT use 'sed -i' (BSD/GNU incompatible)"
else
  pass "common.sh does not use 'sed -i' (in non-comment code)"
fi

# Ensure ((VAR++)) is not used (set -e incompatible when VAR=0)
if grep -v '^[[:space:]]*#' "${REPO_ROOT}/lib/common.sh" | grep -qE '\(\([A-Za-z_]+\+\+\)\)'; then
  fail "common.sh must NOT use ((VAR++)) with set -e"
else
  pass "common.sh does not use ((VAR++)) (in non-comment code)"
fi

# Check all lib scripts for the same guard (excluding comment lines)
for script in setup.sh scaffold.sh apply.sh update.sh uninstall.sh vendor-sync.sh apply-overlay.sh azg; do
  _path="${REPO_ROOT}/lib/${script}"
  [ "${script}" = "azg" ] && _path="${REPO_ROOT}/azg"
  [ -f "${_path}" ] || continue
  if grep -v '^[[:space:]]*#' "${_path}" | grep -q 'sed -i'; then
    fail "${script}: must NOT use 'sed -i'"
  else
    pass "${script}: no 'sed -i'"
  fi
done

section "15. azg shebang and bash compatibility"

_shebang=$(head -1 "${AZG}")
if [ "${_shebang}" = "#!/usr/bin/env bash" ]; then
  pass "azg uses '#!/usr/bin/env bash' shebang"
else
  fail "azg shebang is wrong" "got: '${_shebang}'"
fi

_shebang_common=$(head -1 "${REPO_ROOT}/lib/common.sh")
if [ "${_shebang_common}" = "#!/usr/bin/env bash" ]; then
  pass "common.sh uses '#!/usr/bin/env bash' shebang"
else
  fail "common.sh shebang is wrong" "got: '${_shebang_common}'"
fi

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
