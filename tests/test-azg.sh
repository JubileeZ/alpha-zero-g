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

if [ -f "${TEMP_HOME}/.gemini/config/mcp_config.json" ]; then
  pass "mcp_config.json created globally"
else
  fail "mcp_config.json not created globally"
fi

if [ -d "${TEMP_HOME}/.gemini/config/skills" ]; then
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

# 1a. Profile validation
assert_exit "azg setup with invalid profile fails" 1 "${AZG}" setup --profile invalid

# 1b. Profile core (default) check
# Default is core profile. Verify that core skills (e.g. tdd, teach, writing-great-skills) are copied, but ponytail or setup-matt-pocock-skills is NOT.
if [ -d "${TEMP_HOME}/.gemini/config/skills/tdd" ] && \
   [ -d "${TEMP_HOME}/.gemini/config/skills/teach" ] && \
   [ -d "${TEMP_HOME}/.gemini/config/skills/writing-great-skills" ]; then
  pass "core profile copies core skills (tdd, teach, writing-great-skills)"
else
  fail "core profile missing some core skills"
fi

if [ ! -d "${TEMP_HOME}/.gemini/config/skills/setup-matt-pocock-skills" ] && [ ! -d "${TEMP_HOME}/.gemini/config/skills/ponytail" ]; then
  pass "core profile excludes setup-matt-pocock-skills and ponytail"
else
  fail "core profile did not exclude setup-matt-pocock-skills or ponytail"
fi

# 1c. Smart Setup Sync verification
# Run setup again, capturing output to check if smart sync kicks in
_setup_sync_out="$("${AZG}" setup 2>&1)"
if echo "${_setup_sync_out}" | grep -q "Smart Sync: VENDOR.lock commits unchanged"; then
  pass "setup smart sync skips copying skills when lock commit is unchanged"
else
  fail "setup smart sync failed to skip skill copying" "got: ${_setup_sync_out}"
fi

# 1d. Profile full check
# Force setup with full profile to copy all skills
assert_exit "azg setup --profile full exits 0" 0 "${AZG}" setup --profile full --force >/dev/null
if [ -d "${TEMP_HOME}/.gemini/config/skills/setup-matt-pocock-skills" ] && [ -d "${TEMP_HOME}/.gemini/config/skills/ponytail" ]; then
  pass "full profile copies setup-matt-pocock-skills and ponytail"
else
  fail "full profile missing setup-matt-pocock-skills or ponytail"
fi


section "2. azg new in workspace"

cd "${TEMP_WORKSPACE}"
# Inputs for interactive flow:
# 1) stack: 1 (python)
# 2) custom cmds: n
# 3) mcp: 2 (GitHub)
# 4) git init: y
printf "1\nn\n2\ny\n" | "${AZG}" new my-new-app >/dev/null 2>&1

if [ -d "my-new-app/.agents" ]; then
  pass "Scaffolded app has .agents dir"
else
  fail "Scaffolded app missing .agents dir"
fi

if [ -f "my-new-app/AGENTS.md" ] && grep -q "## Key Commands" "my-new-app/AGENTS.md"; then
  pass "AGENTS.md generated correctly"
else
  fail "AGENTS.md missing or malformed"
fi

if [ -f "my-new-app/ROADMAP.md" ] && grep -q "my-new-app - Project Roadmap" "my-new-app/ROADMAP.md"; then
  pass "ROADMAP.md generated correctly"
else
  fail "ROADMAP.md missing or malformed"
fi

if [ -f "my-new-app/docs/agents/current-state.md" ] && grep -q "Current Implementation State" "my-new-app/docs/agents/current-state.md"; then
  pass "current-state.md generated correctly"
else
  fail "current-state.md missing or malformed"
fi

if [ -f "my-new-app/docs/agents/progress.md" ] && grep -q "Agent Progress Updates" "my-new-app/docs/agents/progress.md"; then
  pass "progress.md generated correctly"
else
  fail "progress.md missing or malformed"
fi

if [ -f "my-new-app/.agents/hooks/commit-gate.sh" ] && \
   [ -f "my-new-app/.agents/hooks/checkpoint.sh" ] && \
   [ -f "my-new-app/.agents/hooks/spawn-budget.sh" ]; then
  pass "Hooks generated correctly during new"
else
  fail "Hooks missing or failed to generate during new"
fi

if [ -f "my-new-app/.cursor/rules/read-agents-md.md" ] && \
   [ -f "my-new-app/.cursor/rules/work-state-continuity.md" ]; then
  pass "Cursor rules generated correctly during new"
else
  fail "Cursor rules missing or failed to generate during new"
fi

if [ -f "my-new-app/tests/test-harness.sh" ] && [ -x "my-new-app/tests/test-harness.sh" ]; then
  pass "Test harness generated correctly during new"
else
  fail "Test harness missing or not executable"
fi

if [ -f "my-new-app/docs/agents/issue-tracker.md" ] && \
   [ -f "my-new-app/docs/agents/triage-labels.md" ] && \
   [ -f "my-new-app/docs/agents/domain.md" ]; then
  pass "Agent doc guides generated correctly during new"
