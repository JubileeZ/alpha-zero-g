#!/usr/bin/env bash
# greet — print a greeting (no --json yet)
set -euo pipefail
name="${1:-}"
if [ -z "${name}" ]; then
  echo "usage: greet.sh NAME" >&2
  exit 2
fi
echo "hello, ${name}"
