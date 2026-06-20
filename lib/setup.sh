#!/usr/bin/env bash
# lib/setup.sh — azg setup
# Installs global skills + MCP config to ~/.gemini/antigravity-cli/
# Sourced by the azg dispatcher; do NOT run directly.
#
# Usage (via dispatcher):
#   azg setup              — install/refresh global config
#   azg setup --dry-run    — print what would be done, write nothing
#   azg setup --force      — re-install even if files are already present

# shellcheck source=lib/common.sh
# common.sh is already sourced by the dispatcher before this file is sourced.

cmd_setup() {
  local dry_run=0
  local force=0

  # Parse flags
  for arg in "$@"; do
    case "${arg}" in
      --dry-run) dry_run=1 ;;
      --force)   force=1   ;;
      *)
        die "azg setup: unknown option '${arg}'. Usage: azg setup [--dry-run] [--force]"
        ;;
    esac
  done

  # -------------------------------------------------------------------------
  # Paths (AZG_GLOBAL_DIR, AZG_GLOBAL_SKILLS_DIR, AZG_GLOBAL_MCP_CONFIG
  # are all defined in common.sh)
  # -------------------------------------------------------------------------
  local template_global="${AZG_ROOT}/templates/global"
  local template_mcp="${template_global}/mcp_config.json"
  local template_agents="${template_global}/AGENTS.md"
  local template_vendor="${template_global}/skills/vendor/mattpocock-skills"

  # -------------------------------------------------------------------------
  # Dry-run mode: just print what would happen and exit 0
  # -------------------------------------------------------------------------
  if [ "${dry_run}" -eq 1 ]; then
    step "azg setup --dry-run: showing planned actions (no files will be written)"
    info "  create dir : ${AZG_GLOBAL_DIR}"
    info "  create dir : ${AZG_GLOBAL_SKILLS_DIR}"
    info "  copy file  : ${template_mcp} → ${AZG_GLOBAL_MCP_CONFIG}"
    info "  copy file  : ${template_agents} → ${AZG_GLOBAL_AGENTS}"

    # List vendor skills if any exist
    if [ -d "${template_vendor}" ]; then
      for category_dir in "${template_vendor}"/{engineering,productivity}; do
        [ -d "${category_dir}" ] || continue
        for skill_dir in "${category_dir}"/*/; do
          [ -d "${skill_dir}" ] || continue
          local skill_name
          skill_name="$(basename "${skill_dir}")"
          info "  copy skill : ${skill_dir} → ${AZG_GLOBAL_SKILLS_DIR}/${skill_name}/"
        done
      done
    else
      info "  (no vendor skills found — run azg update --vendor to populate)"
    fi

    ok "Dry run complete. Run 'azg setup' to apply."
    return 0
  fi

  # -------------------------------------------------------------------------
  # Real install
  # -------------------------------------------------------------------------
  step "azg setup v${AZG_VERSION} — installing global config"
  info "Destination: ${AZG_GLOBAL_DIR}"

  # 1. Create destination directories
  ensure_dir "${AZG_GLOBAL_DIR}"
  ensure_dir "${AZG_GLOBAL_SKILLS_DIR}"

  # 2. Install mcp_config.json (atomic copy)
  if [ ! -f "${template_mcp}" ]; then
    die "Template mcp_config.json not found: ${template_mcp}"
  fi

  local _install_mcp=1
  if [ -f "${AZG_GLOBAL_MCP_CONFIG}" ] && [ "${force}" -eq 0 ]; then
    # Already installed — check if identical
    if diff -q "${template_mcp}" "${AZG_GLOBAL_MCP_CONFIG}" > /dev/null 2>&1; then
      info "mcp_config.json already up-to-date, skipping"
      _install_mcp=0
    fi
  fi

  if [ "${_install_mcp}" -eq 1 ]; then
    atomic_copy "${template_mcp}" "${AZG_GLOBAL_MCP_CONFIG}"
    ok "Installed: mcp_config.json"
  fi

  # 2.0. Install global AGENTS.md (atomic copy)
  if [ ! -f "${template_agents}" ]; then
    die "Template AGENTS.md not found: ${template_agents}"
  fi

  local _install_agents=1
  if [ -f "${AZG_GLOBAL_AGENTS}" ] && [ "${force}" -eq 0 ]; then
    # Already installed — check if identical
    if diff -q "${template_agents}" "${AZG_GLOBAL_AGENTS}" > /dev/null 2>&1; then
      info "AGENTS.md already up-to-date, skipping"
      _install_agents=0
    fi
  fi

  if [ "${_install_agents}" -eq 1 ]; then
    atomic_copy "${template_agents}" "${AZG_GLOBAL_AGENTS}"
    ok "Installed: AGENTS.md (global)"
  fi

  # 2.1. Install statusline.sh (atomic copy)
  local template_statusline="${AZG_ROOT}/templates/global/statusline.sh"
  local statusline_path="${AZG_GLOBAL_DIR}/statusline.sh"
  local _install_statusline=1

  if [ ! -f "${template_statusline}" ]; then
    die "Template statusline.sh not found: ${template_statusline}"
  fi

  if [ -f "${statusline_path}" ] && [ "${force}" -eq 0 ]; then
    if diff -q "${template_statusline}" "${statusline_path}" > /dev/null 2>&1; then
      info "statusline.sh already up-to-date, skipping"
      _install_statusline=0
    fi
  fi

  if [ "${_install_statusline}" -eq 1 ]; then
    atomic_copy "${template_statusline}" "${statusline_path}"
    chmod +x "${statusline_path}"
    ok "Installed: statusline.sh"
  fi

  # 2.2. Configure/merge settings.json
  local settings_file="${AZG_GLOBAL_DIR}/settings.json"
  if [ -f "${settings_file}" ]; then
    # Merge using jq to preserve other user settings
    info "Merging statusline configuration into settings.json"
    local tmp_settings="${settings_file}.azg.tmp"
    jq --arg path "${statusline_path}" '
      .statusLine = {
        type: "command",
        command: $path,
        enabled: true
      }
    ' "${settings_file}" > "${tmp_settings}" && mv "${tmp_settings}" "${settings_file}"
  else
    # Create new settings.json with statusline configuration
    info "Creating new settings.json with statusline configuration"
    printf '{\n  "statusLine": {\n    "type": "command",\n    "command": "%s",\n    "enabled": true\n  }\n}\n' "${statusline_path}" > "${settings_file}"
  fi
  ok "Configured: settings.json"

  # Source apply-overlay
  source "${AZG_ROOT}/lib/apply-overlay.sh"

  # 3. Copy vendor skills
  local skills_copied=0
  local skills_skipped=0
  local skills_pruned=0
  local vendor_base_dir="${template_global}/skills/vendor"

  if [ -d "${vendor_base_dir}" ]; then
    # Loop over each vendor pack directory under vendor/
    for vendor_root in "${vendor_base_dir}"/*/; do
      [ -d "${vendor_root}" ] || continue
      local vendor_name
      vendor_name="$(basename "${vendor_root}")"

      # Loop over each category under this vendor pack
      for category_dir in "${vendor_root}"/*/; do
        [ -d "${category_dir}" ] || continue
        for skill_dir in "${category_dir}"/*/; do
          [ -d "${skill_dir}" ] || continue
          local skill_name
          skill_name="$(basename "${skill_dir}")"
          local dest="${AZG_GLOBAL_SKILLS_DIR}/${skill_name}"

          if [ -d "${dest}" ] && [ "${force}" -eq 0 ]; then
            info "skill '${skill_name}' already installed, skipping (use --force to re-install)"
            skills_skipped=$((skills_skipped + 1))
          else
            apply_overlay "${skill_name}" "${category_dir}" "${template_global}/skills/overlay/${vendor_name}" "${AZG_GLOBAL_SKILLS_DIR}"
            skills_copied=$((skills_copied + 1))
          fi
        done
      done

      # Prune skills from this vendor pack
      _prune_vendor_skills \
        "${AZG_GLOBAL_SKILLS_DIR}" \
        "${vendor_root}" \
        skills_pruned
    done
  else
    info "No vendor skills found at ${vendor_base_dir}"
    info "Tip: run 'azg update --vendor' to vendor skills"
  fi

  # -------------------------------------------------------------------------
  # Summary
  # -------------------------------------------------------------------------
  local _sum_skills=""
  if [ "${skills_copied}" -gt 0 ] && [ "${skills_skipped}" -gt 0 ]; then
    _sum_skills="${skills_copied} skill(s) installed, ${skills_skipped} skipped"
  elif [ "${skills_copied}" -gt 0 ]; then
    _sum_skills="${skills_copied} skill(s) installed"
  elif [ "${skills_skipped}" -gt 0 ]; then
    _sum_skills="all ${skills_skipped} skill(s) already up-to-date"
  else
    _sum_skills="no skills to install (run 'azg update --vendor' to vendor skills)"
  fi
  [ "${skills_pruned}" -gt 0 ] && _sum_skills="${_sum_skills}, ${skills_pruned} removed (deleted upstream)"

  ok "Setup complete. ${_sum_skills}."
  info "Global config: ${AZG_GLOBAL_DIR}"
}
