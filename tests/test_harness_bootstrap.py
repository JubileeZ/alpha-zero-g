import os
import shutil
import pytest

# Paths
TEMPLATES_DIR = "templates"
PYTHON_TEMPLATES = os.path.join(TEMPLATES_DIR, "python")
R_TEMPLATES = os.path.join(TEMPLATES_DIR, "r")
DOCS_TEMPLATES = os.path.join(TEMPLATES_DIR, "docs")

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
    """Verify that templates/AGENTS.md contains pointers to the workflow."""
    agents_path = os.path.join(TEMPLATES_DIR, "AGENTS.md")
    assert os.path.isfile(agents_path), "templates/AGENTS.md template should exist"
    
    with open(agents_path, "r", encoding="utf-8") as f:
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
    cmd = [get_bash_executable(), "create-project.sh", dest_dir, "Test-Python-Project", "python", "A testing python project description"]
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
    assert os.path.isfile(os.path.join(dest_dir, "docs", "adr", "OPEN_DECISIONS.md")), "OPEN_DECISIONS.md should exist"
    assert not os.path.isfile(os.path.join(dest_dir, "docs", "adr", "0001-dynamic-bootstrapping.md")), "Harness ADR 0001 should NOT be in downstream docs/adr/"
    assert not os.path.isfile(os.path.join(dest_dir, "docs", "adr", "0002-automated-project-scaffolder.md")), "Harness ADR 0002 should NOT be in downstream docs/adr/"
    assert os.path.isfile(os.path.join(dest_dir, "DEVELOPER_WORKFLOW.md")), "DEVELOPER_WORKFLOW.md should exist"

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

    # Assert Git initialization and baseline commit (Slice 4)
    assert os.path.isdir(os.path.join(dest_dir, ".git")), "Git repository should be initialized"
    git_log_res = subprocess.run(["git", "-C", dest_dir, "log", "-n", "1", "--oneline"], capture_output=True, text=True)
    assert "initial harness bootstrap" in git_log_res.stdout, f"Baseline commit should be created. Got: {git_log_res.stdout}"

    # Assert Trusted Workspace auto-registration (Slice 5)
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

