#!/usr/bin/env bash

# Alpha-Zero-G Project Generator Script
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
mkdir -p "${PROJECT_ROOT_ABS}/docs/design"
mkdir -p "${PROJECT_ROOT_ABS}/docs/adr"

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
mkdir -p "${PROJECT_ROOT_ABS}/.agents/rules"
cp .agents/rules/* "${PROJECT_ROOT_ABS}/.agents/rules/"

# 3. Copy standard system docs & templates
cp templates/docs/architecture.md "${PROJECT_ROOT_ABS}/docs/architecture.md"
cp templates/docs/beliefs.md "${PROJECT_ROOT_ABS}/docs/beliefs.md"
cp templates/docs/conventions.md "${PROJECT_ROOT_ABS}/docs/conventions.md"
cp templates/docs/data-rules.md "${PROJECT_ROOT_ABS}/docs/data-rules.md"
cp templates/docs/modeling-rules.md "${PROJECT_ROOT_ABS}/docs/modeling-rules.md"
cp templates/docs/context-management.md "${PROJECT_ROOT_ABS}/docs/context-management.md"
cp templates/docs/session-protocols.md "${PROJECT_ROOT_ABS}/docs/session-protocols.md"
cp templates/docs/testing-requirements.md "${PROJECT_ROOT_ABS}/docs/testing-requirements.md"
cp templates/docs/security-rules.md "${PROJECT_ROOT_ABS}/docs/security-rules.md"
cp templates/docs/domain-rules.md "${PROJECT_ROOT_ABS}/docs/domain-rules.md"
cp templates/docs/safety-policies.md "${PROJECT_ROOT_ABS}/docs/safety-policies.md"
cp docs/DATA_DICT.md "${PROJECT_ROOT_ABS}/docs/DATA_DICT.md"
cp docs/MODEL_NOTES.md "${PROJECT_ROOT_ABS}/docs/MODEL_NOTES.md"
cp templates/docs/CONTEXT-FORMAT.md "${PROJECT_ROOT_ABS}/docs/CONTEXT-FORMAT.md"
cp templates/docs/ADR-FORMAT.md "${PROJECT_ROOT_ABS}/docs/ADR-FORMAT.md"
cp templates/docs/adr/0000-adr-template.md "${PROJECT_ROOT_ABS}/docs/adr/0000-adr-template.md"
cp templates/docs/adr/OPEN_DECISIONS.md "${PROJECT_ROOT_ABS}/docs/adr/OPEN_DECISIONS.md"

# 3b. Select language-specific quality template
echo -e "3b. Selecting quality template for project type: ${PROJECT_TYPE}..."
if [ "${PROJECT_TYPE}" = "python" ]; then
    cp templates/docs/quality-python.md "${PROJECT_ROOT_ABS}/docs/quality.md"
elif [ "${PROJECT_TYPE}" = "r" ]; then
    cp templates/docs/quality-r.md "${PROJECT_ROOT_ABS}/docs/quality.md"
else
    cp templates/docs/quality-hybrid.md "${PROJECT_ROOT_ABS}/docs/quality.md"
fi

cp .gitignore "${PROJECT_ROOT_ABS}/.gitignore"
cp LICENSE "${PROJECT_ROOT_ABS}/LICENSE"

# 4. Copy language-specific partitioned templates
if [ "${PROJECT_TYPE}" = "python" ] || [ "${PROJECT_TYPE}" = "hybrid" ]; then
    echo -e "3a. Deploying Python-specific templates..."
    cp templates/python/pyproject.toml "${PROJECT_ROOT_ABS}/pyproject.toml"
    
    # Normalize package name (lowercase, replace hyphens with underscores)
    CLEAN_PKG_NAME=$(echo "${PROJECT_NAME}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    mkdir -p "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}"
    
    cp templates/python/src/__init__.py "${PROJECT_ROOT_ABS}/src/__init__.py"
    cp templates/python/src/__init__.py "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}/__init__.py"
    cp templates/python/src/{{project_name}}/config.py "${PROJECT_ROOT_ABS}/src/${CLEAN_PKG_NAME}/config.py"
    cp templates/python/tests/test_smoke.py "${PROJECT_ROOT_ABS}/tests/test_smoke.py"
    cp templates/python/tests/conftest.py "${PROJECT_ROOT_ABS}/tests/conftest.py"
fi

if [ "${PROJECT_TYPE}" = "r" ] || [ "${PROJECT_TYPE}" = "hybrid" ]; then
    echo -e "3b. Deploying R-specific templates..."
    cp templates/r/DESCRIPTION "${PROJECT_ROOT_ABS}/DESCRIPTION"
    cp templates/r/src/smoke.R "${PROJECT_ROOT_ABS}/src/smoke.R"
    cp templates/r/tests/testthat.R "${PROJECT_ROOT_ABS}/tests/testthat.R"
fi

# 5. Replace parameter placeholders
echo -e "4. Customizing parameters..."
ESCAPED_ROOT=$(echo "${PROJECT_ROOT_ABS}" | sed 's/\//\\\//g')

# Portable replacement function
replace_placeholders() {
    local target_file="$1"
    if [ -f "${target_file}" ]; then
        local clean_pkg=$(echo "${PROJECT_NAME}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
        sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${target_file}"
        sed -i.bak "s/{{PROJECT_DESCRIPTION}}/${PROJECT_DESCRIPTION}/g" "${target_file}"
        sed -i.bak "s/{{PROJECT_ROOT}}/${ESCAPED_ROOT}/g" "${target_file}"
        sed -i.bak "s/{{PROJECT_GOAL_SUMMARY}}/Establish analytical modeling environment for ${PROJECT_NAME}./g" "${target_file}"
        sed -i.bak "s/{{PACKAGE_NAME}}/${clean_pkg}/g" "${target_file}"
        rm -f "${target_file}.bak"
    fi
}

# Apply to all relevant generated assets
replace_placeholders "${PROJECT_ROOT_ABS}/AGENTS.md"
replace_placeholders "${PROJECT_ROOT_ABS}/CONTEXT.md"
replace_placeholders "${PROJECT_ROOT_ABS}/progress.md"
replace_placeholders "${PROJECT_ROOT_ABS}/README.md"
replace_placeholders "${PROJECT_ROOT_ABS}/DEVELOPER_WORKFLOW.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/architecture.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/beliefs.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/conventions.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/data-rules.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/modeling-rules.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/context-management.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/session-protocols.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/testing-requirements.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/security-rules.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/domain-rules.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/safety-policies.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/quality.md"
replace_placeholders "${PROJECT_ROOT_ABS}/docs/adr/OPEN_DECISIONS.md"
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

# 6. Auto-register in global trusted workspaces (Slice 5)
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

# 7. Automated Git Initialization & Baseline Commit (Slice 4)
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
