#!/usr/bin/env bash
set -e

source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

run_test() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd"; then
    pass "$name"
  else
    fail "$name"
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
# Q5: MCP -> 2 (GitHub)
# Q6: git init -> y
printf "1\nn\n2\ny\n" | "$REPO_ROOT/azg" new my-python-app > /dev/null

run_test "Project directory created" "[ -d \"$TEST_DIR/my-python-app\" ]"
run_test "AGENTS.md created" "[ -f \"$TEST_DIR/my-python-app/AGENTS.md\" ]"
run_test "Git repo initialized" "[ -d \"$TEST_DIR/my-python-app/.git\" ]"
run_test "Hooks copied" "[ -x \"$TEST_DIR/my-python-app/.agents/hooks/block-destructive-ops.sh\" ]"
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
# Q5: 1 (None)
# Q6: n (no git init)
printf "2\ny\nnpm run mylint\nMy lint\nnpm run mytest\nMy test\n\n1\nn\n" | "$REPO_ROOT/azg" new my-node-app

run_test "Node project created" "[ -d \"$TEST_DIR/my-node-app\" ]"
run_test "AGENTS.md created in Node project" "[ -f \"$TEST_DIR/my-node-app/AGENTS.md\" ]"
run_test "Git repo not initialized" "[ ! -d \"$TEST_DIR/my-node-app/.git\" ]"
if ! grep -q 'npm run mylint' "$TEST_DIR/my-node-app/AGENTS.md"; then
  echo "DEBUG: AGENTS.md contents:"
  cat "$TEST_DIR/my-node-app/AGENTS.md"
  run_test "Custom build commands in AGENTS.md" "false"
else
  run_test "Custom build commands in AGENTS.md" "true"
fi
run_test "Empty MCP config" "grep -q '\"mcpServers\":{}' \"$TEST_DIR/my-node-app/.agents/mcp_config.json\""

test_summary
