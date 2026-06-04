import os
import sys
import json
import shutil
import subprocess
import pytest

def create_mock_git(tmp_path):
    git_dir = tmp_path / "mock_bin"
    git_dir.mkdir()
    if sys.platform == "win32":
        git_script = git_dir / "git.bat"
        git_script.write_text(f"""@echo off
if "%~1" == "clone" (
    mkdir "%~3"
    for %%s in (diagnose improve-codebase-architecture tdd to-issues to-prd caveman handoff write-a-skill to-dfp execute-dfp) do (
        mkdir "%~3\\%%s"
        echo mock > "%~3\\%%s\\SKILL.md"
    )
    exit /b 0
)
exit /b 1
""")
    else:
        git_script = git_dir / "git"
        git_script.write_text("""#!/usr/bin/env bash
if [ "$1" = "clone" ]; then
    dest="${@: -1}"
    mkdir -p "$dest"
    for s in diagnose improve-codebase-architecture tdd to-issues to-prd caveman handoff write-a-skill to-dfp execute-dfp; do
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
    sep = ";" if sys.platform == "win32" else ":"
    env["PATH"] = f"{mock_bin}{sep}{env.get('PATH', '')}"
    
    cli_dir = mock_home / ".gemini" / "antigravity-cli"
    cli_dir.mkdir(parents=True)
    settings_file = cli_dir / "settings.json"
    settings_file.write_text(json.dumps({"existing_key": "existing_val"}), encoding="utf-8")
    
    script_path = os.path.abspath("scripts/setup-device.py")
    res = subprocess.run([sys.executable, script_path], input="y\ny\ny\n", capture_output=True, text=True, env=env)
    
    assert res.returncode == 0, f"Setup failed: {res.stderr}\nStdout: {res.stdout}"
    assert "Step 1:" in res.stdout
    assert "Exit summary:" in res.stdout
    
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    assert "statusline.py" in data["statusLine"]["command"]
    
    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "AGENTS.md")

def test_setup_second_run_skip(tmp_path):
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    
    skills_dir = mock_home / ".agent-skills" / "mattpocock"
    skills_dir.mkdir(parents=True)
    for s in ["diagnose", "improve-codebase-architecture", "tdd", "to-issues", "to-prd", "caveman", "handoff", "write-a-skill", "to-dfp", "execute-dfp"]:
        (skills_dir / s).mkdir()
        
    gemini_dir = mock_home / ".gemini"
    gemini_dir.mkdir(parents=True)
    for f in ["AGENTS.md", "GEMINI.md", "CLAUDE.md"]:
        (gemini_dir / f).write_text("existing content")
        
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    
    script_path = os.path.abspath("scripts/setup-device.py")
    res = subprocess.run([sys.executable, script_path], input="n\nn\nn\n", capture_output=True, text=True, env=env)
    
    assert "Step 1:" in res.stdout
