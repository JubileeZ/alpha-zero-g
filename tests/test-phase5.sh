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

# Test 1: GEMINI.md.tmpl exists
run_test "GEMINI.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/GEMINI.md.tmpl\" ]"

# Test 2: AGENTS.md.tmpl exists
run_test "AGENTS.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/AGENTS.md.tmpl\" ]"

# Test 3: GEMINI.md.tmpl contains expected placeholders
run_test "GEMINI.md.tmpl has {{PROJECT_NAME}}" "grep -q '{{PROJECT_NAME}}' \"$REPO_ROOT/templates/project/GEMINI.md.tmpl\""
run_test "GEMINI.md.tmpl has {{BUILD_COMMANDS}}" "grep -q '{{BUILD_COMMANDS}}' \"$REPO_ROOT/templates/project/GEMINI.md.tmpl\""

test_summary
