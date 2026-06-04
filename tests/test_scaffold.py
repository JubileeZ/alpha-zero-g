import os
import sys
import shutil
import subprocess
from pathlib import Path
import pytest

SCAFFOLD_PY = os.path.abspath(os.path.join(os.path.dirname(__file__), "../scripts/scaffold.py"))

def test_python_scaffold_python(tmp_path):
    """Test Python project scaffolder with Python type."""
    project_dir = tmp_path / "my_python_project"
    
    # Run scaffolder
    res = subprocess.run(
        [sys.executable, SCAFFOLD_PY, "my_python_project", "python", str(project_dir)],
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
    
    # Verify Git commit
    res_git = subprocess.run(
        ["git", "log", "-1", "--pretty=%s"],
        cwd=str(project_dir),
        capture_output=True,
        text=True
    )
    assert res_git.returncode == 0
    assert "chore: scaffold via alpha-zero-g" in res_git.stdout

def test_python_scaffold_r(tmp_path):
    """Test Python project scaffolder with R type."""
    project_dir = tmp_path / "my_r_project"
    
    res = subprocess.run(
        [sys.executable, SCAFFOLD_PY, "my_r_project", "r", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0
    assert (project_dir / "R").is_dir()
    assert not (project_dir / "src").exists()

def test_python_scaffold_hybrid(tmp_path):
    """Test Python project scaffolder with hybrid type."""
    project_dir = tmp_path / "my_hybrid_project"
    
    res = subprocess.run(
        [sys.executable, SCAFFOLD_PY, "my_hybrid_project", "hybrid", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0
    assert (project_dir / "src").is_dir()
    assert (project_dir / "R").is_dir()

def test_python_scaffold_creates_adr_template_and_research_readme(tmp_path):
    """Test that the python scaffolder creates docs/adr/ADR-TEMPLATE.md and docs/research/README.md."""
    project_dir = tmp_path / "my_python_scaffold_project"
    
    # Run the scaffold.py script
    res = subprocess.run(
        [sys.executable, SCAFFOLD_PY, "my_python_scaffold_project", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    
    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"
    
    # Assert existence of standard directories
    assert (project_dir / "docs/adr").is_dir()
    assert (project_dir / "docs/research").is_dir()
    
    # Assert existence of the newly required template files
    adr_template = project_dir / "docs/adr/ADR-TEMPLATE.md"
    research_readme = project_dir / "docs/research/README.md"
    
    assert adr_template.is_file(), "docs/adr/ADR-TEMPLATE.md was not created"
    assert research_readme.is_file(), "docs/research/README.md was not created"
    
    # Assert placeholders were replaced
    with open(adr_template, "r", encoding="utf-8") as f:
        adr_content = f.read()
    assert "{{PROJECT_NAME}}" not in adr_content
    assert "my_python_scaffold_project" in adr_content
    
    with open(research_readme, "r", encoding="utf-8") as f:
        research_content = f.read()
    assert "{{PROJECT_NAME}}" not in research_content
    assert "my_python_scaffold_project" in research_content
