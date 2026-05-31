#!/usr/bin/env bash

# Alpha-Zero-G GitHub + Local Harness Sync Setup Script
# Automatically seeds ~/.gemini/ configs and copies global rules/skills physically from the local repository's global/ folder.

set -euo pipefail

# Disable automagic path translation in MINGW/MSYS to prevent cmd.exe /c from launching interactive shell
export MSYS_NO_PATHCONV=1

# Visual styling
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   Alpha-Zero-G Local Monorepo Harness Setup    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. Resolve Target Home Directory
REAL_HOME="${MOCK_HOME:-$HOME}"
GEMINI_DIR="${REAL_HOME}/.gemini"
echo -e "Local Target Home: ${GREEN}${REAL_HOME}${NC}"

# Resolve the current repository root directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT=$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null || echo "${SCRIPT_DIR}")
GLOBAL_SRC_DIR="${MOCK_GLOBAL_SRC:-${REPO_ROOT}/global}"

echo -e "Harness Source:    ${GREEN}${GLOBAL_SRC_DIR}${NC}"

# Ensure basic target directories exist
mkdir -p "${GEMINI_DIR}/antigravity-cli"
mkdir -p "${GEMINI_DIR}/antigravity"
mkdir -p "${GEMINI_DIR}/config"
mkdir -p "${GLOBAL_SRC_DIR}/config"
mkdir -p "${GLOBAL_SRC_DIR}/skills"

# 2. Establish Safe Local Backups of existing physical configurations
BACKUP_DIR="${REAL_HOME}/.gemini_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_MADE=false

backup_file() {
    local filepath="$1"
    if [ -f "${filepath}" ] && [ ! -L "${filepath}" ]; then
        if [ "${BACKUP_MADE}" = "false" ]; then
            mkdir -p "${BACKUP_DIR}/antigravity-cli"
            mkdir -p "${BACKUP_DIR}/antigravity"
            mkdir -p "${BACKUP_DIR}/config"
            BACKUP_MADE=true
            echo -e "\n2. Creating local backup folder: ${GREEN}${BACKUP_DIR}${NC}"
        fi
        # Replicate nested directory layout
        if [[ "${filepath}" == *"antigravity-cli"* ]]; then
            cp "${filepath}" "${BACKUP_DIR}/antigravity-cli/"
        elif [[ "${filepath}" == *"antigravity"* ]]; then
            cp "${filepath}" "${BACKUP_DIR}/antigravity/"
        elif [[ "${filepath}" == *"config"* ]]; then
            cp "${filepath}" "${BACKUP_DIR}/config/"
        else
            cp "${filepath}" "${BACKUP_DIR}/"
        fi
    fi
}

backup_dir() {
    local dirpath="$1"
    if [ -d "${dirpath}" ] && [ ! -L "${dirpath}" ]; then
        if [ "${BACKUP_MADE}" = "false" ]; then
            mkdir -p "${BACKUP_DIR}/antigravity-cli"
            mkdir -p "${BACKUP_DIR}/antigravity"
            BACKUP_MADE=true
            echo -e "\n2. Creating local backup folder: ${GREEN}${BACKUP_DIR}${NC}"
        fi
        cp -R "${dirpath}" "${BACKUP_DIR}/antigravity/"
    fi
}

# Scan and backup real local files
backup_file "${GEMINI_DIR}/antigravity-cli/settings.json"
backup_file "${GEMINI_DIR}/antigravity-cli/statusline.sh"
backup_file "${GEMINI_DIR}/AGENTS.md"
backup_file "${GEMINI_DIR}/GEMINI.md"
backup_file "${GEMINI_DIR}/config/config.json"
backup_file "${GEMINI_DIR}/config/mcp_config.json"
backup_dir "${GEMINI_DIR}/antigravity/skills"

