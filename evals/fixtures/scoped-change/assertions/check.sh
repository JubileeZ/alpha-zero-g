#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GREET="${ROOT}/tools/greet.sh"
chmod +x "${GREET}" 2>/dev/null || true

got="$("${GREET}" world)"
if [ "${got}" != "hello, world" ]; then
  echo "FAIL: text mode broken: got '${got}'" >&2
  exit 1
fi

json_out="$("${GREET}" --json world)"
if [ "${json_out}" != '{"greeting":"hello","name":"world"}' ]; then
  echo "FAIL: --json output wrong: got '${json_out}'" >&2
  exit 1
fi

echo "scoped-change assertions OK"
