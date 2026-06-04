import os
import sys
import json
import shutil
import pytest
from pathlib import Path
import subprocess
import importlib.util

# Load setup-device.py dynamically as a module
script_path = Path(__file__).parent.parent / "scripts" / "setup-device.py"
spec = importlib.util.spec_from_file_location("setup_device", str(script_path))
setup_device = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup_device)
main = setup_device.main

def test_setup_device(tmp_path, monkeypatch, capsys):
    mock_home = tmp_path / "home"
    mock_home.mkdir()

    monkeypatch.setattr(Path, "home", lambda: mock_home)

    class MockCompletedProcess:
        returncode = 0
        stdout = "ADDED"
        stderr = ""

    def mock_run(args, **kwargs):
        target_skills_dir = mock_home / ".agent-skills" / "mattpocock"
        (target_skills_dir / "skills" / "engineering").mkdir(parents=True, exist_ok=True)
        (target_skills_dir / "skills" / "productivity").mkdir(parents=True, exist_ok=True)
        (target_skills_dir / "skills" / "engineering" / "test-skill").mkdir(exist_ok=True)
        (target_skills_dir / "skills" / "engineering" / "test-skill" / "SKILL.md").write_text("mock", encoding="utf-8")
        return MockCompletedProcess()

    monkeypatch.setattr(subprocess, "run", mock_run)
    monkeypatch.setattr(sys, "auto_confirm", True, raising=False)

    # Pre-create settings directory
    cli_dir = mock_home / ".gemini" / "antigravity-cli"
    cli_dir.mkdir(parents=True)
    settings_file = cli_dir / "settings.json"
    settings_file.write_text(json.dumps({"existing_key": "existing_val"}), encoding="utf-8")

    main()

    captured = capsys.readouterr()
    assert "Step 1:" in captured.out
    assert "Exit summary:" in captured.out

    with open(settings_file, "r", encoding="utf-8") as f:
        data = json.load(f)
    assert data["existing_key"] == "existing_val"
    assert data["statusLine"]["type"] == "custom"
    assert data["statusLine"]["enabled"] is True
    assert data["planningMode"] is True

    assert os.path.exists(mock_home / ".agent-config" / "statusline.py")
    assert os.path.exists(mock_home / ".gemini" / "AGENTS.md")


def test_setup_second_run_skip(tmp_path, monkeypatch, capsys):
    mock_home = tmp_path / "home"
    mock_home.mkdir()

    monkeypatch.setattr(Path, "home", lambda: mock_home)
    monkeypatch.setattr(sys, "auto_confirm", False, raising=False)

    skills_dir = mock_home / ".agent-skills" / "mattpocock"
    skills_dir.mkdir(parents=True)
    for s in ["diagnose", "improve-codebase-architecture", "tdd", "to-issues", "to-prd", "caveman", "handoff", "write-a-skill", "to-dfp", "execute-dfp"]:
        (skills_dir / "skills" / "engineering" / s).mkdir(parents=True, exist_ok=True)

    gemini_dir = mock_home / ".gemini"
    gemini_dir.mkdir(parents=True, exist_ok=True)
    for f in ["AGENTS.md", "GEMINI.md", "CLAUDE.md"]:
        (gemini_dir / f).write_text("existing content", encoding="utf-8")

    inputs = ["n", "n", "n"]
    input_iter = iter(inputs)
    monkeypatch.setattr("builtins.input", lambda prompt="": next(input_iter))

    class MockCompletedProcess:
        returncode = 0
        stdout = ""
        stderr = ""

    monkeypatch.setattr(subprocess, "run", lambda *a, **kw: MockCompletedProcess())

    main()

    captured = capsys.readouterr()
    assert "Step 1:" in captured.out
    assert "Exit summary:" in captured.out
