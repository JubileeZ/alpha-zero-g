#!/usr/bin/env bash
# tests/run-all.sh — Aggregate evidence runner (Phase 8)
#
# Runs shellcheck (if present), Python verifiers, integration + all phase suites.
# Usage:
#   bash tests/run-all.sh           # full gate
#   bash tests/run-all.sh --list    # print suite order, exit 0
#   AZG_STRICT=1 bash tests/run-all.sh  # fail if shellcheck/python missing

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

STRICT="${AZG_STRICT:-0}"
LIST_ONLY=0
if [ "${1:-}" = "--list" ]; then
  LIST_ONLY=1
fi

PASS=0
FAIL=0
SKIP=0

ok() { PASS=$((PASS + 1)); printf "  \033[0;32m✓\033[0m %s\n" "$1"; }
bad() { FAIL=$((FAIL + 1)); printf "  \033[0;31m✗\033[0m %s\n" "$1"; }
skip() { SKIP=$((SKIP + 1)); printf "  \033[0;33m–\033[0m %s\n" "$1"; }

run_suite() {
  local name="$1"
  shift
  printf "\n\033[1m\033[0;36m▶ %s\033[0m\n" "${name}"
  if [ "${LIST_ONLY}" -eq 1 ]; then
    ok "listed: ${name}"
    return 0
  fi
  if "$@"; then
    ok "${name}"
  else
    bad "${name}"
  fi
}

# --- shellcheck ---
printf "\n\033[1m\033[0;36m▶ shellcheck\033[0m\n"
if [ "${LIST_ONLY}" -eq 1 ]; then
  ok "listed: shellcheck"
elif command -v shellcheck >/dev/null 2>&1; then
  # -S error: style/warning debt (SC2164 etc.) is tracked separately; errors (e.g. SC1017 CRLF) still fail the gate
  # shellcheck disable=SC2086
  if shellcheck -S error azg lib/*.sh tests/*.sh; then
    ok "shellcheck -S error azg lib/*.sh tests/*.sh"
  else
    bad "shellcheck failed"
  fi
else
  if [ "${STRICT}" = "1" ]; then
    bad "shellcheck missing (AZG_STRICT=1)"
  else
    skip "shellcheck not installed"
  fi
fi

# --- Python verifiers ---
printf "\n\033[1m\033[0;36m▶ tests/run-verify-docs.sh\033[0m\n"
if [ "${LIST_ONLY}" -eq 1 ]; then
  ok "listed: tests/run-verify-docs.sh"
else
  if bash tests/run-verify-docs.sh; then
    ok "tests/run-verify-docs.sh"
  else
    _rvd_exit=$?
    if [ "${_rvd_exit}" -eq 127 ] && [ "${STRICT}" != "1" ]; then
      skip "python3 not usable (tests/run-verify-docs.sh)"
    else
      bad "tests/run-verify-docs.sh"
    fi
  fi
fi

# --- Bash suites ---
run_suite "tests/test-azg.sh" bash tests/test-azg.sh
run_suite "tests/test-statusline.sh" bash tests/test-statusline.sh
run_suite "tests/host-contract-smoke.sh" bash tests/host-contract-smoke.sh
run_suite "tests/test-mutation-verify.sh" bash tests/test-mutation-verify.sh
run_suite "tests/test-traps.sh" bash tests/test-traps.sh
run_suite "tests/test-intent-gates-candidate.sh" bash tests/test-intent-gates-candidate.sh
run_suite "tests/test-eval-isolation.sh" bash tests/test-eval-isolation.sh
run_suite "tests/test-candidates-slot.sh" bash tests/test-candidates-slot.sh
run_suite "tests/test-selective-skills.sh" bash tests/test-selective-skills.sh
run_suite "tests/test-cursor-device-setup.sh" bash tests/test-cursor-device-setup.sh

shopt -s nullglob
phase_tests=(tests/test-phase*.sh)
shopt -u nullglob
# Stable order: phase0..phase10
IFS=$'\n' phase_tests=($(printf '%s\n' "${phase_tests[@]}" | LC_ALL=C sort))
unset IFS

for suite in "${phase_tests[@]}"; do
  run_suite "${suite}" bash "${suite}"
done

printf "\n\033[1m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
printf "  Aggregate  \033[0;32m%d passed\033[0m" "${PASS}"
[ "${FAIL}" -gt 0 ] && printf "  \033[0;31m%d failed\033[0m" "${FAIL}"
[ "${SKIP}" -gt 0 ] && printf "  \033[0;33m%d skipped\033[0m" "${SKIP}"
printf "\n\033[1m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n\n"

[ "${FAIL}" -eq 0 ]
