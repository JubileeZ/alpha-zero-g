#!/usr/bin/env bash
# lib/scaffold.sh — azg new
# Interactive scaffold engine for new Antigravity CLI projects.
# 8-question flow; produces a fully wired project directory.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

source "$REPO_ROOT/lib/common.sh"

AZG_VERSION="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo "unknown")"
TODAY="$(date +%Y-%m-%d 2>/dev/null || echo "unknown")"

# ── helpers ───────────────────────────────────────────────────────────────────

ask() {
    local prompt="$1"
    local default="${2:-}"
    local answer
    if [ -n "$default" ]; then
        printf "%s [%s]: " "$prompt" "$default" >&2
    else
        printf "%s: " "$prompt" >&2
    fi
    IFS= read -r answer
    if [ -z "$answer" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$answer"
    fi
}

ask_yn() {
    local prompt="$1"
    local default="${2:-y}"
    local answer
    while true; do
        printf "%s [%s]: " "$prompt" "$default" >&2
        IFS= read -r answer
        answer="${answer:-$default}"
        case "$answer" in
            [Yy]*) echo "yes"; return ;;
            [Nn]*) echo "no"; return ;;
            *) printf "Please answer yes or no.\n" >&2 ;;
        esac
    done
}

# Render a template file: replace {{TOKENS}} and write to dest
render_template() {
    local src="$1"
    local dst="$2"
    shift 2

    local content
    content="$(cat "$src")"

    while [ $# -ge 2 ]; do
        local key="$1"
        local val="$2"
        shift 2
        # Use awk for portable multi-line-safe substitution
        export TEMPLATE_VAL="$val"
        content="$(printf '%s' "$content" | awk -v k="{{${key}}}" '{ gsub(k, ENVIRON["TEMPLATE_VAL"]); print }')"
        unset TEMPLATE_VAL
    done

    local dst_dir
    dst_dir="$(dirname "$dst")"
    mkdir -p "$dst_dir"
    printf '%s\n' "$content" | atomic_write "$dst"
}

# Copy a template file atomically (no token substitution)
copy_template() {
    local src="$1"
    local dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"
    mkdir -p "$dst_dir"
    atomic_write "$dst" < "$src"
}

# ── stack presets ─────────────────────────────────────────────────────────────

build_commands_for_stack() {
    local stack="$1"
    case "$stack" in
        python)
            printf '| Command | What it does |\n'
            printf '|---------|-------------|\n'
            printf '| `uv sync` | Install dependencies |\n'
            printf '| `ruff check . --fix` | Lint (auto-fix) |\n'
            printf '| `ruff format .` | Format |\n'
            printf '| `pytest -v --tb=short` | Test |\n'
            printf '| `mypy src/ --strict` | Type check |\n'
            ;;
        node)
            printf '| Command | What it does |\n'
            printf '|---------|-------------|\n'
            printf '| `npm install` | Install dependencies |\n'
            printf '| `npm run lint` | Lint |\n'
            printf '| `npm run format` | Format |\n'
            printf '| `npm test` | Test |\n'
            printf '| `npx tsc --noEmit` | Type check |\n'
            ;;
        *)
            printf '| Command | What it does |\n'
            printf '|---------|-------------|\n'
            printf '| (add your lint command here) | Lint |\n'
            printf '| (add your test command here) | Test |\n'
            ;;
    esac
}

done_steps_for_stack() {
    local stack="$1"
    case "$stack" in
        python)
            printf '1. `ruff check .` exits 0\n'
            printf '2. `pytest -v` exits 0 with no failures\n'
            printf '3. `mypy src/ --strict` exits 0\n'
            printf '4. Changes committed with conventional format: `type(scope): description`\n'
            ;;
        node)
            printf '1. `npm run lint` exits 0\n'
            printf '2. `npm test` exits 0 with no failures\n'
            printf '3. `npx tsc --noEmit` exits 0\n'
            printf '4. Changes committed with conventional format: `type(scope): description`\n'
            ;;
        *)
            printf '1. Lint passes\n'
            printf '2. Tests pass with no failures\n'
            printf '3. Changes committed with conventional format: `type(scope): description`\n'
            ;;
    esac
}

# ── main scaffold flow ────────────────────────────────────────────────────────

