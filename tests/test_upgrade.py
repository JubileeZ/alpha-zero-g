import os
import sys
import shutil
import subprocess
import tempfile
import pytest

# Paths
UPGRADE_PY = os.path.abspath(os.path.join(os.path.dirname(__file__), "../scripts/upgrade-project.py"))
TEMPLATES_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../templates/project"))

@pytest.fixture
def upgrade_cmd():
    return [sys.executable, UPGRADE_PY]

@pytest.fixture
def temp_project():
    """Create a temporary directory simulating a legacy project."""
    temp_dir = tempfile.mkdtemp()
    yield temp_dir
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)

def test_upgrade_fails_outside_valid_project(temp_project, upgrade_cmd):
    """Ensure upgrade script fails when not inside a valid git/AGENTS.md repo."""
    res = subprocess.run(upgrade_cmd, cwd=temp_project, capture_output=True, text=True)
    assert res.returncode != 0
    assert "not inside a valid project" in res.stderr.lower() or "error" in res.stderr.lower()

def test_upgrade_dry_run(temp_project, upgrade_cmd):
    """Ensure --dry-run prints audit and makes no changes."""
    agents_path = os.path.join(temp_project, "AGENTS.md")
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: Legacy\n\nSome custom instructions.\n")
    
    res = subprocess.run(upgrade_cmd + ["--dry-run"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0
    assert "missing" in res.stdout.lower() or "present" in res.stdout.lower()
    
    contents = os.listdir(temp_project)
    assert contents == ["AGENTS.md"]

def test_upgrade_real_run_and_adr_generation(temp_project, upgrade_cmd):
    """Ensure a real upgrade creates folders/files, appends to AGENTS.md, and generates ADR."""
    agents_path = os.path.join(temp_project, "AGENTS.md")
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: TestProj\n\nExisting content.\n")
        
    docs_adr_dir = os.path.join(temp_project, "docs", "adr")
    os.makedirs(docs_adr_dir)
    with open(os.path.join(docs_adr_dir, "ADR-001-init.md"), "w", encoding="utf-8") as f:
        f.write("ADR-001")
        
    res = subprocess.run(upgrade_cmd + ["--yes"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0
    
    assert os.path.isdir(os.path.join(temp_project, ".agents", "rules"))
    assert os.path.isdir(os.path.join(temp_project, "docs", "research"))
    assert os.path.isdir(os.path.join(temp_project, "data", "raw"))
    
    assert os.path.isfile(os.path.join(temp_project, "GEMINI.md"))
    assert os.path.isfile(os.path.join(temp_project, "CLAUDE.md"))
    assert os.path.isfile(os.path.join(temp_project, ".agents", "rules", "code-style.md"))
    assert os.path.isfile(os.path.join(temp_project, ".agents", "rules", "safety.md"))
    assert os.path.isfile(os.path.join(temp_project, ".gitignore"))
    assert os.path.isfile(os.path.join(temp_project, ".skillsrc"))
    assert os.path.isfile(os.path.join(temp_project, "README.md"))
    
    with open(agents_path, "r", encoding="utf-8") as f:
        content = f.read()
    assert "Existing content." in content
    assert "## Alpha-Zero-G" in content
    assert "Deterministic Python" in content
    
    adr2_path = os.path.join(docs_adr_dir, "ADR-002-alpha-zero-g-upgrade.md")
    assert os.path.isfile(adr2_path)
    with open(adr2_path, "r", encoding="utf-8") as f:
        adr_content = f.read()
    assert "ADR-002" in adr_content
    assert "Alpha-Zero-G Upgrade" in adr_content

def test_upgrade_does_not_duplicate_agents_block(temp_project, upgrade_cmd):
    """Ensure we do not append the block again if it already exists."""
    agents_path = os.path.join(temp_project, "AGENTS.md")
    block = "\n## Alpha-Zero-G\n- **Deterministic Python**"
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: TestProj\n" + block)
        
    res = subprocess.run(upgrade_cmd + ["--yes"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0
    
    with open(agents_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    assert content.count("## Alpha-Zero-G") == 1

def test_upgrade_deploys_hooks_json(temp_project, upgrade_cmd):
    """Ensure the upgrade script deploys .agents/hooks.json if it is missing."""
    agents_path = os.path.join(temp_project, "AGENTS.md")
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: TestProj\n\nExisting content.\n")
        
    res = subprocess.run(upgrade_cmd + ["--yes"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0
    
    hooks_file = os.path.join(temp_project, ".agents", "hooks.json")
    assert os.path.isfile(hooks_file), ".agents/hooks.json was not deployed during upgrade"