#!/usr/bin/env bash

# Alpha-Zero-G Bidirectional Harness Upgrader Utility
# Synchronizes Project Infrastructure Files between core templates and downstream projects.

set -euo pipefail

# Visual styling
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
MODE="push" # push, pull, diff
AUTO_APPROVE="false"
TARGET_DIR=""

show_usage() {
    echo -e "Usage: bash upgrade-project.sh [options] <downstream-project-path>"
    echo -e "\nOptions:"
    echo -e "  --push                Propagate core template updates to the downstream project (Default)"
    echo -e "  --pull, --backport    Pull local optimizations from downstream back into core templates"
    echo -e "  --diff, --dry-run     Display differences between core and downstream without writing any files"
    echo -e "  -y, --yes             Skip confirmation prompts and automatically apply all changes"
    echo -e "  -h, --help            Show this help message"
    echo -e "\nExample:"
    echo -e "  bash upgrade-project.sh --push ../FPL-Jubilee-Ascent"
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --push)
            MODE="push"
            shift
            ;;
        --pull|--backport)
            MODE="pull"
            shift
            ;;
        --diff|--dry-run)
            MODE="diff"
            shift
            ;;
        -y|--yes)
            AUTO_APPROVE="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_usage
            exit 1
            ;;
        *)
            if [ -z "${TARGET_DIR}" ]; then
                TARGET_DIR="$1"
            else
                echo -e "${RED}Error: Multiple target directories specified.${NC}"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "${TARGET_DIR}" ]; then
    echo -e "${RED}Error: Missing target downstream project directory.${NC}"
    show_usage
    exit 1
fi

# Resolve absolute paths
CORE_ROOT=$(pwd)
if [ ! -f "${CORE_ROOT}/create-project.sh" ]; then
    echo -e "${RED}Error: upgrade-project.sh must be run from the Alpha-Zero-G repository root.${NC}"
    exit 1
fi

if [ ! -d "${TARGET_DIR}" ]; then
    echo -e "${RED}Error: Target directory '${TARGET_DIR}' does not exist.${NC}"
    exit 1
fi
TARGET_ROOT_ABS=$(cd "${TARGET_DIR}" && pwd)

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Alpha-Zero-G Harness Upgrader              ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "Core Template Repo: ${GREEN}${CORE_ROOT}${NC}"
echo -e "Target Downstream:  ${GREEN}${TARGET_ROOT_ABS}${NC}"
echo -e "Sync Mode:          ${GREEN}${MODE}${NC}"
echo -e "Auto Approve:       ${GREEN}${AUTO_APPROVE}${NC}"
echo -e "${BLUE}===============================================${NC}\n"

# Verify target Git status (Safety Check)
if [ -d "${TARGET_ROOT_ABS}/.git" ]; then
    echo -e "Checking git working tree in downstream..."
    if ! (cd "${TARGET_ROOT_ABS}" && git diff --quiet); then
        echo -e "${YELLOW}Warning: Downstream project has uncommitted changes.${NC}"
        if [ "${AUTO_APPROVE}" = "false" ]; then
            read -p "Are you sure you want to proceed? [y/N]: " PROCEED
            if [[ ! "${PROCEED}" =~ ^[yY](es)?$ ]]; then
                echo -e "${RED}Aborted by user.${NC}"
                exit 1
            fi
        fi
    else
        echo -e "  - Downstream git working tree is clean."
    fi
fi

# Definitions of Project Infrastructure Files to Sync (Source relative to CORE, Target relative to downstream)
# Format: "core_source_path:target_dest_path:has_placeholders"
FILES_TO_SYNC=(
    "templates/init.sh:init.sh:false"
    ".agents/hooks.json:.agents/hooks.json:false"
    "templates/DEVELOPER_WORKFLOW.md:DEVELOPER_WORKFLOW.md:true"
    "templates/AGENTS.md:AGENTS.md:true"
    "docs/architecture.md:docs/architecture.md:false"
    "docs/quality.md:docs/quality.md:false"
    "templates/docs/CONTEXT-FORMAT.md:docs/CONTEXT-FORMAT.md:false"
    "templates/docs/ADR-FORMAT.md:docs/ADR-FORMAT.md:false"
    "templates/docs/adr/0000-adr-template.md:docs/adr/0000-adr-template.md:false"
    "docs/adr/0001-dynamic-bootstrapping.md:docs/adr/0001-dynamic-bootstrapping.md:false"
    "docs/adr/0002-automated-project-scaffolder.md:docs/adr/0002-automated-project-scaffolder.md:false"
    "docs/adr/0003-bidirectional-harness-upgrader.md:docs/adr/0003-bidirectional-harness-upgrader.md:false"
)

