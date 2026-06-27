#!/usr/bin/env bash
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

run_test() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd"; then
    pass "$name"
  else
    fail "$name"
  fi
}

# Test 1: Templates exist
run_test "AGENTS.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/AGENTS.md.tmpl\" ]"
run_test "ROADMAP.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/ROADMAP.md.tmpl\" ]"
run_test "current-state.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/docs/agents/current-state.md.tmpl\" ]"
run_test "progress.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/docs/agents/progress.md.tmpl\" ]"

# Test 2: Templates contain expected placeholders
run_test "AGENTS.md.tmpl has {{PROJECT_NAME}}" "grep -q '{{PROJECT_NAME}}' \"$REPO_ROOT/templates/project/AGENTS.md.tmpl\""
run_test "AGENTS.md.tmpl has {{BUILD_COMMANDS}}" "grep -q '{{BUILD_COMMANDS}}' \"$REPO_ROOT/templates/project/AGENTS.md.tmpl\""
run_test "ROADMAP.md.tmpl has {{PROJECT_NAME}}" "grep -q '{{PROJECT_NAME}}' \"$REPO_ROOT/templates/project/ROADMAP.md.tmpl\""
run_test "current-state.md.tmpl has {{BUILD_COMMANDS}}" "grep -q '{{BUILD_COMMANDS}}' \"$REPO_ROOT/templates/project/docs/agents/current-state.md.tmpl\""

# Test 3: Hook Integration Tests in isolated environment
TEMP_TEST_DIR="$(mktemp -d "${PWD}/tmp_azg_phase5-XXXXXX")"
trap 'rm -rf "${TEMP_TEST_DIR}"' EXIT

cd "${TEMP_TEST_DIR}"
mkdir -p .agents/hooks tests
cp "$REPO_ROOT/templates/project/.agents/hooks/commit-gate.sh" .agents/hooks/
cp "$REPO_ROOT/templates/project/.agents/hooks/spawn-budget.sh" .agents/hooks/

# commit-gate testing
# 1. Success case: test-harness returns 0
printf '#!/usr/bin/env bash\nexit 0\n' > tests/test-harness.sh
chmod +x tests/test-harness.sh

_res_allow=$(echo '{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"feat: foo\""}}}' | bash .agents/hooks/commit-gate.sh)
if echo "${_res_allow}" | jq -e '.decision == "allow"' >/dev/null; then
  pass "commit-gate allows commit when test-harness passes"
else
  fail "commit-gate denied commit unexpectedly" "got: ${_res_allow}"
fi

# 2. Failure case: test-harness returns 1
printf '#!/usr/bin/env bash\necho "Lint error"\nexit 1\n' > tests/test-harness.sh
_res_deny=$(echo '{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"feat: foo\""}}}' | bash .agents/hooks/commit-gate.sh)
if echo "${_res_deny}" | jq -e '.decision == "deny"' >/dev/null && echo "${_res_deny}" | jq -e '.reason | contains("Lint error")' >/dev/null; then
  pass "commit-gate denies commit and shows harness output when test-harness fails"
else
  fail "commit-gate failed to deny commit or output error" "got: ${_res_deny}"
fi

# Reset test-harness to pass for subsequent cleanup tests
printf '#!/usr/bin/env bash\nexit 0\n' > tests/test-harness.sh

# 3. Cleanup case: task.md exists with all items completed, but implementation_plan.md exists -> deny
echo "- [x] task 1" > task.md
touch implementation_plan.md
_res_cleanup_deny=$(echo '{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"feat: foo\""}}}' | bash .agents/hooks/commit-gate.sh)
if echo "${_res_cleanup_deny}" | jq -e '.decision == "deny"' >/dev/null && echo "${_res_cleanup_deny}" | jq -e '.reason | contains("transient files")' >/dev/null; then
  pass "commit-gate denies commit when task complete but transient plans exist"
else
  fail "commit-gate failed to deny commit when transient plans exist on completed task" "got: ${_res_cleanup_deny}"
fi