cmd_new() {
    local target_dir=""
    local git_init="yes"
    local tracker="github"

    while [ $# -gt 0 ]; do
        case "$1" in
            --no-git)
                git_init="no"
                shift
                ;;
            --tracker)
                if [ -n "${2:-}" ]; then
                    tracker="$2"
                    shift 2
                else
                    die "Error: --tracker requires an argument."
                fi
                ;;
            -*)
                die "Error: Unknown option $1"
                ;;
            *)
                if [ -z "$target_dir" ]; then
                    target_dir="$1"
                    shift
                else
                    die "Error: Multiple target directories specified ($target_dir and $1)"
                fi
                ;;
        esac
    done

    if [ -z "$target_dir" ]; then
        printf 'Usage: azg new <target-dir> [--no-git] [--tracker <github|gitlab|local|none>]\n' >&2
        exit 1
    fi

    local project_name
    project_name="$(basename "$target_dir")"

    if [ -e "$target_dir" ]; then
        printf 'Error: "%s" already exists. Choose a different name or use "azg apply" to retrofit.\n' "$target_dir" >&2
        exit 1
    fi

    printf 'Scaffolding "%s"...\n' "$project_name" >&2
    mkdir -p "$target_dir"

    local tmpl_proj="$REPO_ROOT/templates/project"

    # Copy .agents/ skeleton and hooks
    copy_template \
        "$tmpl_proj/.agents/hooks/block-destructive-ops.sh" \
        "$target_dir/.agents/hooks/block-destructive-ops.sh"
    chmod +x "$target_dir/.agents/hooks/block-destructive-ops.sh"

    copy_template \
        "$tmpl_proj/.agents/hooks/commit-gate.sh" \
        "$target_dir/.agents/hooks/commit-gate.sh"
    chmod +x "$target_dir/.agents/hooks/commit-gate.sh"

    copy_template \
        "$tmpl_proj/.agents/hooks/checkpoint.sh" \
        "$target_dir/.agents/hooks/checkpoint.sh"
    chmod +x "$target_dir/.agents/hooks/checkpoint.sh"

    copy_template \
        "$tmpl_proj/.agents/hooks/spawn-budget.sh" \
        "$target_dir/.agents/hooks/spawn-budget.sh"
    chmod +x "$target_dir/.agents/hooks/spawn-budget.sh"

    copy_template \
        "$tmpl_proj/.agents/hooks/pre-compact.sh" \
        "$target_dir/.agents/hooks/pre-compact.sh"
    chmod +x "$target_dir/.agents/hooks/pre-compact.sh"

    copy_template "$tmpl_proj/.agents/hooks.json" "$target_dir/.agents/hooks.json"
    copy_template "$tmpl_proj/.agents/spawn-budget.json" "$target_dir/.agents/spawn-budget.json"
    copy_template "$tmpl_proj/.agents/session-handoff.md.tmpl" "$target_dir/.agents/session-handoff.md"

    # Copy .cursor/rules/ (.mdc — Cursor ignores plain .md rules)
    mkdir -p "$target_dir/.cursor/rules"
    copy_template "$tmpl_proj/.cursor/rules/read-agents-md.mdc" "$target_dir/.cursor/rules/read-agents-md.mdc"
    copy_template "$tmpl_proj/.cursor/rules/work-state-continuity.mdc" "$target_dir/.cursor/rules/work-state-continuity.mdc"

    # Copy Cursor hook adapters
    mkdir -p "$target_dir/.cursor/hooks"
    copy_template "$tmpl_proj/.cursor/hooks.json" "$target_dir/.cursor/hooks.json"
    for chook in commit-verify.sh stop-checkpoint.sh pre-compact.sh; do
        copy_template "$tmpl_proj/.cursor/hooks/$chook" "$target_dir/.cursor/hooks/$chook"
        chmod +x "$target_dir/.cursor/hooks/$chook"
    done

    # Copy VSCode settings
    copy_template "$tmpl_proj/.vscode/settings.json" "$target_dir/.vscode/settings.json"

    # Copy test harness + portable verify gate
    copy_template "$tmpl_proj/tests/test-harness.sh" "$target_dir/tests/test-harness.sh"
    chmod +x "$target_dir/tests/test-harness.sh"
    copy_template "$tmpl_proj/tests/verify.sh" "$target_dir/tests/verify.sh"
    chmod +x "$target_dir/tests/verify.sh"

    # Copy pre-seeded agent guides
    copy_template "$tmpl_proj/docs/agents/triage-labels.md" "$target_dir/docs/agents/triage-labels.md"
    copy_template "$tmpl_proj/docs/agents/domain.md" "$target_dir/docs/agents/domain.md"
    copy_template "$tmpl_proj/docs/agents/CONTEXT.md.tmpl" "$target_dir/docs/agents/CONTEXT.md.tmpl"

    # Copy the correct issue-tracker template based on selected tracker
    local tracker_src=""
    if [ "$tracker" = "github" ]; then
        tracker_src="$tmpl_proj/docs/agents/issue-tracker.md"
    elif [ "$tracker" = "gitlab" ]; then
        tracker_src="$REPO_ROOT/templates/global/skills/vendor/mattpocock-skills/engineering/setup-matt-pocock-skills/issue-tracker-gitlab.md"
    elif [ "$tracker" = "local" ]; then
        tracker_src="$REPO_ROOT/templates/global/skills/vendor/mattpocock-skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md"
    fi

    if [ -n "$tracker_src" ] && [ -f "$tracker_src" ]; then
        copy_template "$tracker_src" "$target_dir/docs/agents/issue-tracker.md"
    else
        # None or fallback
        printf "# Issue tracker: None\n\nNo external issue tracker is configured.\nAll work state is tracked locally on the filesystem using task.md and ROADMAP.md.\n" > "$target_dir/docs/agents/issue-tracker.md"
    fi

    # Build commands default table
    local build_cmds_table='| Command | What it does |
