#!/usr/bin/env bash
# evals/prepare-judge-packet.sh — build a treatment-blind judge packet from a run workdir
#
# Usage: bash evals/prepare-judge-packet.sh <workdir> [out-dir]
# Copies TASK.md + tools/ only. Strips scorecard, .agents, .cursor, AGENTS.md, etc.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${1:-}"
OUT="${2:-}"

if [ -z "${WORKDIR}" ] || [ ! -d "${WORKDIR}" ]; then
  echo "usage: prepare-judge-packet.sh <workdir> [out-dir]" >&2
  exit 2
fi

WORKDIR="$(cd "${WORKDIR}" && pwd)"
if [ -z "${OUT}" ]; then
  OUT="${WORKDIR}/judge-packet"
fi
rm -rf "${OUT}"
mkdir -p "${OUT}/delivery/tools"

if [ ! -f "${WORKDIR}/TASK.md" ]; then
  echo "missing TASK.md in workdir" >&2
  exit 1
fi
cp "${WORKDIR}/TASK.md" "${OUT}/TASK.md"
cp "${ROOT}/evals/judge/RUBRIC.md" "${OUT}/RUBRIC.md"
cp "${ROOT}/evals/judge/PROMPT.md" "${OUT}/PROMPT.md"
cp "${ROOT}/evals/judge/config.json" "${OUT}/config.json"

if [ -d "${WORKDIR}/tools" ]; then
  cp -R "${WORKDIR}/tools/." "${OUT}/delivery/tools/"
fi

cat > "${OUT}/manifest.json" <<'EOF'
{
  "blind": true,
  "includes": ["TASK.md", "RUBRIC.md", "PROMPT.md", "config.json", "delivery/"],
  "excludes": ["scorecard.json", ".agents", ".cursor", "AGENTS.md", "treatment"]
}
EOF

if grep -qiE 'treatment|No-Harness|azg apply|baseline harness' "${OUT}/TASK.md"; then
  echo "blindness violation: TASK.md mentions treatment/harness" >&2
  exit 1
fi

if [ -e "${OUT}/scorecard.json" ] || [ -d "${OUT}/.agents" ] || [ -d "${OUT}/.cursor" ]; then
  echo "blindness violation: harness or scorecard present in packet" >&2
  exit 1
fi

echo "PACKET=${OUT}"
