#!/usr/bin/env bash
# tests/test-azg.sh — Integration test for setup, new, and apply in a temp HOME

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

TEMP_HOME="$(azg_mktemp_d "tmp_azg_integration-home-XXXXXX")"
TEMP_WORKSPACE="$(azg_mktemp_d "tmp_azg_integration-workspace-XXXXXX")"

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

# 1b. Active vendor install (default curated set with prerequisites)
if [ -d "${TEMP_HOME}/.gemini/config/skills/tdd" ] && \
   [ -d "${TEMP_HOME}/.gemini/config/skills/grill-with-docs" ] && \
   [ -d "${TEMP_HOME}/.gemini/config/skills/retro" ] && \
   [ -d "${TEMP_HOME}/.gemini/config/skills/writing-for-agents" ]; then
  pass "setup copies active skills (tdd, grill-with-docs, retro, writing-for-agents)"
else
  fail "setup missing some skills"
fi

if [ -d "${TEMP_HOME}/.gemini/config/skills/setup-matt-pocock-skills" ] && [ -d "${TEMP_HOME}/.gemini/config/skills/implement" ]; then
  pass "setup installs active vendor set including setup-matt-pocock-skills and implement"
else
  fail "setup missing previously non-core skills"
fi

# 1c. Smart Setup Sync verification
_setup_sync_out="$("${AZG}" setup 2>&1)"
if echo "${_setup_sync_out}" | grep -q "Smart Sync: VENDOR.lock commits unchanged"; then
  pass "setup smart sync skips copying skills when lock commit is unchanged"
else
  fail "setup smart sync failed to skip skill copying" "got: ${_setup_sync_out}"
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
   [ ! -f "my-new-app/.agents/hooks/checkpoint.sh" ] && \
   [ ! -f "my-new-app/.cursor/hooks/stop-checkpoint.sh" ] && \
   [ ! -f "my-new-app/.agents/hooks/spawn-budget.sh" ]; then
  pass "Hooks generated correctly during new"
else
  fail "Hooks missing or failed to generate during new"
fi

if [ -f "my-new-app/.cursor/rules/read-agents-md.mdc" ] && \
   [ ! -f "my-new-app/.cursor/rules/work-state-continuity.mdc" ] && \
   [ ! -f "my-new-app/.cursor/rules/domain-vocabulary.mdc" ] && \
   [ -f "my-new-app/.cursor/rules/progress-updates.mdc" ] && \
   [ -f "my-new-app/.agents/skills/progress-updates/SKILL.md" ] && \
   [ ! -d "my-new-app/.agents/skills/domain-vocabulary" ] && \
   [ -f "my-new-app/.cursor/hooks.json" ]; then
  pass "Cursor rules, continuity skills, and hooks generated correctly during new"
else
  fail "Cursor rules/hooks/skills missing or failed to generate during new"
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

if [ -f ".vscode/settings.json" ] && [ -f "tests/test-harness.sh" ] && \
   [ ! -f ".agents/spawn-budget.json" ] && \
   [ ! -f "task.md" ] && [ ! -f ".agents/session-handoff.md" ]; then
  pass "Apply copied vscode settings and test harness (no seeded task.md/handoff)"
else
  fail "Apply failed to copy vscode/test harness or seeded leftover task.md/handoff"
fi

# Retired template Cursor rule must be removed on reapply
mkdir -p .cursor/rules
printf 'orphan\n' > .cursor/rules/work-state-continuity.mdc
assert_exit "azg apply reapply exits 0" 0 "${AZG}" apply . >/dev/null
assert_file_not_exists "reapply removes retired work-state-continuity.mdc" \
  ".cursor/rules/work-state-continuity.mdc"
# Retired domain-vocabulary must be removed on reapply
mkdir -p .cursor/rules .agents/skills/domain-vocabulary
printf 'orphan\n' > .cursor/rules/domain-vocabulary.mdc
printf 'orphan\n' > .agents/skills/domain-vocabulary/SKILL.md
assert_exit "azg apply retires domain-vocabulary" 0 "${AZG}" apply . >/dev/null
assert_file_not_exists "reapply removes retired domain-vocabulary.mdc" \
  ".cursor/rules/domain-vocabulary.mdc"
assert_dir_not_exists "reapply removes retired domain-vocabulary skill" \
  ".agents/skills/domain-vocabulary"
# Retired spawn-budget must be removed on reapply
mkdir -p .agents/hooks
printf 'orphan\n' > .agents/hooks/spawn-budget.sh
printf '{"max_spawns":1}\n' > .agents/spawn-budget.json
assert_exit "azg apply retires spawn-budget" 0 "${AZG}" apply . >/dev/null
assert_file_not_exists "reapply removes retired spawn-budget.sh" \
  ".agents/hooks/spawn-budget.sh"
assert_file_not_exists "reapply removes retired spawn-budget.json" \
  ".agents/spawn-budget.json"
