#!/usr/bin/env bash

# Alpha-Zero-G Project Generator Script
# Automates the creation of new analytics/statistical workspaces from templates.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$#" -lt 1 ]; then
    echo -e "${RED}Usage: bash create-project.sh <destination-path> [project-name]${NC}"
    echo -e "Example: bash create-project.sh ../FPL-Model 'FPL Score Projection'"
    exit 1
fi

DEST_DIR="$1"
PROJECT_NAME="${2:-$(basename "${DEST_DIR}")}"
PROJECT_ROOT_ABS=$(mkdir -p "${DEST_DIR}" && cd "${DEST_DIR}" && pwd)

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Alpha-Zero-G Project Generator             ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e "Creating project: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "Target directory: ${GREEN}${PROJECT_ROOT_ABS}${NC}"

# Create directory structure
echo -e "\n1. Establishing directory structures..."
mkdir -p "${PROJECT_ROOT_ABS}/src"
mkdir -p "${PROJECT_ROOT_ABS}/notebooks"
mkdir -p "${PROJECT_ROOT_ABS}/tests"
mkdir -p "${PROJECT_ROOT_ABS}/.agents/skills"
mkdir -p "${PROJECT_ROOT_ABS}/docs/design"

# Copy template files
echo -e "2. Deploying template files..."
cp templates/AGENTS.md "${PROJECT_ROOT_ABS}/AGENTS.md"
cp templates/CONTEXT.md "${PROJECT_ROOT_ABS}/CONTEXT.md"
cp templates/progress.md "${PROJECT_ROOT_ABS}/progress.md"
cp templates/features.json "${PROJECT_ROOT_ABS}/features.json"
cp templates/pyproject.toml "${PROJECT_ROOT_ABS}/pyproject.toml"
cp templates/init.sh "${PROJECT_ROOT_ABS}/init.sh"
cp .agents/hooks.json "${PROJECT_ROOT_ABS}/.agents/hooks.json"

# Copy standard system docs
cp docs/architecture.md "${PROJECT_ROOT_ABS}/docs/architecture.md"
cp docs/beliefs.md "${PROJECT_ROOT_ABS}/docs/beliefs.md"
cp docs/quality.md "${PROJECT_ROOT_ABS}/docs/quality.md"
cp docs/DATA_DICT.md "${PROJECT_ROOT_ABS}/docs/DATA_DICT.md"
cp docs/MODEL_NOTES.md "${PROJECT_ROOT_ABS}/docs/MODEL_NOTES.md"
cp docs/design/INDEX.md "${PROJECT_ROOT_ABS}/docs/design/INDEX.md"
cp .gitignore "${PROJECT_ROOT_ABS}/.gitignore"
cp README.md "${PROJECT_ROOT_ABS}/README.md"
cp LICENSE "${PROJECT_ROOT_ABS}/LICENSE"

# Replace parameter placeholders
echo -e "3. Customizing parameters..."
# Escape project root path for sed
ESCAPED_ROOT=$(echo "${PROJECT_ROOT_ABS}" | sed 's/\//\\\//g')

# Use portable sed for macOS/Linux
sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${PROJECT_ROOT_ABS}/AGENTS.md"
sed -i.bak "s/{{PROJECT_ROOT}}/${ESCAPED_ROOT}/g" "${PROJECT_ROOT_ABS}/AGENTS.md"
sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${PROJECT_ROOT_ABS}/CONTEXT.md"
sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${PROJECT_ROOT_ABS}/progress.md"
sed -i.bak "s/{{PROJECT_NAME}}/${PROJECT_NAME}/g" "${PROJECT_ROOT_ABS}/pyproject.toml"
sed -i.bak "s/{{PROJECT_GOAL_SUMMARY}}/Establish analytical modeling environment for ${PROJECT_NAME}./g" "${PROJECT_ROOT_ABS}/progress.md"

# Remove sed backup files
find "${PROJECT_ROOT_ABS}" -name "*.bak" -type f -delete

echo -e "${GREEN}✔ Project successfully bootstrapped!${NC}"
echo -e "\nNext steps:"
echo -e "  1. CD into the new workspace: ${YELLOW}cd \"${DEST_DIR}\"${NC}"
echo -e "  2. Run the local bootstrapper: ${YELLOW}bash init.sh${NC}"
echo -e "  3. Open the directory with your AI Agent to begin!${NC}"
echo -e "${BLUE}===============================================${NC}"
