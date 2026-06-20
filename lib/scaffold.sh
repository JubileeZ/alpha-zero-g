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
    local target_dir="${1:-}"

    printf '\nAlpha-Zero-G — New Project Scaffold\n' >&2
    printf '=====================================\n\n' >&2

    # Q1: Project name / directory
    local project_name
    if [ -n "$target_dir" ]; then
        project_name="$(basename "$target_dir")"
    else
        project_name="$(ask 'Q1. Project name (used as directory name)')"
        if [ -z "$project_name" ]; then
            printf 'Error: project name is required.\n' >&2
            exit 1
        fi
        target_dir="$(pwd)/$project_name"
    fi

    if [ -e "$target_dir" ]; then
        printf 'Error: "%s" already exists. Choose a different name or use "azg apply" to retrofit.\n' "$target_dir" >&2
        exit 1
    fi

    # Q2: Stack
    printf '\nQ2. Technology stack:\n' >&2
    printf '  1) Python + uv\n' >&2
    printf '  2) Node / TypeScript\n' >&2
    printf '  3) Other\n' >&2
    local stack_choice
    stack_choice="$(ask 'Choose [1/2/3]' '1')"
    local stack
    case "$stack_choice" in
        1) stack="python" ;;
        2) stack="node" ;;
        *) stack="other" ;;
    esac

    # Q3: Custom build commands (or accept defaults from stack)
    local build_cmds_table
    build_cmds_table="$(build_commands_for_stack "$stack")"
    local done_steps
    done_steps="$(done_steps_for_stack "$stack")"

    printf '\nQ3. Build commands (press Enter to accept defaults for %s):\n' "$stack" >&2
    local custom
    custom="$(ask_yn 'Customize build commands?' 'n')"
    if [ "$custom" = "yes" ]; then
        printf 'Enter each command on one line. Enter an empty line to finish.\n' >&2
        build_cmds_table='| Command | What it does |
|---------|-------------|'
        done_steps=""
        local step=1
        while true; do
            local line
            line="$(ask "  Step $step command (empty to finish)")"
            [ -z "$line" ] && break
            local desc
            desc="$(ask "  Step $step description")"
            build_cmds_table="${build_cmds_table}
| \`${line}\` | ${desc} |"
            done_steps="${done_steps}${step}. \`${line}\` exits 0\n"
            step=$((step + 1))
        done
    fi

    # Q4: mattpocock skills
    printf '\nQ4. The "setup-matt-pocock-skills" global skill will be available after azg setup.\n' >&2
    printf '    After scaffolding, run it inside your first agy session to set up issue tracking.\n' >&2
    local remind_skills
    remind_skills="yes"

    # Q5: MCP servers
    printf '\nQ5. MCP servers to include in .agents/mcp_config.json:\n' >&2
    printf '  1) None\n' >&2
    printf '  2) GitHub MCP\n' >&2
    printf '  3) Browser (headless Chrome)\n' >&2
    printf '  4) Custom path\n' >&2
    local mcp_choice
    mcp_choice="$(ask 'Choose [1/2/3/4]' '1')"

    # Q6: Git init
    local git_init
    git_init="$(ask_yn 'Q6. Run git init and create initial commit?' 'y')"

    # ── scaffold the project ──────────────────────────────────────────────────

    printf '\nScaffolding "%s"...\n' "$project_name" >&2
    mkdir -p "$target_dir"

    local tmpl_proj="$REPO_ROOT/templates/project"

    # Copy .agents/ skeleton — safety-gate hook only
    copy_template \
        "$tmpl_proj/.agents/hooks/block-destructive-ops.sh" \
        "$target_dir/.agents/hooks/block-destructive-ops.sh"
    chmod +x "$target_dir/.agents/hooks/block-destructive-ops.sh"

    # Copy hooks.json (safety-gate only)
    copy_template "$tmpl_proj/.agents/hooks.json" "$target_dir/.agents/hooks.json"

    # Copy skills placeholder
    copy_template "$tmpl_proj/.agents/skills/.gitkeep" "$target_dir/.agents/skills/.gitkeep"

    # MCP config
    case "$mcp_choice" in
        2)
            printf '{"mcpServers":{"github":{"command":"npx","args":["-y","@modelcontextprotocol/server-github"]}}}\n' | \
                atomic_write "$target_dir/.agents/mcp_config.json"
            ;;
        3)
            printf '{"mcpServers":{"browser":{"command":"npx","args":["-y","@modelcontextprotocol/server-puppeteer"]}}}\n' | \
                atomic_write "$target_dir/.agents/mcp_config.json"
            ;;
        4)
            local custom_mcp
            custom_mcp="$(ask 'Path to custom mcp_config.json')"
            if [ -f "$custom_mcp" ]; then
                copy_template "$custom_mcp" "$target_dir/.agents/mcp_config.json"
            else
                printf '{"mcpServers":{}}\n' | atomic_write "$target_dir/.agents/mcp_config.json"
                printf 'Warning: custom MCP config not found; wrote empty config.\n' >&2
            fi
            ;;
        *)
            printf '{"mcpServers":{}}\n' | atomic_write "$target_dir/.agents/mcp_config.json"
            ;;
    esac

    # Render AGENTS.md
    render_template \
        "$tmpl_proj/AGENTS.md.tmpl" \
        "$target_dir/AGENTS.md" \
        "PROJECT_NAME" "$project_name" \
        "AZG_VERSION" "$AZG_VERSION" \
        "DATE" "$TODAY" \
        "BUILD_COMMANDS" "$build_cmds_table"

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
    printf '  2. agy  (start your first session)\n' >&2
    if [ "$remind_skills" = "yes" ]; then
        printf '  3. Inside agy: run the "setup-matt-pocock-skills" skill to configure issue tracking.\n' >&2
    fi
    printf '\n' >&2
}
