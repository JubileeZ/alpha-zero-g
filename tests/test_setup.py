import os
import json
import shutil
import subprocess
import pytest

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

def test_bash_setup_first_run(tmp_path):
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    mock_bin = create_mock_git(tmp_path)
    
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    env["PATH"] = f"{mock_bin}:{env.get('PATH', '')}"
    
    cli_dir = mock_home / ".gemini" / "antigravity-cli"
    cli_dir.mkdir(parents=True)
    settings_file = cli_dir / "settings.json"
    settings_file.write_text(json.dumps({"existing_key": "existing_val"}), encoding="utf-8")
    
    script_path = os.path.abspath("scripts/setup-device.sh")
    res = subprocess.run(["bash", script_path], capture_output=True, text=True, env=env, check=True)
    
    assert "Step 1:" in res.stdout
    assert "Step 9: Exit summary: 8/8 steps OK." in res.stdout
    
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    assert data["statusLine"]["command"] == "python3 ~/.agent-config/statusline.py"
    
    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "AGENTS.md")

def test_bash_setup_second_run_skip(tmp_path):
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    
    skills_dir = mock_home / ".agent-skills" / "mattpocock"
    skills_dir.mkdir(parents=True)
    for s in ["diagnose", "improve-codebase-architecture", "setup-matt-pocock-skills", "tdd", "to-issues", "to-prd", "zoom-out", "caveman", "handoff", "write-a-skill", "to-dfp", "execute-dfp"]:
        (skills_dir / s).mkdir()
        
    gemini_dir = mock_home / ".gemini"
    gemini_dir.mkdir(parents=True)
    for f in ["AGENTS.md", "GEMINI.md", "CLAUDE.md"]:
        (gemini_dir / f).write_text("existing content")
        
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    
    script_path = os.path.abspath("scripts/setup-device.sh")
    res = subprocess.run(["bash", script_path], input="n\nn\nn\n", capture_output=True, text=True, env=env, check=True)
    
    assert "Step 1: Clone mattpocock/skills to ~/.agent-skills/mattpocock/... SKIP" in res.stdout
    assert "Step 3: Deploy global AGENTS.md to ~/.gemini/AGENTS.md... SKIP" in res.stdout
    assert "Step 9: Exit summary: 4/8 steps OK." in res.stdout

def test_powershell_setup_if_available(tmp_path):
    pwsh = shutil.which("pwsh") or shutil.which("powershell")
    if not pwsh:
        pytest.skip("PowerShell (pwsh/powershell) not available")
        
    mock_home = tmp_path / "home"
    mock_home.mkdir()
    mock_bin = create_mock_git(tmp_path)
    
    env = os.environ.copy()
    env["HOME"] = str(mock_home)
    env["USERPROFILE"] = str(mock_home)
    env["PATH"] = f"{mock_bin}:{env.get('PATH', '')}"
    
    script_path = os.path.abspath("scripts/setup-device.ps1")
    res = subprocess.run([pwsh, "-File", script_path], capture_output=True, text=True, env=env, check=True)
    
    assert "Step 1:" in res.stdout
    assert "Step 9: Exit summary: 8/8 steps OK." in res.stdout
    
    settings_file = mock_home / ".gemini" / "antigravity-cli" / "settings.json"
    assert settings_file.exists()
    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    assert "%USERPROFILE%" in data["statusLine"]["command"]
