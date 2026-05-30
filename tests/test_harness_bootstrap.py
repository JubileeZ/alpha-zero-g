import os
import shutil
import pytest
import stat

# Robust shutil.rmtree wrapper for Windows read-only git files
_orig_rmtree = shutil.rmtree
def rmtree_robust(path, *args, **kwargs):
    def remove_readonly(func, p, exc):
        try:
            os.chmod(p, stat.S_IWRITE)
            func(p)
        except Exception:
            pass
    return _orig_rmtree(path, onerror=remove_readonly)
shutil.rmtree = rmtree_robust

# Paths
TEMPLATES_DIR = "templates"
PYTHON_TEMPLATES = os.path.join(TEMPLATES_DIR, "python")
R_TEMPLATES = os.path.join(TEMPLATES_DIR, "r")

def get_bash_executable():
    """Resolve the bash executable path, supporting Windows Git Bash location if not in PATH.
    
    Returns:
        str: Absolute path to bash.exe or 'bash'.
    """
    import shutil
    bash_path = shutil.which("bash")
    if bash_path:
        return bash_path
    # Windows fallback
    for path in [
        r"C:\Program Files\Git\bin\bash.exe",
        r"C:\Program Files\Git\usr\bin\bash.exe",
        r"C:\Program Files (x86)\Git\bin\bash.exe",
    ]:
        if os.path.exists(path):
            return path
    return "bash"


def test_slice1_template_directories_exist():
    """Verify that templates/ is partitioned into python/ and r/ subdirectories."""
    assert os.path.isdir(PYTHON_TEMPLATES), "templates/python directory should exist"
    assert os.path.isdir(R_TEMPLATES), "templates/r directory should exist"

def test_slice1_python_templates_present():
    """Verify standard Python templates are present in the partitioned directory."""
    pyproject_toml = os.path.join(PYTHON_TEMPLATES, "pyproject.toml")
    init_py = os.path.join(PYTHON_TEMPLATES, "src", "__init__.py")
    test_smoke = os.path.join(PYTHON_TEMPLATES, "tests", "test_smoke.py")
    
    assert os.path.isfile(pyproject_toml), "python pyproject.toml template should exist"
    assert os.path.isfile(init_py), "python __init__.py template should exist"
    assert os.path.isfile(test_smoke), "python test_smoke.py template should exist"

def test_slice1_r_templates_present():
    """Verify standard R templates are present in the partitioned directory."""
    description = os.path.join(R_TEMPLATES, "DESCRIPTION")
    smoke_r = os.path.join(R_TEMPLATES, "src", "smoke.R")
    testthat_r = os.path.join(R_TEMPLATES, "tests", "testthat.R")
    
    assert os.path.isfile(description), "R DESCRIPTION template should exist"
    assert os.path.isfile(smoke_r), "R smoke.R template should exist"
    assert os.path.isfile(testthat_r), "R testthat.R template should exist"

