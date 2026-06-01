#!/usr/bin/env python3
import os
import json
import subprocess
from datetime import datetime

def find_project_name(start_dir: str) -> str:
    curr = os.path.abspath(start_dir)
    while True:
        agents_path = os.path.join(curr, "AGENTS.md")
        if os.path.isfile(agents_path):
            try:
                with open(agents_path, "r", encoding="utf-8") as f:
                    first_line = f.readline()
                if first_line.strip().startswith("# Project:"):
                    return first_line.strip().split("# Project:", 1)[1].strip()
            except Exception:
                pass
        parent = os.path.dirname(curr)
        if parent == curr:
            break
        curr = parent
    return os.path.basename(os.path.abspath(start_dir)) or "unknown"

def get_git_branch() -> str:
    try:
        res = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            check=True
        )
        return res.stdout.strip()
    except Exception:
        return ""

def get_model_hint(settings_path: str = None) -> str:
    if settings_path is None:
        settings_path = os.path.expanduser("~/.gemini/antigravity-cli/settings.json")
    try:
        with open(settings_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data.get(".model", "Gemini")
    except Exception:
        return "Gemini"

def main() -> None:
    try:
        project = find_project_name(os.getcwd())
        branch = get_git_branch()
        model_hint = get_model_hint()
        date_str = datetime.now().strftime("%Y-%m-%d")
        print(f"[{project}] {branch} | {model_hint} | {date_str}")
    except Exception:
        try:
            date_str = datetime.now().strftime("%Y-%m-%d")
            print(f"[unknown]  | Gemini | {date_str}")
        except Exception:
            pass

if __name__ == "__main__":
    main()