# Seed existing local skills to global/skills if any exist
if [ -d "${GEMINI_DIR}/antigravity/skills" ] && [ ! -L "${GEMINI_DIR}/antigravity/skills" ]; then
    echo -e "\n3. Importing existing local skills to monorepo..."
    for skill_path in "${GEMINI_DIR}/antigravity/skills"/*; do
        if [ -d "${skill_path}" ]; then
            skill_name=$(basename "${skill_path}")
            if [ ! -d "${GLOBAL_SRC_DIR}/skills/${skill_name}" ]; then
                echo -e "  - Importing skill: copying ${skill_name} to global/skills/"
                cp -R "${skill_path}" "${GLOBAL_SRC_DIR}/skills/"
            fi
        fi
    done
fi

# 3. Clean up any existing repository-level symlinks to prevent conflicts
echo -e "\n3. Cleaning up repository-level symbolic links..."
cleanup_repo_symlink() {
    local path="$1"
    if [ -L "${path}" ]; then
        echo -e "  - Removing old repository symlink: ${path}"
        rm -f "${path}"
    fi
}
cleanup_repo_symlink "${GEMINI_DIR}/antigravity-cli/settings.json"
cleanup_repo_symlink "${GEMINI_DIR}/antigravity-cli/statusline.sh"
cleanup_repo_symlink "${GEMINI_DIR}/AGENTS.md"
cleanup_repo_symlink "${GEMINI_DIR}/GEMINI.md"
cleanup_repo_symlink "${GEMINI_DIR}/antigravity/skills"
cleanup_repo_symlink "${GEMINI_DIR}/config/config.json"
cleanup_repo_symlink "${GEMINI_DIR}/config/mcp_config.json"

# 4. Seed and Deploy Configuration Files (copied physically, only if missing)
echo -e "\n4. Seeding user configuration files from templates..."
seed_from_example() {
    local target_file="$1"
    local example_file="$2"
    if [ ! -f "${target_file}" ]; then
        if [ -f "${example_file}" ]; then
            echo -e "  - Seeding: copying $(basename "${example_file}") to ${target_file}"
            cp "${example_file}" "${target_file}"
        else
            echo -e "${YELLOW}  - Warning: baseline template $(basename "${example_file}") missing.${NC}"
        fi
    else
        echo -e "  - Preserving existing physical config: ${target_file}"
    fi
}

# Deploy settings & client configs by preferring tracked physical configs in global/, falling back to examples
deploy_config_or_seed() {
    local target_path="$1"
    local local_repo_file="$2"
    local example_file="$3"
    
    if [ -f "${local_repo_file}" ]; then
        echo -e "  - Deploying config: copying $(basename "${local_repo_file}") to ${target_path}"
        cp "${local_repo_file}" "${target_path}"
    else
        seed_from_example "${target_path}" "${example_file}"
    fi
}

deploy_config_or_seed "${GEMINI_DIR}/antigravity-cli/settings.json" "${GLOBAL_SRC_DIR}/settings.json" "${GLOBAL_SRC_DIR}/settings.json.example"
deploy_config_or_seed "${GEMINI_DIR}/config/config.json" "${GLOBAL_SRC_DIR}/config/config.json" "${GLOBAL_SRC_DIR}/config/config.json.example"
deploy_config_or_seed "${GEMINI_DIR}/config/mcp_config.json" "${GLOBAL_SRC_DIR}/config/mcp_config.json" "${GLOBAL_SRC_DIR}/config/mcp_config.json.example"

# Deploy and customize custom statusline script
if [ -f "${GLOBAL_SRC_DIR}/statusline.sh" ]; then
    echo -e "  - Deploying statusline script: copying statusline.sh to ${GEMINI_DIR}/antigravity-cli/statusline.sh"
    cp "${GLOBAL_SRC_DIR}/statusline.sh" "${GEMINI_DIR}/antigravity-cli/statusline.sh"
    chmod +x "${GEMINI_DIR}/antigravity-cli/statusline.sh"
fi

# Customize settings.json with actual home/device specific GEMINI_DIR path
if [ -f "${GEMINI_DIR}/antigravity-cli/settings.json" ]; then
    echo -e "  - Customizing settings.json for the active user/device..."
    sed "s|{{GEMINI_DIR}}|${GEMINI_DIR}|g" "${GEMINI_DIR}/antigravity-cli/settings.json" > "${GEMINI_DIR}/antigravity-cli/settings.json.tmp"
    mv "${GEMINI_DIR}/antigravity-cli/settings.json.tmp" "${GEMINI_DIR}/antigravity-cli/settings.json"
fi

# 5. Deploy Global Rules (copied physically, always overwritten to sync rules)
echo -e "\n5. Deploying universal developer rules to ~/.gemini..."
deploy_rule_file() {
    local source_file="$1"
    local dest_file="$2"
    if [ -f "${source_file}" ]; then
        echo -e "  - Deploying rule file: copying $(basename "${source_file}") to ${dest_file}"
        cp "${source_file}" "${dest_file}"
    else
        echo -e "${RED}  - Error: Source rule file missing: ${source_file}${NC}"
        exit 1
    fi
}
deploy_rule_file "${GLOBAL_SRC_DIR}/AGENTS.md" "${GEMINI_DIR}/AGENTS.md"
deploy_rule_file "${GLOBAL_SRC_DIR}/GEMINI.md" "${GEMINI_DIR}/GEMINI.md"

# 6. Deploy Global Custom Skills (copied physically to preserve isolation)
echo -e "\n6. Deploying global custom skills..."
mkdir -p "${GEMINI_DIR}/antigravity/skills"
if [ -d "${GLOBAL_SRC_DIR}/skills" ]; then
    for skill_path in "${GLOBAL_SRC_DIR}/skills"/*; do
        if [ -d "${skill_path}" ]; then
            skill_name=$(basename "${skill_path}")
            # Deploy skill if not existing, or update it
            if [ ! -d "${GEMINI_DIR}/antigravity/skills/${skill_name}" ]; then
                echo -e "  - Deploying skill: copying ${skill_name} to ~/.gemini/antigravity/skills/"
                cp -R "${skill_path}" "${GEMINI_DIR}/antigravity/skills/"
            fi
        fi
    done
fi



# 8. Verification and reporting loop
echo -e "\n8. Verifying environment configurations..."
FAILED=false

verify_physical_file() {
    local filepath="$1"
    if [ -f "${filepath}" ] && [ ! -L "${filepath}" ]; then
        echo -e "  - ${GREEN}✔${NC} $(basename "${filepath}") [Physical File]"
    else
        echo -e "  - ${RED}✘${NC} $(basename "${filepath}") [FAILED - not a physical file]"
        FAILED=true
    fi
}

verify_physical_dir() {
    local dirpath="$1"
    if [ -d "${dirpath}" ] && [ ! -L "${dirpath}" ]; then
        echo -e "  - ${GREEN}✔${NC} $(basename "${dirpath}")/ [Physical Directory]"
    else
        echo -e "  - ${RED}✘${NC} $(basename "${dirpath}")/ [FAILED - not a physical directory]"
        FAILED=true
    fi
}

verify_physical_file "${GEMINI_DIR}/antigravity-cli/settings.json"
verify_physical_file "${GEMINI_DIR}/antigravity-cli/statusline.sh"
verify_physical_file "${GEMINI_DIR}/AGENTS.md"
verify_physical_file "${GEMINI_DIR}/GEMINI.md"
verify_physical_dir "${GEMINI_DIR}/antigravity/skills"
verify_physical_file "${GEMINI_DIR}/config/config.json"
verify_physical_file "${GEMINI_DIR}/config/mcp_config.json"


if [ "${FAILED}" = "true" ]; then
    echo -e "\n${RED}✘ Verification failed for some configurations!${NC}"
    exit 1
fi

echo -e "\n${GREEN}✔ Local harness successfully synced with physical decoupled files!${NC}"
echo -e "  - All configuration templates and global custom rules are copied and isolated."
echo -e "${BLUE}===============================================${NC}"
