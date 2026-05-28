import os
import shutil
import pytest

# Paths
TEMPLATES_DIR = "templates"
PYTHON_TEMPLATES = os.path.join(TEMPLATES_DIR, "python")
R_TEMPLATES = os.path.join(TEMPLATES_DIR, "r")
DOCS_TEMPLATES = os.path.join(TEMPLATES_DIR, "docs")

def test_slice1_template_directories_exist():
    """Verify that templates/ is partitioned into python/, r/, and docs/ subdirectories."""
    assert os.path.isdir(PYTHON_TEMPLATES), "templates/python directory should exist"
    assert os.path.isdir(R_TEMPLATES), "templates/r directory should exist"
    assert os.path.isdir(DOCS_TEMPLATES), "templates/docs directory should exist"

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

def test_slice1_doc_templates_present():
    """Verify standard glossary, ADR guidelines, and ADR template are present."""
    context_format = os.path.join(DOCS_TEMPLATES, "CONTEXT-FORMAT.md")
    adr_format = os.path.join(DOCS_TEMPLATES, "ADR-FORMAT.md")
    adr_template = os.path.join(DOCS_TEMPLATES, "adr", "0000-adr-template.md")
    
    assert os.path.isfile(context_format), "docs CONTEXT-FORMAT.md template should exist"
    assert os.path.isfile(adr_format), "docs ADR-FORMAT.md template should exist"
    assert os.path.isfile(adr_template), "docs adr/0000-adr-template.md template should exist"

def test_slice2_readme_template_has_golden_path_workflow():
    """Verify that templates/README.md and templates/DEVELOPER_WORKFLOW.md exist and contain the Golden Path descriptions."""
    readme_path = os.path.join(TEMPLATES_DIR, "README.md")
    workflow_path = os.path.join(TEMPLATES_DIR, "DEVELOPER_WORKFLOW.md")
    
    assert os.path.isfile(readme_path), "templates/README.md template should exist"
    assert os.path.isfile(workflow_path), "templates/DEVELOPER_WORKFLOW.md template should exist"
    
    with open(readme_path, "r") as f:
        readme_content = f.read()
    assert "Golden Path" in readme_content, "README.md should mention 'Golden Path'"
    assert "DEVELOPER_WORKFLOW.md" in readme_content, "README.md should reference DEVELOPER_WORKFLOW.md"
    
    with open(workflow_path, "r") as f:
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
    """Verify that templates/AGENTS.md contains pointers to the workflow."""
    agents_path = os.path.join(TEMPLATES_DIR, "AGENTS.md")
    assert os.path.isfile(agents_path), "templates/AGENTS.md template should exist"
    
    with open(agents_path, "r") as f:
        content = f.read()
        
    assert "Preferred Workflows" in content, "AGENTS.md should have a Preferred Workflows section"
    assert "grill-with-docs" in content or "grill-analytics" in content, "AGENTS.md should point to grill skills"

