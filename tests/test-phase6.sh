#!/usr/bin/env bash
# tests/test-phase6.sh — TDD suite for Phase 6: non-interactive harness scaffolding
#
# Tests that `azg new` executes fully non-interactively and scaffolds
# the harness-only project layout correctly.

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

section "1. Default non-interactive harness scaffolding"

# Close stdin to guarantee it does not prompt
"$REPO_ROOT/azg" new my-default-app < /dev/null > /dev/null

run_test "Default project directory created" "[ -d \"$TEST_DIR/my-default-app\" ]"
run_test "Default AGENTS.md created" "[ -f \"$TEST_DIR/my-default-app/AGENTS.md\" ]"
run_test "Default Git repo initialized" "[ -d \"$TEST_DIR/my-default-app/.git\" ]"
run_test "Default Hooks copied" "[ -x \"$TEST_DIR/my-default-app/.agents/hooks/block-destructive-ops.sh\" ]"
run_test "Default issue tracker is GitHub" "grep -q 'GitHub' \"$TEST_DIR/my-default-app/docs/agents/issue-tracker.md\""

section "2. Scaffold with --no-git flag"

"$REPO_ROOT/azg" new my-nogit-app --no-git < /dev/null > /dev/null

run_test "No-Git project directory created" "[ -d \"$TEST_DIR/my-nogit-app\" ]"
run_test "No-Git AGENTS.md created" "[ -f \"$TEST_DIR/my-nogit-app/AGENTS.md\" ]"
run_test "No-Git Git repo NOT initialized" "[ ! -d \"$TEST_DIR/my-nogit-app/.git\" ]"

section "3. Scaffold with custom tracker flag"

"$REPO_ROOT/azg" new my-gitlab-app --tracker gitlab < /dev/null > /dev/null

run_test "GitLab project directory created" "[ -d \"$TEST_DIR/my-gitlab-app\" ]"
run_test "GitLab issue tracker set to GitLab" "grep -q 'GitLab' \"$TEST_DIR/my-gitlab-app/docs/agents/issue-tracker.md\""

test_summary
