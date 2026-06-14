#!/usr/bin/env bash
# lib/uninstall.sh — azg uninstall
# Removes everything azg setup created under ~/.gemini/antigravity-cli/.
# Sourced by the azg dispatcher; do NOT run directly.
# Implemented in Phase 8.

cmd_uninstall() {
  step "Uninstalling Alpha-Zero-G globally managed files..."
  
  local target_dir="${HOME}/.gemini/antigravity-cli"
  
  if [ -d "${target_dir}" ]; then
    rm -rf "${target_dir}"
    ok "Removed: ${target_dir}"
  else
    info "Already removed (or not found): ${target_dir}"
  fi
}
