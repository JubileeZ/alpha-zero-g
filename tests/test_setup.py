import os
import sys
import json
import shutil
import subprocess
import pytest

def create_mock_git(tmp_path):
    git_dir = tmp_path / "mock_bin"
    git_dir.mkdir(exist_ok=True)
    
    # Unix bash mock
    git_script = git_dir / "git"
    git_script.write_text(r"""#!/usr/bin/env bash
if [ "$1" = "clone" ] || [ "$1" = "pull" ]; then
    # find the last argument as destination
    dest="${@: -1}"
    if [ "$1" = "clone" ]; then
        mkdir -p "$dest"
    else
        dest="."
    fi
    for s in diagnose improve-codebase-architecture setup-matt-pocock-skills tdd to-issues to-prd zoom-out caveman handoff write-a-skill to-dfp execute-dfp; do
        mkdir -p "$dest/skills/engineering/$s"
        echo "mock" > "$dest/skills/engineering/$s/SKILL.md"
    done
    exit 0
fi
exit 1
""")
    git_script.chmod(0o755)
    
    # Windows bat mock
    git_bat = git_dir / "git.bat"
    git_bat.write_text(r"""@echo off
if "%1" == "clone" (
    setlocal enabledelayedexpansion
    set "last="
    for %%x in (%*) do set "last=%%x"
    mkdir "!last!"
    for %%s in (diagnose improve-codebase-architecture setup-matt-pocock-skills tdd to-issues to-prd zoom-out caveman handoff write-a-skill to-dfp execute-dfp) do (
        mkdir "!last!\skills\engineering\%%s"
        echo mock > "!last!\skills\engineering\%%s\SKILL.md"
    )
    exit /b 0
)
if "%1" == "pull" (
    for %%s in (diagnose improve-codebase-architecture setup-matt-pocock-skills tdd to-issues to-prd zoom-out caveman handoff write-a-skill to-dfp execute-dfp) do (
        mkdir "skills\engineering\%%s" 2>nul
        echo mock > "skills\engineering\%%s\SKILL.md"
    )
    exit /b 0
)
exit /b 1
""")
    
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
    assert "Exit summary:" in res.stdout
    
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    
    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "AGENTS.md")

def test_setup_second_run_skip(tmp_path):
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    
    skills_dir = mock_home / ".agent-skills" / "mattpocock"
    skills_dir.mkdir(parents=True)
    for s in ["diagnose", "improve-codebase-architecture", "setup-matt-pocock-skills", "tdd", "to-issues", "to-prd", "zoom-out", "caveman", "handoff", "write-a-skill", "to-dfp", "execute-dfp"]:
        (skills_dir / "skills" / "engineering" / s).mkdir(parents=True, exist_ok=True)
        
    gemini_dir = mock_home / ".gemini"
    gemini_dir.mkdir(parents=True)
    for f in ["AGENTS.md", "GEMINI.md", "CLAUDE.md"]:
        (gemini_dir / f).write_text("existing content")
        
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    
    script_path = os.path.abspath("scripts/setup-device.py")
    res = subprocess.run([sys.executable, script_path], input="n\nn\nn\n", capture_output=True, text=True, env=env, check=True)
    
    assert "Step 1:" in res.stdout
    assert "Exit summary:" in res.stdout