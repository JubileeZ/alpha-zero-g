#!/usr/bin/env bash
# price — total + discount
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
  discount)
    price="${1:-}"
    pct="${2:-}"
    if [ -z "${price}" ] || [ -z "${pct}" ]; then
      echo "usage: price.sh discount PRICE PCT" >&2
      exit 2
    fi
    echo $((price * (100 - pct) / 100))
    ;;
  *)
    echo "usage: price.sh total N [N...] | price.sh discount PRICE PCT" >&2
    exit 2
    ;;
esac
