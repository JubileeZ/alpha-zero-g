#!/usr/bin/env bash
# evals/run-long-horizon.sh — scaffold a Long-Horizon Task run
#
# Usage:
#   bash evals/run-long-horizon.sh <fixture-id> [core|baseline|core+fable]
#
# Creates:
#   SESSION1  — prepared fixture workdir (git repo)
#   SESSION2  — clean clone of SESSION1 (simulates second device)
#   long-horizon-log.json + checklist copy
#
# After Session1 Checkpoint commit, re-run with:
#   bash evals/run-long-horizon.sh <fixture-id> [core|baseline|core+fable] --sync-clone <SESSION1>

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_ID="${1:-}"
TREATMENT="${2:-core}"
MODE="init"
SESSION1_ARG=""

if [ "${3:-}" = "--sync-clone" ]; then
  MODE="sync"
  SESSION1_ARG="${4:-}"
fi

if [ -z "${FIXTURE_ID}" ]; then
  echo "usage: run-long-horizon.sh <fixture-id> [core|baseline|core+fable] [--sync-clone SESSION1]" >&2
  exit 2
fi

if [ "${TREATMENT}" = "core-fable" ]; then
  TREATMENT="core+fable"
fi

case "${TREATMENT}" in
  core|baseline|core+fable) ;;
  *) echo "treatment must be core, baseline, or core+fable" >&2; exit 2 ;;
esac

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2
  exit 1
fi

BASE="${TMPDIR:-${TEMP:-/tmp}}/azg-lh-${FIXTURE_ID}-${TREATMENT}-$$"
BASE="${BASE//\\//}"

if [ "${MODE}" = "init" ]; then
  rm -rf "${BASE}"
  mkdir -p "${BASE}"

  # Session 1 via paired prepare
  pair_out=$(bash "${ROOT}/evals/run-pair.sh" "${FIXTURE_ID}" "${TREATMENT}")
  SESSION1=$(echo "${pair_out}" | sed -n 's/^WORKDIR=//p' | head -n1)
  if [ -z "${SESSION1}" ] || [ ! -d "${SESSION1}" ]; then
    echo "run-pair failed: ${pair_out}" >&2
    exit 1
  fi

  # Ensure git repo (baseline path may lack git — run-pair only inits for core)
  if [ ! -d "${SESSION1}/.git" ]; then
    (
      cd "${SESSION1}"
      git init -q
      git add -A
      git -c user.email=lh@azg -c user.name=lh commit -m "lh: seed session1" -q
    )
  fi

  # Seed Work Packet + handoff for Checkpoint culture
  if [ ! -f "${SESSION1}/task.md" ]; then
    cat > "${SESSION1}/task.md" <<EOF
# Active Task: ${FIXTURE_ID} (Long-Horizon)

- **Status:** In Progress
- **Objective:** See TASK.md
- **Acceptance:** assertions/check.sh passes after Session 2
- **Issue/Ticket:** long-horizon-${FIXTURE_ID}

## Work Packet (SFDBN)

- **Status:** Session 1 started (fresh context)
- **Files:** tools/
- **Decisions:** Long-Horizon run; IDE handoff required
- **Blocked:** None
- **Next:** Partial progress then Checkpoint; resume on clean clone in other IDE
EOF
  fi

  mkdir -p "${SESSION1}/.agents"
  if [ ! -f "${SESSION1}/.agents/session-handoff.md" ]; then
    cat > "${SESSION1}/.agents/session-handoff.md" <<EOF
# Session handoff

- Fixture: ${FIXTURE_ID}
- Treatment: (do not show to Blind Judge)
- Session: 1 of 2 — stop after Checkpoint; resume from clone only
EOF
  fi

  cp "${ROOT}/evals/long-horizon/checklist.md" "${BASE}/checklist.md"

  # Placeholder Session2 path (filled after first Checkpoint via --sync-clone)
  SESSION2="${BASE}/session2-clone"
  mkdir -p "${SESSION2}"
  echo "Awaiting Session1 Checkpoint commit, then: bash evals/run-long-horizon.sh ${FIXTURE_ID} ${TREATMENT} --sync-clone ${SESSION1}" \
    > "${SESSION2}/README-WAIT.txt"

  jq -n \
    --arg fixture "${FIXTURE_ID}" \
    --arg treatment "${TREATMENT}" \
    --arg session1 "${SESSION1}" \
    --arg session2 "${SESSION2}" \
    --arg base "${BASE}" \
    --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
    '{
      fixture_id: $fixture,
      treatment: $treatment,
      started_at: $started,
      base: $base,
      session1: $session1,
      session2: $session2,
      phases: {
        fresh_context: {status: "pending_operator", detail: "Open SESSION1 in IDE A with a new chat"},
        checkpoint: {status: "pending_operator", detail: "Commit code + task.md in SESSION1"},
        clean_clone: {status: "pending", detail: "Run --sync-clone after Checkpoint"},
        ide_handoff: {status: "pending_operator", detail: "Open SESSION2 in the other IDE with a new chat"},
        acceptance: {status: "pending_operator", detail: "assertions/check.sh on SESSION2"}
      }
    }' > "${BASE}/long-horizon-log.json"

  # Convenience symlink/copy log into session1
  cp "${BASE}/long-horizon-log.json" "${SESSION1}/long-horizon-log.json"
  cp "${BASE}/checklist.md" "${SESSION1}/LONG-HORIZON-CHECKLIST.md"

  cat <<EOF