def test_slice6_global_harness_sync():
    """Verify that setup-harness.sh can backup local configs, seed monorepo settings, and establish symlinks."""
    import tempfile
    if os.name == 'nt':
        # Use system temp directory (NTFS) to bypass Windows symlink limitations
        mock_home = os.path.join(tempfile.gettempdir(), f"mock_home_{os.getpid()}")
        mock_global_src = os.path.join(tempfile.gettempdir(), f"mock_global_src_{os.getpid()}")
    else:
        mock_home = os.path.abspath("scratch/mock_home")
        mock_global_src = os.path.abspath("scratch/mock_global_src")
    
    # Cleanup previous runs
    for path in [mock_home, mock_global_src]:
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
    
    with open(local_settings, "w", encoding="utf-8") as f:
        f.write('{"colorScheme": "dark"}')
    with open(local_agents, "w", encoding="utf-8") as f:
        f.write("# Local AGENTS")
    with open(local_gemini_md, "w", encoding="utf-8") as f:
        f.write("# Local GEMINI")
        
    os.makedirs(os.path.join(local_gemini, "antigravity", "skills", "test-skill"))
    with open(os.path.join(local_gemini, "antigravity", "skills", "test-skill", "SKILL.md"), "w", encoding="utf-8") as f:
        f.write("test skill content")
        
    # Seed templates in the mock monorepo global folder
    os.makedirs(os.path.join(mock_global_src, "config"))
    os.makedirs(os.path.join(mock_global_src, "skills"))
    shutil.copy2("global/settings.json.example", os.path.join(mock_global_src, "settings.json.example"))
    shutil.copy2("global/config/config.json.example", os.path.join(mock_global_src, "config", "config.json.example"))
    shutil.copy2("global/config/mcp_config.json.example", os.path.join(mock_global_src, "config", "mcp_config.json.example"))
    shutil.copy2("global/AGENTS.md", os.path.join(mock_global_src, "AGENTS.md"))
    shutil.copy2("global/GEMINI.md", os.path.join(mock_global_src, "GEMINI.md"))
    
    # Execute setup-harness.sh with mock envs
    import subprocess
    cmd = [get_bash_executable(), "setup-harness.sh"]
    env = os.environ.copy()
    env["MOCK_HOME"] = mock_home
    env["MOCK_GLOBAL_SRC"] = mock_global_src
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    
    assert result.returncode == 0, f"setup-harness.sh failed: {result.stderr}\nStdout: {result.stdout}"
    
    # Assert backup folder was created locally
    backups = [d for d in os.listdir(mock_home) if d.startswith(".gemini_backup_")]
    assert len(backups) == 1, "A backup of ~/.gemini should have been created"
    backup_path = os.path.join(mock_home, backups[0])
    assert os.path.isfile(os.path.join(backup_path, "AGENTS.md")), "AGENTS.md should be backed up"
    
    # Assert monorepo configs were seeded from templates
    repo_settings = os.path.join(mock_global_src, "settings.json")
    repo_config = os.path.join(mock_global_src, "config", "config.json")
    repo_mcp = os.path.join(mock_global_src, "config", "mcp_config.json")
    repo_skills = os.path.join(mock_global_src, "skills")
    
    assert os.path.isfile(repo_settings), "settings.json should be seeded from templates"
    assert os.path.isfile(repo_config), "config.json should be seeded from templates"
    assert os.path.isfile(repo_mcp), "mcp_config.json should be seeded from templates"
    assert os.path.isdir(repo_skills), "skills/ should exist"
    assert os.path.isfile(os.path.join(repo_skills, "test-skill", "SKILL.md")), "Individual skills should be imported to monorepo"
    
    # Assert local ~/.gemini/ paths are now symlinks pointing to the monorepo global directory
    assert os.path.islink(local_settings), "Local settings.json should be a symlink"
    assert os.path.islink(local_agents), "Local AGENTS.md should be a symlink"
    assert os.path.islink(local_gemini_md), "Local GEMINI.md should be a symlink"
    assert os.path.islink(os.path.join(local_gemini, "antigravity", "skills")), "Local skills/ should be a symlink"
    
    # Clean up
    for path in [mock_home, mock_global_src]:
        if os.path.exists(path):
            shutil.rmtree(path)


