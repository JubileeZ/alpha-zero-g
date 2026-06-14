#!/usr/bin/env bash
# tests/test-phase8.sh — TDD suite for Phase 8: update and uninstall

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AZG="${REPO_ROOT}/azg"

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
  "$@" || actual_exit=$?
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

assert_dir_not_exists() {
  local desc="$1" path="$2"
  if [ -d "${path}" ]; then fail "${desc}" "directory should not exist: ${path}"; else pass "${desc}"; fi
}

TEMP_HOME="$(mktemp -d "${PWD}/tmp_azg_phase8-home-XXXXXX")"
TEMP_REPO="$(mktemp -d "${PWD}/tmp_azg_phase8-repo-XXXXXX")"
UPSTREAM_REPO="$(mktemp -d "${PWD}/tmp_azg_phase8-upstream-XXXXXX")"
trap 'rm -rf "${TEMP_HOME}" "${TEMP_REPO}" "${UPSTREAM_REPO}"' EXIT

section "1. azg update — runs git pull on AZG_ROOT"

# Setup fake upstream
cd "${UPSTREAM_REPO}"
git init -q
git config user.name "Test"
git config user.email "test@example.com"
tar -cf - --exclude=.git --exclude='tmp_azg*' -C "${REPO_ROOT}" . | tar -xf - -C "${UPSTREAM_REPO}"
git add .
git commit -q -m "Initial commit"
cd "${REPO_ROOT}"

rm -rf "${TEMP_REPO}"
git clone -q "${UPSTREAM_REPO}" "${TEMP_REPO}"
git -C "${TEMP_REPO}" config user.name "Test"
git -C "${TEMP_REPO}" config user.email "test@example.com"

# Make upstream have a new commit
cd "${UPSTREAM_REPO}"
echo "NEW_FILE" > test_update_file.txt
git add test_update_file.txt
git commit -q -m "New file"
cd "${REPO_ROOT}"

TEMP_AZG="${TEMP_REPO}/azg"

assert_exit "azg update exits 0" 0 env HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" update
if [ -f "${TEMP_REPO}/test_update_file.txt" ]; then
  pass "azg update pulled upstream commits"
else
  fail "azg update failed to pull upstream commits"
fi

section "2. azg uninstall — removes ~/.gemini/antigravity-cli/"

# Populate via setup
env HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" setup >/dev/null 2>&1
if [ ! -d "${TEMP_HOME}/.gemini/antigravity-cli" ]; then
  fail "Setup failed to create dir"
fi

assert_exit "azg uninstall exits 0" 0 env HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" uninstall

assert_dir_not_exists "uninstall removes ~/.gemini/antigravity-cli/" "${TEMP_HOME}/.gemini/antigravity-cli"
if [ -d "${TEMP_HOME}/.gemini" ]; then
  pass "uninstall leaves ~/.gemini untouched"
else
  fail "uninstall should not remove ~/.gemini itself"
fi

# Try running uninstall again (idempotent)
assert_output_contains "uninstall output mentions already removed or removed" "emove" env HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" uninstall

TOTAL=$((PASS + FAIL + SKIP))
printf "\n${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n"
printf "  Results  ${_clr_green}%d passed${_clr_reset}  " "${PASS}"
[ "${FAIL}" -gt 0 ] && printf "${_clr_red}%d failed${_clr_reset}  " "${FAIL}"
[ "${SKIP}" -gt 0 ] && printf "${_clr_yellow}%d skipped${_clr_reset}  " "${SKIP}"
printf "/ %d total\n" "${TOTAL}"
printf "${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n\n"

[ "${FAIL}" -eq 0 ]
