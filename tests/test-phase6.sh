#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

echo "--- Phase 6: Scaffold Engine Tests ---"
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

cd "$TEST_DIR"

export GIT_TERMINAL_PROMPT=0
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test User"
export GIT_COMMITTER_EMAIL="test@example.com"

# Test 1: Scaffold a python project with default options
# inputs for questions:
# Q2: stack -> 1 (python)
# Q3: custom build cmds -> n
# Q4.1: quality gate -> y
# Q4.2: auto lint -> y
# Q6: MCP -> 2 (GitHub)
# Q7: write AGENTS.md -> y
# Q8: git init -> y
printf "1\nn\ny\ny\n2\ny\ny\n" | "$REPO_ROOT/azg" new my-python-app > /dev/null

run_test "Project directory created" "[ -d \"$TEST_DIR/my-python-app\" ]"
run_test "GEMINI.md created" "[ -f \"$TEST_DIR/my-python-app/GEMINI.md\" ]"
run_test "AGENTS.md created" "[ -f \"$TEST_DIR/my-python-app/AGENTS.md\" ]"
run_test "Git repo initialized" "[ -d \"$TEST_DIR/my-python-app/.git\" ]"
run_test "Hooks copied" "[ -x \"$TEST_DIR/my-python-app/.agents/hooks/block-destructive-ops.sh\" ]"
run_test "quality-gate enabled in hooks.json" "[ \"\$(jq -r '.\"quality-gate\".enabled' \"$TEST_DIR/my-python-app/.agents/hooks.json\")\" = \"true\" ]"
run_test "auto-lint enabled in hooks.json" "[ \"\$(jq -r '.\"auto-lint\".enabled' \"$TEST_DIR/my-python-app/.agents/hooks.json\")\" = \"true\" ]"
run_test "MCP config has GitHub" "grep -q 'server-github' \"$TEST_DIR/my-python-app/.agents/mcp_config.json\""

# Test 2: Custom build commands, Node stack
# inputs:
# Q2: 2 (node)
# Q3: y (custom cmds)
#   step 1 cmd: npm run mylint
#   step 1 desc: My lint
#   step 2 cmd: npm run mytest
#   step 2 desc: My test
#   step 3 cmd: (empty to finish)
# Q4.1: n
# Q4.2: n
# Q6: 1 (None)
# Q7: n (no AGENTS.md)
# Q8: n (no git init)
printf "2\ny\nnpm run mylint\nMy lint\nnpm run mytest\nMy test\n\nn\nn\n1\nn\nn\n" | "$REPO_ROOT/azg" new my-node-app

run_test "Node project created" "[ -d \"$TEST_DIR/my-node-app\" ]"
run_test "AGENTS.md not created" "[ ! -f \"$TEST_DIR/my-node-app/AGENTS.md\" ]"
run_test "Git repo not initialized" "[ ! -d \"$TEST_DIR/my-node-app/.git\" ]"
if ! grep -q 'npm run mylint' "$TEST_DIR/my-node-app/GEMINI.md"; then
  echo "DEBUG: GEMINI.md contents:"
  cat "$TEST_DIR/my-node-app/GEMINI.md"
  run_test "Custom build commands in GEMINI.md" "false"
else
  run_test "Custom build commands in GEMINI.md" "true"
fi
run_test "Empty MCP config" "grep -q '\"mcpServers\":{}' \"$TEST_DIR/my-node-app/.agents/mcp_config.json\""

echo "----------------------------------------"
if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "✅ All $TESTS_PASSED Phase 6 tests passed!"
  exit 0
else
  echo "❌ $TESTS_FAILED Phase 6 tests failed."
  exit 1
fi