def test_slice3_python_project_generation():
    """Verify that create-project.sh can generate a Python-only project with interactive inputs."""
    dest_dir = "scratch/test-py"
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
        
    import subprocess
    # Run create-project.sh non-interactively using arguments for this test
    # Args: <destination> <project-name> <project-type> <description>
    cmd = ["bash", "create-project.sh", dest_dir, "Test-Python-Project", "python", "A testing python project description"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    assert result.returncode == 0, f"create-project.sh failed: {result.stderr}"
    
    # Assert directory structure
    assert os.path.isdir(os.path.join(dest_dir, "src")), "src/ directory should exist"
    assert os.path.isdir(os.path.join(dest_dir, "tests")), "tests/ directory should exist"
    
    # Assert Python files copied, R files omitted
    assert os.path.isfile(os.path.join(dest_dir, "pyproject.toml")), "pyproject.toml should exist"
    assert os.path.isfile(os.path.join(dest_dir, "src", "__init__.py")), "src/__init__.py should exist"
    assert os.path.isfile(os.path.join(dest_dir, "tests", "test_smoke.py")), "test_smoke.py should exist"
    
    assert not os.path.isfile(os.path.join(dest_dir, "DESCRIPTION")), "DESCRIPTION should NOT exist in a Python project"
    assert not os.path.isfile(os.path.join(dest_dir, "src", "smoke.R")), "smoke.R should NOT exist in a Python project"
    
    # Assert glossary, workflow, and ADR format copied
    assert os.path.isfile(os.path.join(dest_dir, "docs", "CONTEXT-FORMAT.md")), "CONTEXT-FORMAT.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "docs", "ADR-FORMAT.md")), "ADR-FORMAT.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "docs", "adr", "0000-adr-template.md")), "0000-adr-template.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "docs", "adr", "0001-dynamic-bootstrapping.md")), "0001-dynamic-bootstrapping.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "docs", "adr", "0002-automated-project-scaffolder.md")), "0002-automated-project-scaffolder.md should exist"
    assert os.path.isfile(os.path.join(dest_dir, "DEVELOPER_WORKFLOW.md")), "DEVELOPER_WORKFLOW.md should exist"

    # Assert placeholder resolution
    with open(os.path.join(dest_dir, "AGENTS.md"), "r") as f:
        agents_content = f.read()
    assert "A testing python project description" in agents_content, "Project description placeholder was not replaced"
    assert "Test-Python-Project" in agents_content, "Project name placeholder was not replaced"
    assert "{{PROJECT_DESCRIPTION}}" not in agents_content, "AGENTS.md still contains raw description placeholder"
    assert "{{PROJECT_ROOT}}" not in agents_content, "AGENTS.md still contains raw root placeholder"

    with open(os.path.join(dest_dir, "DEVELOPER_WORKFLOW.md"), "r") as f:
        workflow_content = f.read()
    assert "Test-Python-Project" in workflow_content, "Project name placeholder was not replaced in DEVELOPER_WORKFLOW.md"

    # Assert Git initialization and baseline commit (Slice 4)
    assert os.path.isdir(os.path.join(dest_dir, ".git")), "Git repository should be initialized"
    git_log_res = subprocess.run(["git", "-C", dest_dir, "log", "-n", "1", "--oneline"], capture_output=True, text=True)
    assert "initial harness bootstrap" in git_log_res.stdout, f"Baseline commit should be created. Got: {git_log_res.stdout}"

    # Assert Trusted Workspace auto-registration (Slice 5)
    import json
    settings_path = os.path.expanduser("~/.gemini/antigravity-cli/settings.json")
    if os.path.isfile(settings_path):
        with open(settings_path, "r") as f:
            data = json.load(f)
        assert os.path.abspath(dest_dir) in data.get("trustedWorkspaces", []), "Workspace should be auto-registered as trusted"

    # Clean up
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)

def test_slice3_r_project_generation():
    """Verify that create-project.sh can generate an R-only project."""
    dest_dir = "scratch/test-r"
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
        
    import subprocess
    cmd = ["bash", "create-project.sh", dest_dir, "Test-R-Project", "r", "A testing R project description"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    assert result.returncode == 0, f"create-project.sh failed: {result.stderr}"
    
    # Assert R files copied, Python files omitted
    assert os.path.isfile(os.path.join(dest_dir, "DESCRIPTION")), "DESCRIPTION should exist in R project"
    assert os.path.isfile(os.path.join(dest_dir, "src", "smoke.R")), "smoke.R should exist in R project"
    assert os.path.isfile(os.path.join(dest_dir, "tests", "testthat.R")), "testthat.R should exist in R project"
    
    assert not os.path.isfile(os.path.join(dest_dir, "pyproject.toml")), "pyproject.toml should NOT exist in R project"
    assert not os.path.isfile(os.path.join(dest_dir, "tests", "test_smoke.py")), "test_smoke.py should NOT exist in R project"
    
    # Assert placeholder resolution
    with open(os.path.join(dest_dir, "DESCRIPTION"), "r") as f:
        desc_content = f.read()
    assert "Test-R-Project" in desc_content, "Project name placeholder not resolved in DESCRIPTION"
    assert "{{PROJECT_NAME}}" not in desc_content, "DESCRIPTION still contains raw name placeholder"

    # Clean up
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)

