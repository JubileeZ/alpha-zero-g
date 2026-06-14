#!/usr/bin/env bash
# lib/update.sh — azg update [--vendor]
#
# azg update          : git pull the Alpha-Zero-G repo itself
# azg update --vendor : git pull + re-vendor mattpocock/skills
#
# Sourced by the azg dispatcher; do NOT run directly.
# vendor_sync() lives in vendor-sync.sh (Phase 2).

cmd_update() {
  local do_vendor=0
  local arg
  for arg in "$@"; do
    case "${arg}" in
      --vendor) do_vendor=1 ;;
      *) warn "Unknown flag for 'update': ${arg}" ;;
    esac
  done

  if [ "${do_vendor}" -eq 1 ]; then
    # Source vendor-sync.sh (sibling of this file)
    local lib_dir
    lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=lib/vendor-sync.sh
    source "${lib_dir}/vendor-sync.sh"
    vendor_sync
  else
    step "Updating Alpha-Zero-G..."
    local azg_root="${AZG_ROOT:-}"
    if [ -z "${azg_root}" ]; then
      azg_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
    
    if [ ! -d "${azg_root}/.git" ]; then
      err "Not a git repository: ${azg_root}"
      return 1
    fi

    # Run git pull
    if git -C "${azg_root}" pull --quiet; then
      ok "Alpha-Zero-G updated successfully."
    else
      err "Failed to update Alpha-Zero-G."
      return 1
    fi
  fi
}