# Retired Stop/PreCompact must be removed on reapply
mkdir -p .agents/hooks .cursor/hooks
printf 'orphan\n' > .agents/hooks/checkpoint.sh
printf 'orphan\n' > .agents/hooks/checkpoint-scan.sh
printf 'orphan\n' > .agents/hooks/pre-compact.sh
printf 'orphan\n' > .cursor/hooks/stop-checkpoint.sh
printf 'orphan\n' > .cursor/hooks/pre-compact.sh
assert_exit "azg apply retires Stop/PreCompact hooks" 0 "${AZG}" apply . >/dev/null
assert_file_not_exists "reapply removes retired checkpoint.sh" \
  ".agents/hooks/checkpoint.sh"
assert_file_not_exists "reapply removes retired checkpoint-scan.sh" \
  ".agents/hooks/checkpoint-scan.sh"
assert_file_not_exists "reapply removes retired agy pre-compact.sh" \
  ".agents/hooks/pre-compact.sh"
assert_file_not_exists "reapply removes retired stop-checkpoint.sh" \
  ".cursor/hooks/stop-checkpoint.sh"
assert_file_not_exists "reapply removes retired Cursor pre-compact.sh" \
  ".cursor/hooks/pre-compact.sh"
assert_file_not_contains "reapply strips Stop from hooks.json" \
  ".agents/hooks.json" '"Stop"'
assert_file_not_contains "reapply strips preCompact from Cursor hooks.json" \
  ".cursor/hooks.json" '"preCompact"'
if command -v jq >/dev/null 2>&1; then
  jq '.["safety-gate"].Stop = [{"matcher":"*","hooks":[{"type":"command","command":"./hooks/checkpoint.sh"}]}]' \
    .agents/hooks.json > .agents/hooks.json.azg-stop || true
  if [ -f .agents/hooks.json.azg-stop ]; then
    mv .agents/hooks.json.azg-stop .agents/hooks.json
    assert_exit "azg apply strips leftover Stop key" 0 "${AZG}" apply . >/dev/null
    assert_file_not_contains "reapply deletes leftover Stop key" \
      ".agents/hooks.json" '"Stop"'
  fi
fi
# Migrate leftover task.md + unused session-handoff
printf '# Active Task: Stop Hook Fix\n' > task.md
cat > .agents/session-handoff.md <<'EOF'
# Session Handoff (SFDBN)

- **Status:** [Current status of implementation/session]
- **Files:** [Key files modified or being worked on]
- **Decisions:** [Decisions made in the session]
- **Blocked:** [Blockers, if any]
- **Next:** [Actionable next steps for the next agent/session]
EOF
assert_exit "azg apply migrates task.md" 0 "${AZG}" apply . >/dev/null
assert_file_not_exists "apply removes task.md after migrate" "task.md"
assert_file_exists "apply writes work packet from task.md heading" \
  ".agents/work-packets/stop-hook-fix.md"
assert_file_not_exists "apply removes unused session-handoff template" \
  ".agents/session-handoff.md"
# Collision: same heading must not clobber an existing packet
printf '# Active Task: Stop Hook Fix\n' > task.md
assert_exit "azg apply unique-names colliding task.md" 0 "${AZG}" apply . >/dev/null
assert_file_exists "original packet kept on collision" \
  ".agents/work-packets/stop-hook-fix.md"
assert_file_exists "colliding task.md gets unique packet path" \
  ".agents/work-packets/stop-hook-fix-2.md"
assert_file_not_exists "colliding task.md removed" "task.md"
# Filled session-handoff merges into a new packet
cat > .agents/session-handoff.md <<'EOF'
# Session Handoff (SFDBN)

- **Status:** Real device notes
- **Files:** foo.sh
- **Decisions:** keep packets
- **Blocked:** none
- **Next:** apply migrate
EOF
assert_exit "azg apply merges filled session-handoff" 0 "${AZG}" apply . >/dev/null
assert_file_not_exists "apply removes filled session-handoff" \
  ".agents/session-handoff.md"
assert_file_exists "apply writes imported-handoff packet" \
  ".agents/work-packets/imported-handoff.md"
if grep -q "Real device notes" ".agents/work-packets/imported-handoff.md"; then
  pass "imported packet contains filled handoff body"
else
  fail "imported packet missing filled handoff body"
fi
if [ -f "AGENTS.md" ] && grep -q "## Session start" "AGENTS.md"; then
  pass "Session start remains in AGENTS.md after continuity rule retire"
else
  fail "AGENTS.md Session start missing after reapply"
fi
if [ -f "AGENTS.md" ] && grep -q "## Placeholder fill" "AGENTS.md"; then
  pass "Placeholder fill lives in project AGENTS managed block"
else
  fail "AGENTS.md missing Placeholder fill after apply"
fi
if [ -f "AGENTS.md" ] && grep -q "## Harness Safety" "AGENTS.md" && grep -q "## Work State & Checkpoints" "AGENTS.md"; then
  pass "Managed block has Harness Safety and Work State & Checkpoints"
else
  fail "AGENTS.md managed headings missing after apply"
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
   echo "${_dryrun_out}" | grep -q "\[CREATE\] .agents/hooks/commit-gate.sh" && \
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

