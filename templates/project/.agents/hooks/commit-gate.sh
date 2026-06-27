#!/usr/bin/env bash
# commit-gate.sh — block commit until harness test passes
input=$(cat)

tool_name=""
cmd=""

if command -v jq >/dev/null 2>&1; then
  tool_name=$(printf '%s' "$input" | jq -r '.toolCall.name // empty' 2>/dev/null)
  cmd=$(printf '%s' "$input" | jq -r '.toolCall.args.CommandLine // empty' 2>/dev/null)
else
  tool_name=$(printf '%s' "$input" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
  cmd=$(printf '%s' "$input" | sed -n 's/.*"CommandLine"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
fi

# Only intercept git commit commands
if [ "$tool_name" = "run_command" ] || [ -n "$cmd" ]; then
  if echo "$cmd" | grep -qE '^git[[:space:]]+commit'; then
    # Verify no transient file leftovers if the task is complete
    if [ -f "task.md" ] && ! grep -q -E '\- \[[[:space:]]*\]' task.md; then
      if [ -f "implementation_plan.md" ] || [ -f "walkthrough.md" ] || [ -s "task.md" ]; then
        reason="Task is complete (no unchecked items in task.md). Please delete task.md, implementation_plan.md, and walkthrough.md (or clear task.md) to avoid leaving transient files in the repository."
        if command -v jq >/dev/null 2>&1; then
          jq -n --arg r "$reason" '{decision: "deny", reason: $r}'
        else
          escaped_reason=$(printf '%s' "$reason" | sed 's/"/\"/g' | tr '\n' ' ')
          printf '{"decision":"deny","reason":"%s"}\n' "$escaped_reason"
        fi
        exit 0
      fi
    fi

    # Run harness tests
    harness_output=$(bash tests/test-harness.sh 2>&1)
    harness_status=$?
    if [ $harness_status -ne 0 ]; then
      reason="Harness tests failed:\n$harness_output"
      if command -v jq >/dev/null 2>&1; then
        jq -n --arg r "$reason" '{decision: "deny", reason: $r}'
      else
        escaped_reason=$(printf '%s' "$reason" | sed 's/"/\"/g' | tr '\n' ' ')
        printf '{"decision":"deny","reason":"%s"}\n' "$escaped_reason"
      fi
      exit 0
    fi

    # Run project tests if configured
    project_test_cmd=""
    if [ -x "tests/project-tests.sh" ]; then
      project_test_cmd="tests/project-tests.sh"
    elif [ -n "${AZG_PROJECT_TEST_CMD:-}" ]; then
      project_test_cmd="$AZG_PROJECT_TEST_CMD"
    fi

    if [ -n "$project_test_cmd" ]; then
      project_output=$(eval "$project_test_cmd" 2>&1)
      project_status=$?
      if [ $project_status -ne 0 ]; then
        reason="Project tests failed:\n$project_output"
        if command -v jq >/dev/null 2>&1; then
          jq -n --arg r "$reason" '{decision: "deny", reason: $r}'
        else
          escaped_reason=$(printf '%s' "$reason" | sed 's/"/\"/g' | tr '\n' ' ')
          printf '{"decision":"deny","reason":"%s"}\n' "$escaped_reason"
        fi
        exit 0
      fi
    fi
  fi
fi

printf '{"decision":"allow"}\n'
exit 0
