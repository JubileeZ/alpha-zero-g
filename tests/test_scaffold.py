import os
import shutil
import subprocess
import pytest
from pathlib import Path

has_bash = shutil.which("bash") is not None
bash_only = pytest.mark.skipif(not has_bash, reason="bash not available")

@bash_only
def test_bash_scaffold_python(tmp_path):
    """Test Bash project scaffolder with Python type."""
    project_dir = tmp_path / "my_python_project"
    script_path = Path("scripts/scaffold-project.sh").resolve()
    
    # Run scaffolder
    res = subprocess.run(
        ["bash", str(script_path), "my_python_project", "--type", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    
    # Assert successful execution (will fail currently because script doesn't exist)
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
    
    # Verify global skills are physically copied
    expected_skills = [
        "diagnose",
        "improve-codebase-architecture",
        "setup-matt-pocock-skills",
        "tdd",
        "to-issues",
        "to-prd",
        "zoom-out",
        "caveman",
        "handoff",
        "write-a-skill",
        "to-dfp",
        "execute-dfp"
    ]
    for skill in expected_skills:
        assert (project_dir / ".agents/skills" / skill / "SKILL.md").is_file()
        
    # Verify Git commit
    res_git = subprocess.run(
        ["git", "log", "-1", "--pretty=%s"],
        cwd=str(project_dir),
        capture_output=True,
        text=True
    )
    assert res_git.returncode == 0
    assert "chore: scaffold via alpha-zero-g" in res_git.stdout

@bash_only
def test_bash_scaffold_r(tmp_path):
    """Test Bash project scaffolder with R type."""
    project_dir = tmp_path / "my_r_project"
    script_path = Path("scripts/scaffold-project.sh").resolve()
    
    res = subprocess.run(
        ["bash", str(script_path), "my_r_project", "--type", "r", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0
    assert (project_dir / "R").is_dir()
    assert not (project_dir / "src").exists()

@bash_only
def test_bash_scaffold_hybrid(tmp_path):
    """Test Bash project scaffolder with hybrid type."""
    project_dir = tmp_path / "my_hybrid_project"
    script_path = Path("scripts/scaffold-project.sh").resolve()
    
    res = subprocess.run(
        ["bash", str(script_path), "my_hybrid_project", "--type", "hybrid", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0
    assert (project_dir / "src").is_dir()
    assert (project_dir / "R").is_dir()

def test_powershell_scaffold_if_available(tmp_path):
    """Test PowerShell project scaffolder if pwsh or powershell is available."""
    import shutil
    pwsh = shutil.which("pwsh") or shutil.which("powershell")
    if not pwsh:
        pytest.skip("PowerShell not available")
        
    project_dir = tmp_path / "my_pwsh_project"
    script_path = Path("scripts/scaffold-project.ps1").resolve()
    
    res = subprocess.run(
        [pwsh, "-File", str(script_path), "my_pwsh_project", "-Type", "hybrid", str(project_dir)],
        capture_output=True,
        text=True
    )
    
    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"
    assert (project_dir / "src").is_dir()
    assert (project_dir / "R").is_dir()
    assert (project_dir / "tests").is_dir()
    assert (project_dir / "docs/adr").is_dir()
    assert (project_dir / "docs/research").is_dir()
    assert (project_dir / "data/raw").is_dir()
    assert (project_dir / "data/interim").is_dir()
    assert (project_dir / "data/processed").is_dir()
    assert (project_dir / ".agents/rules").is_dir()
    assert (project_dir / ".agents/skills").is_dir()
    
    # Verify Git commit
    res_git = subprocess.run(
        ["git", "log", "-1", "--pretty=%s"],
        cwd=str(project_dir),
        capture_output=True,
        text=True
    )
    assert res_git.returncode == 0
    assert "chore: scaffold via alpha-zero-g" in res_git.stdout