BASE=${BASE}
SESSION1=${SESSION1}
SESSION2=${SESSION2}
LOG=${BASE}/long-horizon-log.json
CHECKLIST=${BASE}/checklist.md

Next:
  1. Open SESSION1 in IDE A (Cursor or Antigravity) — NEW chat
  2. Work TASK.md; update task.md; git add && git commit -m "checkpoint: session1"
  3. bash evals/run-long-horizon.sh ${FIXTURE_ID} ${TREATMENT} --sync-clone ${SESSION1}
  4. Open SESSION2 in the OTHER IDE — NEW chat; finish; bash assertions/check.sh
EOF
  exit 0
fi

# --- sync-clone mode ---
SESSION1="${SESSION1_ARG}"
if [ -z "${SESSION1}" ] || [ ! -d "${SESSION1}/.git" ]; then
  echo "--sync-clone requires SESSION1 git repo path" >&2
  exit 2
fi

SESSION1="$(cd "${SESSION1}" && pwd)"
if ! git -C "${SESSION1}" rev-parse HEAD >/dev/null 2>&1; then
  echo "SESSION1 has no commits — create Checkpoint first" >&2
  exit 1
fi

BASE="$(dirname "${SESSION1}")"
# If session1 is under tmp from run-pair, put clone beside log if present
if [ -f "${SESSION1}/long-horizon-log.json" ]; then
  BASE="$(cd "$(dirname "${SESSION1}/long-horizon-log.json")" && pwd)"
  # log may live in SESSION1 itself
  if [ "$(basename "${SESSION1}")" != "" ]; then
    :
  fi
fi

# Prefer sibling base from log
LOG="${SESSION1}/long-horizon-log.json"
if [ ! -f "${LOG}" ]; then
  echo "missing long-horizon-log.json in SESSION1; was init run?" >&2
  exit 1
fi

SESSION2=$(jq -r '.session2' "${LOG}")
BASE=$(jq -r '.base // empty' "${LOG}")
rm -rf "${SESSION2}"
git clone --quiet "${SESSION1}" "${SESSION2}"

HEAD1=$(git -C "${SESSION1}" rev-parse HEAD)
HEAD2=$(git -C "${SESSION2}" rev-parse HEAD)
if [ "${HEAD1}" != "${HEAD2}" ]; then
  echo "clone HEAD mismatch" >&2
  exit 1
fi

# Refresh log phases
tmp="${LOG}.tmp"
jq \
  --arg h "${HEAD1}" \
  --arg synced "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
  '.phases.checkpoint.status="ok"
   | .phases.checkpoint.commit=$h
   | .phases.clean_clone.status="ok"
   | .phases.clean_clone.synced_at=$synced
   | .phases.fresh_context.status="operator_confirmed_or_assumed"
   | .phases.ide_handoff.status="pending_operator"
   | .phases.acceptance.status="pending_operator"
   | .session2_head=$h' \
  "${LOG}" > "${tmp}"
mv "${tmp}" "${LOG}"
cp "${LOG}" "${SESSION2}/long-horizon-log.json"
cp "${ROOT}/evals/long-horizon/checklist.md" "${SESSION2}/LONG-HORIZON-CHECKLIST.md"

# Remove wait stub if any leftover outside clone — clone is clean from git
rm -f "${SESSION2}/README-WAIT.txt" 2>/dev/null || true

cat <<EOF
SESSION1=${SESSION1}
SESSION2=${SESSION2}
HEAD=${HEAD1}
LOG=${LOG}

Next:
  1. Open SESSION2 in the OTHER IDE (not Session1 IDE) — NEW chat
  2. Resume from task.md / Checkpoint only
  3. Finish TASK; bash assertions/check.sh
  4. bash evals/judge-score.sh ${SESSION2}   # optional
  5. Tick LONG-HORIZON-CHECKLIST.md
EOF
