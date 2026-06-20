#!/usr/bin/env bash
# lib/uninstall.sh — azg uninstall
# Removes everything azg setup created under ~/.gemini/antigravity-cli/.
# Sourced by the azg dispatcher; do NOT run directly.
# Implemented in Phase 8.

cmd_uninstall() {
  step "Uninstalling Alpha-Zero-G globally managed files..."
  
  local target_dir="${HOME}/.gemini/antigravity-cli"
  local global_skills="${HOME}/.gemini/config/skills"
  local global_mcp="${HOME}/.gemini/config/mcp_config.json"
  
  local removed=0
  if [ -d "${target_dir}" ]; then
    rm -rf "${target_dir}"
    ok "Removed: ${target_dir}"
    removed=1
  fi
  if [ -d "${global_skills}" ]; then
    rm -rf "${global_skills}"
    ok "Removed: ${global_skills}"
    removed=1
  fi
  if [ -f "${global_mcp}" ]; then
    rm -f "${global_mcp}"
    ok "Removed: ${global_mcp}"
    removed=1
  fi
  
  if [ "${removed}" -eq 0 ]; then
    info "Already removed (or not found)"
  fi
}
