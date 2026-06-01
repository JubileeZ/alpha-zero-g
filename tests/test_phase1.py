import os
import pytest

# Constants for deleted files
DELETED_FILES = [
    "create-project.sh",
    "init.sh",
    "setup-harness.sh",
    "global/statusline.sh",
    "global/settings.json",
    "global/settings.json.example",
    "global/AGENTS.md",
    "global/GEMINI.md",
    "docs/adr/harness/ADR-001-no-symlink-portability.md"
]

# Constants for deleted directories
DELETED_DIRS = [
    "docs/adr/harness"
]

# Constants for templates
TEMPLATE_FILES = [
    "templates/global/AGENTS.md",
    "templates/global/GEMINI.md",
    "templates/global/CLAUDE.md",
    "templates/project/AGENTS.md",
    "templates/project/GEMINI.md",
    "templates/project/CLAUDE.md",
    "templates/project/.agents/rules/code-style.md",
    "templates/project/.agents/rules/safety.md",
    "templates/project/docs/adr/adr-init.template",
    "templates/project/gitignore.template",
    "templates/project/skillsrc.template",
    "templates/project/README.md"
]

def test_legacy_files_purged():
    """Ensure all specified legacy files and directories are completely deleted."""
    for rel_path in DELETED_FILES:
        full_path = os.path.join(os.getcwd(), rel_path)
        assert not os.path.exists(full_path), f"Legacy file should be deleted: {rel_path}"
    
    for rel_dir in DELETED_DIRS:
        full_path = os.path.join(os.getcwd(), rel_dir)
        assert not os.path.exists(full_path), f"Legacy directory should be deleted: {rel_dir}"

def test_new_templates_exist():
    """Ensure all revamped base templates are created and exist."""
    for rel_path in TEMPLATE_FILES:
        full_path = os.path.join(os.getcwd(), rel_path)
        assert os.path.isfile(full_path), f"Template file should exist: {rel_path}"

def test_templates_under_100_lines():
    """Ensure all templates have strictly fewer than 100 lines."""
    for rel_path in TEMPLATE_FILES:
        full_path = os.path.join(os.getcwd(), rel_path)
        assert os.path.isfile(full_path), f"Template file must exist: {rel_path}"
        with open(full_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
        line_count = len(lines)
        assert line_count < 100, f"Template {rel_path} has {line_count} lines (must be < 100)"

def test_templates_use_portable_references():
    """Ensure all templates use portable relative references (no file:/// or local filesystem paths)."""
    for rel_path in TEMPLATE_FILES:
        full_path = os.path.join(os.getcwd(), rel_path)
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
        assert "file:///" not in content, f"Template {rel_path} contains non-portable reference 'file:///'"
        assert "/Users/" not in content, f"Template {rel_path} contains absolute system reference '/Users/'"
        assert "C:\\" not in content, f"Template {rel_path} contains absolute system reference 'C:\\'"
