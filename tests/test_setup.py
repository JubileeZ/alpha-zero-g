import os
import sys
import json
import shutil
import subprocess
import pytest
from pathlib import Path

def create_mock_git(tmp_path):
    git_dir = tmp_path / "mock_bin"
    git_dir.mkdir()
    git_script = git_dir / "git"
    
    # Simple mock git script (handles clone and pull)
    if sys.platform == "win32":
        # Windows batch file mock git
        git_script = git_dir / "git.bat"
        git_script.write_text("""@echo off
if "%1"=="clone" (
    mkdir "%~5"
    mkdir "%~5/skills/engineering"
    mkdir "%~5/skills/productivity"
    echo mock > "%~5/skills/engineering/SKILL.md"
    exit /b 0
)
if "%1"=="pull" (
    exit /b 0
)
exit /b 1
""")
    else:
        # Bash script mock git
        git_script.write_text("""#!/usr/bin/env bash
if [ "$1" = "clone" ]; then
    dest="${@: -1}"
    mkdir -p "$dest/skills/engineering"
    mkdir -p "$dest/skills/productivity"
    echo "mock" > "$dest/skills/engineering/SKILL.md"
    exit 0
fi
if [ "$1" = "pull" ]; then
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
    env["PATH"] = f"{mock_bin}{os.pathsep}{env.get('PATH', '')}"
    
    cli_dir = mock_home / ".gemini" / "antigravity-cli"
    cli_dir.mkdir(parents=True)
    settings_file = cli_dir / "settings.json"
    settings_file.write_text(json.dumps({"existing_key": "existing_val"}), encoding="utf-8")
    
    script_path = os.path.abspath("scripts/setup-device.py")
    res = subprocess.run([sys.executable, script_path], capture_output=True, text=True, env=env, check=True)
    
    assert "Step 1:" in res.stdout
    assert "Exit summary: 9/9 steps OK." in res.stdout or "Exit summary: 8/9 steps OK." in res.stdout
    
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    assert "statusline.py" in data["statusLine"]["command"]
    assert data["planningMode"] is True
    
    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "AGENTS.md")

def test_setup_second_run_skip(tmp_path):
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    
    # Pre-create skills
    skills_dir = mock_home / ".gemini" / "antigravity-cli" / "skills"
    skills_dir.mkdir(parents=True)
    
    gemini_dir = mock_home / ".gemini"
    gemini_dir.mkdir(parents=True, exist_ok=True)
    for f in ["AGENTS.md", "GEMINI.md", "CLAUDE.md"]:
        (gemini_dir / f).write_text("existing content", encoding="utf-8")
        
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    
    script_path = os.path.abspath("scripts/setup-device.py")
    # Simulate user entering 'n' to skip overwriting AGENTS.md, GEMINI.md, CLAUDE.md
    res = subprocess.run([sys.executable, script_path], input="n\nn\nn\n", capture_output=True, text=True, env=env, check=True)
    
    assert "Step 3:" in res.stdout
    assert "SKIP" in res.stdout