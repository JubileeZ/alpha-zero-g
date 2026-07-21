#!/usr/bin/env bash
# clamp — print n clamped to [lo, hi]
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
if [ "${n}" -lt "${lo}" ]; then
  echo "${lo}"
elif [ "${n}" -le "${hi}" ]; then
  echo "${n}"
else
  echo "${hi}"
fi
