import os
from pathlib import Path

def test_skillsrc_template_exists() -> None:
    """Validate templates/project/skillsrc.template exists."""
    template_path = Path("templates/project/skillsrc.template")
    assert template_path.exists(), "templates/project/skillsrc.template does not exist"
