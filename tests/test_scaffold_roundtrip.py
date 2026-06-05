import os
import sys
import subprocess
from pathlib import Path
import pytest

def test_scaffold_python_roundtrip(tmp_path):
    """End-to-end integration test to scaffold a project, sync it, and run its tests."""
    project_dir = tmp_path / "roundtrip_project"
    script_path = Path("scripts/scaffold.py").resolve()

    res = subprocess.run(
        [sys.executable, str(script_path), "Roundtrip-Project", "python", str(project_dir)],
        capture_output=True,
        text=True
    )
    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"

    for root, _, files in os.walk(project_dir):
        if ".git" in root or ".pytest_cache" in root or "__pycache__" in root or ".venv" in root or ".ruff_cache" in root:
            continue
        for f in files:
            p = os.path.join(root, f)
            try:
                with open(p, "r", encoding="utf-8") as file:
                    content = file.read()
                    if "{{" in content or "}}" in content:
                        pytest.fail(f"Raw placeholder found in {p}")
            except UnicodeDecodeError:
                pass

    env = os.environ.copy()
    env.pop("VIRTUAL_ENV", None)

    sync_res = subprocess.run(
        ["uv", "sync"],
        cwd=str(project_dir),
        capture_output=True,
        text=True,
        env=env
    )
    assert sync_res.returncode == 0, f"uv sync failed: {sync_res.stderr}\nStdout: {sync_res.stdout}"

    pytest_res = subprocess.run(
        ["uv", "run", "pytest"],
        cwd=str(project_dir),
        capture_output=True,
        text=True,
        env=env
    )
    assert pytest_res.returncode == 0, f"uv run pytest failed: {pytest_res.stderr}\nStdout: {pytest_res.stdout}"
