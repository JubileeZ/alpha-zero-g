#!/usr/bin/env bash

# Alpha-Zero-G Environment Bootstrap Script
# Standardized dynamic bootstrapper for Python (uv) and R (renv) pipelines.

set -euo pipefail

# Visual styling
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Alpha-Zero-G Environment Bootstrapper      ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Detect systems
OS_NAME=$(uname)
echo -e "System OS: ${GREEN}${OS_NAME}${NC}"

# 1. PYTHON BOOTSTRAP (uv)
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -n "$(find . -name "*.py" -maxdepth 3 2>/dev/null)" ]; then
    echo -e "\n${BLUE}[1/2] Python Environment Detected${NC}"
    
    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}uv package manager not found. Installing uv...${NC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        # Source cargo/bin/uv path
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if command -v uv &> /dev/null; then
        echo -e "uv version: ${GREEN}$(uv --version)${NC}"
        
        # Build/sync virtual environment
        echo -e "Synchronizing Python virtual environment using uv..."
        if [ -f "pyproject.toml" ]; then
            # Syncs virtual env and installs dependency groups
            [ -d ".venv" ] || uv venv --python 3.12
            uv pip install -e . --all-extras 2>/dev/null || uv pip install -e . || uv pip install -r pyproject.toml 2>/dev/null || true
            # Sync dev dependencies if any
            if grep -q "dependency-groups" pyproject.toml; then
                echo -e "Installing dev dependencies..."
                uv pip install -e ".[dev]" 2>/dev/null || uv pip install pytest ruff ipykernel
            fi
        elif [ -f "requirements.txt" ]; then
            [ -d ".venv" ] || uv venv --python 3.12
            uv pip install -r requirements.txt
        fi
        
        # Python Smoke Test
        echo -e "\nRunning Python validation checks (smoke test)..."
        source .venv/bin/activate
        python -c "
import sys
import pandas as pd
import numpy as np
import scipy
print(f'  - Python version: {sys.version.split()[0]} (OK)')
print(f'  - pandas version: {pd.__version__} (OK)')
print(f'  - numpy version: {np.__version__} (OK)')
"
        echo -e "${GREEN}✔ Python environment synced and verified successfully!${NC}"
    else
        echo -e "${RED}✘ Failed to install or locate uv. Python setup aborted.${NC}"
        exit 1
    fi
else
    echo -e "\n${YELLOW}Python requirements or scripts not detected. Skipping Python setup.${NC}"
fi

# 2. R BOOTSTRAP (renv)
R_SCRIPTS=$(find . -name "*.R" -o -name "*.Rmd" -o -name ".Rprofile" -maxdepth 3 2>/dev/null)
if [ -f "DESCRIPTION" ] || [ -f "renv.lock" ] || [ -n "${R_SCRIPTS}" ]; then
    echo -e "\n${BLUE}[2/2] R Statistical Language Environment Detected${NC}"
    
    # Check if R is installed
    if command -v Rscript &> /dev/null; then
        echo -e "R version: ${GREEN}$(Rscript --version 2>&1)${NC}"
        
        # Check and install renv if not initialized
        echo -e "Checking R library management (renv)..."
        Rscript -e "
if (!requireNamespace('renv', quietly = TRUE)) {
    cat('renv package not found. Installing renv...\n')
    install.packages('renv', repos='https://cloud.r-project.org/')
} else {
    cat('renv package verified (OK)\n')
}
"
        
        if [ -f "renv.lock" ]; then
            echo -e "Synchronizing libraries from renv.lock..."
            Rscript -e "renv::restore(prompt = FALSE)"
        else
            echo -e "${YELLOW}renv.lock not found. Initializing local renv workspace...${NC}"
            Rscript -e "renv::init(bare = TRUE, restart = FALSE)"
        fi
        
        # R Smoke Test
        echo -e "\nRunning R validation checks (smoke test)..."
        Rscript -e "
cat(paste('  - R version:', R.version$version.string, '(OK)\n'))
if (requireNamespace('renv', quietly=TRUE)) {
    cat('  - renv validation: passed (OK)\n')
}
"
        echo -e "${GREEN}✔ R environment synced and verified successfully!${NC}"
    else
        echo -e "${YELLOW}Rscript command is not available. Please install R on your system to execute R processes.${NC}"
    fi
else
    echo -e "\n${YELLOW}R requirements or scripts not detected. Skipping R setup.${NC}"
fi

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}      Harness Bootstrapping Completed          ${NC}"
echo -e "${GREEN}===============================================${NC}"
