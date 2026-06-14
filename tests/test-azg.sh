#!/usr/bin/env bash
# tests/test-azg.sh — Integration test for setup, new, and apply in a temp HOME

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

TEMP_HOME="$(mktemp -d "${PWD}/tmp_azg_integration-home-XXXXXX")"
TEMP_WORKSPACE="$(mktemp -d "${PWD}/tmp_azg_integration-workspace-XXXXXX")"
trap 'rm -rf "${TEMP_HOME}" "${TEMP_WORKSPACE}"' EXIT

export HOME="${TEMP_HOME}"
export AZG_ROOT="${REPO_ROOT}"
export GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test User"
export GIT_COMMITTER_EMAIL="test@example.com"

section "1. azg setup in clean HOME"

assert_exit "azg setup exits 0" 0 "${AZG}" setup >/dev/null

if [ -f "${TEMP_HOME}/.gemini/antigravity-cli/mcp_config.json" ]; then
  pass "mcp_config.json created globally"
else
  fail "mcp_config.json not created globally"
fi

if [ -d "${TEMP_HOME}/.gemini/antigravity-cli/skills" ]; then
  pass "Skills directory created globally"
else
  fail "Skills directory not created globally"
fi

section "2. azg new in workspace"

cd "${TEMP_WORKSPACE}"
# Inputs for interactive flow:
# 1) stack: 1 (python)
# 2) custom cmds: n
# 3) hooks: y (quality-gate), y (auto-lint)
# 4) run setup-matt-pocock-skills now: n
# 5) mcp: 2 (GitHub)
# 6) AGENTS.md: y
# 7) git init: y
printf "1\nn\ny\ny\nn\n2\ny\ny\n" | "${AZG}" new my-new-app >/dev/null 2>&1

if [ -d "my-new-app/.agents" ]; then
  pass "Scaffolded app has .agents dir"
else
  fail "Scaffolded app missing .agents dir"
fi

if [ -f "my-new-app/GEMINI.md" ] && grep -q "## Build and Test Commands" "my-new-app/GEMINI.md"; then
  pass "GEMINI.md generated correctly"
else
  fail "GEMINI.md missing or malformed"
fi

if [ -d "my-new-app/.git" ]; then
  pass "Git repository initialized"
else
  fail "Git repository not initialized"
fi

section "3. azg apply to existing repo"

mkdir -p existing-app
cd existing-app
git init -q
git commit --allow-empty -m "Init" -q
touch README.md
echo "# Existing Project" > GEMINI.md
git add README.md GEMINI.md
git commit -q -m "Add README and GEMINI.md"

assert_exit "azg apply exits 0" 0 "${AZG}" apply . >/dev/null

if [ -d ".agents/hooks" ] && [ -f ".agents/hooks.json" ]; then
  pass "Apply injected hooks"
else
  fail "Apply failed to inject hooks"
fi

if [ -f "GEMINI.md" ] && grep -q "AZG:MANAGED:START" "GEMINI.md"; then
  pass "Apply injected GEMINI.md managed block"
else
  fail "Apply failed to inject GEMINI.md managed block"
fi

TOTAL=$((PASS + FAIL + SKIP))
printf "\n${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n"
printf "  Results  ${_clr_green}%d passed${_clr_reset}  " "${PASS}"
[ "${FAIL}" -gt 0 ] && printf "${_clr_red}%d failed${_clr_reset}  " "${FAIL}"
[ "${SKIP}" -gt 0 ] && printf "${_clr_yellow}%d skipped${_clr_reset}  " "${SKIP}"
printf "/ %d total\n" "${TOTAL}"
printf "${_clr_bold}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_clr_reset}\n\n"

[ "${FAIL}" -eq 0 ]
