#!/usr/bin/env bash
# lib/setup.sh — azg setup
# Installs all vendored global skills + MCP config (full-only; no core profile).
# Sourced by the azg dispatcher; do NOT run directly.
#
# Usage (via dispatcher):
#   azg setup              — install/refresh global config
#   azg setup --dry-run    — print what would be done, write nothing
#   azg setup --force      — re-install even if files are already present

# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

_cursor_rule_markers() {
  local rule_base="${1}"

  case "${rule_base}" in
    azg-agent-instructions.mdc)
      printf '%s\n' '<!-- AZG:AGENT-INSTRUCTIONS:START -->' '<!-- AZG:AGENT-INSTRUCTIONS:END -->'
      ;;
    *)
      die "No AGENTS.md marker mapping for Cursor rule: ${rule_base}"
      ;;
  esac
}

_validate_cursor_rule_templates() {
  local cursor_rules_tmpl_dir="${1}"
  local template_agents="${2}"
  local rule_src rule_base marker_start marker_end

  [ -d "${cursor_rules_tmpl_dir}" ] || die "Cursor rules template dir missing: ${cursor_rules_tmpl_dir}"
  for rule_src in "${cursor_rules_tmpl_dir}"/azg-*.mdc; do
    [ -f "${rule_src}" ] || continue
    rule_base="$(basename "${rule_src}")"
    # Bash 3.2-safe (macOS / GHA macos-latest): two reads, not Bash-4 array-load
    {
      IFS= read -r marker_start
      IFS= read -r marker_end
    } < <(_cursor_rule_markers "${rule_base}")
    if ! extract_managed_block "${template_agents}" "${marker_start}" "${marker_end}" > /dev/null; then
      die "AGENTS.md marker block missing or empty for Cursor rule: ${rule_base}"
    fi
  done
}

_render_cursor_rule() {
  local rule_src="${1}"
  local rule_dest="${2}"
  local template_agents="${3}"
  local rule_base marker_start marker_end body

  rule_base="$(basename "${rule_src}")"
  # Bash 3.2-safe (macOS / GHA macos-latest): two reads, not Bash-4 array-load
  {
    IFS= read -r marker_start
    IFS= read -r marker_end
  } < <(_cursor_rule_markers "${rule_base}")
  body="$(extract_managed_block "${template_agents}" "${marker_start}" "${marker_end}")" || \
    die "AGENTS.md marker block missing or empty for Cursor rule: ${rule_base}"

  local render_tmp="${rule_dest}.azg.render.tmp"
  if ! awk '{ sub(/\r$/, ""); print }' "${rule_src}" > "${render_tmp}" ||
    ! printf '%s\n' "${body}" >> "${render_tmp}"; then
    # DESTRUCTIVE: remove failed Cursor rule render temporary
    rm -f "${render_tmp}"
    die "Failed to render Cursor rule: ${rule_dest}"
  fi
  if ! atomic_copy "${render_tmp}" "${rule_dest}"; then
    # DESTRUCTIVE: remove failed Cursor rule render temporary
    rm -f "${render_tmp}"
    die "Failed to install Cursor rule: ${rule_dest}"
  fi
  # DESTRUCTIVE: remove completed Cursor rule render temporary
  rm -f "${render_tmp}"
}

_migrate_agent_instruction_try() {
  local target="${1}"
  local start_heading="${2}"
  local end_line="${3}"
  local tmp="${target}.azg.migrate.tmp"

  if awk -v start="${start_heading}" -v end="${end_line}" '
    {
      line = $0
      sub(/\r$/, "", line)
      if (line == start) {
        starts += 1
        if (starts != 1 || state != 0) bad = 1
        print "<!-- AZG:AGENT-INSTRUCTIONS:START -->"
        state = 1
      }
      print line
      if (line == end) {
        ends += 1
        if (ends != 1 || state != 1) bad = 1
        print "<!-- AZG:AGENT-INSTRUCTIONS:END -->"
        state = 2
      }
    }
    END { exit !(starts == 1 && ends == 1 && state == 2 && bad != 1) }
  ' "${target}" > "${tmp}"; then
    # DESTRUCTIVE: replace owned AGENTS.md with marker-preserving migration
    if mv "${tmp}" "${target}"; then
      return 0
    fi
    # DESTRUCTIVE: remove failed marker migration temporary
    rm -f "${tmp}"
    return 1
  fi
  # DESTRUCTIVE: remove failed temporary marker migration
  rm -f "${tmp}"
  return 1
}

