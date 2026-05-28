#!/usr/bin/env bash

# Alpha-Zero-G Cross-Device Sync Setup Script
# Automatically links ~/.gemini/ configs and global skills to Google Drive.

set -euo pipefail

# Visual styling
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Alpha-Zero-G Global Harness Sync           ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. Resolve Target Home Directory (support TDD mock injection)
REAL_HOME="${MOCK_HOME:-$HOME}"
GEMINI_DIR="${REAL_HOME}/.gemini"
echo -e "Local Target Home: ${GREEN}${REAL_HOME}${NC}"

# Ensure basic directories exist
mkdir -p "${GEMINI_DIR}/antigravity-cli"
mkdir -p "${GEMINI_DIR}/antigravity"
mkdir -p "${GEMINI_DIR}/config"

# 2. Resolve Google Drive Mount Path (support TDD mock injection)
if [ -n "${MOCK_GDRIVE:-}" ]; then
    GDRIVE_BASE="${MOCK_GDRIVE}"
    echo -e "Using Mock Google Drive: ${GREEN}${GDRIVE_BASE}${NC}"
else
    # Dynamic detection based on OS
    OS_NAME=$(uname -s)
    GDRIVE_BASE=""
    
    if [ "${OS_NAME}" = "Darwin" ]; then
        echo -e "Detecting Google Drive on macOS..."
        CLOUD_DIR="/Users/${USER}/Library/CloudStorage"
        if [ -d "${CLOUD_DIR}" ]; then
            # Find any folder starting with GoogleDrive
            MATCHES=($(find "${CLOUD_DIR}" -maxdepth 1 -name "GoogleDrive*" -type d 2>/dev/null))
            if [ ${#MATCHES[@]} -gt 0 ]; then
                GDRIVE_BASE="${MATCHES[0]}"
                echo -e "  - Found macOS mount: ${GREEN}${GDRIVE_BASE}${NC}"
            fi
        fi
    else
        echo -e "Detecting Google Drive on Windows/Linux..."
        # Iterate drive letters G through Z looking for 'My Drive'
        for letter in {G..Z}; do
            TEST_PATH="/mnt/${letter,,}/My Drive" # WSL format
            if [ -d "${TEST_PATH}" ]; then
                GDRIVE_BASE="/mnt/${letter,,}"
                echo -e "  - Found Windows mount (WSL): ${GREEN}${GDRIVE_BASE}${NC}"
                break
            fi
            # Windows native mount letter check (Git Bash)
            TEST_PATH="/${letter}/My Drive"
            if [ -d "${TEST_PATH}" ]; then
                GDRIVE_BASE="/${letter}"
                echo -e "  - Found Windows mount (Git Bash): ${GREEN}${GDRIVE_BASE}${NC}"
                break
            fi
        done
    fi
    
    # Prompt fallback if detection fails
    if [ -z "${GDRIVE_BASE}" ]; then
        echo -e "${YELLOW}Google Drive mount not found automatically.${NC}"
        read -p "Please enter your absolute Google Drive path: " INPUT_PATH
        if [ -z "${INPUT_PATH}" ] || [ ! -d "${INPUT_PATH}" ]; then
            echo -e "${RED}Error: Valid Google Drive mount path is required.${NC}"
            exit 1
        fi
        GDRIVE_BASE="${INPUT_PATH}"
    fi
fi

# Define source-of-truth directories in Google Drive
GDRIVE_SETTINGS_DIR="${GDRIVE_BASE}/My Drive/Settings/antigravity-cli"
GDRIVE_SKILLS_DIR="${GDRIVE_BASE}/My Drive/Settings/antigravity"
GDRIVE_CONFIG_DIR="${GDRIVE_BASE}/My Drive/Settings/antigravity/config"

# Create the directories in Google Drive
mkdir -p "${GDRIVE_SETTINGS_DIR}"
mkdir -p "${GDRIVE_SKILLS_DIR}/skills"
mkdir -p "${GDRIVE_CONFIG_DIR}"

# 3. Establish Safe Local Backups before symlinking
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
            echo -e "\n3. Creating local backup folder: ${GREEN}${BACKUP_DIR}${NC}"
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
            echo -e "\n3. Creating local backup folder: ${GREEN}${BACKUP_DIR}${NC}"
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

# 4. Seed Google Drive if cloud directories are empty
echo -e "\n4. Syncing/seeding configuration files..."

seed_file() {
    local filename="$1"
    local local_path="${GEMINI_DIR}/${filename}"
    local gdrive_path=""
    
    if [[ "${filename}" == *"antigravity-cli"* ]]; then
        gdrive_path="${GDRIVE_SETTINGS_DIR}/$(basename "${filename}")"
    elif [[ "${filename}" == *"config"* ]]; then
        gdrive_path="${GDRIVE_CONFIG_DIR}/$(basename "${filename}")"
    else
        gdrive_path="${GDRIVE_SKILLS_DIR}/$(basename "${filename}")"
    fi
    
    if [ ! -f "${gdrive_path}" ]; then
        if [ -f "${local_path}" ] && [ ! -L "${local_path}" ]; then
            echo -e "  - Seeding: copying local ${filename} to Google Drive."
            cp "${local_path}" "${gdrive_path}"
        else
            # Create a clean baseline fallback
            echo -e "  - Seeding: creating clean baseline ${filename} on Google Drive."
            if [[ "${filename}" == *"settings.json"* ]]; then
                echo -e '{\n  "trustedWorkspaces": [],\n  "model": "Gemini 3.5 Flash (High)"\n}' > "${gdrive_path}"
            elif [[ "${filename}" == *"AGENTS.md"* ]]; then
                echo -e "# Global Agent Rules\n\n## Standards\n- All python functions require docstrings and type hints." > "${gdrive_path}"
            elif [[ "${filename}" == *"GEMINI.md"* ]]; then
                echo -e "# Global Gemini Rules\n\n## Settings\n- run_command is allowed." > "${gdrive_path}"
            elif [[ "${filename}" == *"config.json"* ]]; then
                echo -e '{\n  "userSettings": {\n    "useAiCredits": true\n  }\n}' > "${gdrive_path}"
            elif [[ "${filename}" == *"mcp_config.json"* ]]; then
                echo -e '{\n  "mcpServers": {}\n}' > "${gdrive_path}"
            fi
        fi
    else
        echo -e "  - Verified: ${filename} already exists on Google Drive."
    fi
}

seed_file "antigravity-cli/settings.json"
seed_file "AGENTS.md"
seed_file "GEMINI.md"
seed_file "config/config.json"
seed_file "config/mcp_config.json"

# Seed skills directory
if [ -d "${GEMINI_DIR}/antigravity/skills" ] && [ ! -L "${GEMINI_DIR}/antigravity/skills" ]; then
    for skill_path in "${GEMINI_DIR}/antigravity/skills"/*; do
        if [ -d "${skill_path}" ]; then
            skill_name=$(basename "${skill_path}")
            if [ ! -d "${GDRIVE_SKILLS_DIR}/skills/${skill_name}" ]; then
                echo -e "  - Seeding skill: copying ${skill_name} to Google Drive."
                cp -R "${skill_path}" "${GDRIVE_SKILLS_DIR}/skills/"
            fi
        fi
    done
fi

# 5. Establish robust local symlinks
echo -e "\n5. Linking local ~/.gemini paths to Google Drive..."

create_symlink() {
    local target="$1"
    local link_path="$2"
    
    if [ -f "${link_path}" ] || [ -d "${link_path}" ] || [ -L "${link_path}" ]; then
        rm -rf "${link_path}"
    fi
    
    # Check if we are on Windows (Git Bash/MINGW/MSYS)
    if [[ "$(uname -s)" == *"MINGW"* ]] || [[ "$(uname -s)" == *"MSYS"* ]]; then
        local win_target=$(cygpath -w "${target}")
        local win_link=$(cygpath -w "${link_path}")
        
        if [ -d "${target}" ]; then
            # Directory junction does not require administrative privileges
            cmd.exe /c "mklink /j \"${win_link}\" \"${win_target}\"" &>/dev/null || \
            cmd.exe /c "mklink /d \"${win_link}\" \"${win_target}\"" &>/dev/null || \
            ln -s "${target}" "${link_path}"
        else
            cmd.exe /c "mklink \"${win_link}\" \"${win_target}\"" &>/dev/null || \
            cmd.exe /c "mklink /h \"${win_link}\" \"${win_target}\"" &>/dev/null || \
            ln -s "${target}" "${link_path}"
        fi
    else
        ln -s "${target}" "${link_path}"
    fi
    
    echo -e "  - Symlink established: $(basename "${link_path}") -> ${target}"
}

create_symlink "${GDRIVE_SETTINGS_DIR}/settings.json" "${GEMINI_DIR}/antigravity-cli/settings.json"
create_symlink "${GDRIVE_SKILLS_DIR}/AGENTS.md" "${GEMINI_DIR}/AGENTS.md"
create_symlink "${GDRIVE_SKILLS_DIR}/GEMINI.md" "${GEMINI_DIR}/GEMINI.md"
create_symlink "${GDRIVE_SKILLS_DIR}/skills" "${GEMINI_DIR}/antigravity/skills"
create_symlink "${GDRIVE_CONFIG_DIR}/config.json" "${GEMINI_DIR}/config/config.json"
create_symlink "${GDRIVE_CONFIG_DIR}/mcp_config.json" "${GEMINI_DIR}/config/mcp_config.json"

echo -e "\n${GREEN}✔ Global harness successfully synced across devices!${NC}"
echo -e "  - All global settings, global skills, and custom rules are now synchronized in real-time."
echo -e "${BLUE}===============================================${NC}"
