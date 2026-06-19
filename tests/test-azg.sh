#!/usr/bin/env bash
# tests/test-azg.sh — Integration test for setup, new, and apply in a temp HOME

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

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

if [ -f "${TEMP_HOME}/.gemini/antigravity-cli/statusline.sh" ]; then
  pass "statusline.sh created globally"
else
  fail "statusline.sh not created globally"
fi

if [ -f "${TEMP_HOME}/.gemini/antigravity-cli/settings.json" ]; then
  pass "settings.json created globally"
else
  fail "settings.json not created globally"
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

test_summary