_migrate_agent_instruction_markers() {
  local target="${1}"
  # Clean slate (Cleanup → telegraphic end), then legacy full gates, then Placeholder → old telegraphic.
  if _migrate_agent_instruction_try "${target}" \
    "# AGENT INSTRUCTIONS: Temporary File Cleanup" \
    "Write updates to agent-reread surfaces (AGENTS.md, CONTEXT.md, ADRs, ROADMAP, progress/current-state, and similar always-on or JIT agent docs) in telegraphic style: drop articles (a/an/the), pleasantries, filler (just/actually/basically/simply), and hedging. Use concise fragments. Keep code, paths, commands, and technical terms exact. Goal: denser future context, less bloat. Not for the user-facing task report."; then
    return 0
  fi
  if _migrate_agent_instruction_try "${target}" \
    "# AGENT INSTRUCTIONS: Temporary File Cleanup" \
    "Before send: non-trivial → layout: top owed \`INTENT:\`/\`AUTH:\` → main body → bottom owed \`TWINS:\`/\`PENDING:\` + Prove verdict; omit un-owed (no N/A). Repair missing lines, then send."; then
    return 0
  fi
  _migrate_agent_instruction_try "${target}" \
    "# AGENT INSTRUCTIONS: Project AGENTS.md Placeholder Rule" \
    "Write all system/project doc updates or additions in telegraphic style: drop articles (a/an/the), pleasantries, filler (just/actually/basically/simply), and hedging. Use concise fragments. Keep code, paths, commands, and technical terms exact."
}

# _install_skill_pair NAME SRC_PARENT OVERLAY_DIR FORCE GEMINI_COUNT_VAR CURSOR_COUNT_VAR
#
# Installs one skill into both targets: Gemini (overlay-processed) and Cursor
# (plain copy). Foreign copies are left alone unless FORCE=1. Records ownership
# and increments the named caller counters (same eval pattern as prune).
_install_skill_pair() {
  local skill_name="${1}"
  local src_parent="${2}"
  local overlay_dir="${3}"
  local force="${4}"
  local gemini_count_var="${5}"
  local cursor_count_var="${6}"

  if [ "${force}" -eq 0 ] && azg_skill_is_foreign "${AZG_GLOBAL_SKILLS_DIR}/${skill_name}"; then
    warn "Foreign skill '${skill_name}' (no ANTIGRAVITY-NOTE) — skipping (use --force to overwrite)"
  else
    apply_overlay "${skill_name}" "${src_parent}" "${overlay_dir}" "${AZG_GLOBAL_SKILLS_DIR}"
    azg_ownership_list_add skills "${skill_name}"
    # ponytail: indirect variable increment via eval (no ((VAR++)) with set -e)
    eval "${gemini_count_var}=\$(( \${${gemini_count_var}} + 1 ))"
  fi

  if [ "${force}" -eq 0 ] && azg_cursor_skill_is_foreign "${AZG_CURSOR_SKILLS_DIR}/${skill_name}"; then
    warn "Foreign Cursor skill '${skill_name}' (no AZG-OWNED.md) — skipping (use --force to overwrite)"
  else
    install_cursor_skill "${skill_name}" "${src_parent}" "${AZG_CURSOR_SKILLS_DIR}"
    azg_ownership_list_add cursor_skills "${skill_name}"
    eval "${cursor_count_var}=\$(( \${${cursor_count_var}} + 1 ))"
  fi
}

_get_requested_skills() {
  local manifest="${1}"
  if [ -f "${manifest}" ] && command -v jq >/dev/null 2>&1; then
    local from_file
    # ponytail: jq on Windows Git Bash may emit CR; strip before skill-name lookups
    from_file="$(jq -r '.skills[]? // empty' "${manifest}" 2>/dev/null | tr -d '\r' || true)"
    printf '%s\n' "${from_file}"
    return 0
  fi
  # Default curated active set requested by operator when no manifest exists
  printf '%s\n' "grill-with-docs" "implement" "retro" "wayfinder" "writing-for-agents"
}

_find_skill_info() {
  local vendor_base="${1}"
  local skill_name="${2}"
  for vroot in "${vendor_base}"/*/; do
    [ -d "${vroot}" ] || continue
    local vname
    vname="$(basename "${vroot}")"
    for cdir in "${vroot}"/*/; do
      [ -d "${cdir}" ] || continue
      if [ -d "${cdir}/${skill_name}" ] && [ -f "${cdir}/${skill_name}/SKILL.md" ]; then
        printf '%s %s\n' "${cdir}" "${vname}"
        return 0
      fi
    done
  done
  return 1
}

_scan_skill_prereqs() {
  local skill_md="${1}"
  local vendor_base="${2}"
  [ -f "${skill_md}" ] || return 0

  # Slash tokens (`/tdd`) and quoted Skill-tool names (`with "grilling"`).
  local tokens
  tokens="$(
    {
      grep -oE '/[a-z0-9-]+' "${skill_md}" 2>/dev/null | sed 's|^/||' || true
      grep -oE '"[a-z0-9-]+"' "${skill_md}" 2>/dev/null | sed 's/^"//;s/"$//' || true
    } | sort -u
  )"
  for tok in ${tokens}; do
    if _find_skill_info "${vendor_base}" "${tok}" >/dev/null 2>&1; then
      printf '%s\n' "${tok}"
    fi
  done
}

