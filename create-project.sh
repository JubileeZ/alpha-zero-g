#!/usr/bin/env bash

# Alpha-Zero-G Project Generator Script (MVP Edition)
# Automates the creation of new analytics/statistical workspaces from templates.

set -euo pipefail

# Visual styling
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Alpha-Zero-G Project Generator             ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Interactive inputs if arguments are missing
if [ "$#" -lt 1 ]; then
    echo -e "${YELLOW}No parameters provided. Running interactive setup...${NC}"
    read -p "Enter destination path (e.g. ../FPL-Project): " DEST_DIR
    if [ -z "${DEST_DIR}" ]; then
        echo -e "${RED}Error: Destination path is required.${NC}"
        exit 1
    fi
else
    DEST_DIR="$1"
fi

if [ "$#" -lt 2 ]; then
    DEFAULT_NAME=$(basename "${DEST_DIR}")
    read -p "Enter project name [${DEFAULT_NAME}]: " INPUT_NAME
    PROJECT_NAME="${INPUT_NAME:-${DEFAULT_NAME}}"
else
    PROJECT_NAME="$2"
fi

if [ "$#" -lt 3 ]; then
    read -p "Enter project type (python / r / hybrid) [python]: " INPUT_TYPE
    PROJECT_TYPE="${INPUT_TYPE:-python}"
else
    PROJECT_TYPE="$3"
fi
PROJECT_TYPE=$(echo "${PROJECT_TYPE}" | tr '[:upper:]' '[:lower:]')

if [ "$#" -lt 4 ]; then
    read -p "Enter project description [Statistical Analytics Project]: " INPUT_DESC
    PROJECT_DESCRIPTION="${INPUT_DESC:-"Statistical Analytics Project bootstrapped from Alpha-Zero-G"}"
else
    PROJECT_DESCRIPTION="$4"
fi

PROJECT_ROOT_ABS=$(mkdir -p "${DEST_DIR}" && cd "${DEST_DIR}" && pwd)

echo -e "\nInitializing project: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "Target directory: ${GREEN}${PROJECT_ROOT_ABS}${NC}"
echo -e "Project type: ${GREEN}${PROJECT_TYPE}${NC}"

# 1. Create directory structure
echo -e "\n1. Establishing directory structures..."
mkdir -p "${PROJECT_ROOT_ABS}/src"
mkdir -p "${PROJECT_ROOT_ABS}/notebooks"
mkdir -p "${PROJECT_ROOT_ABS}/tests"
mkdir -p "${PROJECT_ROOT_ABS}/.agents/skills"

# Fetch and deploy fresh skills if not bypassed
SKIP_EXTERNAL_SKILLS="${SKIP_EXTERNAL_SKILLS:-false}"
if [ "${SKIP_EXTERNAL_SKILLS}" = "true" ]; then
    echo -e "  - Skipping external skills retrieval (SKIP_EXTERNAL_SKILLS=true)."
