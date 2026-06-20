#!/usr/bin/env bash
# lib/apply.sh — azg apply
# Retrofits existing projects with the azg harness.
# Sourced by the azg dispatcher; do NOT run directly.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=lib/scaffold.sh
source "$REPO_ROOT/lib/scaffold.sh"

cmd_apply() {
    local target_dir="${1:-.}"
    if [ ! -d "$target_dir" ]; then
        err "Target directory '$target_dir' does not exist."
        exit 1
    fi

    require_jq

    local tmpl_proj="$REPO_ROOT/templates/project"
    
    printf "Retrofitting '%s' with azg harness...\n" "$target_dir"

    # 1. Additive copy of hooks
    ensure_dir "$target_dir/.agents/hooks"
    for hook_file in "$tmpl_proj/.agents/hooks"/*; do
        if [ -f "$hook_file" ]; then
            local base
            base="$(basename "$hook_file")"
            if [ -f "$target_dir/.agents/hooks/$base" ]; then
                warn "Skipping existing hook: $base"
            else
                copy_template "$hook_file" "$target_dir/.agents/hooks/$base"
                chmod +x "$target_dir/.agents/hooks/$base"
                info "Copied hook: $base"
            fi
        fi
    done

    # 2. Additive copy of skills
    ensure_dir "$target_dir/.agents/skills"
    for item in "$tmpl_proj/.agents/skills"/*; do
        if [ -e "$item" ]; then
            local base
            base="$(basename "$item")"
            if [ -e "$target_dir/.agents/skills/$base" ]; then
                warn "Skipping existing skill: $base"
            else
                cp -R "$item" "$target_dir/.agents/skills/"
                info "Copied skill: $base"
            fi
        fi
    done

    # 3. Merge hooks.json
    if [ ! -f "$target_dir/.agents/hooks.json" ]; then
        copy_template "$tmpl_proj/.agents/hooks.json" "$target_dir/.agents/hooks.json"
        info "Created hooks.json"
    else
        jq -s '(.[1] | map_values(.enabled = false)) * .[0]' "$target_dir/.agents/hooks.json" "$tmpl_proj/.agents/hooks.json" | atomic_write "$target_dir/.agents/hooks.json"
        info "Merged hooks.json"
    fi

    # 4. Handle AGENTS.md
    local project_name
    project_name="$(basename "$(cd "$target_dir" && pwd)")"
    local azg_version
    azg_version="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "unknown")"
    local today
    today="$(date +%Y-%m-%d 2>/dev/null || echo "unknown")"

    local build_cmds_table
    build_cmds_table='| Command | What it does |
|---------|-------------|
| (add your lint command here) | Lint |
| (add your test command here) | Test |'

    local doc="AGENTS.md"
    local tmpl="$tmpl_proj/$doc.tmpl"
    local dst="$target_dir/$doc"
    
    if [ ! -f "$dst" ]; then
        render_template "$tmpl" "$dst" \
            "PROJECT_NAME" "$project_name" \
            "AZG_VERSION" "$azg_version" \
            "DATE" "$today" \
            "BUILD_COMMANDS" "$build_cmds_table"
        info "Created $doc"
    else
        local rendered_tmpl
        rendered_tmpl="$(mktemp)"
        render_template "$tmpl" "$rendered_tmpl" \
            "PROJECT_NAME" "$project_name" \
            "AZG_VERSION" "$azg_version" \
            "DATE" "$today" \
            "BUILD_COMMANDS" "$build_cmds_table"
        
        if grep -q '<!-- AZG:MANAGED:START -->' "$dst"; then
            export MANAGED_CONTENT="$(cat "$rendered_tmpl")"
            awk '
            BEGIN { in_block = 0 }
            /<!-- AZG:MANAGED:START -->/ {
                print "<!-- AZG:MANAGED:START -->"
                print ENVIRON["MANAGED_CONTENT"]
                print "<!-- AZG:MANAGED:END -->"
                in_block = 1
                next
            }
            /<!-- AZG:MANAGED:END -->/ {
                in_block = 0
                next
            }
            !in_block { print }
            ' "$dst" | atomic_write "$dst"
            info "Updated managed block in $doc"
        else
            {
                echo ""
                echo "<!-- AZG:MANAGED:START -->"
                cat "$rendered_tmpl"
                echo "<!-- AZG:MANAGED:END -->"
            } >> "$dst"
            info "Appended managed block to $doc"
        fi
        rm -f "$rendered_tmpl"
    fi

    ok "Retrofit complete."
}
