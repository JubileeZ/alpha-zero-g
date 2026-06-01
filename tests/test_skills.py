import os
from pathlib import Path

def test_skills_manifest_exists_and_valid() -> None:
    """Validate templates/skills_manifest.txt exists and has exactly the 10 skills."""
    manifest_path = Path("templates/skills_manifest.txt")
    assert manifest_path.exists(), "templates/skills_manifest.txt does not exist"
    
    expected_skills = [
        "diagnose",
        "improve-codebase-architecture",
        "setup-matt-pocock-skills",
        "tdd",
        "to-issues",
        "to-prd",
        "zoom-out",
        "caveman",
        "handoff",
        "write-a-skill"
    ]
    
    with open(manifest_path, "r", encoding="utf-8") as f:
        skills = [line.strip() for line in f if line.strip() and not line.strip().startswith("#")]
        
    assert sorted(skills) == sorted(expected_skills), f"Manifest skills {skills} do not match expected {expected_skills}"

def test_skillsrc_template_exists() -> None:
    """Validate templates/project/skillsrc.template exists."""
    template_path = Path("templates/project/skillsrc.template")
    assert template_path.exists(), "templates/project/skillsrc.template does not exist"