else
    echo -e "  - Fetching fresh skills from github.com/mattpocock/skills..."
    TEMP_SKILLS_DIR=$(mktemp -d)
    # Perform shallow clone for speed
    if git clone --depth 1 https://github.com/mattpocock/skills.git "${TEMP_SKILLS_DIR}" -q; then
        if [ -d "${TEMP_SKILLS_DIR}/skills/productivity" ]; then
            echo -e "    - Copying productivity skills..."
            for skill_path in "${TEMP_SKILLS_DIR}"/skills/productivity/*; do
                if [ -d "${skill_path}" ]; then
                    cp -r "${skill_path}" "${PROJECT_ROOT_ABS}/.agents/skills/"
                fi
            done
        fi
        if [ -d "${TEMP_SKILLS_DIR}/skills/engineering" ]; then
            echo -e "    - Copying engineering skills..."
            for skill_path in "${TEMP_SKILLS_DIR}"/skills/engineering/*; do
                if [ -d "${skill_path}" ]; then
                    cp -r "${skill_path}" "${PROJECT_ROOT_ABS}/.agents/skills/"
                fi
            done
        fi
        echo -e "  - Fresh skills deployed to .agents/skills/"
    else
        echo -e "${YELLOW}  - Warning: Failed to clone mattpocock/skills. Proceeding without fresh skills.${NC}"
    fi
    rm -rf "${TEMP_SKILLS_DIR}"
fi


# 2. Deploy standard template files
echo -e "2. Deploying common template files..."
cp templates/AGENTS.md "${PROJECT_ROOT_ABS}/AGENTS.md"
cp templates/CONTEXT.md "${PROJECT_ROOT_ABS}/CONTEXT.md"
cp templates/progress.md "${PROJECT_ROOT_ABS}/progress.md"
cp templates/features.json "${PROJECT_ROOT_ABS}/features.json"
cp templates/README.md "${PROJECT_ROOT_ABS}/README.md"
cp templates/DEVELOPER_WORKFLOW.md "${PROJECT_ROOT_ABS}/DEVELOPER_WORKFLOW.md"
cp templates/init.sh "${PROJECT_ROOT_ABS}/init.sh"
cp templates/Makefile "${PROJECT_ROOT_ABS}/Makefile"
cp templates/.pre-commit-config.yaml "${PROJECT_ROOT_ABS}/.pre-commit-config.yaml"
cp templates/.env.example "${PROJECT_ROOT_ABS}/.env.example"
cp .agents/hooks.json "${PROJECT_ROOT_ABS}/.agents/hooks.json"
cp .gitignore "${PROJECT_ROOT_ABS}/.gitignore"
cp LICENSE "${PROJECT_ROOT_ABS}/LICENSE"

# 3. Copy language-specific partitioned templates
if [ "${PROJECT_TYPE}" = "python" ] || [ "${PROJECT_TYPE}" = "hybrid" ]; then
    echo -e "3. Deploying Python-specific templates..."
    cp templates/python/pyproject.toml "${PROJECT_ROOT_ABS}/pyproject.toml"
    
    # Normalize package name (lowercase, replace hyphens and spaces with underscores)
    CLEAN_PKG_NAME=$(echo "${PROJECT_NAME}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')
    mkdir -p "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}"
    
    cp templates/python/src/__init__.py "${PROJECT_ROOT_ABS}/src/__init__.py"
    cp templates/python/src/__init__.py "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}/__init__.py"
    cp templates/python/src/{{project_name}}/config.py "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}/config.py"
    cp templates/python/tests/test_smoke.py "${PROJECT_ROOT_ABS}/tests/test_smoke.py"
    cp templates/python/tests/conftest.py "${PROJECT_ROOT_ABS}/tests/conftest.py"
fi

if [ "${PROJECT_TYPE}" = "r" ] || [ "${PROJECT_TYPE}" = "hybrid" ]; then
    echo -e "3. Deploying R-specific templates..."
    cp templates/r/DESCRIPTION "${PROJECT_ROOT_ABS}/DESCRIPTION"
    cp templates/r/src/smoke.R "${PROJECT_ROOT_ABS}/src/smoke.R"
    cp templates/r/tests/testthat.R "${PROJECT_ROOT_ABS}/tests/testthat.R"
fi

# 4. Replace parameter placeholders
echo -e "4. Customizing parameters..."
ESCAPED_ROOT=$(echo "${PROJECT_ROOT_ABS}" | sed 's/\//\\\//g')

# Portable replacement function
replace_placeholders() {
    local target_file="$1"
    if [ -f "${target_file}" ]; then
        local clean_pkg=$(echo "${PROJECT_NAME}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr '-' '_')
        sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${target_file}"
        sed -i.bak "s/{{PROJECT_DESCRIPTION}}/${PROJECT_DESCRIPTION}/g" "${target_file}"
        sed -i.bak "s/{{PROJECT_ROOT}}/${ESCAPED_ROOT}/g" "${target_file}"
        sed -i.bak "s/{{PROJECT_GOAL_SUMMARY}}/Establish analytical modeling environment for ${PROJECT_NAME}./g" "${target_file}"
        sed -i.bak "s/{{PACKAGE_NAME}}/${clean_pkg}/g" "${target_file}"
        rm -f "${target_file}.bak"
    fi
}

# Apply placeholders to standard assets
replace_placeholders "${PROJECT_ROOT_ABS}/AGENTS.md"
replace_placeholders "${PROJECT_ROOT_ABS}/CONTEXT.md"
replace_placeholders "${PROJECT_ROOT_ABS}/progress.md"
replace_placeholders "${PROJECT_ROOT_ABS}/README.md"
replace_placeholders "${PROJECT_ROOT_ABS}/DEVELOPER_WORKFLOW.md"
replace_placeholders "${PROJECT_ROOT_ABS}/Makefile"
replace_placeholders "${PROJECT_ROOT_ABS}/.pre-commit-config.yaml"
replace_placeholders "${PROJECT_ROOT_ABS}/.env.example"

if [ -f "${PROJECT_ROOT_ABS}/pyproject.toml" ]; then
    replace_placeholders "${PROJECT_ROOT_ABS}/pyproject.toml"
fi
if [ -f "${PROJECT_ROOT_ABS}/DESCRIPTION" ]; then
    replace_placeholders "${PROJECT_ROOT_ABS}/DESCRIPTION"
fi

if [ "${PROJECT_TYPE}" = "python" ] || [ "${PROJECT_TYPE}" = "hybrid" ]; then
    CLEAN_PKG_NAME=$(echo "${PROJECT_NAME}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    replace_placeholders "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}/config.py"
    replace_placeholders "${PROJECT_ROOT_ABS}/tests/conftest.py"
fi

# 5. Auto-register in global trusted workspaces
echo -e "5. Syncing workspace to trusted environment list..."
PYTHON_CMD="python3"
if command -v uv &>/dev/null; then
    PYTHON_CMD="uv run python"
fi

$PYTHON_CMD -c "
import json, os
path = os.path.expanduser('~/.gemini/antigravity-cli/settings.json')
if os.path.exists(path):
    try:
        with open(path, 'r') as f:
            data = json.load(f)
    except Exception:
        data = {}
    trusted = data.setdefault('trustedWorkspaces', [])
    if '${PROJECT_ROOT_ABS}' not in trusted:
        trusted.append('${PROJECT_ROOT_ABS}')
        with open(path, 'w') as f:
            json.dump(data, f, indent=2)
        print('  - Path added to global trustedWorkspaces.')
    else:
        print('  - Path already trusted.')
else:
    print('  - Global settings.json not found. Skipping auto-registration.')
" || echo -e "${YELLOW}Warning: Failed to update global trustedWorkspaces.${NC}"

# 6. Automated Git Initialization & Baseline Commit
echo -e "6. Initializing local Git repository baseline..."
(
    cd "${PROJECT_ROOT_ABS}"
    git init -q
    git add .
    # Allow empty/fallback if git config not established on machine
    git commit -m "feat: initial harness bootstrap" -q 2>/dev/null || \
    (
        git config user.email "agent@alpha-zero-g.local"
        git config user.name "Alpha Zero G Initializer"
        git commit -m "feat: initial harness bootstrap" -q
    )
    echo -e "  - Git baseline established successfully."
)

echo -e "${GREEN}✔ Project successfully bootstrapped!${NC}"
echo -e "\nNext steps:"
echo -e "  1. CD into the new workspace: ${YELLOW}cd \"${DEST_DIR}\"${NC}"
echo -e "  2. Run the local bootstrapper: ${YELLOW}bash init.sh${NC}"
echo -e "  3. Open the directory with your AI Agent to begin!${NC}"
echo -e "${BLUE}===============================================${NC}"
