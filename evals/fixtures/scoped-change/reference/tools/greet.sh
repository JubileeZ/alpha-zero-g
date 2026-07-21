#!/usr/bin/env bash
# greet — print a greeting; optional --json
set -euo pipefail
json=0
name=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json) json=1; shift ;;
    *) name="$1"; shift ;;
  esac
done
if [ -z "${name}" ]; then
  echo "usage: greet.sh [--json] NAME" >&2
  exit 2
fi
if [ "${json}" -eq 1 ]; then
  printf '{"greeting":"hello","name":"%s"}\n' "${name}"
else
  echo "hello, ${name}"
fi
