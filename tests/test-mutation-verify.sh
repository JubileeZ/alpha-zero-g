#!/usr/bin/env bash
# tests/test-mutation-verify.sh — Mutation checks for portable verify.sh
#
# For each required harness path, removing it must make verify.sh exit non-zero.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/harness.sh"

WORK="$(azg_mktemp_d "tmp_azg_mutation-XXXXXX")"
cd "${WORK}"

assert_exit "azg new mutation-app" 0 "${AZG}" new mutation-app --no-git
APP="${WORK}/mutation-app"
cd "${APP}"

assert_exit "baseline verify passes" 0 bash tests/verify.sh

section "1. Mutate required paths — verify must fail"

REQUIRED=(
  AGENTS.md
  ROADMAP.md
  docs/agents/current-state.md
  docs/agents/progress.md
  docs/agents/issue-tracker.md
  docs/agents/triage-labels.md
  docs/agents/domain.md
  .agents/hooks.json
  .agents/spawn-budget.json
  .agents/hooks/block-destructive-ops.sh
  .agents/hooks/commit-gate.sh
  .agents/hooks/checkpoint.sh
  .agents/hooks/spawn-budget.sh
  .agents/hooks/pre-compact.sh
  tests/test-harness.sh
  tests/verify.sh
)

failures=0
for path in "${REQUIRED[@]}"; do
  if [ ! -e "${path}" ]; then
    fail "expected scaffold path missing before mutation: ${path}"
    failures=$((failures + 1))
    continue
  fi
  backup="${path}.azg-mutbak"
  # Move aside (preserve mode for restore)
  mv "${path}" "${backup}"
  if bash tests/verify.sh >/dev/null 2>&1; then
    fail "verify should fail without ${path}"
    failures=$((failures + 1))
  else
    pass "verify fails without ${path}"
  fi
  mv "${backup}" "${path}"
  # verify.sh itself was moved — restore executable bit if needed
  if [[ "${path}" == *.sh ]]; then
    chmod +x "${path}"
  fi
done

# Special case: verify.sh removed — cannot invoke it; treat as covered by path check above
# (when tests/verify.sh is missing, we moved it then tried bash tests/verify.sh which fails)

assert_exit "verify still passes after all restores" 0 bash tests/verify.sh

if [ "${failures}" -eq 0 ]; then
  :
else
  fail "mutation suite had ${failures} unexpected passes"
fi

test_summary
