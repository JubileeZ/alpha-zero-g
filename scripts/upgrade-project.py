#!/usr/bin/env python3
import os
import sys
import shutil
import argparse
from pathlib import Path
from datetime import datetime

def main() -> None:
    parser = argparse.ArgumentParser(description="Alpha-Zero-G Project Upgrade Audit")
    parser.add_argument("--dry-run", action="store_true", help="Dry-run mode")
    parser.add_argument("-y", "--yes", action="store_true", help="Auto-confirm")
    args = parser.parse_args()
    
    if not Path(".git").exists() and not Path("AGENTS.md").exists():
        print("Error: Not inside a valid project", file=sys.stderr)
        sys.exit(1)
        
    script_dir: Path = Path(__file__).resolve().parent
    tdir: Path = script_dir.parent / "templates" / "project"
    
    if not tdir.is_dir():
        print(f"Error: Templates directory not found at {tdir}", file=sys.stderr)
        sys.exit(1)
        
    dirs: list[str] = [
        ".agents", ".agents/rules", ".agents/skills", "docs", "docs/adr",
        "docs/research", "data", "data/raw", "data/interim", "data/processed",
        "src", "tests", "notebooks", "scripts"
    ]
    files: list[str] = [
        "AGENTS.md", "GEMINI.md", "CLAUDE.md", ".agents/rules/code-style.md",
        ".agents/rules/safety.md", ".agents/hooks.json", ".gitignore", ".skillsrc", "README.md"
    ]
    
    print("--- Alpha-Zero-G Project Upgrade Audit ---")
    add_count: int = 0
    skip_count: int = 0
    
    for d in dirs:
        if Path(d).is_dir():
            print(f"[EXISTS]  Directory: {d}")
            skip_count += 1
        else:
            print(f"[MISSING] Directory: {d}")
            add_count += 1
            
    for f in files:
        if Path(f).is_file():
            print(f"[EXISTS]  File: {f}")
            skip_count += 1
        else:
            print(f"[MISSING] File: {f}")
            add_count += 1
            
    if args.dry_run:
        print("Dry-run mode. Stopping.")
        sys.exit(0)
        
    if not args.yes and sys.stdout.isatty():
        resp: str = input("Proceed with upgrade? (y/N) ")
        if not resp.lower().startswith('y'):
            print("Upgrade cancelled.")
            sys.exit(0)
            
    proj_name: str = Path.cwd().name
    
    for d in dirs:
        Path(d).mkdir(parents=True, exist_ok=True)
        
    def write_default_file(path_str: str) -> None:
        path: Path = Path(path_str)
        if path.exists():
            return
        
        if path_str == "AGENTS.md":
            content: str = (tdir / "AGENTS.md").read_text(encoding="utf-8")
            path.write_text(content.replace("{{PROJECT_NAME}}", proj_name), encoding="utf-8")
        elif path_str == "GEMINI.md":
            shutil.copy2(tdir / "GEMINI.md", path)
        elif path_str == "CLAUDE.md":
            shutil.copy2(tdir / "CLAUDE.md", path)
        elif path_str == ".agents/rules/code-style.md":
            shutil.copy2(tdir / ".agents/rules/code-style.md", path)
        elif path_str == ".agents/rules/safety.md":
            shutil.copy2(tdir / ".agents/rules/safety.md", path)
        elif path_str == ".agents/hooks.json":
            shutil.copy2(tdir / ".agents/hooks.json", path)
        elif path_str == ".gitignore":
            shutil.copy2(tdir / "gitignore.template", path)
        elif path_str == ".skillsrc":
            shutil.copy2(tdir / "skillsrc.template", path)
        elif path_str == "README.md":
            content = (tdir / "README.md").read_text(encoding="utf-8")
            content = content.replace("{{PROJECT_NAME}}", proj_name).replace("{{PROJECT_DESCRIPTION}}", "")
            path.write_text(content, encoding="utf-8")
            
    for f in files:
        if f == "AGENTS.md" and Path("AGENTS.md").exists():
            content: str = Path("AGENTS.md").read_text(encoding="utf-8")
            if "## Alpha-Zero-G" not in content:
                block: str = "\n\n## Alpha-Zero-G\n- **Deterministic Python**: Always execute via `uv run` (`uv run pytest`, `uv run python`).\n- **No Symlink Portability**: All project rules are physical copies and use relative links.\n- **Explicit Typings**: Require strict type hints in Python."
                with open("AGENTS.md", "a", encoding="utf-8") as fh:
                    fh.write(block)
        else:
            write_default_file(f)
            
    max_adr: int = 0
    adr_dir: Path = Path("docs/adr")
    if adr_dir.exists():
        for adr_file in adr_dir.glob("ADR-*.md"):
            try:
                num: int = int(adr_file.name.split("-")[1])
                if num > max_adr:
                    max_adr = num
            except Exception:
                pass
                
    next_adr: int = max_adr + 1
    next_pad: str = f"{next_adr:03d}"
    date_str: str = datetime.now().strftime("%Y-%m-%d")
    adr_file_path: Path = adr_dir / f"ADR-{next_pad}-alpha-zero-g-upgrade.md"
    
    adr_content: str = f"""# ADR-{next_pad}: Alpha-Zero-G Upgrade
**Status:** Accepted
**Date:** {date_str}

## Context
We need to upgrade the existing project to the latest Alpha-Zero-G canonical structure.

## Decision
Upgrade the project structure, append missing instructions to AGENTS.md, and ensure all canonical files/directories are present.

## Alternatives Considered
- Manual upgrade: Rejected because it is error-prone and time-consuming.

## Consequences
- Good: Project aligns with the latest Alpha-Zero-G standards.
- Bad: None.
"""
    adr_file_path.write_text(adr_content, encoding="utf-8")
    add_count += 1
    
    print(f"Upgrade complete. {add_count} items added, {skip_count} items skipped (already present).")

if __name__ == "__main__":
    main()