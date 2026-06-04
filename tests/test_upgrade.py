import os
import sys
import shutil
import subprocess
import tempfile
import pytest

UPGRADE_PY = os.path.abspath(os.path.join(os.path.dirname(__file__), "../scripts/upgrade-project.py"))

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
    # temp_project has neither .git nor AGENTS.md
    res = subprocess.run(upgrade_cmd, cwd=temp_project, capture_output=True, text=True)
    assert res.returncode != 0
    assert "not inside a valid project" in res.stderr.lower() or "error" in res.stderr.lower()

def test_upgrade_dry_run(temp_project, upgrade_cmd):
    """Ensure --dry-run prints audit and makes no changes."""
    # Make it a valid project by creating AGENTS.md
    agents_path = os.path.join(temp_project, "AGENTS.md")
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: Legacy\n\nSome custom instructions.\n")
    
    # Run with --dry-run
    res = subprocess.run(upgrade_cmd + ["--dry-run"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0
    assert "missing" in res.stdout.lower() or "exists" in res.stdout.lower()
    
    # Verify no files/folders were created besides our original AGENTS.md
    contents = os.listdir(temp_project)
    assert contents == ["AGENTS.md"]

def test_upgrade_real_run_and_adr_generation(temp_project, upgrade_cmd):
    """Ensure a real upgrade creates folders/files, appends to AGENTS.md, and generates ADR."""
    # Make it a valid project
    agents_path = os.path.join(temp_project, "AGENTS.md")
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: TestProj\n\nExisting content.\n")
        
    # Let's create an existing ADR so we verify next free index scanning
    docs_adr_dir = os.path.join(temp_project, "docs", "adr")
    os.makedirs(docs_adr_dir)
    with open(os.path.join(docs_adr_dir, "ADR-001-init.md"), "w", encoding="utf-8") as f:
        f.write("ADR-001")
        
    # Run upgrade (non-interactive using --yes)
    res = subprocess.run(upgrade_cmd + ["--yes"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0, f"Upgrade failed: {res.stderr}\nStdout: {res.stdout}"
    
    # Check that directories were created
    assert os.path.isdir(os.path.join(temp_project, ".agents", "rules"))
    assert os.path.isdir(os.path.join(temp_project, "docs", "research"))
    assert os.path.isdir(os.path.join(temp_project, "data", "raw"))
    
    # Check that files were created
    assert os.path.isfile(os.path.join(temp_project, "GEMINI.md"))
    assert os.path.isfile(os.path.join(temp_project, "CLAUDE.md"))
    assert os.path.isfile(os.path.join(temp_project, ".agents", "rules", "code-style.md"))
    assert os.path.isfile(os.path.join(temp_project, ".agents", "rules", "safety.md"))
    assert os.path.isfile(os.path.join(temp_project, ".gitignore"))
    assert os.path.isfile(os.path.join(temp_project, ".agents", "hooks.json"))
    assert os.path.isfile(os.path.join(temp_project, ".skillsrc"))
    assert os.path.isfile(os.path.join(temp_project, "README.md"))
    
    # Check AGENTS.md was appended, not overwritten
    with open(agents_path, "r", encoding="utf-8") as f:
        content = f.read()
    assert "Existing content." in content
    assert "## Alpha-Zero-G" in content
    assert "Deterministic Python" in content
    
    # Check next ADR was generated (should be ADR-002)
    adr2_path = os.path.join(docs_adr_dir, "ADR-002-alpha-zero-g-upgrade.md")
    assert os.path.isfile(adr2_path)
    with open(adr2_path, "r", encoding="utf-8") as f:
        adr_content = f.read()
    assert "ADR-002" in adr_content
    assert "Alpha-Zero-G Upgrade" in adr_content

def test_upgrade_does_not_duplicate_agents_block(temp_project, upgrade_cmd):
    """Ensure we do not append the block again if it already exists."""
    agents_path = os.path.join(temp_project, "AGENTS.md")
    block = "\n\n## Alpha-Zero-G\n- **Deterministic Python**: Always execute via `uv run` (`uv run pytest`, `uv run python`).\n- **No Symlink Portability**: All project rules are physical copies and use relative links.\n- **Explicit Typings**: Require strict type hints in Python."
    with open(agents_path, "w", encoding="utf-8") as f:
        f.write("# Project: TestProj\n" + block)
        
    res = subprocess.run(upgrade_cmd + ["--yes"], cwd=temp_project, capture_output=True, text=True)
    assert res.returncode == 0
    
    with open(agents_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Ensure block only appears once
    assert content.count("## Alpha-Zero-G") == 1