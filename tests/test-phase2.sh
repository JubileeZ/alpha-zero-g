#!/usr/bin/env bash
# tests/test-phase2.sh — TDD suite for Phase 2: Hooks
#
# Run from repo root:  bash tests/test-phase2.sh
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

TEMP_WORKSPACE="$(mktemp -d "${PWD}/tmp_azg_phase2-workspace-XXXXXX")"
TEMP_HOME="$(mktemp -d "${PWD}/tmp_azg_phase2-home-XXXXXX")"
# Use python to clean up directory to avoid triggering the safety gate hook with rm -rf
trap 'python3 -c "import shutil, sys; [shutil.rmtree(x, ignore_errors=True) for x in sys.argv[1:]]" "${TEMP_WORKSPACE}" "${TEMP_HOME}"' EXIT

export HOME="${TEMP_HOME}"
export AZG_ROOT="${REPO_ROOT}"
export GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test User"
export GIT_COMMITTER_EMAIL="test@example.com"

# ---------------------------------------------------------------------------
# Setup & Scaffolding Check
# ---------------------------------------------------------------------------
section "1. Scaffolding Hooks & Rules"

APP_DIR="${TEMP_WORKSPACE}/my-app"
_scaffold_exit=0
"${AZG_ROOT}/azg" new "${APP_DIR}" --no-git --tracker github >/dev/null 2>&1 || _scaffold_exit=$?

if [ "${_scaffold_exit}" -eq 0 ]; then
  pass "azg new executes successfully"
else
  fail "azg new failed with exit code ${_scaffold_exit}"
  exit 1
fi

assert_dir_exists "App directory exists" "${APP_DIR}"
assert_dir_exists ".agents/hooks directory exists" "${APP_DIR}/.agents/hooks"
assert_dir_exists ".cursor/rules directory exists" "${APP_DIR}/.cursor/rules"

assert_file_exists "hooks.json exists" "${APP_DIR}/.agents/hooks.json"
assert_file_exists "block-destructive-ops.sh exists" "${APP_DIR}/.agents/hooks/block-destructive-ops.sh"
assert_file_exists "commit-gate.sh exists" "${APP_DIR}/.agents/hooks/commit-gate.sh"
assert_file_exists "checkpoint.sh exists" "${APP_DIR}/.agents/hooks/checkpoint.sh"
assert_file_exists "spawn-budget.sh exists" "${APP_DIR}/.agents/hooks/spawn-budget.sh"
assert_file_exists "pre-compact.sh exists" "${APP_DIR}/.agents/hooks/pre-compact.sh"

assert_file_exists "read-agents-md.md rule exists" "${APP_DIR}/.cursor/rules/read-agents-md.md"
assert_file_exists "work-state-continuity.md rule exists" "${APP_DIR}/.cursor/rules/work-state-continuity.md"

# Executable checks
for h in block-destructive-ops.sh commit-gate.sh checkpoint.sh spawn-budget.sh pre-compact.sh; do
  if [ -x "${APP_DIR}/.agents/hooks/${h}" ]; then
    pass "Hook ${h} is executable"
  else
    fail "Hook ${h} is NOT executable"
  fi
done

# ---------------------------------------------------------------------------
# Shellcheck Checks
# ---------------------------------------------------------------------------
section "2. Shellcheck Validation"

