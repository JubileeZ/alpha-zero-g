import os
import sys
import shutil
import subprocess
import pytest
from pathlib import Path

def test_scaffold_python(tmp_path):
    """Test Python project scaffolder with Python type."""
    project_dir = tmp_path / "my_python_project"
    script_path = Path("scripts/scaffold.py").resolve()
    
    # Run scaffolder
    res = subprocess.run(
        [sys.executable, str(script_path), "my_python_project", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    
    # Assert successful execution
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
    
    # Verify newly required deployed templates
    shared_templates = [
        "progress.md", "features.json", "CONTEXT.md", "DEVELOPER_WORKFLOW.md",
        ".env.example", "Makefile", ".pre-commit-config.yaml"
    ]
    for f in shared_templates:
        assert (project_dir / f).is_file(), f"Shared template {f} missing from destination"
        
    # Verify placeholder resolution in progress.md and CONTEXT.md
    progress_file = project_dir / "progress.md"
    with open(progress_file, "r", encoding="utf-8") as f:
        progress_content = f.read()
    assert "{{PROJECT_NAME}}" not in progress_content
    assert "my_python_project" in progress_content
    assert "{{PROJECT_GOAL_SUMMARY}}" not in progress_content
    assert "Establish analytical modeling environment for my_python_project." in progress_content
    
    context_file = project_dir / "CONTEXT.md"
    with open(context_file, "r", encoding="utf-8") as f:
        context_content = f.read()
    assert "{{PROJECT_NAME}}" not in context_content
    assert "my_python_project" in context_content

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
    """Test Python project scaffolder with R type."""
    project_dir = tmp_path / "my_r_project"
    script_path = Path("scripts/scaffold.py").resolve()
    
    res = subprocess.run(
        [sys.executable, str(script_path), "my_r_project", "r", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0
    assert (project_dir / "R").is_dir()
    assert not (project_dir / "src").exists()

def test_scaffold_hybrid(tmp_path):
    """Test Python project scaffolder with hybrid type."""
    project_dir = tmp_path / "my_hybrid_project"
    script_path = Path("scripts/scaffold.py").resolve()
    
    res = subprocess.run(
        [sys.executable, str(script_path), "my_hybrid_project", "hybrid", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0
    assert (project_dir / "src").is_dir()
    assert (project_dir / "R").is_dir()
