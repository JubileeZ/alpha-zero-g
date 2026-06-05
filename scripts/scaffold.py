#!/usr/bin/env python3
import datetime
import os
import re
import shutil
import subprocess
import sys


def slugify_package_name(name: str) -> str:
    # Lowercase, replace spaces, dashes, dots, and underscores with a single underscore
    s = name.lower()
    s = re.sub(r'[\s\-._]+', '_', s)
    # Strip any characters that are not lowercase alphanumeric or underscore
    s = re.sub(r'[^a-z0-9_]', '', s)
    # Ensure it starts with a letter or underscore
    if s and s[0].isdigit():
        s = '_' + s
    if not s:
        s = "project_package"
    return s

def main() -> None:
    # reconfigure stdout for utf-8 if possible to avoid Windows UnicodeEncodeError
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

    if len(sys.argv) < 3:
        print("Usage: scaffold.py <name> <type> [dest]")
        sys.exit(1)
    name: str = sys.argv[1]
    ptype: str = sys.argv[2]
    dest: str = sys.argv[3] if len(sys.argv) > 3 else f"./{name}"
    if ptype not in ("python", "r", "hybrid"):
        print("Error: Invalid project type. Must be 'python', 'r', or 'hybrid'.")
        sys.exit(1)
        
    package_name = slugify_package_name(name)
    dest = os.path.abspath(dest)
    os.makedirs(dest, exist_ok=True)

    # Generate canonical folder structure
    dirs: list[str] = [
        "tests",
        "docs/adr",
        "docs/research",
        "data/raw",
        "data/interim",
        "data/processed",
        ".agents/rules",
        ".agents/skills",
    ]
    if ptype in ("python", "hybrid"):
        dirs.append("src")
    if ptype in ("r", "hybrid"):
        dirs.append("R")

    for d in dirs:
        os.makedirs(os.path.join(dest, d), exist_ok=True)

    # Write project rules from templates/project/
    root: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ptemp: str = os.path.join(root, "templates/project")
    for f in ["AGENTS.md", "GEMINI.md", "CLAUDE.md", "README.md"]:
        src: str = os.path.join(ptemp, f)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(dest, f))
    # Copy hooks.json if it exists
    hooks_src = os.path.join(ptemp, ".agents/hooks.json")
    if os.path.exists(hooks_src):
        shutil.copy(hooks_src, os.path.join(dest, ".agents/hooks.json"))

    # Copy project rules sub-documents
    rules_src: str = os.path.join(ptemp, ".agents/rules")
    if os.path.exists(rules_src):
        for f in os.listdir(rules_src):
            shutil.copy(os.path.join(rules_src, f), os.path.join(dest, ".agents/rules", f))
            
    # Copy local custom skills to .agents/skills
    skills_src: str = os.path.join(root, "templates/skills")
    if os.path.exists(skills_src):
        for item in os.listdir(skills_src):
            src_skill: str = os.path.join(skills_src, item)
            if os.path.isdir(src_skill):
                shutil.copytree(src_skill, os.path.join(dest, ".agents/skills", item))

    # Copy ADR-TEMPLATE.md if it exists
    adr_template_src: str = os.path.join(ptemp, "docs/adr/ADR-TEMPLATE.md")
    if os.path.exists(adr_template_src):
        shutil.copy(adr_template_src, os.path.join(dest, "docs/adr/ADR-TEMPLATE.md"))

    # Copy docs/research/README.md if it exists
    research_readme_src: str = os.path.join(ptemp, "docs/research/README.md")
    if os.path.exists(research_readme_src):
        shutil.copy(research_readme_src, os.path.join(dest, "docs/research/README.md"))

    # Generate docs/adr/ADR-001-project-init.md
    adr_temp: str = os.path.join(ptemp, "docs/adr/adr-init.template")
    if os.path.exists(adr_temp):
        with open(adr_temp, "r", encoding="utf-8") as f_in:
            c: str = f_in.read().replace("{{DATE}}", datetime.date.today().isoformat())
        with open(
            os.path.join(dest, "docs/adr/ADR-001-project-init.md"),
            "w",
            encoding="utf-8",
        ) as f_out:
            f_out.write(c)

    # Deploy standard .gitignore and .skillsrc
    for s, d in [
        ("gitignore.template", ".gitignore"),
        ("skillsrc.template", ".skillsrc"),
    ]:
        src = os.path.join(ptemp, s)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(dest, d))

    # Deploy CI/CD workflow template
    github_src = os.path.join(ptemp, ".github", "workflows")
    if os.path.exists(github_src):
        github_dest = os.path.join(dest, ".github", "workflows")
        os.makedirs(github_dest, exist_ok=True)
        for f in os.listdir(github_src):
            shutil.copy(os.path.join(github_src, f), os.path.join(github_dest, f))

    # Wire R templates if applicable
    if ptype in ("r", "hybrid"):
        r_temp = os.path.join(root, "templates/r")
        if os.path.exists(r_temp):
            # Copy DESCRIPTION to root
            desc_src = os.path.join(r_temp, "DESCRIPTION")
            if os.path.exists(desc_src):
                shutil.copy(desc_src, os.path.join(dest, "DESCRIPTION"))
            
            # Copy src/smoke.R to src/smoke.R
            smoke_src = os.path.join(r_temp, "src/smoke.R")
            if os.path.exists(smoke_src):
                os.makedirs(os.path.join(dest, "src"), exist_ok=True)
                shutil.copy(smoke_src, os.path.join(dest, "src/smoke.R"))
                
            # Copy tests/testthat.R to tests/testthat.R
            test_src = os.path.join(r_temp, "tests/testthat.R")
            if os.path.exists(test_src):
                os.makedirs(os.path.join(dest, "tests"), exist_ok=True)
                shutil.copy(test_src, os.path.join(dest, "tests/testthat.R"))

    # Deploy shared templates from templates/
    shared_templates = [
        "progress.md",
        "features.json",
        "CONTEXT.md",
        "DEVELOPER_WORKFLOW.md",
        ".env.example",
        "Makefile",
        ".pre-commit-config.yaml",
    ]
    for f in shared_templates:
        src = os.path.join(root, "templates", f)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(dest, f))

    # Python-specific structure deployment
    if ptype in ("python", "hybrid"):
        # Create src/<package_name> directory
        pkg_dir = os.path.join(dest, "src", package_name)
        os.makedirs(pkg_dir, exist_ok=True)
        
        # Copy config.py from templates
        config_src = os.path.join(root, "templates/python/src/{{PACKAGE_NAME}}/config.py")
        if os.path.exists(config_src):
            shutil.copy(config_src, os.path.join(pkg_dir, "config.py"))
            
        # Copy schemas.py from templates
        schemas_src = os.path.join(root, "templates/python/src/{{PACKAGE_NAME}}/schemas.py")
        if os.path.exists(schemas_src):
            shutil.copy(schemas_src, os.path.join(pkg_dir, "schemas.py"))
            
        # Copy __init__.py from templates to src/<package_name>/__init__.py
        init_src = os.path.join(root, "templates/python/src/__init__.py")
        if os.path.exists(init_src):
            shutil.copy(init_src, os.path.join(pkg_dir, "__init__.py"))
            
        # Deploy pyproject.toml
        pyproject_src = os.path.join(root, "templates/python/pyproject.toml")
        if os.path.exists(pyproject_src):
            shutil.copy(pyproject_src, os.path.join(dest, "pyproject.toml"))
            
        # Deploy conftest.py and test_smoke.py
        conftest_src = os.path.join(root, "templates/python/tests/conftest.py")
        if os.path.exists(conftest_src):
            shutil.copy(conftest_src, os.path.join(dest, "tests", "conftest.py"))
            
        smoke_src = os.path.join(root, "templates/python/tests/test_smoke.py")
        if os.path.exists(smoke_src):
            shutil.copy(smoke_src, os.path.join(dest, "tests", "test_smoke.py"))
            
    # Replace {{PROJECT_NAME}}, {{PACKAGE_NAME}}, {{PROJECT_DESCRIPTION}} and {{PROJECT_GOAL_SUMMARY}} placeholders
    for r, ds, fs in os.walk(dest):
        for f in fs:
            ext: str = os.path.splitext(f)[1]
            if (
                ext in (".md", ".template", ".py", ".toml", ".yaml", ".yml", ".json")
                or f in (".skillsrc", ".gitignore", "Makefile", ".env.example", "DESCRIPTION")
            ):
                p: str = os.path.join(r, f)
                try:
                    with open(p, "r", encoding="utf-8", errors="ignore") as file:
                        content: str = file.read()
                    new_content: str = (
                        content.replace("{{PROJECT_NAME}}", name)
                        .replace("{{PACKAGE_NAME}}", package_name)
                        .replace("{{PROJECT_DESCRIPTION}}", f"Scaffolded {name} project.")
                        .replace(
                            "{{PROJECT_GOAL_SUMMARY}}",
                            f"Establish analytical modeling environment for {name}.",
                        )
                    )
                    if new_content != content:
                        with open(p, "w", encoding="utf-8") as file:
                            file.write(new_content)
                except Exception:
                    pass

    # .agents/skills/ directory is already created above and left empty for project-specific overrides.

    # Initialize git and commit baseline changes
    print("git init")
    subprocess.run(["git", "init", "-q"], cwd=dest)
    print('git config --local user.email "agent@alpha-zero-g.local"')
    subprocess.run(
        ["git", "config", "--local", "user.email", "agent@alpha-zero-g.local"], cwd=dest
    )
    print('git config --local user.name "Alpha Zero G Initializer"')
    subprocess.run(
        ["git", "config", "--local", "user.name", "Alpha Zero G Initializer"], cwd=dest
    )
    print("git add .")
    subprocess.run(["git", "add", "."], cwd=dest)
    print('git commit -m "chore: scaffold via alpha-zero-g"')
    subprocess.run(
        ["git", "commit", "-m", "chore: scaffold via alpha-zero-g", "-q"], cwd=dest
    )
    print(f"[OK] Project '{name}' successfully scaffolded.")

if __name__ == "__main__":
    main()