def test_slice6_global_harness_sync():
    """Verify that setup-global-harness.sh can backup local configs, seed Google Drive, and establish symlinks."""
    mock_home = os.path.abspath("scratch/mock_home")
    mock_gdrive = os.path.abspath("scratch/mock_gdrive")
    
    # Cleanup previous runs
    for path in [mock_home, mock_gdrive]:
        if os.path.exists(path):
            shutil.rmtree(path)
            
    # Setup initial local home structure
    local_gemini = os.path.join(mock_home, ".gemini")
    os.makedirs(os.path.join(local_gemini, "antigravity-cli"))
    os.makedirs(os.path.join(local_gemini, "antigravity"))
    
    # Write some initial local configs to seed
    local_settings = os.path.join(local_gemini, "antigravity-cli", "settings.json")
    local_agents = os.path.join(local_gemini, "AGENTS.md")
    local_gemini_md = os.path.join(local_gemini, "GEMINI.md")
    
    with open(local_settings, "w") as f:
        f.write('{"colorScheme": "dark"}')
    with open(local_agents, "w") as f:
        f.write("# Local AGENTS")
    with open(local_gemini_md, "w") as f:
        f.write("# Local GEMINI")
        
    os.makedirs(os.path.join(local_gemini, "antigravity", "skills", "test-skill"))
    with open(os.path.join(local_gemini, "antigravity", "skills", "test-skill", "SKILL.md"), "w") as f:
        f.write("test skill content")
        
    # Execute setup-global-harness.sh with mock envs
    import subprocess
    cmd = ["bash", "setup-global-harness.sh"]
    env = os.environ.copy()
    env["MOCK_HOME"] = mock_home
    env["MOCK_GDRIVE"] = mock_gdrive
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    
    assert result.returncode == 0, f"setup-global-harness.sh failed: {result.stderr}\nStdout: {result.stdout}"
    
    # Assert backup folder was created locally
    backups = [d for d in os.listdir(mock_home) if d.startswith(".gemini_backup_")]
    assert len(backups) == 1, "A backup of ~/.gemini should have been created"
    backup_path = os.path.join(mock_home, backups[0])
    assert os.path.isfile(os.path.join(backup_path, "AGENTS.md")), "AGENTS.md should be backed up"
    
    # Assert Google Drive folders were seeded
    gdrive_settings = os.path.join(mock_gdrive, "My Drive", "Settings", "antigravity-cli", "settings.json")
    gdrive_agents = os.path.join(mock_gdrive, "My Drive", "Settings", "antigravity", "AGENTS.md")
    gdrive_gemini = os.path.join(mock_gdrive, "My Drive", "Settings", "antigravity", "GEMINI.md")
    gdrive_skills = os.path.join(mock_gdrive, "My Drive", "Settings", "antigravity", "skills")
    
    assert os.path.isfile(gdrive_settings), "Settings should be seeded on Google Drive"
    assert os.path.isfile(gdrive_agents), "AGENTS.md should be seeded on Google Drive"
    assert os.path.isfile(gdrive_gemini), "GEMINI.md should be seeded on Google Drive"
    assert os.path.isdir(gdrive_skills), "skills/ should be seeded on Google Drive"
    assert os.path.isfile(os.path.join(gdrive_skills, "test-skill", "SKILL.md")), "Individual skills should be seeded on Google Drive"
    
    # Assert local ~/.gemini/ paths are now symlinks pointing to Google Drive
    assert os.path.islink(local_settings), "Local settings.json should be a symlink"
    assert os.path.islink(local_agents), "Local AGENTS.md should be a symlink"
    assert os.path.islink(local_gemini_md), "Local GEMINI.md should be a symlink"
    assert os.path.islink(os.path.join(local_gemini, "antigravity", "skills")), "Local skills/ should be a symlink"
    
    # Clean up
    for path in [mock_home, mock_gdrive]:
        if os.path.exists(path):
            shutil.rmtree(path)



