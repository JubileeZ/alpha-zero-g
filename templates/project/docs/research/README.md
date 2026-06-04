# Research & Experiments - {{PROJECT_NAME}}

This directory contains research notebooks, exploratory analysis scripts, and experimental modeling workflows.

## Guidelines
1. **Source of Truth:** Notebooks should be authored in the `py:percent` format (as `.py` files with `# %%` cell markers) rather than raw `.ipynb` files to ensure they are clean, diff-able, and version-control friendly.
2. **Data Isolation:** Never commit raw or processed datasets directly to this directory. Use the `data/` folder for data storage and keep it gitignored.
3. **Execution:** Run scripts and models within the virtual environment using `uv run python <script_path>`.