# Discovery helper for placeholders
get_parameter_values() {
    # Extract project name from target AGENTS.md or default to folder name
    if [ -f "${TARGET_ROOT_ABS}/AGENTS.md" ]; then
        PARAM_NAME=$(grep -oE '^# Agent Harness — .*' "${TARGET_ROOT_ABS}/AGENTS.md" | head -n 1 | sed 's/# Agent Harness — //')
    fi
    if [ -z "${PARAM_NAME:-}" ]; then
        PARAM_NAME=$(basename "${TARGET_ROOT_ABS}")
    fi

    # Extract project description from target AGENTS.md or default
    if [ -f "${TARGET_ROOT_ABS}/AGENTS.md" ]; then
        PARAM_DESC=$(awk '/## What This Project Is/{getline; if ($0 == "") getline; print}' "${TARGET_ROOT_ABS}/AGENTS.md" | head -n 1)
    fi
    if [ -z "${PARAM_DESC:-}" ]; then
        PARAM_DESC="Statistical Analytics Project bootstrapped from Alpha-Zero-G"
    fi

    PARAM_ROOT="${TARGET_ROOT_ABS}"
}

# Helper to escape paths for sed
escape_sed() {
    echo "$1" | sed 's/\//\\\//g'
}

# Perform beautiful git color diff
show_file_diff() {
    local file1="$1"
    local file2="$2"
    local label1="$3"
    local label2="$4"

    if command -v git >/dev/null 2>&1; then
        git diff --no-index --color "${file1}" "${file2}" || true
    else
        diff -u --label "${label1}" --label "${label2}" "${file1}" "${file2}" || true
    fi
}

# Initialize parameter discovery
get_parameter_values

# Setup temporary directory for processing placeholders
TMP_DIR=$(mktemp -d -t alpha-zero-g-upgrader-XXXXXX)
trap 'rm -rf "${TMP_DIR}"' EXIT

# Main processing loop
CHANGES_COUNT=0

