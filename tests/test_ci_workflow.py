import subprocess
import sys
from pathlib import Path

import pytest
import yaml


def test_scaffold_creates_valid_ci_workflow(tmp_path: Path) -> None:
    """Test that running scaffold.py creates .github/workflows/ci.yml as valid YAML."""
    project_dir = tmp_path / "my_test_project"
    scaffold_script = Path("scripts/scaffold.py").resolve()

    # Run the scaffold.py script directly using the current python executable
    res = subprocess.run(
        [
            sys.executable,
            str(scaffold_script),
            "my_test_project",
            "python",
            str(project_dir),
        ],
        capture_output=True,
        text=True,
    )

    assert res.returncode == 0, f"Scaffolder failed: {res.stderr}\nStdout: {res.stdout}"

    # Verify .github/workflows/ci.yml exists
    ci_file = project_dir / ".github" / "workflows" / "ci.yml"
    assert ci_file.is_file(), f"CI workflow file not found at {ci_file}"

    # Verify it's valid YAML
    with open(ci_file, "r", encoding="utf-8") as f:
        try:
            data = yaml.safe_load(f)
            assert data is not None
            assert isinstance(data, dict)
        except yaml.YAMLError as exc:
            pytest.fail(f"CI workflow is not valid YAML: {exc}")