|---------|-------------|
| `bash tests/verify.sh` | Portable delivery gate (harness + project validation) |
| `bash tests/test-harness.sh` | Harness integrity self-check |'

    # Render AGENTS.md
    render_template \
        "$tmpl_proj/AGENTS.md.tmpl" \
        "$target_dir/AGENTS.md" \
        "PROJECT_NAME" "$project_name" \
        "AZG_VERSION" "$AZG_VERSION" \
        "DATE" "$TODAY" \
        "BUILD_COMMANDS" "$build_cmds_table"

    # Render ROADMAP.md
    render_template \
        "$tmpl_proj/ROADMAP.md.tmpl" \
        "$target_dir/ROADMAP.md" \
        "PROJECT_NAME" "$project_name" \
        "AZG_VERSION" "$AZG_VERSION" \
        "DATE" "$TODAY" \
        "BUILD_COMMANDS" "$build_cmds_table"

    # Render docs/agents/current-state.md
    render_template \
        "$tmpl_proj/docs/agents/current-state.md.tmpl" \
        "$target_dir/docs/agents/current-state.md" \
        "PROJECT_NAME" "$project_name" \
        "AZG_VERSION" "$AZG_VERSION" \
        "DATE" "$TODAY" \
        "BUILD_COMMANDS" "$build_cmds_table"

    # Render docs/agents/progress.md
    render_template \
        "$tmpl_proj/docs/agents/progress.md.tmpl" \
        "$target_dir/docs/agents/progress.md" \
        "PROJECT_NAME" "$project_name" \
        "AZG_VERSION" "$AZG_VERSION" \
        "DATE" "$TODAY" \
        "BUILD_COMMANDS" "$build_cmds_table"

    # Render task.md from template
    render_template \
        "$tmpl_proj/task.md.tmpl" \
        "$target_dir/task.md" \
        "TASK_NAME" "Initial project setup"

    # Git init
    if [ "$git_init" = "yes" ]; then
        if command -v git >/dev/null 2>&1; then
            (
                cd "$target_dir"
                git init -q
                git add .
                git commit -q -m "chore: scaffold project with Alpha-Zero-G v${AZG_VERSION}"
            )
        else
            printf 'Warning: git not found; skipping git init.\n' >&2
        fi
    fi

    printf '\nDone! Project scaffolded at: %s\n' "$target_dir" >&2
    printf '\nNext steps:\n' >&2
    printf '  1. cd %s\n' "$project_name" >&2
    printf '  2. bash tests/verify.sh  (portable delivery gate)\n' >&2
    printf '  3. agy  (start your first session)\n\n' >&2
}
