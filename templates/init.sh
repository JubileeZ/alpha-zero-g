#!/usr/bin/env bash

# Project Environment Bootstrap Script
# Standardized dynamic bootstrapper for Python (uv) and R (renv) pipelines.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Environment Bootstrapper                   ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Python Bootstrap (uv)
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -n "$(find . -name "*.py" -maxdepth 3 2>/dev/null)" ]; then
    echo -e "\n${BLUE}[1/2] Python Environment Detected${NC}"
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}uv package manager not found. Installing uv...${NC}"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if command -v uv &> /dev/null; then
        echo -e "uv version: ${GREEN}$(uv --version)${NC}"
        echo -e "Synchronizing Python virtual environment using uv..."
        uv venv --python 3.12
        if [ -f "pyproject.toml" ]; then
            uv pip install -e . --all-extras 2>/dev/null || uv pip install -e . || uv pip install -r pyproject.toml 2>/dev/null || true
            if grep -q "dependency-groups" pyproject.toml; then
                uv pip install -e ".[dev]" 2>/dev/null || uv pip install pytest ruff ipykernel
            fi
        elif [ -f "requirements.txt" ]; then
            uv pip install -r requirements.txt
        fi
        
        # Smoke Test
        echo -e "\nRunning Python validation checks..."
        source .venv/bin/activate
        python -c "import sys; import pandas as pd; import numpy as np; print(f'  - Python version: {sys.version.split()[0]} (OK)')"
        echo -e "${GREEN}✔ Python environment synced successfully!${NC}"
    fi
fi

# R Bootstrap (renv)
R_SCRIPTS=$(find . -name "*.R" -o -name "*.Rmd" -o -name ".Rprofile" -maxdepth 3 2>/dev/null)
if [ -f "DESCRIPTION" ] || [ -f "renv.lock" ] || [ -n "${R_SCRIPTS}" ]; then
    echo -e "\n${BLUE}[2/2] R Language Environment Detected${NC}"
    if command -v Rscript &> /dev/null; then
        echo -e "R version: ${GREEN}$(Rscript --version 2>&1)${NC}"
        Rscript -e "
if (!requireNamespace('renv', quietly = TRUE)) {
    install.packages('renv', repos='https://cloud.r-project.org/')
}
"
        if [ -f "renv.lock" ]; then
            Rscript -e "renv::restore(prompt = FALSE)"
        else
            Rscript -e "renv::init(bare = TRUE, restart = FALSE)"
        fi
        echo -e "${GREEN}✔ R environment synced successfully!${NC}"
    fi
fi

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}      Harness Bootstrapping Completed          ${NC}"
echo -e "${GREEN}===============================================${NC}"
