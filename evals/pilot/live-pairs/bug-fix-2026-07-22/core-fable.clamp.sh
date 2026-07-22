#!/usr/bin/env bash
# clamp — print n clamped to [lo, hi] (BUG: never clamps the upper bound)
set -euo pipefail
lo=0
hi=10
n=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lo) lo="$2"; shift 2 ;;
    --hi) hi="$2"; shift 2 ;;
    *) n="$1"; shift ;;
  esac
done
if [ -z "${n}" ]; then
  echo "usage: clamp.sh [--lo N] [--hi N] VALUE" >&2
  exit 2
fi
# BUG: only enforces lower bound
if [ "${n}" -lt "${lo}" ]; then
  echo "${lo}"
elif [ "${n}" -gt "${hi}" ]; then
  echo "${hi}"
else
  echo "${n}"
fi