def test_slice2_readme_template_has_golden_path_workflow():
    """Verify that templates/README.md and templates/DEVELOPER_WORKFLOW.md exist and contain the Golden Path descriptions."""
    readme_path = os.path.join(TEMPLATES_DIR, "README.md")
    workflow_path = os.path.join(TEMPLATES_DIR, "DEVELOPER_WORKFLOW.md")
    
    assert os.path.isfile(readme_path), "templates/README.md template should exist"
    assert os.path.isfile(workflow_path), "templates/DEVELOPER_WORKFLOW.md template should exist"
    
    with open(readme_path, "r", encoding="utf-8") as f:
        readme_content = f.read()
    assert "Golden Path" in readme_content, "README.md should mention 'Golden Path'"
    assert "DEVELOPER_WORKFLOW.md" in readme_content, "README.md should reference DEVELOPER_WORKFLOW.md"
    
    with open(workflow_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    assert "Golden Path" in content, "DEVELOPER_WORKFLOW.md should mention 'Golden Path'"
    
    content_upper = content.upper()
    assert "GRILL" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Grill'"
    assert "SPEC" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Spec'"
    assert "SLICE" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Slice'"
    assert "SHIP" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Ship'"
    assert "VERIFY" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Verify'"
    assert "REFACTOR" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Refactor'"
    assert "HANDOFF" in content_upper, "DEVELOPER_WORKFLOW.md should mention 'Handoff'"

def test_slice2_agents_template_has_workflow_pointers():
    """Verify that templates/AGENTS.md contains core operating protocols."""
    agents_path = os.path.join(TEMPLATES_DIR, "AGENTS.md")
    assert os.path.isfile(agents_path), "templates/AGENTS.md template should exist"
    
    with open(agents_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    assert "Core Rules & Operating Protocols" in content, "AGENTS.md should have a Core Rules & Operating Protocols section"
    assert "Deterministic Python" in content or "deterministic python" in content.lower(), "AGENTS.md should assert deterministic python"

def test_slice3_python_project_generation():
    """Verify that create-project.sh can generate a Python-only project with interactive inputs."""
    dest_dir = "scratch/test-py"
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
        
    import subprocess
    # Run create-project.sh non-interactively using arguments for this test
    # Args: <destination> <project-name> <project-type> <description>
    cmd = [get_bash_executable(), "create-project.sh", dest_dir, "Test-Python-Project", "python", "A testing python project description"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    assert result.returncode == 0, f"create-project.sh failed: {result.stderr}"
    
    # Assert directory structure
    assert os.path.isdir(os.path.join(dest_dir, "src")), "src/ directory should exist"
    assert os.path.isdir(os.path.join(dest_dir, "tests")), "tests/ directory should exist"
    assert not os.path.isdir(os.path.join(dest_dir, "docs")), "docs/ directory should NOT exist in MVP"
    assert not os.path.isdir(os.path.join(dest_dir, ".agents", "rules")), ".agents/rules/ should NOT exist in MVP"
    
    # Assert Python files copied, R files omitted
    assert os.path.isfile(os.path.join(dest_dir, "pyproject.toml")), "pyproject.toml should exist"
    assert os.path.isfile(os.path.join(dest_dir, "src", "__init__.py")), "src/__init__.py should exist"
    assert os.path.isfile(os.path.join(dest_dir, "tests", "test_smoke.py")), "test_smoke.py should exist"
    
    assert not os.path.isfile(os.path.join(dest_dir, "DESCRIPTION")), "DESCRIPTION should NOT exist in a Python project"
    assert not os.path.isfile(os.path.join(dest_dir, "src", "smoke.R")), "smoke.R should NOT exist in a Python project"
    
    # Assert glossary, workflow, and core files copied
    assert os.path.isfile(os.path.join(dest_dir, "AGENTS.md")), "AGENTS.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "CONTEXT.md")), "CONTEXT.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "progress.md")), "progress.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "features.json")), "features.json should exist"
    assert os.path.isfile(os.path.join(dest_dir, "README.md")), "README.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "DEVELOPER_WORKFLOW.md")), "DEVELOPER_WORKFLOW.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "init.sh")), "init.sh should exist"
    assert os.path.isfile(os.path.join(dest_dir, "Makefile")), "Makefile should exist"
    assert os.path.isfile(os.path.join(dest_dir, ".pre-commit-config.yaml")), ".pre-commit-config.yaml should exist"
    assert os.path.isfile(os.path.join(dest_dir, ".env.example")), ".env.example should exist"
    assert os.path.isfile(os.path.join(dest_dir, ".agents", "hooks.json")), "hooks.json should exist"

    # Assert placeholder resolution
    with open(os.path.join(dest_dir, "AGENTS.md"), "r", encoding="utf-8") as f:
        agents_content = f.read()
    assert "A testing python project description" in agents_content, "Project description placeholder was not replaced"
    assert "Test-Python-Project" in agents_content, "Project name placeholder was not replaced"
    assert "{{PROJECT_DESCRIPTION}}" not in agents_content, "AGENTS.md still contains raw description placeholder"
    assert "{{PROJECT_ROOT}}" not in agents_content, "AGENTS.md still contains raw root placeholder"

    with open(os.path.join(dest_dir, "DEVELOPER_WORKFLOW.md"), "r", encoding="utf-8") as f:
        workflow_content = f.read()
    assert "Test-Python-Project" in workflow_content, "Project name placeholder was not replaced in DEVELOPER_WORKFLOW.md"

    # Assert Git initialization and baseline commit
    assert os.path.isdir(os.path.join(dest_dir, ".git")), "Git repository should be initialized"
    git_log_res = subprocess.run(["git", "-C", dest_dir, "log", "-n", "1", "--oneline"], capture_output=True, text=True)
    assert "initial harness bootstrap" in git_log_res.stdout, f"Baseline commit should be created. Got: {git_log_res.stdout}"

    # Assert Trusted Workspace auto-registration
    import json
    settings_path = os.path.expanduser("~/.gemini/antigravity-cli/settings.json")
    if os.path.isfile(settings_path):
        with open(settings_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        trusted = data.get("trustedWorkspaces", [])
        import re
        norm_trusted = [os.path.normpath(re.sub(r'^[\\/]([a-zA-Z])[\\/]', r'\1:\\', p)).lower() for p in trusted]
        norm_target = os.path.normpath(os.path.abspath(dest_dir)).lower()
        assert norm_target in norm_trusted, "Workspace should be auto-registered as trusted"

    # Clean up
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)

def test_slice3_r_project_generation():
    """Verify that create-project.sh can generate an R-only project."""
    dest_dir = "scratch/test-r"
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
        
    import subprocess
    cmd = [get_bash_executable(), "create-project.sh", dest_dir, "Test-R-Project", "r", "A testing R project description"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    assert result.returncode == 0, f"create-project.sh failed: {result.stderr}"
    
    # Assert R files copied, Python files omitted
    assert os.path.isfile(os.path.join(dest_dir, "DESCRIPTION")), "DESCRIPTION should exist in R project"
    assert os.path.isfile(os.path.join(dest_dir, "src", "smoke.R")), "smoke.R should exist in R project"
    assert os.path.isfile(os.path.join(dest_dir, "tests", "testthat.R")), "testthat.R should exist in R project"
    
    assert not os.path.isfile(os.path.join(dest_dir, "pyproject.toml")), "pyproject.toml should NOT exist in R project"
    assert not os.path.isfile(os.path.join(dest_dir, "tests", "test_smoke.py")), "test_smoke.py should NOT exist in R project"
    
    # Assert placeholder resolution
    with open(os.path.join(dest_dir, "DESCRIPTION"), "r", encoding="utf-8") as f:
        desc_content = f.read()
    assert "Test-R-Project" in desc_content, "Project name placeholder not resolved in DESCRIPTION"
    assert "{{PROJECT_NAME}}" not in desc_content, "DESCRIPTION still contains raw name placeholder"

    # Clean up
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