for file_entry in "${FILES_TO_SYNC[@]}"; do
    IFS=':' read -r core_rel target_rel has_placeholders <<< "${file_entry}"
    
    CORE_FILE="${CORE_ROOT}/${core_rel}"
    TARGET_FILE="${TARGET_ROOT_ABS}/${target_rel}"
    
    # Ensure source core file exists
    if [ "${MODE}" != "pull" ] && [ ! -f "${CORE_FILE}" ]; then
        echo -e "${RED}Error: Core file '${CORE_FILE}' is missing!${NC}"
        exit 1
    fi
    
    # Process files depending on mode
    if [ "${MODE}" = "push" ] || [ "${MODE}" = "diff" ]; then
        # Check if target directory needs to be created
        TARGET_DIR_PATH=$(dirname "${TARGET_FILE}")
        
        # Core source file
        SRC_TO_COMPARE="${CORE_FILE}"
        
        # If the file has placeholders, replace them in a temp file first for fair comparison
        if [ "${has_placeholders}" = "true" ]; then
            ESCAPED_ROOT=$(escape_sed "${PARAM_ROOT}")
            ESCAPED_NAME=$(escape_sed "${PARAM_NAME}")
            ESCAPED_DESC=$(escape_sed "${PARAM_DESC}")
            
            sed -e "s/{{PROJECT_NAME}}/${ESCAPED_NAME}/g" \
                -e "s/{{PROJECT_DESCRIPTION}}/${ESCAPED_DESC}/g" \
                -e "s/{{PROJECT_ROOT}}/${ESCAPED_ROOT}/g" \
                "${CORE_FILE}" > "${TMP_DIR}/compare_push"
            SRC_TO_COMPARE="${TMP_DIR}/compare_push"
        fi
        
        # Compare
        FILES_DIFFER=false
        if [ ! -f "${TARGET_FILE}" ]; then
            FILES_DIFFER=true
            echo -e "File does not exist downstream: ${YELLOW}${target_rel}${NC}"
        elif ! cmp -s "${SRC_TO_COMPARE}" "${TARGET_FILE}"; then
            FILES_DIFFER=true
            echo -e "Difference detected in: ${YELLOW}${target_rel}${NC}"
        fi
        
        if [ "${FILES_DIFFER}" = "true" ]; then
            CHANGES_COUNT=$((CHANGES_COUNT + 1))
            
            if [ "${MODE}" = "diff" ]; then
                if [ -f "${TARGET_FILE}" ]; then
                    show_file_diff "${TARGET_FILE}" "${SRC_TO_COMPARE}" "downstream/${target_rel}" "core_template/${core_rel}"
                else
                    echo -e "${GREEN}+++ Brand New File +++${NC}"
                    cat "${SRC_TO_COMPARE}"
                fi
                echo -e "-----------------------------------------------\n"
            else
                # Push mode
                if [ -f "${TARGET_FILE}" ]; then
                    show_file_diff "${TARGET_FILE}" "${SRC_TO_COMPARE}" "downstream/${target_rel}" "core_template/${core_rel}"
                fi
                
                APPLY_CHANGE="${AUTO_APPROVE}"
                if [ "${APPLY_CHANGE}" = "false" ]; then
                    read -p "Apply this update to target? [y/N]: " CHOICE
                    if [[ "${CHOICE}" =~ ^[yY](es)?$ ]]; then
                        APPLY_CHANGE="true"
                    fi
                fi
                
                if [ "${APPLY_CHANGE}" = "true" ]; then
                    mkdir -p "${TARGET_DIR_PATH}"
                    cp "${SRC_TO_COMPARE}" "${TARGET_FILE}"
                    echo -e "${GREEN}✔ Updated: ${target_rel}${NC}\n"
                else
                    echo -e "${YELLOW}Skipped: ${target_rel}${NC}\n"
                fi
            fi
        fi
        
    elif [ "${MODE}" = "pull" ]; then
        # Backporting mode
        if [ ! -f "${TARGET_FILE}" ]; then
            echo -e "Skipping pull for non-existent target file: ${YELLOW}${target_rel}${NC}"
            continue
        fi
        
        SRC_TO_COMPARE="${TARGET_FILE}"
        
        # If the file has placeholders, replace target values back with placeholders in temp file for fair comparison
        if [ "${has_placeholders}" = "true" ]; then
            ESCAPED_ROOT=$(escape_sed "${PARAM_ROOT}")
            ESCAPED_NAME=$(escape_sed "${PARAM_NAME}")
            ESCAPED_DESC=$(escape_sed "${PARAM_DESC}")
            
            sed -e "s/${ESCAPED_ROOT}/{{PROJECT_ROOT}}/g" \
                -e "s/${ESCAPED_NAME}/{{PROJECT_NAME}}/g" \
                -e "s/${ESCAPED_DESC}/{{PROJECT_DESCRIPTION}}/g" \
                "${TARGET_FILE}" > "${TMP_DIR}/compare_pull"
            SRC_TO_COMPARE="${TMP_DIR}/compare_pull"
        fi
        
        # Compare target against template
        if ! cmp -s "${SRC_TO_COMPARE}" "${CORE_FILE}"; then
            CHANGES_COUNT=$((CHANGES_COUNT + 1))
            echo -e "Difference detected in: ${YELLOW}${core_rel} (optimized downstream)${NC}"
            show_file_diff "${CORE_FILE}" "${SRC_TO_COMPARE}" "core_template/${core_rel}" "downstream/${target_rel} (with placeholders)"
            
            APPLY_CHANGE="${AUTO_APPROVE}"
            if [ "${APPLY_CHANGE}" = "false" ]; then
                read -p "Pull this optimization back into core templates? [y/N]: " CHOICE
                if [[ "${CHOICE}" =~ ^[yY](es)?$ ]]; then
                    APPLY_CHANGE="true"
                fi
            fi
            
            if [ "${APPLY_CHANGE}" = "true" ]; then
                mkdir -p "$(dirname "${CORE_FILE}")"
                cp "${SRC_TO_COMPARE}" "${CORE_FILE}"
                echo -e "${GREEN}✔ Backported: ${core_rel}${NC}\n"
            else
                echo -e "${YELLOW}Skipped backport of: ${core_rel}${NC}\n"
            fi
        fi
    fi
done

if [ "${CHANGES_COUNT}" -eq 0 ]; then
    echo -e "${GREEN}✔ No differences found. Harness configurations are fully in sync!${NC}"
else
    if [ "${MODE}" = "diff" ]; then
        echo -e "${YELLOW}Total files with differences: ${CHANGES_COUNT}${NC}"
    else
        echo -e "${GREEN}✔ Synchronization complete. Total changes processed: ${CHANGES_COUNT}${NC}"
    fi
fi
echo -e "${BLUE}===============================================${NC}"
