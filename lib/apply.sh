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
    local target_dir=""
    local dry_run="no"
    local tracker=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --dry-run)
                dry_run="yes"
                shift
                ;;
            --tracker)
                if [ -n "${2:-}" ]; then
                    tracker="$2"
                    shift 2
                else
                    err "Error: --tracker requires an argument."
                    exit 1
                fi
                ;;
            -*)
                err "Error: Unknown option $1"
                exit 1
                ;;
            *)
                if [ -z "$target_dir" ]; then
                    target_dir="$1"
                    shift
                else
                    err "Error: Multiple target directories specified ($target_dir and $1)"
                    exit 1
                fi
                ;;
        esac
    done

    target_dir="${target_dir:-.}"

    if [ ! -d "$target_dir" ]; then
        err "Target directory '$target_dir' does not exist."
        exit 1
    fi

    if [ -n "$tracker" ]; then
        if [ "$tracker" != "github" ] && [ "$tracker" != "gitlab" ] && [ "$tracker" != "local" ] && [ "$tracker" != "none" ]; then
            err "Error: Invalid tracker type '$tracker'. Allowed values are: github, gitlab, local, none."
            exit 1
        fi
    fi

    require_jq

    local tmpl_proj="$REPO_ROOT/templates/project"
    
    if [ "$dry_run" != "yes" ]; then
        printf "Retrofitting '%s' with azg harness...\n" "$target_dir"
    fi

    # 1. Additive copy of hooks
    if [ "$dry_run" != "yes" ]; then
        ensure_dir "$target_dir/.agents/hooks"
    fi
    for hook_file in "$tmpl_proj/.agents/hooks"/*; do
        if [ -f "$hook_file" ]; then
            local base
            base="$(basename "$hook_file")"
            if [ -f "$target_dir/.agents/hooks/$base" ]; then
                if [ "$dry_run" = "yes" ]; then
                    printf "[SKIP] .agents/hooks/%s (already exists)\n" "$base"
                else
                    warn "Skipping existing hook: $base"
                fi
            else
                if [ "$dry_run" = "yes" ]; then
                    printf "[COPY] .agents/hooks/%s\n" "$base"
                else
                    copy_template "$hook_file" "$target_dir/.agents/hooks/$base"
                    chmod +x "$target_dir/.agents/hooks/$base"
                    info "Copied hook: $base"
                fi
            fi
        fi
    done

    # 2. Additive copy of skills
    if [ "$dry_run" != "yes" ]; then
        ensure_dir "$target_dir/.agents/skills"
    fi
    for item in "$tmpl_proj/.agents/skills"/*; do
        if [ -e "$item" ]; then
            local base
            base="$(basename "$item")"
            if [ -e "$target_dir/.agents/skills/$base" ]; then
                if [ "$dry_run" = "yes" ]; then
                    printf "[SKIP] .agents/skills/%s (already exists)\n" "$base"
                else
                    warn "Skipping existing skill: $base"
                fi
            else
                if [ "$dry_run" = "yes" ]; then
                    printf "[COPY] .agents/skills/%s\n" "$base"
                else
                    cp -R "$item" "$target_dir/.agents/skills/"
                    info "Copied skill: $base"
                fi
            fi
        fi
    done

    # 3. Merge hooks.json
    if [ ! -f "$target_dir/.agents/hooks.json" ]; then
        if [ "$dry_run" = "yes" ]; then
            printf "[CREATE] .agents/hooks.json\n"
        else
            copy_template "$tmpl_proj/.agents/hooks.json" "$target_dir/.agents/hooks.json"
            info "Created hooks.json"
        fi
    else
        if [ "$dry_run" = "yes" ]; then
            printf "[MERGE] .agents/hooks.json\n"
        else
            jq -s '(.[1] | map_values(.enabled = false)) * .[0]' "$target_dir/.agents/hooks.json" "$tmpl_proj/.agents/hooks.json" | atomic_write "$target_dir/.agents/hooks.json"
            info "Merged hooks.json"
        fi
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
    
    local rendered_tmpl
    rendered_tmpl="$(mktemp)"
    render_template "$tmpl" "$rendered_tmpl" \
        "PROJECT_NAME" "$project_name" \
        "AZG_VERSION" "$azg_version" \
        "DATE" "$today" \
        "BUILD_COMMANDS" "$build_cmds_table"

    local new_managed_block
    new_managed_block="$(awk '/<!-- AZG:MANAGED:START -->/{f=1; next} /<!-- AZG:MANAGED:END -->/{f=0} f' "$rendered_tmpl")"

    if [ ! -f "$dst" ]; then
        if [ "$dry_run" = "yes" ]; then
            printf "[CREATE] %s\n" "$doc"
        else
            copy_template "$rendered_tmpl" "$dst"
            info "Created $doc"
        fi
    else
        if [ "$dry_run" = "yes" ]; then
            if grep -q "<!-- AZG:MANAGED:START -->" "$dst"; then
                printf "[UPDATE] %s (managed block)\n" "$doc"
                local tmp_proposed
                tmp_proposed="$(mktemp)"
                cp "$dst" "$tmp_proposed"
                replace_managed_block "$tmp_proposed" "<!-- AZG:MANAGED:START -->" "<!-- AZG:MANAGED:END -->" "$new_managed_block" >/dev/null
                diff -u "$dst" "$tmp_proposed" || true
                rm -f "$tmp_proposed"
            else
                printf "[UPDATE] %s (append managed block)\n" "$doc"
                local tmp_proposed
                tmp_proposed="$(mktemp)"
                cp "$dst" "$tmp_proposed"
                {
                    echo ""
                    echo "<!-- AZG:MANAGED:START -->"
                    echo "$new_managed_block"
                    echo "<!-- AZG:MANAGED:END -->"
                } >> "$tmp_proposed"
                diff -u "$dst" "$tmp_proposed" || true
                rm -f "$tmp_proposed"
            fi
        else
            if grep -q "<!-- AZG:MANAGED:START -->" "$dst"; then
                if replace_managed_block "$dst" "<!-- AZG:MANAGED:START -->" "<!-- AZG:MANAGED:END -->" "$new_managed_block"; then
                    info "Updated managed block in $doc"
                else
                    err "Failed to update managed block in $doc"
                fi
            else
                {
                    echo ""
                    echo "<!-- AZG:MANAGED:START -->"
                    echo "$new_managed_block"
                    echo "<!-- AZG:MANAGED:END -->"
                } >> "$dst"
                info "Appended managed block to $doc"
            fi
        fi
    fi
    rm -f "$rendered_tmpl"

    # 5. Handle .cursor/rules/
    if [ "$dry_run" != "yes" ]; then
        ensure_dir "$target_dir/.cursor/rules"
    fi
    for rule in "$tmpl_proj/.cursor/rules"/*; do
        if [ -f "$rule" ]; then
            local base
            base="$(basename "$rule")"
            if [ -f "$target_dir/.cursor/rules/$base" ]; then
                if [ "$dry_run" = "yes" ]; then
                    printf "[SKIP] .cursor/rules/%s (already exists)\n" "$base"
                fi
            else
                if [ "$dry_run" = "yes" ]; then
                    printf "[COPY] .cursor/rules/%s\n" "$base"
                else
                    copy_template "$rule" "$target_dir/.cursor/rules/$base"
                    info "Copied Cursor rule: $base"
                fi
            fi
        fi
    done

    # 6. Handle ROADMAP.md, docs/agents/current-state.md, docs/agents/progress.md
    for doc in "ROADMAP.md" "docs/agents/current-state.md" "docs/agents/progress.md"; do
        local tmpl="$tmpl_proj/${doc}.tmpl"
        local dst="$target_dir/$doc"
        if [ ! -f "$dst" ]; then
            if [ "$dry_run" = "yes" ]; then
                printf "[CREATE] %s\n" "$doc"
            else
                render_template "$tmpl" "$dst" \
                    "PROJECT_NAME" "$project_name" \
                    "AZG_VERSION" "$azg_version" \
                    "DATE" "$today" \
                    "BUILD_COMMANDS" "$build_cmds_table"
                info "Created $doc"
            fi
        else
            if [ "$dry_run" = "yes" ]; then
                printf "[SKIP] %s (already exists)\n" "$doc"
            else
                warn "Skipping existing tracking file: $doc"
            fi
        fi
    done

    # 7. Copy triage-labels.md, domain.md, and CONTEXT.md.tmpl if they do not exist
    for doc in "docs/agents/triage-labels.md" "docs/agents/domain.md" "docs/agents/CONTEXT.md.tmpl"; do
        local src="$tmpl_proj/$doc"
        local dst="$target_dir/$doc"
        if [ ! -f "$dst" ]; then
            if [ "$dry_run" = "yes" ]; then
                printf "[CREATE] %s\n" "$doc"
            else
                ensure_dir "$(dirname "$dst")"
                copy_template "$src" "$dst"
                info "Created $doc"
            fi
        else
            if [ "$dry_run" = "yes" ]; then
                printf "[SKIP] %s (already exists)\n" "$doc"
            fi
        fi
    done

    # 8. Copy or generate issue-tracker.md
    local active_tracker="${tracker:-}"
    if [ -z "$active_tracker" ]; then
        if [ ! -f "$target_dir/docs/agents/issue-tracker.md" ]; then
            active_tracker="github"
        fi
    fi

    if [ -n "$active_tracker" ]; then
        local tracker_src=""
        if [ "$active_tracker" = "github" ]; then
            tracker_src="$tmpl_proj/docs/agents/issue-tracker.md"
        elif [ "$active_tracker" = "gitlab" ]; then
            tracker_src="$REPO_ROOT/templates/global/skills/vendor/mattpocock-skills/engineering/setup-matt-pocock-skills/issue-tracker-gitlab.md"
        elif [ "$active_tracker" = "local" ]; then
            tracker_src="$REPO_ROOT/templates/global/skills/vendor/mattpocock-skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md"
        fi

        if [ "$dry_run" = "yes" ]; then
            if [ -f "$target_dir/docs/agents/issue-tracker.md" ]; then
                printf "[UPDATE] docs/agents/issue-tracker.md (overwrite to %s)\n" "$active_tracker"
            else
                printf "[CREATE] docs/agents/issue-tracker.md (tracker: %s)\n" "$active_tracker"
            fi
        else
            ensure_dir "$target_dir/docs/agents"
            if [ -n "$tracker_src" ] && [ -f "$tracker_src" ]; then
                copy_template "$tracker_src" "$target_dir/docs/agents/issue-tracker.md"
                info "Created docs/agents/issue-tracker.md (tracker: $active_tracker)"
            else
                # none or fallback
                printf "# Issue tracker: None\n\nNo external issue tracker is configured.\nAll work state is tracked locally on the filesystem using task.md and ROADMAP.md.\n" > "$target_dir/docs/agents/issue-tracker.md"
                info "Created docs/agents/issue-tracker.md (tracker: $active_tracker)"
            fi
        fi
    else
        if [ "$dry_run" = "yes" ]; then
            printf "[SKIP] docs/agents/issue-tracker.md (already exists)\n"
        fi
    fi

    if [ "$dry_run" != "yes" ]; then
        ok "Retrofit complete."
    fi
}
