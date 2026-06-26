#!/usr/bin/env bash
# pre-compact.sh — pre-compact observability hook
input=$(cat)
printf "PreCompact event triggered. Context compaction is starting...\n" >&2
printf '{"decision":"allow"}\n'
exit 0
