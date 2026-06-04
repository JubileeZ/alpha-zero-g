import os
import json
import shutil
import subprocess
import pytest
import sys

def create_mock_git(tmp_path):
    git_dir = tmp_path / "mock_bin"
    git_dir.mkdir()
    git_script = git_dir / "git"
    git_script.write_text("""#!/usr/bin/env bash
if [ "$1" = "clone" ]; then
    dest="${@: -1}"
    mkdir -p "$dest"
    for s in diagnose improve-codebase-architecture setup-matt-pocock-skills tdd to-issues to-prd zoom-out caveman handoff write-a-skill to-dfp execute-dfp; do
        mkdir -p "$dest/$s"
        echo "mock" > "$dest/$s/SKILL.md"
    done
    exit 0
fi
exit 1
""")
    git_script.chmod(0o755)
    return str(git_dir)

def test_setup_first_run(tmp_path):
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    mock_bin = create_mock_git(tmp_path)
    
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    env["PATH"] = f"{mock_bin}:{env.get('PATH', '')}"
    
    # Pre-create settings directory
    cli_dir = mock_home / ".gemini" / "antigravity-cli"
    cli_dir.mkdir(parents=True)
    settings_file = cli_dir / "settings.json"
    settings_file.write_text(json.dumps({"existing_key": "existing_val"}), encoding="utf-8")
    
    script_path = os.path.abspath("scripts/setup-device.py")
    # Set target skills directory mock so we don't try to clone from Github
    # Create the git directory so git clone mocks can run
    os.makedirs(mock_home / ".agent-skills" / "mattpocock", exist_ok=True)
    
    res = subprocess.run([sys.executable, script_path], input="y\ny\ny\n", capture_output=True, text=True, env=env)
    
    assert "Step 1:" in res.stdout
    # settings patch assertions
    assert settings_file.exists()
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    
    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "AGENTS.md")