def test_harness_upgrader():
    """Verify that upgrade-project.sh can push core changes to downstream, pull downstream updates back to templates, and correctly handle parameter placeholders in AGENTS.md / DEVELOPER_WORKFLOW.md."""
    import subprocess
    
    # 1. Scaffolder creation of dummy downstream
    dest_dir = "scratch/test-upgrade-target"
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
        
    cmd = [get_bash_executable(), "create-project.sh", dest_dir, "Test-Upgrade-Project", "python", "Upgrade testing project"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0
    
    # Backup original core files we are going to modify during testing
    core_init_sh = "templates/init.sh"
    core_init_sh_backup = "templates/init.sh.bak"
    shutil.copy2(core_init_sh, core_init_sh_backup)
    
    core_agents_md = "templates/AGENTS.md"
    core_agents_md_backup = "templates/AGENTS.md.bak"
    shutil.copy2(core_agents_md, core_agents_md_backup)
    
    try:
        # A. TEST --push (Template -> Downstream)
        # Modify the core template
        with open(core_init_sh, "a", encoding="utf-8") as f:
            f.write("\n# core testing modification\n")
            
        # Run upgrade-project.sh in push mode
        upgrade_cmd = [get_bash_executable(), "upgrade-project.sh", "--push", "-y", dest_dir]
        res_push = subprocess.run(upgrade_cmd, capture_output=True, text=True)
        assert res_push.returncode == 0, f"Push failed: {res_push.stderr}\nStdout: {res_push.stdout}"
        
        # Verify target is updated
        with open(os.path.join(dest_dir, "init.sh"), "r", encoding="utf-8") as f:
            target_content = f.read()
        assert "core testing modification" in target_content, "Push mode did not update downstream target file"
        
        # B. TEST --pull (Downstream -> Template)
        # Modify the downstream target
        with open(os.path.join(dest_dir, "init.sh"), "a", encoding="utf-8") as f:
            f.write("\n# downstream testing optimization\n")
            
        # Run upgrade-project.sh in pull mode
        pull_cmd = [get_bash_executable(), "upgrade-project.sh", "--pull", "-y", dest_dir]
        res_pull = subprocess.run(pull_cmd, capture_output=True, text=True)
        assert res_pull.returncode == 0, f"Pull failed: {res_pull.stderr}\nStdout: {res_pull.stdout}"
        
        # Verify template is updated with the downstream modification
        with open(core_init_sh, "r", encoding="utf-8") as f:
            template_content = f.read()
        assert "downstream testing optimization" in template_content, "Pull mode did not update core template file"
        
        # C. TEST PLACEHOLDERS IN --push and --pull
        # Modify the template file with placeholders
        with open(core_agents_md, "a", encoding="utf-8") as f:
            f.write("\n# new guideline for {{PROJECT_NAME}}\n")
            
        # Push to downstream
        res_push_placeholder = subprocess.run([get_bash_executable(), "upgrade-project.sh", "--push", "-y", dest_dir], capture_output=True, text=True)
        assert res_push_placeholder.returncode == 0, f"Push placeholder failed: {res_push_placeholder.stderr}"
        
        # Assert downstream file resolved the placeholder
        with open(os.path.join(dest_dir, "AGENTS.md"), "r", encoding="utf-8") as f:
            target_agents_content = f.read()
        assert "new guideline for Test-Upgrade-Project" in target_agents_content, "Pushing placeholder file did not resolve parameters"
        assert "{{PROJECT_NAME}}" not in target_agents_content, "Pushing placeholder file left raw placeholder in target"
        
        # Modify downstream to optimize the new guidelines
        updated_agents = target_agents_content.replace("new guideline for Test-Upgrade-Project", "optimal rule for Test-Upgrade-Project")
        with open(os.path.join(dest_dir, "AGENTS.md"), "w", encoding="utf-8") as f:
            f.write(updated_agents)
            
        # Pull back to templates
        res_pull_placeholder = subprocess.run([get_bash_executable(), "upgrade-project.sh", "--pull", "-y", dest_dir], capture_output=True, text=True)
        assert res_pull_placeholder.returncode == 0, f"Pull placeholder failed: {res_pull_placeholder.stderr}\nStdout: {res_pull_placeholder.stdout}"
        
        # Assert template file pulled the optimization and RESTORED the placeholder
        with open(core_agents_md, "r", encoding="utf-8") as f:
            template_agents_content = f.read()
        assert "optimal rule for {{PROJECT_NAME}}" in template_agents_content, "Pulling optimized file did not restore the placeholder in templates"
        assert "Test-Upgrade-Project" not in template_agents_content, "Pulling optimized file leaked target project name into templates"
        
    finally:
        # Restore backups
        if os.path.exists(core_init_sh_backup):
            shutil.move(core_init_sh_backup, core_init_sh)
        if os.path.exists(core_agents_md_backup):
            shutil.move(core_agents_md_backup, core_agents_md)
            
        # Clean up target
        if os.path.exists(dest_dir):
            shutil.rmtree(dest_dir)


def test_slice6_global_harness_sync_windows_preflight_success():
    """Verify that setup-harness.sh behaves correctly on Windows when the pre-flight check confirms Developer Mode is active (no elevation needed)."""
    import tempfile
    import subprocess
    
    mock_home = os.path.join(tempfile.gettempdir(), f"mock_home_pref_succ_{os.getpid()}")
    mock_global_src = os.path.join(tempfile.gettempdir(), f"mock_global_src_pref_succ_{os.getpid()}")
    
    # Cleanup previous runs
    for path in [mock_home, mock_global_src]:
        if os.path.exists(path):
            shutil.rmtree(path)
            
    # Setup initial local home structure
    local_gemini = os.path.join(mock_home, ".gemini")
    os.makedirs(os.path.join(local_gemini, "antigravity-cli"))
    os.makedirs(os.path.join(local_gemini, "antigravity"))
    
    # Write initial settings.json to seed
    local_settings = os.path.join(local_gemini, "antigravity-cli", "settings.json")
    with open(local_settings, "w", encoding="utf-8") as f:
        f.write('{"colorScheme": "dark"}')
        
    # Seed templates in mock monorepo global
    os.makedirs(os.path.join(mock_global_src, "config"))
    os.makedirs(os.path.join(mock_global_src, "skills"))
    shutil.copy2("global/settings.json.example", os.path.join(mock_global_src, "settings.json.example"))
    shutil.copy2("global/config/config.json.example", os.path.join(mock_global_src, "config", "config.json.example"))
    shutil.copy2("global/config/mcp_config.json.example", os.path.join(mock_global_src, "config", "mcp_config.json.example"))
    shutil.copy2("global/AGENTS.md", os.path.join(mock_global_src, "AGENTS.md"))
    shutil.copy2("global/GEMINI.md", os.path.join(mock_global_src, "GEMINI.md"))
    
    cmd = [get_bash_executable(), "setup-harness.sh"]
    env = os.environ.copy()
    env["MOCK_HOME"] = mock_home
    env["MOCK_GLOBAL_SRC"] = mock_global_src
    # Mock pre-flight symlink capability to return success directly
    env["MOCK_SYMLINK_CAPABILITY"] = "true"
    
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    assert result.returncode == 0, f"Sync script failed: {result.stderr}\nStdout: {result.stdout}"
    
    # Verify symlink is successfully established (meaning the pre-flight success pathway successfully completed)
    assert os.path.islink(local_settings), "Local settings.json should be a symlink in the pre-flight success path"
    
    # Clean up
    for path in [mock_home, mock_global_src]:
        if os.path.exists(path):
            shutil.rmtree(path)


def test_slice6_global_harness_sync_windows_preflight_fail_elevated_success():
    """Verify that setup-harness.sh behaves correctly on Windows when the pre-flight check fails but elevation is mock-accepted and successfully creates symlinks."""
    import tempfile
    import subprocess
    
    mock_home = os.path.join(tempfile.gettempdir(), f"mock_home_pref_fail_{os.getpid()}")
    mock_global_src = os.path.join(tempfile.gettempdir(), f"mock_global_src_pref_fail_{os.getpid()}")
    
    # Cleanup previous runs
    for path in [mock_home, mock_global_src]:
        if os.path.exists(path):
            shutil.rmtree(path)
            
    # Setup initial local home structure
    local_gemini = os.path.join(mock_home, ".gemini")
    os.makedirs(os.path.join(local_gemini, "antigravity-cli"))
    os.makedirs(os.path.join(local_gemini, "antigravity"))
    
    # Write initial settings.json to seed
    local_settings = os.path.join(local_gemini, "antigravity-cli", "settings.json")
    with open(local_settings, "w", encoding="utf-8") as f:
        f.write('{"colorScheme": "dark"}')
        
    # Seed templates in mock monorepo global
    os.makedirs(os.path.join(mock_global_src, "config"))
    os.makedirs(os.path.join(mock_global_src, "skills"))
    shutil.copy2("global/settings.json.example", os.path.join(mock_global_src, "settings.json.example"))
    shutil.copy2("global/config/config.json.example", os.path.join(mock_global_src, "config", "config.json.example"))
    shutil.copy2("global/config/mcp_config.json.example", os.path.join(mock_global_src, "config", "mcp_config.json.example"))
    shutil.copy2("global/AGENTS.md", os.path.join(mock_global_src, "AGENTS.md"))
    shutil.copy2("global/GEMINI.md", os.path.join(mock_global_src, "GEMINI.md"))
    
    cmd = [get_bash_executable(), "setup-harness.sh"]
    env = os.environ.copy()
    env["MOCK_HOME"] = mock_home
    env["MOCK_GLOBAL_SRC"] = mock_global_src
    # Mock pre-flight symlink capability to fail (simulating no Developer Mode / no admin)
    env["MOCK_SYMLINK_CAPABILITY"] = "false"
    # Mock elevation to run direct non-admin batch for testing
    env["MOCK_ELEVATION_MOCK"] = "true"
    
    result = subprocess.run(cmd, capture_output=True, text=True, env=env)
    
    # Since mock elevation runs on NTFS temp directory base, the batch script should successfully create the symlinks!
    assert result.returncode == 0, f"Sync script failed: {result.stderr}\nStdout: {result.stdout}"
    assert os.path.islink(local_settings), "Local settings.json should be successfully created via the elevated mock path"
    
    # Clean up
    for path in [mock_home, mock_global_src]:
        if os.path.exists(path):
            shutil.rmtree(path)




