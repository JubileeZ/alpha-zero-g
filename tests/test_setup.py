import os
import sys
import json
import shutil
import subprocess
import pytest

SETUP_PY = os.path.abspath(os.path.join(os.path.dirname(__file__), "../scripts/setup-device.py"))

def create_mock_git(tmp_path):
    git_dir = tmp_path / "mock_bin"
    git_dir.mkdir()
    
    # Write bash script
    git_script = git_dir / "git"
    git_script.write_text("""#!/usr/bin/env bash
if [ "$1" = "clone" ]; then
    dest="${@: -1}"
    mkdir -p "$dest/skills/engineering"
    mkdir -p "$dest/skills/productivity"
    for s in diagnose improve-codebase-architecture setup-matt-pocock-skills tdd; do
        mkdir -p "$dest/skills/engineering/$s"
        echo "mock" > "$dest/skills/engineering/$s/SKILL.md"
    done
    for s in to-issues to-prd zoom-out caveman handoff write-a-skill to-dfp execute-dfp; do
        mkdir -p "$dest/skills/productivity/$s"
        echo "mock" > "$dest/skills/productivity/$s/SKILL.md"
    done
    exit 0
fi
if [ "$1" = "pull" ]; then
    exit 0
fi
exit 1
""")
    git_script.chmod(0o755)
    
    # Write Windows batch script
    git_bat = git_dir / "git.bat"
    git_bat.write_text(r"""@echo off
if "%1" == "clone" (
    set "dest="
    for %%a in (%*) do set "dest=%%a"
    mkdir "%dest%\skills\engineering" 2>nul
    mkdir "%dest%\skills\productivity" 2>nul
    for %%s in (diagnose improve-codebase-architecture setup-matt-pocock-skills tdd) do (
        mkdir "%dest%\skills\engineering\%%s" 2>nul
        echo mock > "%dest%\skills\engineering\%%s\SKILL.md"
    )
    for %%s in (to-issues to-prd zoom-out caveman handoff write-a-skill to-dfp execute-dfp) do (
        mkdir "%dest%\skills\productivity\%%s" 2>nul
        echo mock > "%dest%\skills\productivity\%%s\SKILL.md"
    )
    exit /b 0
fi
if "%1" == "pull" (
    exit /b 0
)
exit /b 1
""")
    
    return str(git_dir)

def test_python_setup_first_run(tmp_path):
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
    
    res = subprocess.run([sys.executable, SETUP_PY], capture_output=True, text=True, env=env, check=True)
    
    assert "Step 1:" in res.stdout
    assert "Exit summary:" in res.stdout
    
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    
    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "antigravity-cli" / "skills" / "diagnose" / "SKILL.md")
