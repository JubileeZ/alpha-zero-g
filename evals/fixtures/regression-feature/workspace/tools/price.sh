#!/usr/bin/env bash
# price — totals only (discount not implemented)
set -euo pipefail
cmd="${1:-}"
shift || true
case "${cmd}" in
  total)
    sum=0
    for x in "$@"; do
      sum=$((sum + x))
    done
    echo "${sum}"
    ;;
  *)
    echo "usage: price.sh total N [N...] | price.sh discount PRICE PCT" >&2
    exit 2
    ;;
esac
