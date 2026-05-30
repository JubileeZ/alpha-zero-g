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

# 1. Resolve Target Home Directory (support TDD mock injection)
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
seed_from_example "${GEMINI_DIR}/antigravity-cli/settings.json" "${GLOBAL_SRC_DIR}/settings.json.example"
seed_from_example "${GEMINI_DIR}/config/config.json" "${GLOBAL_SRC_DIR}/config/config.json.example"
seed_from_example "${GEMINI_DIR}/config/mcp_config.json" "${GLOBAL_SRC_DIR}/config/mcp_config.json.example"

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

# 7. Establish internal helper symlinks
# Helper links remain internal to ~/.gemini/ and do not depend on external repos.
echo -e "\n7. Establishing internal helper symlinks..."

is_windows() {
    [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]]
}

# Returns 0 if symlinks can be created, 1 otherwise
test_symlink_capability() {
    if [ -n "${MOCK_SYMLINK_CAPABILITY:-}" ]; then
        if [ "${MOCK_SYMLINK_CAPABILITY}" = "true" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    local test_link="${GEMINI_DIR}/.symlink_test_$$"
    local test_target="${GEMINI_DIR}/antigravity/skills"
    local win_link=$(cygpath -w "${test_link}" | tr -d '\r')
    local win_target=$(cygpath -w "${test_target}" | tr -d '\r')
    
    cmd.exe /c mklink /d "${win_link}" "${win_target}" &>/dev/null
    local result=$?
    cmd.exe /c rmdir "${win_link}" &>/dev/null 2>&1
    return ${result}
}

HELPER_SYMLINK_PAIRS=(
    "${GEMINI_DIR}/antigravity/skills|${GEMINI_DIR}/antigravity-cli/skills"
    "${GEMINI_DIR}/antigravity/skills|${GEMINI_DIR}/config/skills"
)

create_symlink() {
    local target="$1"
    local link_path="$2"
    
    if [ -f "${link_path}" ] || [ -d "${link_path}" ] || [ -L "${link_path}" ]; then
        rm -rf "${link_path}"
    fi
    
    if is_windows; then
        local win_target=$(cygpath -w "${target}" | tr -d '\r')
        local win_link=$(cygpath -w "${link_path}" | tr -d '\r')
        
        if [ -d "${target}" ]; then
            cmd.exe /c mklink /d "${win_link}" "${win_target}" || \
            cmd.exe /c mklink /j "${win_link}" "${win_target}" || \
            ln -s "${target}" "${link_path}"
        else
            cmd.exe /c mklink "${win_link}" "${win_target}" || \
            cmd.exe /c mklink /h "${win_link}" "${win_target}" || \
            ln -s "${target}" "${link_path}"
        fi
    else
        ln -s "${target}" "${link_path}"
    fi
}

create_symlinks_elevated() {
    local batch_file="${REAL_HOME}/.gemini_setup_links.bat"
    
    # Header: Enable Developer Mode for future non-elevated runs
    cat > "${batch_file}" << 'BATCH_HEADER'
@echo off
echo Enabling Developer Mode...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f >nul 2>&1
BATCH_HEADER
    
    # Append helper symlinks
    for pair in "${HELPER_SYMLINK_PAIRS[@]}"; do
        local target="${pair%%|*}"
        local link_path="${pair##*|}"
        local win_target=$(cygpath -w "${target}" | tr -d '\r')
        local win_link=$(cygpath -w "${link_path}" | tr -d '\r')
        
        if [ -d "${target}" ]; then
            echo "if exist \"${win_link}\" rmdir \"${win_link}\" 2>nul" >> "${batch_file}"
            echo "mklink /d \"${win_link}\" \"${win_target}\"" >> "${batch_file}"
        else
            echo "if exist \"${win_link}\" del \"${win_link}\" 2>nul" >> "${batch_file}"
            echo "mklink \"${win_link}\" \"${win_target}\"" >> "${batch_file}"
        fi
    done
    
    # Execute elevated (or mock it for testing)
    local win_batch=$(cygpath -w "${batch_file}" | tr -d '\r')
    if [ -n "${MOCK_ELEVATION_MOCK:-}" ]; then
        echo -e "  - ${YELLOW}[MOCK] Bypassing UAC, executing batch script directly for tests...${NC}"
        cmd.exe /c "${win_batch}"
    else
        powershell.exe -NoProfile -Command \
            "Start-Process cmd -Verb RunAs -Wait -ArgumentList '/c \"${win_batch}\"'"
    fi
    
    rm -f "${batch_file}"
}

# Symlink Orchestrator
if is_windows; then
    if test_symlink_capability; then
        echo -e "  ${GREEN}✔ Symlink capability confirmed (Developer Mode active)${NC}"
        for pair in "${HELPER_SYMLINK_PAIRS[@]}"; do
            create_symlink "${pair%%|*}" "${pair##*|}"
        done
    else
        echo -e "  ${YELLOW}⚠ Symbolic links require elevation on first run.${NC}"
        echo -e "  ${BLUE}Enabling Developer Mode & creating links (you will see a UAC prompt)...${NC}"
        create_symlinks_elevated
    fi
else
    # macOS/Linux: normal symlinks
    for pair in "${HELPER_SYMLINK_PAIRS[@]}"; do
        create_symlink "${pair%%|*}" "${pair##*|}"
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

verify_symlink() {
    local link_path="$1"
    if [ -L "${link_path}" ]; then
        echo -e "  - ${GREEN}✔${NC} $(basename "${link_path}") -> $(readlink "${link_path}" || echo "Windows Symlink Target") [Symlink]"
    else
        echo -e "  - ${RED}✘${NC} $(basename "${link_path}") [FAILED - not a symbolic link]"
        FAILED=true
    fi
}

verify_physical_file "${GEMINI_DIR}/antigravity-cli/settings.json"
verify_physical_file "${GEMINI_DIR}/AGENTS.md"
verify_physical_file "${GEMINI_DIR}/GEMINI.md"
verify_physical_dir "${GEMINI_DIR}/antigravity/skills"
verify_physical_file "${GEMINI_DIR}/config/config.json"
verify_physical_file "${GEMINI_DIR}/config/mcp_config.json"

for pair in "${HELPER_SYMLINK_PAIRS[@]}"; do
    verify_symlink "${pair##*|}"
done

if [ "${FAILED}" = "true" ]; then
    echo -e "\n${RED}✘ Verification failed for some configurations!${NC}"
    exit 1
fi

echo -e "\n${GREEN}✔ Local harness successfully synced with physical decoupled files!${NC}"
echo -e "  - All configuration templates and global custom rules are copied and isolated."
echo -e "${BLUE}===============================================${NC}"