_resolve_active_skills() {
  local vendor_base="${1}"
  local manifest="${2}"

  local initial_list
  initial_list="$(_get_requested_skills "${manifest}")"

  local queue=()
  local resolved=()

  for sk in ${initial_list}; do
    [ -n "${sk}" ] && queue+=("${sk}")
  done

  while [ ${#queue[@]} -gt 0 ]; do
    local current="${queue[0]}"
    queue=("${queue[@]:1}")

    local already=0
    for res in "${resolved[@]:-}"; do
      if [ "${res}" = "${current}" ]; then
        already=1
        break
      fi
    done
    [ "${already}" -eq 1 ] && continue

    local sinfo
    sinfo="$(_find_skill_info "${vendor_base}" "${current}" || echo "")"
    if [ -n "${sinfo}" ]; then
      resolved+=("${current}")
      local cdir="${sinfo%% *}"
      local skill_file="${cdir}/${current}/SKILL.md"
      if [ -f "${skill_file}" ]; then
        local prereqs
        prereqs="$(_scan_skill_prereqs "${skill_file}" "${vendor_base}")"
        for pr in ${prereqs}; do
          queue+=("${pr}")
        done
      fi
    fi
  done

  if [ ${#resolved[@]} -gt 0 ]; then
    printf '%s\n' "${resolved[@]}" | sort -u
  fi
}

cmd_setup() {
  local dry_run=0
  local force=0

  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)
        dry_run=1
        shift
        ;;
      --force)
        force=1
        shift
        ;;
      *)
        die "azg setup: unknown option '$1'. Usage: azg setup [--dry-run] [--force]"
        ;;
    esac
  done

  local template_global="${AZG_ROOT}/templates/global"
  local template_mcp="${template_global}/mcp_config.json"
  local template_agents="${template_global}/AGENTS.md"
  local vendor_base_dir="${template_global}/skills/vendor"
  local azg_skills_dir="${template_global}/skills/azg"
  local azg_overlay_dir="${template_global}/skills/overlay/azg"
  local cursor_rules_tmpl_dir="${template_global}/cursor/rules"
  local manifest_file="${AZG_GLOBAL_DIR}/azg-skills.json"

  if [ ! -f "${template_agents}" ]; then
    die "Template AGENTS.md not found: ${template_agents}"
  fi
  if [ -d "${cursor_rules_tmpl_dir}" ]; then
    _validate_cursor_rule_templates "${cursor_rules_tmpl_dir}" "${template_agents}"
  fi

  local active_skills=""
  if [ -d "${vendor_base_dir}" ]; then
    active_skills="$(_resolve_active_skills "${vendor_base_dir}" "${manifest_file}")"
  fi

  local skip_sync=0
  local current_stamp_file="${AZG_GLOBAL_DIR}/setup_stamp"
  local new_stamp=""

  if [ -d "${vendor_base_dir}" ]; then
    new_stamp="$(find "${vendor_base_dir}" -name "VENDOR.lock" -exec grep "^commit:" {} + | sort)"
    new_stamp="${new_stamp}
active: ${active_skills}"
  fi

  if [ "${force}" -eq 0 ] && [ -f "${current_stamp_file}" ] && [ -n "${new_stamp}" ]; then
    local old_stamp
    old_stamp="$(cat "${current_stamp_file}" 2>/dev/null || echo "")"
    if [ "${old_stamp}" = "${new_stamp}" ]; then
      skip_sync=1
    fi
  fi

  if [ "${dry_run}" -eq 1 ]; then
    require_jq
    step "azg setup --dry-run: showing planned actions (no files will be written)"
    info "  create dir : ${AZG_GLOBAL_DIR}"
    info "  create dir : ${AZG_GLOBAL_SKILLS_DIR}"
    info "  create dir : ${AZG_CURSOR_SKILLS_DIR}"
    info "  create dir : ${AZG_CURSOR_RULES_DIR}"
    info "  copy file  : ${template_mcp} → ${AZG_GLOBAL_MCP_CONFIG}"
    info "  copy file  : ${template_agents} → ${AZG_GLOBAL_AGENTS}"
    info "  render file : Cursor rules from ${template_agents} → ${AZG_CURSOR_RULES_DIR}/azg-*.mdc"

    if [ "${skip_sync}" -eq 1 ]; then
      info "  [SMART SYNC] vendor skills up-to-date (VENDOR.lock unchanged); would skip vendor skill copying"
    else
      if [ -n "${active_skills}" ]; then
        for skill_name in ${active_skills}; do
          local sinfo
          sinfo="$(_find_skill_info "${vendor_base_dir}" "${skill_name}" || echo "")"
          [ -n "${sinfo}" ] || continue
          local category_dir="${sinfo%% *}"
          info "  copy skill : ${category_dir}/${skill_name} → ${AZG_GLOBAL_SKILLS_DIR}/${skill_name}/"
          info "  copy skill : ${category_dir}/${skill_name} → ${AZG_CURSOR_SKILLS_DIR}/${skill_name}/"
        done
      elif [ -d "${vendor_base_dir}" ]; then
        for vendor_root in "${vendor_base_dir}"/*/; do
          [ -d "${vendor_root}" ] || continue
          local vendor_name
          vendor_name="$(basename "${vendor_root}")"
          for category_dir in "${vendor_root}"/*/; do
            [ -d "${category_dir}" ] || continue
            for skill_dir in "${category_dir}"/*/; do
              [ -d "${skill_dir}" ] || continue
              local skill_name
              skill_name="$(basename "${skill_dir}")"
              info "  copy skill : ${skill_dir} → ${AZG_GLOBAL_SKILLS_DIR}/${skill_name}/"
              info "  copy skill : ${skill_dir} → ${AZG_CURSOR_SKILLS_DIR}/${skill_name}/"
            done
          done
        done
      else
        info "  (no vendor skills found — run azg update --vendor to populate)"
      fi
    fi

    if [ -d "${azg_skills_dir}" ]; then
      for skill_dir in "${azg_skills_dir}"/*/; do
        [ -d "${skill_dir}" ] || continue
        [ -f "${skill_dir}/SKILL.md" ] || continue
        local azg_skill_name
        azg_skill_name="$(basename "${skill_dir}")"
        info "  copy azg skill : ${skill_dir} → ${AZG_GLOBAL_SKILLS_DIR}/${azg_skill_name}/"
        info "  copy azg skill : ${skill_dir} → ${AZG_CURSOR_SKILLS_DIR}/${azg_skill_name}/"
      done
    else
      info "  (no first-party azg skills at ${azg_skills_dir})"
    fi

    ok "Dry run complete. Run 'azg setup' to apply."
    return 0
  fi

  step "azg setup v${AZG_VERSION} — installing global config"
  info "Destination: ${AZG_GLOBAL_DIR}"
  info "Skills: vendored + azg-owned"

  require_jq

  ensure_dir "${AZG_GLOBAL_DIR}"
  ensure_dir "${AZG_GLOBAL_SKILLS_DIR}"

  if [ ! -f "${template_mcp}" ]; then
    die "Template mcp_config.json not found: ${template_mcp}"
  fi

  azg_ownership_init

  local _install_mcp=1
  if [ -f "${AZG_GLOBAL_MCP_CONFIG}" ] && [ "${force}" -eq 0 ]; then
    if diff -q "${template_mcp}" "${AZG_GLOBAL_MCP_CONFIG}" > /dev/null 2>&1; then
      info "mcp_config.json already up-to-date, skipping"
      _install_mcp=0
      azg_ownership_set_flag mcp true
    elif [ "$(azg_ownership_get mcp)" != "true" ]; then
      warn "Foreign mcp_config.json present — skipping (use --force to overwrite)"
      _install_mcp=0
    fi
  fi

  if [ "${_install_mcp}" -eq 1 ]; then
    ensure_dir "$(dirname "${AZG_GLOBAL_MCP_CONFIG}")"
    atomic_copy "${template_mcp}" "${AZG_GLOBAL_MCP_CONFIG}"
    azg_ownership_set_flag mcp true
    ok "Installed: mcp_config.json"
  fi

  if [ ! -f "${AZG_GLOBAL_AGENTS}" ]; then
    ensure_dir "$(dirname "${AZG_GLOBAL_AGENTS}")"
    atomic_copy "${template_agents}" "${AZG_GLOBAL_AGENTS}"
    azg_ownership_set_flag agents true
    ok "Installed: AGENTS.md (global)"
  elif [ "${force}" -eq 1 ]; then
    cp "${AZG_GLOBAL_AGENTS}" "${AZG_GLOBAL_AGENTS}.bak"
    atomic_copy "${template_agents}" "${AZG_GLOBAL_AGENTS}"
    azg_ownership_set_flag agents true
    ok "Installed: AGENTS.md (global, forced; backup saved to .bak)"
  elif diff -q "${template_agents}" "${AZG_GLOBAL_AGENTS}" > /dev/null 2>&1; then
    info "AGENTS.md already up-to-date, skipping"
    azg_ownership_set_flag agents true
  else
    # Owned / azg-marked AGENTS: sync AGENT-INSTRUCTIONS; strip legacy PONYTAIL if present
    local _has_ai=0 _has_pony=0 _ai_ok=0 _pony_ok=0
    grep -q '<!-- AZG:AGENT-INSTRUCTIONS:' "${AZG_GLOBAL_AGENTS}" 2>/dev/null && _has_ai=1
    grep -q '<!-- PONYTAIL:MANAGED:' "${AZG_GLOBAL_AGENTS}" 2>/dev/null && _has_pony=1
    extract_managed_block "${AZG_GLOBAL_AGENTS}" \
      '<!-- AZG:AGENT-INSTRUCTIONS:START -->' '<!-- AZG:AGENT-INSTRUCTIONS:END -->' > /dev/null 2>&1 && _ai_ok=1
    extract_managed_block "${AZG_GLOBAL_AGENTS}" \
      '<!-- PONYTAIL:MANAGED:START -->' '<!-- PONYTAIL:MANAGED:END -->' > /dev/null 2>&1 && _pony_ok=1
    if { [ "${_has_ai}" -eq 1 ] && [ "${_ai_ok}" -eq 0 ]; } \
      || { [ "${_has_pony}" -eq 1 ] && [ "${_pony_ok}" -eq 0 ]; }; then
      die "Owned AGENTS.md has malformed managed markers; use --force to refresh"
    fi
    if [ "${_ai_ok}" -eq 1 ] || [ "${_pony_ok}" -eq 1 ] \
      || [ "$(azg_ownership_get agents)" = "true" ]; then
      local agents_sync_tmp="${AZG_GLOBAL_AGENTS}.azg.sync.tmp"
      if ! cp "${AZG_GLOBAL_AGENTS}" "${agents_sync_tmp}"; then
        rm -f "${agents_sync_tmp}"
        die "Failed to prepare AGENTS.md sync temporary"
      fi
      if [ "${_ai_ok}" -eq 0 ]; then
        if [ "${_pony_ok}" -eq 1 ]; then
          # Legacy owned file: strip pony then append AGENT-INSTRUCTIONS
          :
        else
          _migrate_agent_instruction_markers "${agents_sync_tmp}" || {
            rm -f "${agents_sync_tmp}"
            die "Owned AGENTS.md lacks migratable agent-instruction markers; use --force to refresh"
          }
        fi
      fi
      local new_agent_instructions
      new_agent_instructions="$(extract_managed_block "${template_agents}" \
        '<!-- AZG:AGENT-INSTRUCTIONS:START -->' \
        '<!-- AZG:AGENT-INSTRUCTIONS:END -->')" || {
        rm -f "${agents_sync_tmp}"
        die "Failed to extract AGENTS.md agent-instruction block"
      }
      # Strip retired always-on ponytail (ADR 0015)
      if grep -q '<!-- PONYTAIL:MANAGED:START -->' "${agents_sync_tmp}" 2>/dev/null; then
        remove_managed_block "${agents_sync_tmp}" \
          "<!-- PONYTAIL:MANAGED:START -->" "<!-- PONYTAIL:MANAGED:END -->" || {
          rm -f "${agents_sync_tmp}"
          die "Failed to remove legacy PONYTAIL block from AGENTS.md"
        }
      fi
      if extract_managed_block "${agents_sync_tmp}" \
        '<!-- AZG:AGENT-INSTRUCTIONS:START -->' \
        '<!-- AZG:AGENT-INSTRUCTIONS:END -->' > /dev/null 2>&1; then
        if ! replace_managed_block "${agents_sync_tmp}" \
          "<!-- AZG:AGENT-INSTRUCTIONS:START -->" \
          "<!-- AZG:AGENT-INSTRUCTIONS:END -->" "${new_agent_instructions}"; then
          rm -f "${agents_sync_tmp}"
          die "Failed to update AGENTS.md agent-instruction block"
        fi
      else
        # No instructions block left after strip — append template block
        {
          printf '\n'
          printf '%s\n' '<!-- AZG:AGENT-INSTRUCTIONS:START -->'
          printf '%s\n' "${new_agent_instructions}"
          printf '%s\n' '<!-- AZG:AGENT-INSTRUCTIONS:END -->'
        } >>"${agents_sync_tmp}"
      fi
      if ! atomic_copy "${agents_sync_tmp}" "${AZG_GLOBAL_AGENTS}"; then
        rm -f "${agents_sync_tmp}"
        die "Failed to install synchronized AGENTS.md"
      fi
      rm -f "${agents_sync_tmp}"
      azg_ownership_set_flag agents true
      ok "Updated: AGENTS.md managed blocks (global)"
    elif [ "$(azg_ownership_get agents)" = "true" ]; then
      if grep -q '<!-- AZG:AGENT-INSTRUCTIONS:' "${AZG_GLOBAL_AGENTS}" ||
        grep -q '<!-- PONYTAIL:MANAGED:' "${AZG_GLOBAL_AGENTS}"; then
        die "Owned AGENTS.md has malformed managed markers; use --force to refresh"
      fi
      cp "${AZG_GLOBAL_AGENTS}" "${AZG_GLOBAL_AGENTS}.bak"
      atomic_copy "${template_agents}" "${AZG_GLOBAL_AGENTS}"
      ok "Installed: AGENTS.md (global, owned file refreshed; backup .bak)"
    else
      warn "Foreign AGENTS.md (no AZG:AGENT-INSTRUCTIONS markers) — skipping (use --force to overwrite)"
    fi
  fi

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
    azg_ownership_set_flag statusline true
    ok "Installed: statusline.sh"
  fi

  local settings_file="${AZG_GLOBAL_DIR}/settings.json"
  if [ -f "${settings_file}" ]; then
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
    info "Creating new settings.json with statusline configuration"
    printf '{\n  "statusLine": {\n    "type": "command",\n    "command": "%s",\n    "enabled": true\n  }\n}\n' "${statusline_path}" > "${settings_file}"
  fi
  ok "Configured: settings.json"

  source "${AZG_ROOT}/lib/apply-overlay.sh"

  local skills_copied=0
  local skills_pruned=0
  local cursor_skills_copied=0

  ensure_dir "${AZG_CURSOR_SKILLS_DIR}"
  ensure_dir "${AZG_CURSOR_RULES_DIR}"

  if [ "${skip_sync}" -eq 1 ]; then
    info "Smart Sync: VENDOR.lock commits unchanged. Skipping global skill sync."
  elif [ -d "${vendor_base_dir}" ]; then
    if [ -n "${active_skills}" ]; then
      for skill_name in ${active_skills}; do
        local sinfo
        sinfo="$(_find_skill_info "${vendor_base_dir}" "${skill_name}" || echo "")"
        [ -n "${sinfo}" ] || continue
        local category_dir="${sinfo%% *}"
        local vendor_name="${sinfo##* }"
        _install_skill_pair "${skill_name}" "${category_dir}" \
          "${template_global}/skills/overlay/${vendor_name}" "${force}" \
          skills_copied cursor_skills_copied
      done
    else
      for vendor_root in "${vendor_base_dir}"/*/; do
        [ -d "${vendor_root}" ] || continue
        local vendor_name
        vendor_name="$(basename "${vendor_root}")"

        for category_dir in "${vendor_root}"/*/; do
          [ -d "${category_dir}" ] || continue
          for skill_dir in "${category_dir}"/*/; do
            [ -d "${skill_dir}" ] || continue
            local skill_name
            skill_name="$(basename "${skill_dir}")"

            _install_skill_pair "${skill_name}" "${category_dir}" \
              "${template_global}/skills/overlay/${vendor_name}" "${force}" \
              skills_copied cursor_skills_copied
          done
        done
      done
    fi

    for vendor_root in "${vendor_base_dir}"/*/; do
      [ -d "${vendor_root}" ] || continue
      _prune_vendor_skills \
        "${AZG_GLOBAL_SKILLS_DIR}" \
        "${vendor_root}" \
        skills_pruned \
        "${active_skills}"
    done

    _prune_cursor_skills \
      "${AZG_CURSOR_SKILLS_DIR}" \
      skills_pruned \
      "${active_skills}"

    if [ -n "${new_stamp}" ]; then
      printf "%s\n" "${new_stamp}" > "${current_stamp_file}"
    fi
  else
    info "No vendor skills found at ${vendor_base_dir}"
    info "Tip: run 'azg update --vendor' to vendor skills"
  fi

  # First-party azg Device Setup skills (ADR 0020). Ship dirs under
  # templates/global/skills/azg/; prune leftover parked names not in that tree.
  local azg_skills_copied=0
  local azg_cursor_skills_copied=0
  if [ -d "${azg_skills_dir}" ]; then
    if [ ! -f "${azg_overlay_dir}/_shared/ANTIGRAVITY-NOTE.md.tmpl" ]; then
      die "azg skill overlay missing: ${azg_overlay_dir}/_shared/ANTIGRAVITY-NOTE.md.tmpl"
    fi
    local azg_skill_dir azg_skill_name
    for azg_skill_dir in "${azg_skills_dir}"/*/; do
      [ -d "${azg_skill_dir}" ] || continue
      [ -f "${azg_skill_dir}/SKILL.md" ] || continue
      azg_skill_name="$(basename "${azg_skill_dir}")"
      _install_skill_pair "${azg_skill_name}" "${azg_skills_dir}" \
        "${azg_overlay_dir}" "${force}" \
        azg_skills_copied azg_cursor_skills_copied
    done
  fi
  local parked_sk
  for parked_sk in azg-method-refs; do
    if [ -d "${azg_skills_dir}/${parked_sk}" ] && [ -f "${azg_skills_dir}/${parked_sk}/SKILL.md" ]; then
      continue
    fi
    if [ -d "${AZG_CURSOR_SKILLS_DIR}/${parked_sk}" ] \
      && { [ -f "${AZG_CURSOR_SKILLS_DIR}/${parked_sk}/AZG-OWNED.md" ] \
        || azg_ownership_list_owns cursor_skills "${parked_sk}"; }; then
      # DESTRUCTIVE: remove retired distill skill from Cursor
      rm -rf "${AZG_CURSOR_SKILLS_DIR}/${parked_sk}"
      azg_ownership_list_remove cursor_skills "${parked_sk}"
    fi
    if [ -d "${AZG_GLOBAL_SKILLS_DIR}/${parked_sk}" ] \
      && { [ -f "${AZG_GLOBAL_SKILLS_DIR}/${parked_sk}/ANTIGRAVITY-NOTE.md" ] \
        || azg_ownership_list_owns skills "${parked_sk}"; }; then
      # DESTRUCTIVE: remove retired distill skill from Gemini
      rm -rf "${AZG_GLOBAL_SKILLS_DIR}/${parked_sk}"
      azg_ownership_list_remove skills "${parked_sk}"
    fi
  done

  # Cursor azg-owned global rules (foreign-safe: only azg-*.mdc)
  local cursor_rules_installed=0
  local cursor_rules_pruned=0
  if [ -d "${cursor_rules_tmpl_dir}" ]; then
    local rule_src rule_base rule_dest
    for rule_src in "${cursor_rules_tmpl_dir}"/azg-*.mdc; do
      [ -f "${rule_src}" ] || continue
      rule_base="$(basename "${rule_src}")"
      rule_dest="${AZG_CURSOR_RULES_DIR}/${rule_base}"
      if [ -f "${rule_dest}" ] && [ "${force}" -eq 0 ] && ! azg_ownership_list_owns cursor_rules "${rule_base}"; then
        warn "Foreign Cursor rule '${rule_base}' — skipping (use --force to overwrite)"
        continue
      fi
      _render_cursor_rule "${rule_src}" "${rule_dest}" "${template_agents}"
      azg_ownership_list_add cursor_rules "${rule_base}"
      cursor_rules_installed=$((cursor_rules_installed + 1))
      ok "Installed Cursor rule: ${rule_base}"
    done
    # Prune owned rules no longer in templates (e.g. retired azg-ponytail.mdc)
    local owned_rule own_path
    own_path="$(azg_ownership_path)"
    if [ -f "${own_path}" ]; then
      while IFS= read -r owned_rule; do
        [ -n "${owned_rule}" ] || continue
        if [ ! -f "${cursor_rules_tmpl_dir}/${owned_rule}" ]; then
          if [ -f "${AZG_CURSOR_RULES_DIR}/${owned_rule}" ]; then
            rm -f "${AZG_CURSOR_RULES_DIR}/${owned_rule}"
            ok "Removed retired Cursor rule: ${owned_rule}"
          fi
          azg_ownership_list_remove cursor_rules "${owned_rule}"
          cursor_rules_pruned=$((cursor_rules_pruned + 1))
        fi
      done <<EOF
$(jq -r '.cursor_rules[]? // empty' "${own_path}")
EOF
    fi
  else
    warn "Cursor rules template dir missing: ${cursor_rules_tmpl_dir}"
  fi

  local _sum_skills=""
  if [ "${skip_sync}" -eq 1 ]; then
    _sum_skills="vendor skills up-to-date (smart sync)"
  elif [ "${skills_copied}" -gt 0 ] || [ "${cursor_skills_copied}" -gt 0 ]; then
    _sum_skills="${skills_copied} Gemini vendor skill(s), ${cursor_skills_copied} Cursor vendor skill(s) installed"
  else
    _sum_skills="no vendor skills to install (run 'azg update --vendor' to vendor skills)"
  fi
  if [ "${azg_skills_copied}" -gt 0 ] || [ "${azg_cursor_skills_copied}" -gt 0 ]; then
    _sum_skills="${_sum_skills}, ${azg_skills_copied} Gemini azg skill(s), ${azg_cursor_skills_copied} Cursor azg skill(s)"
  fi
  [ "${skills_pruned}" -gt 0 ] && _sum_skills="${_sum_skills}, ${skills_pruned} removed (deleted/inactive)"
  [ "${cursor_rules_installed}" -gt 0 ] && _sum_skills="${_sum_skills}, ${cursor_rules_installed} Cursor rule(s)"
  [ "${cursor_rules_pruned}" -gt 0 ] && _sum_skills="${_sum_skills}, ${cursor_rules_pruned} retired Cursor rule(s) removed"

  ok "Setup complete. ${_sum_skills}."
  info "Global config: ${AZG_GLOBAL_DIR}"
  info "Cursor skills: ${AZG_CURSOR_SKILLS_DIR}"
  info "Cursor rules: ${AZG_CURSOR_RULES_DIR}"
}

cmd_skill() {
  local subcmd="${1:-list}"
  shift || true

  local template_global="${AZG_ROOT}/templates/global"
  local vendor_base_dir="${template_global}/skills/vendor"
  local manifest_file="${AZG_GLOBAL_DIR}/azg-skills.json"

  case "${subcmd}" in
    list)
      require_jq
      step "Alpha-Zero-G Skill Catalog & Active Skills"
      local req_skills
      req_skills="$(_get_requested_skills "${manifest_file}")"
      local active_skills
      active_skills="$(_resolve_active_skills "${vendor_base_dir}" "${manifest_file}")"

      info "Active / Installed Skills (with auto-resolved prerequisites):"
      for ask in ${active_skills}; do
        local is_req=0
        for r in ${req_skills}; do
          if [ "${r}" = "${ask}" ]; then
            is_req=1
            break
          fi
        done
        if [ "${is_req}" -eq 1 ]; then
          printf "  ${CLR_GREEN}•${CLR_RESET} %-24s ${CLR_BLUE}[requested]${CLR_RESET}\n" "${ask}"
        else
          printf "  ${CLR_GREEN}•${CLR_RESET} %-24s ${CLR_YELLOW}[prereq]${CLR_RESET}\n" "${ask}"
        fi
      done

      echo ""
      info "Available Catalog Skills (inactive):"
      if [ -d "${vendor_base_dir}" ]; then
        for vroot in "${vendor_base_dir}"/*/; do
          [ -d "${vroot}" ] || continue
          for cdir in "${vroot}"/*/; do
            [ -d "${cdir}" ] || continue
            for sdir in "${cdir}"/*/; do
              [ -d "${sdir}" ] || continue
              [ -f "${sdir}/SKILL.md" ] || continue
              local sname
              sname="$(basename "${sdir}")"
              local is_act=0
              for ask in ${active_skills}; do
                if [ "${ask}" = "${sname}" ]; then
                  is_act=1
                  break
                fi
              done
              if [ "${is_act}" -eq 0 ]; then
                printf "  – %-24s (%s)\n" "${sname}" "${sdir#${vendor_base_dir}/}"
              fi
            done
          done
        done
      fi
      ;;

    enable)
      if [ $# -eq 0 ]; then
        die "Usage: azg skill enable <skill_name...>"
      fi
      require_jq
      ensure_dir "${AZG_GLOBAL_DIR}"
      local current_req=()
      local existing
      existing="$(_get_requested_skills "${manifest_file}")"
      for ex in ${existing}; do
        current_req+=("${ex}")
      done

      for to_add in "$@"; do
        if ! _find_skill_info "${vendor_base_dir}" "${to_add}" >/dev/null 2>&1; then
          die "Skill '${to_add}' not found in vendor catalog (${vendor_base_dir})"
        fi
        current_req+=("${to_add}")
      done

      local tmp_m="${manifest_file}.azg.tmp"
      if [ ${#current_req[@]} -gt 0 ]; then
        printf '%s\n' "${current_req[@]}" | jq -R . | jq -s '{version: 1, skills: (. | map(select(length > 0)) | unique)}' > "${tmp_m}"
      else
        printf '{\n  "version": 1,\n  "skills": []\n}\n' > "${tmp_m}"
      fi
      mv "${tmp_m}" "${manifest_file}"
      ok "Enabled skills: $*"
      cmd_setup --force
      ;;

    disable)
      if [ $# -eq 0 ]; then
        die "Usage: azg skill disable <skill_name...>"
      fi
      require_jq
      ensure_dir "${AZG_GLOBAL_DIR}"
      local current_req=()
      local defs
      defs="$(_get_requested_skills "${manifest_file}")"
      for d in ${defs}; do
        [ -n "${d}" ] && current_req+=("${d}")
      done

      local new_req=()
      for c in "${current_req[@]}"; do
        local remove=0
        for to_rm in "$@"; do
          if [ "${c}" = "${to_rm}" ]; then
            remove=1
            break
          fi
        done
        if [ "${remove}" -eq 0 ] && [ -n "${c}" ]; then
          new_req+=("${c}")
        fi
      done

      local tmp_m="${manifest_file}.azg.tmp"
      if [ ${#new_req[@]} -gt 0 ]; then
        printf '%s\n' "${new_req[@]}" | jq -R . | jq -s '{version: 1, skills: (. | map(select(length > 0)) | unique)}' > "${tmp_m}"
      else
        printf '{\n  "version": 1,\n  "skills": []\n}\n' > "${tmp_m}"
      fi
      mv "${tmp_m}" "${manifest_file}"
      ok "Disabled skills: $*"
      cmd_setup --force
      ;;

    *)
      die "Unknown skill subcommand: '${subcmd}'. Usage: azg skill [list|enable|disable]"
      ;;
  esac
}
