import os
import sys
import shutil
import subprocess
from pathlib import Path
import pytest
import ast

SCAFFOLD_PY = os.path.abspath(os.path.join(os.path.dirname(__file__), "../scripts/scaffold.py"))


def test_scaffold_python(tmp_path):
    """Test project scaffolder with Python type."""
    project_dir = tmp_path / "my_python_project"
    script_path = Path("scripts/scaffold.py").resolve()

    # Run scaffolder: scaffold.py <name> <type> [dest]
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
    assert (project_dir / ".agents/hooks.json").is_file()

    # Verify local custom skills are physically copied
    for skill in ["archive-progress", "compact-memory", "to-dfp", "execute-dfp"]:
        assert (project_dir / ".agents/skills" / skill / "SKILL.md").is_file()

    # Verify newly required deployed templates
    shared_templates = [
        "progress.md",
        "features.json",
        "CONTEXT.md",
        "DEVELOPER_WORKFLOW.md",
        ".env.example",
        "Makefile",
        ".pre-commit-config.yaml",
    ]
    for f in shared_templates:
        assert (
            project_dir / f
        ).is_file(), f"Shared template {f} missing from destination"

    # Verify placeholder resolution in progress.md and CONTEXT.md
    progress_file = project_dir / "progress.md"
    with open(progress_file, "r", encoding="utf-8") as f:
        progress_content = f.read()
    assert "{{PROJECT_NAME}}" not in progress_content
    assert "my_python_project" in progress_content
    assert "{{PROJECT_GOAL_SUMMARY}}" not in progress_content
    assert (
        "Establish analytical modeling environment for my_python_project."
        in progress_content
    )

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

    # R templates checks
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


def test_scaffold_python_structure_and_slugification(tmp_path):
    """Test Python package structure deployment and slugification logic."""
    project_dir = tmp_path / "My-Awesome-Project"
    script_path = Path("scripts/scaffold.py").resolve()

    # Run scaffolder
    res = subprocess.run(
        [sys.executable, str(script_path), "My-Awesome-Project", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0

    # PACKAGE_NAME derivation: My-Awesome-Project -> my_awesome_project
    package_name = "my_awesome_project"

    # Verify src/<package_name>/__init__.py, config.py, and schemas.py exist
    assert (project_dir / "src" / package_name).is_dir()
    assert (project_dir / "src" / package_name / "__init__.py").is_file()
    assert (project_dir / "src" / package_name / "config.py").is_file()
    assert (project_dir / "src" / package_name / "schemas.py").is_file()
    
    # Verify AST validity of config.py and schemas.py
    for py_file in ["config.py", "schemas.py"]:
        file_path = project_dir / "src" / package_name / py_file
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
        try:
            ast.parse(content)
        except SyntaxError as e:
            pytest.fail(f"{py_file} contains invalid Python syntax: {e}")

    # Verify templates/python/src/__init__.py didn't just get copied to src/__init__.py
    assert not (project_dir / "src" / "__init__.py").exists()

    # Verify pyproject.toml deployed
    pyproject_file = project_dir / "pyproject.toml"
    assert pyproject_file.is_file()
    with open(pyproject_file, "r", encoding="utf-8") as f:
        pyproject_content = f.read()
    assert 'name = "my_awesome_project"' in pyproject_content
    assert "{{PACKAGE_NAME}}" not in pyproject_content

    # Verify conftest.py and test_smoke.py deployed
    conftest_file = project_dir / "tests" / "conftest.py"
    smoke_file = project_dir / "tests" / "test_smoke.py"
    assert conftest_file.is_file()
    assert smoke_file.is_file()

    # Verify conftest.py PACKAGE_NAME replacement
    with open(conftest_file, "r", encoding="utf-8") as f:
        conftest_content = f.read()
    assert "from my_awesome_project.config import Settings, settings" in conftest_content
    assert "{{PACKAGE_NAME}}" not in conftest_content


def test_scaffold_deploys_hooks_json(tmp_path):
    """Test project scaffolder deploys hooks.json to .agents/hooks.json."""
    project_dir = tmp_path / "my_hooks_project"
    script_path = Path("scripts/scaffold.py").resolve()

    res = subprocess.run(
        [sys.executable, str(script_path), "my_hooks_project", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0

    # Assert hooks.json exists
    hooks_file = project_dir / ".agents" / "hooks.json"
    assert hooks_file.is_file(), ".agents/hooks.json was not deployed during scaffolding"


def test_scaffold_creates_adr_template_and_research_readme(tmp_path):
    """Test that the scaffolder creates docs/adr/ADR-TEMPLATE.md and docs/research/README.md."""
    project_dir = tmp_path / "my_python_scaffold_project"
    script_path = Path("scripts/scaffold.py").resolve()

    res = subprocess.run(
        [sys.executable, str(script_path), "my_python_scaffold_project", "python", str(project_dir)],
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
