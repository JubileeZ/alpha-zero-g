#!/usr/bin/env bash
set -e

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

test_summary
