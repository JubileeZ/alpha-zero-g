import os
import shutil
import subprocess
import pytest
import sys
from pathlib import Path

def test_scaffold_python(tmp_path):
    """Test project scaffolder with Python type."""
    project_dir = tmp_path / "my_python_project"
    script_path = Path("scripts/scaffold.py").resolve()
    
    # Run scaffolder
    res = subprocess.run(
        [sys.executable, str(script_path), "my_python_project", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    
    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"
    
    # Verify directories
    assert (project_dir / "src").is_dir()
    assert not (project_dir / "R").exists()
    assert (project_dir / "tests").is_dir()
    assert (project_dir / "docs/adr").is_dir()
    assert (project_dir / "docs/research").is_dir()
    assert (project_dir / "data/raw").is_dir()
    assert (project_dir / "data/interim").is_dir()
    assert (project_dir / "data/processed").is_dir()
    assert (project_dir / ".agents/rules").is_dir()
    assert (project_dir / ".agents/skills").is_dir()
    
    # Verify rules copy and placeholder replacement
    agents_file = project_dir / "AGENTS.md"
    gemini_file = project_dir / "GEMINI.md"
    claude_file = project_dir / "CLAUDE.md"
    
    assert agents_file.is_file()
    assert gemini_file.is_file()
    assert claude_file.is_file()
    
    with open(agents_file, "r", encoding="utf-8") as f:
        agents_content = f.read()
    assert "{{PROJECT_NAME}}" not in agents_content
    assert "my_python_project" in agents_content
    
    # Verify ADR-001 generation
    adr_file = project_dir / "docs/adr/ADR-001-project-init.md"
    assert adr_file.is_file()
    with open(adr_file, "r", encoding="utf-8") as f:
        adr_content = f.read()
    assert "Status:** Accepted" in adr_content
    assert "{{DATE}}" not in adr_content
    
    # Verify .gitignore and .skillsrc deployment
    assert (project_dir / ".gitignore").is_file()
    assert (project_dir / ".skillsrc").is_file()
    
    # Verify Git commit
    res_git = subprocess.run(
        ["git", "log", "-1", "--pretty=%s"],
        cwd=str(project_dir),
        capture_output=True,
        text=True
    )
    assert res_git.returncode == 0
    assert "chore: scaffold via alpha-zero-g" in res_git.stdout

def test_scaffold_r(tmp_path):
    """Test project scaffolder with R type."""
    project_dir = tmp_path / "my_r_project"
    script_path = Path("scripts/scaffold.py").resolve()
    
    res = subprocess.run(
        [sys.executable, str(script_path), "my_r_project", "r", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"
    assert (project_dir / "R").is_dir()
    
    # R templates checks (should fail before implementation)
    assert (project_dir / "DESCRIPTION").is_file()
    assert (project_dir / "src/smoke.R").is_file()
    assert (project_dir / "tests/testthat.R").is_file()
    
    with open(project_dir / "DESCRIPTION", "r", encoding="utf-8") as f:
        desc_content = f.read()
    assert "Package: my_r_project" in desc_content
    assert "{{PROJECT_NAME}}" not in desc_content

def test_scaffold_hybrid(tmp_path):
    """Test project scaffolder with hybrid type."""
    project_dir = tmp_path / "my_hybrid_project"
    script_path = Path("scripts/scaffold.py").resolve()
    
    res = subprocess.run(
        [sys.executable, str(script_path), "my_hybrid_project", "hybrid", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"
    assert (project_dir / "src").is_dir()
    assert (project_dir / "R").is_dir()
    
    # R templates checks (should fail before implementation)
    assert (project_dir / "DESCRIPTION").is_file()
    assert (project_dir / "src/smoke.R").is_file()
    assert (project_dir / "tests/testthat.R").is_file()
    
    with open(project_dir / "DESCRIPTION", "r", encoding="utf-8") as f:
        desc_content = f.read()
    assert "Package: my_hybrid_project" in desc_content
    assert "{{PROJECT_NAME}}" not in desc_content
