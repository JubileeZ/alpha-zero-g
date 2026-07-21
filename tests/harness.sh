#!/usr/bin/env bash
# tests/harness.sh — Shared test harness for Alpha-Zero-G test suites

set -uo pipefail

# Test counters
PASS=0
FAIL=0
SKIP=0

# Colors
_clr_reset="\033[0m"
_clr_green="\033[0;32m"
_clr_red="\033[0;31m"
_clr_yellow="\033[0;33m"
_clr_bold="\033[1m"
_clr_dim="\033[2m"
_clr_cyan="\033[0;36m"

# Environment
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AZG="${REPO_ROOT}/azg"

# Temp dirs live under TMPDIR (never REPO_ROOT). Prior runs left tmp_azg* at root when
# EXIT traps failed on Windows (locked HOME trees). Scrub + register for cleanup.
_AZG_TEMP_DIRS=()

azg_mktemp_d() {
  local template="${1:-tmp_azg-XXXXXX}"
  local base="${TMPDIR:-${TEMP:-${TMP:-/tmp}}}"
  base="${base//\\//}"
  local dir
  dir="$(mktemp -d "${base}/${template}")"
  _AZG_TEMP_DIRS+=("${dir}")
  printf '%s' "${dir}"
}

azg_rmtree() {
  local target="$1"
  [ -e "${target}" ] || return 0
  # DESTRUCTIVE: test/temp scrub only (EXIT trap — not agent-mediated)
  # Prefer rm -rf: Windows Store python3 stub breaks shutil.rmtree paths.
  rm -rf "${target}" 2>/dev/null || true
  if [ -e "${target}" ] && command -v powershell.exe >/dev/null 2>&1; then
    local win
    win="$(cygpath -w "${target}" 2>/dev/null || printf '%s' "${target}")"
    powershell.exe -NoProfile -Command "Remove-Item -LiteralPath '${win}' -Recurse -Force -ErrorAction SilentlyContinue" >/dev/null 2>&1 || true
  fi
}

azg_scrub_root_leaks() {
  # DESTRUCTIVE: remove leaked test dirs matching tmp_azg* at repo root only
  local leak
  shopt -s nullglob
  for leak in "${REPO_ROOT}"/tmp_azg*; do
    azg_rmtree "${leak}"
  done
  shopt -u nullglob
}

azg_cleanup_temps() {
  local d
  for d in "${_AZG_TEMP_DIRS[@]:-}"; do
    azg_rmtree "${d}"
  done
  _AZG_TEMP_DIRS=()
  azg_scrub_root_leaks
}

azg_scrub_root_leaks
trap 'azg_cleanup_temps' EXIT

# Reporting
pass() { PASS=$((PASS + 1)); printf "  ${_clr_green}✓${_clr_reset} %s\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "  ${_clr_red}✗${_clr_reset} %s\n" "$1"; [ -n "${2:-}" ] && printf "    ${_clr_dim}%s${_clr_reset}\n" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf "  ${_clr_yellow}–${_clr_reset} %s ${_clr_dim}(skipped)${_clr_reset}\n" "$1"; }
section() { printf "\n${_clr_bold}${_clr_cyan}▶ %s${_clr_reset}\n" "$1"; }

# Assertions
assert_exit() {
  local desc="$1" expected_exit="$2"; shift 2
  local actual_exit=0
  "$@" >/dev/null 2>&1 || actual_exit=$?
  if [ "${actual_exit}" -eq "${expected_exit}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "expected exit ${expected_exit}, got ${actual_exit}  (cmd: $*)"
  fi
}

assert_output() {
  local desc="$1" expected="$2"; shift 2
  local out
  out="$("$@" 2>&1)" || true
  if [ "${out}" = "${expected}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "expected '${expected}', got '${out}'"
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
  if ! echo "${out}" | grep -qF "${pattern}"; then
    pass "${desc}"
  else
    fail "${desc}" "unexpected pattern found: '${pattern}'"
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -e "${path}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "missing file: ${path}"
  fi
}

assert_file_not_exists() {
  local desc="$1" path="$2"
  if [ ! -e "${path}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "file should not exist: ${path}"
  fi
}

assert_dir_exists() {
  local desc="$1" path="$2"
  if [ -d "${path}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "directory missing: ${path}"
  fi
}

assert_dir_not_exists() {
  local desc="$1" path="$2"
  if [ ! -d "${path}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "directory should not exist: ${path}"
  fi
}

assert_file_executable() {
  local desc="$1" path="$2"
  if [ -x "${path}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "not executable: ${path}"
  fi
}

assert_executable() {
  assert_file_executable "$@"
}

assert_file_contains() {
  local desc="$1" path="$2" pattern="$3"
  if [ -f "${path}" ] && grep -qF "${pattern}" "${path}"; then
    pass "${desc}"
  else
    fail "${desc}" "pattern '${pattern}' not found in ${path}"
  fi
}

assert_file_not_contains() {
  local desc="$1" path="$2" pattern="$3"
  if [ -f "${path}" ] && ! grep -qF "${pattern}" "${path}"; then
    pass "${desc}"
  else
    fail "${desc}" "unexpected pattern '${pattern}' found in ${path}"
  fi
}

assert_file_matches() {
  local desc="$1" path="$2" pattern="$3"
  if [ -f "${path}" ] && grep -qE "${pattern}" "${path}"; then
    pass "${desc}"
  else
    fail "${desc}" "regex '${pattern}' not found in ${path}"
  fi
}

assert_files_identical() {
  local desc="$1" file1="$2" file2="$3"
  if cmp -s "${file1}" "${file2}"; then
    pass "${desc}"
  else
    fail "${desc}" "files not identical: ${file1} vs ${file2}"
  fi
}

assert_var_set() {
  local desc="$1" varname="$2" val="${3:-}"
  if [ -n "${val}" ]; then
    pass "${desc}"
  else
    fail "${desc}" "\$${varname} is empty or unset"
  fi
}

test_summary() {
  local total=$((PASS + FAIL + SKIP))
  printf "\n${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n"
  printf "  Results  ${_clr_green}%d passed${_clr_reset}  " "${PASS}"
  [ "${FAIL}" -gt 0 ] && printf "${_clr_red}%d failed${_clr_reset}  " "${FAIL}"
  [ "${SKIP}" -gt 0 ] && printf "${_clr_yellow}%d skipped${_clr_reset}  " "${SKIP}"
  printf "/ %d total\n" "${total}"
  printf "${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n\n"
  [ "${FAIL}" -eq 0 ]
}
