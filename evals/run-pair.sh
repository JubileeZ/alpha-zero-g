#!/usr/bin/env bash
# evals/run-pair.sh — prepare a fixture workdir for core or baseline treatment
#
# Usage: bash evals/run-pair.sh <fixture-id> <core|baseline>
# Copies workspace + TASK + assertions into a temp dir. For core, runs azg apply.
# Writes scorecard.json stub. Prints WORKDIR=...

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_ID="${1:-}"
TREATMENT="${2:-}"

if [ -z "${FIXTURE_ID}" ] || [ -z "${TREATMENT}" ]; then
  echo "usage: bash evals/run-pair.sh <fixture-id> <core|baseline>" >&2
  exit 2
fi

case "${TREATMENT}" in
  core|baseline) ;;
  *) echo "treatment must be core or baseline" >&2; exit 2 ;;
esac

SUITE="${ROOT}/evals/suite.json"
if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

path=$(jq -r --arg id "${FIXTURE_ID}" '.fixtures[] | select(.id==$id) | .path' "${SUITE}")
if [ -z "${path}" ] || [ "${path}" = "null" ]; then
  echo "unknown fixture: ${FIXTURE_ID}" >&2
  exit 1
fi

SRC="${ROOT}/evals/${path}"
WORKDIR="${TMPDIR:-${TEMP:-/tmp}}/azg-eval-${FIXTURE_ID}-${TREATMENT}-$$"
# Normalize Windows TEMP
WORKDIR="${WORKDIR//\\//}"
rm -rf "${WORKDIR}"
mkdir -p "${WORKDIR}"

# Seed broken workspace + task + assertions (assertions live beside tools for check.sh ROOT)
cp -R "${SRC}/workspace/." "${WORKDIR}/"
cp "${SRC}/TASK.md" "${WORKDIR}/TASK.md"
mkdir -p "${WORKDIR}/assertions"
cp "${SRC}/assertions/check.sh" "${WORKDIR}/assertions/check.sh"
chmod +x "${WORKDIR}/assertions/check.sh"
find "${WORKDIR}/tools" -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true

# Scorecard stub
jq \
  --arg id "${FIXTURE_ID}" \
  --arg t "${TREATMENT}" \
  --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  '.fixture_id=$id | .treatment=$t | .started_at=$started' \
  "${ROOT}/evals/scorecard.json.tmpl" > "${WORKDIR}/scorecard.json"

if [ "${TREATMENT}" = "core" ]; then
  # Minimal git repo so azg apply accepts target
  (
    cd "${WORKDIR}"
    git init -q
    git add -A
    git -c user.email=eval@azg -c user.name=eval commit -m "eval seed" -q
  )
  AZG_ROOT="${ROOT}" "${ROOT}/azg" apply "${WORKDIR}" --tracker none >/dev/null
fi

# Point check.sh at workdir layout: assertions/check.sh expects ROOT/tools
# Our check.sh uses dirname/../ = workdir. Good.

cat <<EOF
WORKDIR=${WORKDIR}
TREATMENT=${TREATMENT}
FIXTURE=${FIXTURE_ID}
TASK=${WORKDIR}/TASK.md
SCORECARD=${WORKDIR}/scorecard.json
CHECK=bash ${WORKDIR}/assertions/check.sh
EOF
