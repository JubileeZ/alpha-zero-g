#!/usr/bin/env bash
# lib/fable.sh — opt-in Fable skill sync into a project (Phase 10)
#
# Usage (via azg):
#   azg fable sync [DIR] [--experimental]
#
# Installs templates/optional/fable/skills into DIR/.agents/skills/fable/
# Never touches global core setup profile.
# If prereg reliability_claim_allowed is false, requires --experimental.

# shellcheck source=lib/common.sh
# Sourced from azg after common.sh

cmd_fable() {
  local sub="${1:-}"
  shift || true
  case "${sub}" in
    sync) fable_sync "$@" ;;
    status) fable_status "$@" ;;
    *)
      err "Unknown fable subcommand: '${sub:-}'"
      echo "Usage: azg fable sync [DIR] [--experimental]"
      echo "       azg fable status [DIR]"
      return 1
      ;;
  esac
}

fable_claim_allowed() {
  local prereg="${AZG_ROOT}/evals/pilot/prereg.json"
  if [ -f "${prereg}" ] && command -v jq >/dev/null 2>&1; then
    [ "$(jq -r '.reliability_claim_allowed // false' "${prereg}")" = "true" ]
    return $?
  fi
  return 1
}

fable_sync() {
  local target="."
  local experimental=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --experimental) experimental=1; shift ;;
      -*)
        err "Unknown flag: $1"
        return 1
        ;;
      *)
        target="$1"
        shift
        ;;
    esac
  done

  if [ ! -d "${target}" ]; then
    die "Target directory not found: ${target}"
  fi
  target="$(cd "${target}" && pwd)"

  if ! fable_claim_allowed; then
    if [ "${experimental}" -ne 1 ]; then
      err "Fable sync is experimental until held-out claim is allowed (ADR 0005)."
      err "Re-run with: azg fable sync ${target} --experimental"
      err "Or complete confirmation+held-out and: bash evals/analyze-pilot-gate.sh --apply-claim"
      return 1
    fi
    warn "reliability_claim_allowed=false — installing Fable as EXPERIMENTAL opt-in only (not a reliability claim)"
  fi

  local src="${AZG_ROOT}/templates/optional/fable"
  if [ -n "${AZG_FABLE_UPSTREAM:-}" ]; then
    info "AZG_FABLE_UPSTREAM set — clone override not yet implemented; using bundled stubs"
    # ponytail: ceiling = local stubs only; upgrade = sparse-clone upstream like vendor-sync
  fi

  if [ ! -d "${src}/skills" ]; then
    die "Missing bundled Fable skills at ${src}/skills"
  fi

  local dest="${target}/.agents/skills/fable"
  ensure_dir "${dest}"

  # Copy skills
  local skill
  for skill in "${src}/skills"/*; do
    if [ -d "${skill}" ]; then
      local base
      base="$(basename "${skill}")"
      rm -rf "${dest}/${base}"
      cp -R "${skill}" "${dest}/${base}"
      info "Installed skill: fable/${base}"
    fi
  done

  if [ -f "${src}/FABLE.lock.json" ]; then
    cp "${src}/FABLE.lock.json" "${dest}/FABLE.lock.json"
  fi

  # Marker so status/evals can detect treatment without enabling globally
  printf '%s\n' "experimental=$( [ "${experimental}" -eq 1 ] && echo true || echo false )" \
    "synced_at=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date)" \
    > "${dest}/.fable-installed"

  ok "Fable skills installed under ${dest}"
  ok "Opt-in only — core profile unchanged. Compare via Evaluation Suite treatment core+fable when ready."
}

fable_status() {
  local target="${1:-.}"
  if [ ! -d "${target}" ]; then
    die "Target directory not found: ${target}"
  fi
  target="$(cd "${target}" && pwd)"
  local dest="${target}/.agents/skills/fable"
  if [ -d "${dest}" ] && [ -f "${dest}/.fable-installed" ]; then
    ok "Fable installed at ${dest}"
    cat "${dest}/.fable-installed"
    if [ -f "${dest}/FABLE.lock.json" ]; then
      info "lock: $(tr -d '\n' < "${dest}/FABLE.lock.json" | head -c 200)"
    fi
  else
    info "Fable not installed in ${target}"
    return 1
  fi
}