# 4. Cleanup case: task.md exists with unchecked items, and implementation_plan.md exists -> allow
echo "- [ ] task 1" > task.md
_res_cleanup_allow=$(echo '{"toolCall":{"name":"run_command","args":{"CommandLine":"git commit -m \"feat: foo\""}}}' | bash .agents/hooks/commit-gate.sh)
if echo "${_res_cleanup_allow}" | jq -e '.decision == "allow"' >/dev/null; then
  pass "commit-gate allows commit when task is in-progress and transient plans exist"
else
  fail "commit-gate denied commit when task in-progress and transient plans exist" "got: ${_res_cleanup_allow}"
fi

# Clean up files created for testing
rm -f task.md implementation_plan.md

# spawn-budget testing
# 1. Reset spawn budget
_res_reset=$(bash .agents/hooks/spawn-budget.sh --reset)
if [ -f .agents/spawn-state.json ] && echo "${_res_reset}" | jq -e '.decision == "allow"' >/dev/null; then
  pass "spawn-budget resets and initializes successfully"
else
  fail "spawn-budget reset failed"
fi

# 2. Allow within spawns budget (max_spawns=3)
# Spawn 1
_res1=$(echo '{"session_id":"sess1","subagent_id":"sub1"}' | bash .agents/hooks/spawn-budget.sh)
# Spawn 2
_res2=$(echo '{"session_id":"sess1","subagent_id":"sub2"}' | bash .agents/hooks/spawn-budget.sh)
# Spawn 3
_res3=$(echo '{"session_id":"sess1","subagent_id":"sub3"}' | bash .agents/hooks/spawn-budget.sh)

if echo "${_res1}" | jq -e '.decision == "allow"' >/dev/null && \
   echo "${_res2}" | jq -e '.decision == "allow"' >/dev/null && \
   echo "${_res3}" | jq -e '.decision == "allow"' >/dev/null; then
  pass "spawn-budget allows spawns within budget limits"
else
  fail "spawn-budget denied spawns within budget" "res1: ${_res1}, res2: ${_res2}, res3: ${_res3}"
fi

# Spawn 4 should be denied (max_spawns=3 exceeded)
_res4=$(echo '{"session_id":"sess1","subagent_id":"sub4"}' | bash .agents/hooks/spawn-budget.sh)
if echo "${_res4}" | jq -e '.decision == "deny"' >/dev/null && echo "${_res4}" | jq -e '.reason | contains("Spawn budget exceeded")' >/dev/null; then
  pass "spawn-budget denies spawn when max_spawns is exceeded"
else
  fail "spawn-budget failed to deny spawn on exceed limit" "got: ${_res4}"
fi

# 3. Spawn depth limit (max_depth=2)
# Reset
bash .agents/hooks/spawn-budget.sh --reset >/dev/null
# Write a budget json setting max_spawns=10, max_depth=2 for testing depth explicitly
printf '{"max_spawns": 10, "max_depth": 2}' > .agents/spawn-budget.json

# Session root depth is 0. 
# Spawn child at depth 1
_depth1=$(echo '{"session_id":"root","subagent_id":"child1"}' | bash .agents/hooks/spawn-budget.sh)
# Spawn child at depth 2 (parent session_id is child1, which has depth 1)
_depth2=$(echo '{"session_id":"child1","subagent_id":"child2"}' | bash .agents/hooks/spawn-budget.sh)
# Spawn child at depth 3 (parent session_id is child2, which has depth 2) - should be denied
_depth3=$(echo '{"session_id":"child2","subagent_id":"child3"}' | bash .agents/hooks/spawn-budget.sh)

if echo "${_depth1}" | jq -e '.decision == "allow"' >/dev/null && \
   echo "${_depth2}" | jq -e '.decision == "allow"' >/dev/null && \
   echo "${_depth3}" | jq -e '.decision == "deny"' >/dev/null && \
   echo "${_depth3}" | jq -e '.reason | contains("depth")' >/dev/null; then
  pass "spawn-budget enforces max_depth limit successfully"
else
  fail "spawn-budget depth limit enforcement failed" "depth1: ${_depth1}, depth2: ${_depth2}, depth3: ${_depth3}"
fi

test_summary

