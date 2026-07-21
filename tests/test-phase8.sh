#!/usr/bin/env bash
# tests/test-phase8.sh — TDD suite for Phase 8: update and uninstall

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

TEMP_HOME="$(azg_mktemp_d "tmp_azg_phase8-home-XXXXXX")"
TEMP_REPO="$(azg_mktemp_d "tmp_azg_phase8-repo-XXXXXX")"
UPSTREAM_REPO="$(azg_mktemp_d "tmp_azg_phase8-upstream-XXXXXX")"

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
git clone -q --no-local "${UPSTREAM_REPO}" "${TEMP_REPO}"
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
assert_dir_not_exists "uninstall removes ~/.gemini/config/skills/" "${TEMP_HOME}/.gemini/config/skills"
assert_file_not_exists "uninstall removes ~/.gemini/config/mcp_config.json" "${TEMP_HOME}/.gemini/config/mcp_config.json"
if [ -d "${TEMP_HOME}/.gemini" ]; then
  pass "uninstall leaves ~/.gemini untouched"
else
  fail "uninstall should not remove ~/.gemini itself"
fi

# Try running uninstall again (idempotent)
assert_output_contains "uninstall output mentions already removed or removed" "emove" env HOME="${TEMP_HOME}" AZG_ROOT="${TEMP_REPO}" "${TEMP_AZG}" uninstall

test_summary