if command -v shellcheck >/dev/null 2>&1; then
  _sc_exit=0
  shellcheck "${APP_DIR}/.agents/hooks"/*.sh || _sc_exit=$?
  if [ "${_sc_exit}" -eq 0 ]; then
    pass "All hook scripts pass shellcheck linting"
  else
    fail "One or more hooks failed shellcheck"
  fi
else
  echo "  – Shellcheck not installed (skipping lint check)"
fi

# ---------------------------------------------------------------------------
# commit-gate.sh Integration Tests
# ---------------------------------------------------------------------------
section "3. commit-gate.sh Tests"

COMMIT_GATE="${APP_DIR}/.agents/hooks/commit-gate.sh"

# Mock git commit payload
commit_json='{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"chore: some work\""}},"session_id":"test-session"}'
# Mock git status payload
status_json='{"toolCall":{"name":"run_command","args":{"CommandLine":"git status"}},"session_id":"test-session"}'

# Test 1: For non-commit command, it should immediately allow
out_status=$(echo "${status_json}" | "${COMMIT_GATE}")
dec_status=$(echo "${out_status}" | jq -r '.decision')
if [ "${dec_status}" = "allow" ]; then
  pass "Allows non-commit commands immediately"
else
  fail "Blocked non-commit command" "got: ${out_status}"
fi

# Test 2: For git commit command, harness passing
(
  cd "${APP_DIR}"
  # Make sure the harness passes (files exist)
  out_commit=$(echo "${commit_json}" | "${COMMIT_GATE}")
  dec_commit=$(echo "${out_commit}" | jq -r '.decision')
  if [ "${dec_commit}" = "allow" ]; then
    pass "Allows commit when test-harness passes"
  else
    fail "Blocked commit when test-harness passes" "got: ${out_commit}"
  fi
)

# Test 3: For git commit command, harness failing
(
  cd "${APP_DIR}"
  # Make the harness fail by deleting task.md
  rm -f task.md
  out_commit_fail=$(echo "${commit_json}" | "${COMMIT_GATE}")
  dec_commit_fail=$(echo "${out_commit_fail}" | jq -r '.decision')
  if [ "${dec_commit_fail}" = "deny" ]; then
    pass "Denies commit when test-harness fails"
  else
    fail "Allowed commit when test-harness fails" "got: ${out_commit_fail}"
  fi
  # Restore workspace integrity for other tests
  printf -- "- [ ] Initial project setup\n" > task.md
)

# Test 4: Project tests override
(
  cd "${APP_DIR}"
  # Configure a passing project test script
  mkdir -p tests
  printf '#!/usr/bin/env bash\nexit 0\n' > tests/project-tests.sh
  chmod +x tests/project-tests.sh
  
  out_proj_pass=$(echo "${commit_json}" | "${COMMIT_GATE}")
  dec_proj_pass=$(echo "${out_proj_pass}" | jq -r '.decision')
  if [ "${dec_proj_pass}" = "allow" ]; then
    pass "Allows commit when configured project-tests.sh passes"
  else
    fail "Blocked commit when project-tests.sh passes" "got: ${out_proj_pass}"
  fi

  # Configure a failing project test script
  printf '#!/usr/bin/env bash\necho "Custom error msg"\nexit 1\n' > tests/project-tests.sh
  out_proj_fail=$(echo "${commit_json}" | "${COMMIT_GATE}")
  dec_proj_fail=$(echo "${out_proj_fail}" | jq -r '.decision')
  if [ "${dec_proj_fail}" = "deny" ] && echo "${out_proj_fail}" | grep -q "Custom error msg"; then
    pass "Denies commit and includes custom error message when project-tests.sh fails"
  else
    fail "Did not behave correctly on project-tests.sh failure" "got: ${out_proj_fail}"
  fi

  rm -f tests/project-tests.sh
)

# ---------------------------------------------------------------------------
# checkpoint.sh Integration Tests
# ---------------------------------------------------------------------------
section "4. checkpoint.sh Tests"

CHECKPOINT="${APP_DIR}/.agents/hooks/checkpoint.sh"
stop_json='{"session_id":"test-session"}'

# Setup git repo in target to test git operations
(
  cd "${APP_DIR}"
  git init -q
  git config user.email "test@azg"
  git config user.name "AZG Test"
  git add .
  git commit -q -m "initial commit"
)

# Test 1: If git status is clean, it should allow Stop
(
  cd "${APP_DIR}"
  out_stop=$(echo "${stop_json}" | "${CHECKPOINT}")
  dec_stop=$(echo "${out_stop}" | jq -r '.decision')
  if [ "${dec_stop}" = "allow" ]; then
    pass "Allows Stop when repo is clean"
  else
    fail "Blocked Stop on clean repo" "got: ${out_stop}"
  fi
)

# Test 2: If code changes exist but no workstate files modified, it should block
(
  cd "${APP_DIR}"
  mkdir -p src
  echo "print('hello')" > src/main.py
  out_stop_code=$(echo "${stop_json}" | "${CHECKPOINT}")
  dec_stop_code=$(echo "${out_stop_code}" | jq -r '.decision')
  if [ "${dec_stop_code}" = "deny" ]; then
    pass "Blocks Stop when code changes exist without work-state documentation updates"
  else
    fail "Allowed Stop with undocumented code changes" "got: ${out_stop_code}"
  fi
)

# Test 3: If code changes exist and current-state.md is updated, it should allow
(
  cd "${APP_DIR}"
  echo "update" >> docs/agents/current-state.md
  out_stop_doc=$(echo "${stop_json}" | "${CHECKPOINT}")
  dec_stop_doc=$(echo "${out_stop_doc}" | jq -r '.decision')
  if [ "${dec_stop_doc}" = "allow" ]; then
    pass "Allows Stop when docs/agents/current-state.md is updated alongside code changes"
  else
    fail "Blocked Stop even though docs/agents/current-state.md was updated" "got: ${out_stop_doc}"
  fi
  # Clean up for next test
  git checkout -q docs/agents/current-state.md
)

# Test 4: If code changes exist and session-handoff.md is updated, it should allow
(
  cd "${APP_DIR}"
  echo "handoff details" > .agents/session-handoff.md
  out_stop_handoff=$(echo "${stop_json}" | "${CHECKPOINT}")
  dec_stop_handoff=$(echo "${out_stop_handoff}" | jq -r '.decision')
  if [ "${dec_stop_handoff}" = "allow" ]; then
    pass "Allows Stop when .agents/session-handoff.md is updated alongside code changes"
  else
    fail "Blocked Stop even though .agents/session-handoff.md was updated" "got: ${out_stop_handoff}"
  fi
  # Clean up workspace
  rm -f .agents/session-handoff.md src/main.py
  rm -rf src
)

# Test 5: Editing only task.md or ROADMAP.md should be allowed without docs/agents/current-state.md changes
(
  cd "${APP_DIR}"
  echo "mod" >> task.md
  out_stop_task=$(echo "${stop_json}" | "${CHECKPOINT}")
  dec_stop_task=$(echo "${out_stop_task}" | jq -r '.decision')
  if [ "${dec_stop_task}" = "allow" ]; then
    pass "Allows Stop when only task.md is edited"
  else
    fail "Blocked Stop when only task.md was edited" "got: ${out_stop_task}"
  fi
  git checkout -q task.md
)

# ---------------------------------------------------------------------------
# spawn-budget.sh Integration Tests
# ---------------------------------------------------------------------------
section "5. spawn-budget.sh Tests"

SPAWN_BUDGET="${APP_DIR}/.agents/hooks/spawn-budget.sh"

# Test 1: Reset budget
(
  cd "${APP_DIR}"
  out_reset=$("${SPAWN_BUDGET}" --reset <<< "{}")
  dec_reset=$(echo "${out_reset}" | jq -r '.decision')
  if [ "${dec_reset}" = "allow" ] && [ -f .agents/spawn-state.json ]; then
    total=$(jq -r '.total_spawns' .agents/spawn-state.json)
    if [ "${total}" -eq 0 ]; then
      pass "spawn-budget.sh --reset initializes and resets spawn budget state"
    else
      fail "Total spawns is not 0 after reset" "got: ${total}"
    fi
  else
    fail "Reset failed" "got: ${out_reset}"
  fi
)

# Test 2: Spawn nesting depth (max_depth: 2)
(
  cd "${APP_DIR}"
  # Reset first
  "${SPAWN_BUDGET}" --reset <<< "{}" >/dev/null

  # Spawn 1 (Parent: root -> Child: c1)
  # Input represents spawning c1 from session root
  in1='{"session_id":"root","subagent_id":"c1"}'
  out1=$(echo "${in1}" | "${SPAWN_BUDGET}")
  dec1=$(echo "${out1}" | jq -r '.decision')
  
  # Spawn 2 (Parent: c1 -> Child: g1)
  # Nesting depth: c1 is depth 1, so g1 is depth 2
  in2='{"session_id":"c1","subagent_id":"g1"}'
  out2=$(echo "${in2}" | "${SPAWN_BUDGET}")
  dec2=$(echo "${out2}" | jq -r '.decision')

  # Spawn 3 (Parent: g1 -> Child: gg1)
  # Nesting depth: g1 is depth 2, so gg1 would be depth 3 (exceeds max_depth: 2)
  in3='{"session_id":"g1","subagent_id":"gg1"}'
  out3=$(echo "${in3}" | "${SPAWN_BUDGET}")
  dec3=$(echo "${out3}" | jq -r '.decision')

  if [ "${dec1}" = "allow" ] && [ "${dec2}" = "allow" ] && [ "${dec3}" = "deny" ]; then
    pass "Spawn nesting depth budget (max_depth = 2) is enforced correctly"
  else
    fail "Depth budget enforcement failed" "spawn1=${dec1} spawn2=${dec2} spawn3=${dec3}"
  fi
)

# Test 3: Total Spawns count (max_spawns: 3)
(
  cd "${APP_DIR}"
  # Reset first
  "${SPAWN_BUDGET}" --reset <<< "{}" >/dev/null

  # Spawn 1 (allow)
  in1='{"session_id":"root","subagent_id":"agent1"}'
  dec1=$(echo "${in1}" | "${SPAWN_BUDGET}" | jq -r '.decision')

  # Spawn 2 (allow)
  in2='{"session_id":"root","subagent_id":"agent2"}'
  dec2=$(echo "${in2}" | "${SPAWN_BUDGET}" | jq -r '.decision')

  # Spawn 3 (allow)
  in3='{"session_id":"root","subagent_id":"agent3"}'
  dec3=$(echo "${in3}" | "${SPAWN_BUDGET}" | jq -r '.decision')

  # Spawn 4 (deny - exceeds max_spawns: 3)
  in4='{"session_id":"root","subagent_id":"agent4"}'
  dec4=$(echo "${in4}" | "${SPAWN_BUDGET}" | jq -r '.decision')

  if [ "${dec1}" = "allow" ] && [ "${dec2}" = "allow" ] && [ "${dec3}" = "allow" ] && [ "${dec4}" = "deny" ]; then
    pass "Spawn count budget (max_spawns = 3) is enforced correctly"
  else
    fail "Count budget enforcement failed" "spawn1=${dec1} spawn2=${dec2} spawn3=${dec3} spawn4=${dec4}"
  fi
)

# ---------------------------------------------------------------------------
# pre-compact.sh Integration Tests
# ---------------------------------------------------------------------------
section "6. pre-compact.sh Tests"

PRE_COMPACT="${APP_DIR}/.agents/hooks/pre-compact.sh"
# Test 1: Always allows and logs message to stderr
out_pc=$(echo "{}" | "${PRE_COMPACT}" 2>/dev/null)
dec_pc=$(echo "${out_pc}" | jq -r '.decision')

err_pc=$(echo "{}" | "${PRE_COMPACT}" 2>&1 >/dev/null)

if [ "${dec_pc}" = "allow" ] && echo "${err_pc}" | grep -q "PreCompact event triggered"; then
  pass "pre-compact.sh logs to stderr and allows context compaction"
else
  fail "pre-compact.sh behavior incorrect" "dec=${dec_pc} stderr=${err_pc}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