else
  fail "Agent doc guides missing or failed to generate during new"
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
echo "# Existing Project" > AGENTS.md
git add README.md AGENTS.md
git commit -q -m "Add README and AGENTS.md"

assert_exit "azg apply exits 0" 0 "${AZG}" apply . >/dev/null

if [ -d ".agents/hooks" ] && [ -f ".agents/hooks.json" ]; then
  pass "Apply injected hooks"
else
  fail "Apply failed to inject hooks"
fi

if [ -f "AGENTS.md" ] && grep -q "AZG:MANAGED:START" "AGENTS.md"; then
  pass "Apply injected AGENTS.md managed block"
else
  fail "Apply failed to inject AGENTS.md managed block"
fi

if [ -f "ROADMAP.md" ] && [ -f "docs/agents/current-state.md" ] && [ -f "docs/agents/progress.md" ]; then
  pass "Apply created tracking templates"
else
  fail "Apply failed to create tracking templates"
fi

if [ -f ".agents/spawn-budget.json" ] && [ -f ".agents/session-handoff.md" ] && [ -f ".vscode/settings.json" ] && [ -f "tests/test-harness.sh" ]; then
  pass "Apply copied budget, handoff, vscode settings, and test harness"
else
  fail "Apply failed to copy budget, handoff, vscode settings, or test harness"
fi

# 3a. Tracker validation
assert_exit "azg apply with invalid tracker fails" 1 "${AZG}" apply . --tracker invalid

# 3b. Dry-run verification
# Prepare a fresh repo to test dry-run
cd "${TEMP_WORKSPACE}"
mkdir -p dryrun-app
cd dryrun-app
git init -q
git commit --allow-empty -m "Init" -q
echo "# User Customized AGENTS.md" > AGENTS.md

_dryrun_out="$(${AZG} apply . --dry-run)"
assert_exit "azg apply --dry-run exits 0" 0 echo "$?"

# Assert dry-run output contains creation actions and diff
if echo "${_dryrun_out}" | grep -q "\[CREATE\] docs/agents/issue-tracker.md" && \
   echo "${_dryrun_out}" | grep -q "\[COPY\] .agents/hooks/commit-gate.sh" && \
   echo "${_dryrun_out}" | grep -q "<!-- AZG:MANAGED:START -->"; then
  pass "dry-run displays actions and unified diff"
else
  fail "dry-run missing action summary or diff" "got: ${_dryrun_out}"
fi

# Assert no files actually written during dry-run
if [ ! -d ".agents" ] && [ ! -f "docs/agents/issue-tracker.md" ] && [ ! -f "ROADMAP.md" ]; then
  pass "dry-run does not modify target workspace"
else
  fail "dry-run modified target workspace"
fi

# 3c. Overwrite issue-tracker based on tracker flag
cd "${TEMP_WORKSPACE}"
# GitLab tracker test
mkdir -p gitlab-app
cd gitlab-app
git init -q
git commit --allow-empty -m "Init" -q
"${AZG}" apply . --tracker gitlab >/dev/null
assert_file_contains "GitLab issue-tracker used" "docs/agents/issue-tracker.md" "GitLab"

# Local tracker test
cd "${TEMP_WORKSPACE}"
mkdir -p local-app
cd local-app
git init -q
git commit --allow-empty -m "Init" -q
"${AZG}" apply . --tracker local >/dev/null
assert_file_contains "Local issue-tracker used" "docs/agents/issue-tracker.md" "Local Markdown"

# None tracker test
cd "${TEMP_WORKSPACE}"
mkdir -p none-app
cd none-app
git init -q
git commit --allow-empty -m "Init" -q
"${AZG}" apply . --tracker none >/dev/null
assert_file_contains "None issue-tracker used" "docs/agents/issue-tracker.md" "Issue tracker: None"

# 3d. Idempotency test (no block duplication and updates block only)
cd "${TEMP_WORKSPACE}"
mkdir -p idempotency-app
cd idempotency-app
git init -q
git commit --allow-empty -m "Init" -q
echo -e "# User custom header\n\n<!-- AZG:MANAGED:START -->\nOld content\n<!-- AZG:MANAGED:END -->\n\n# User custom footer" > AGENTS.md
git add AGENTS.md
git commit -m "commit agents" -q

# Run apply once
"${AZG}" apply . >/dev/null

# Assert block replaced but user prose untouched
if grep -q "# User custom header" AGENTS.md && \
   grep -q "# User custom footer" AGENTS.md && \
   grep -q "Session start" AGENTS.md; then
  pass "apply merges block without clobbering user prose"
else
  fail "apply clobbered user prose or failed to update block" "$(cat AGENTS.md)"
fi

# Assert no duplicated blocks
_start_count=$(grep -c "<!-- AZG:MANAGED:START -->" AGENTS.md)
if [ "${_start_count}" -eq 1 ]; then
  pass "apply is idempotent (no block duplication)"
else
  fail "apply duplicated managed block" "count: ${_start_count}"
fi

test_summary

