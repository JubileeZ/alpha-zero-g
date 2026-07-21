#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRICE="${ROOT}/tools/price.sh"
chmod +x "${PRICE}" 2>/dev/null || true

expect() {
  local want="$1"; shift
  local got
  got="$("${PRICE}" "$@")"
  if [ "${got}" != "${want}" ]; then
    echo "FAIL: price $* → got '${got}', want '${want}'" >&2
    exit 1
  fi
}

# Regression: existing totals
expect 6 total 1 2 3
expect 0 total
expect 10 total 10

# New feature
expect 90 discount 100 10
expect 50 discount 100 50
expect 0 discount 100 100

echo "regression-feature assertions OK"
