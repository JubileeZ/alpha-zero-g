#!/usr/bin/env bash
set -e

# Setup test environment
REPO_ROOT="/Users/jubilee/Alpha-Zero-G"

echo "--- Phase 5: Template Generation Tests ---"
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd"; then
    echo "✅ PASS: $name"
    ((TESTS_PASSED++)) || true
  else
    echo "❌ FAIL: $name"
    ((TESTS_FAILED++)) || true
  fi
}

# Test 1: GEMINI.md.tmpl exists
run_test "GEMINI.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/GEMINI.md.tmpl\" ]"

# Test 2: AGENTS.md.tmpl exists
run_test "AGENTS.md.tmpl exists" "[ -f \"$REPO_ROOT/templates/project/AGENTS.md.tmpl\" ]"

# Test 3: GEMINI.md.tmpl contains expected placeholders
run_test "GEMINI.md.tmpl has {{PROJECT_NAME}}" "grep -q '{{PROJECT_NAME}}' \"$REPO_ROOT/templates/project/GEMINI.md.tmpl\""
run_test "GEMINI.md.tmpl has {{BUILD_COMMANDS}}" "grep -q '{{BUILD_COMMANDS}}' \"$REPO_ROOT/templates/project/GEMINI.md.tmpl\""

echo "----------------------------------------"
if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "✅ All $TESTS_PASSED Phase 5 tests passed!"
  exit 0
else
  echo "❌ $TESTS_FAILED Phase 5 tests failed."
  exit 1
fi
