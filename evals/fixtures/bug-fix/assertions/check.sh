#!/usr/bin/env bash
# Hidden assertions for bug-fix (not part of agent prompt beyond TASK acceptance)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAMP="${ROOT}/tools/clamp.sh"
chmod +x "${CLAMP}" 2>/dev/null || true

expect() {
  local want="$1"; shift
  local got
  got="$("${CLAMP}" "$@")"
  if [ "${got}" != "${want}" ]; then
    echo "FAIL: clamp $* → got '${got}', want '${want}'" >&2
    exit 1
  fi
}

expect 0 --lo 0 --hi 10 -3
expect 0 --lo 0 --hi 10 0
expect 5 --lo 0 --hi 10 5
expect 10 --lo 0 --hi 10 10
expect 10 --lo 0 --hi 10 99
echo "bug-fix assertions OK"
