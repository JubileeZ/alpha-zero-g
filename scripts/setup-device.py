#!/usr/bin/env python3
import os
import sys
import json
import shutil
import subprocess
from pathlib import Path

def main():
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    manifest_path = repo_root / "templates" / "skills_manifest.txt"
    global_templates_dir = repo_root / "templates" / "global"
    statusline_src = script_dir / "statusline.py"
    
    ok_count = 0
    home = Path.home()
    
    # Step 1
    print("Step 1: Clone mattpocock/skills to ~/.agent-skills/mattpocock/... ", end="")
    target_skills_dir = home / ".agent-skills" / "mattpocock"
    if target_skills_dir.exists():
        print("SKIP")
    else:
        target_skills_dir.parent.mkdir(parents=True, exist_ok=True)
        res = subprocess.run(["git", "clone", "--depth", "1", "https://github.com/mattpocock/skills.git", str(target_skills_dir)], capture_output=True)
        if res.returncode == 0:
            print("OK")
            ok_count += 1
        else:
            print("FAIL")
            
    # Step 2
    print("Step 2: Copy selected skills to ~/.gemini/antigravity-cli/skills/... ", end="")
    dest_skills_dir = home / ".gemini" / "antigravity-cli" / "skills"
    dest_skills_dir.mkdir(parents=True, exist_ok=True)
    
    if not manifest_path.exists():
        print("FAIL (manifest missing)")
    else:
        failed = False
        with open(manifest_path, "r", encoding="utf-8") as f:
            for line in f:
                skill = line.split("#")[0].strip()
                if not skill:
                    continue
                local_src = repo_root / "templates" / "skills" / skill
                dst_skill = dest_skills_dir / skill
                
                if local_src.is_dir():
                    if dst_skill.exists():
                        shutil.rmtree(dst_skill)
                    shutil.copytree(local_src, dst_skill)
                else:
                    found = False
                    for root, dirs, files in os.walk(target_skills_dir):
                        if skill in dirs:
                            src_skill = Path(root) / skill
                            if dst_skill.exists():
                                shutil.rmtree(dst_skill)
                            shutil.copytree(src_skill, dst_skill)
                            found = True
                            break
                    if not found:
                        failed = True
        if not failed:
            print("OK")
            ok_count += 1
        else:
            print("FAIL (some skills missing in source)")
            
    # Function to deploy global file
    def deploy_global_file(step_num, filename):
        nonlocal ok_count
        print(f"Step {step_num}: Deploy global {filename} to ~/.gemini/{filename}... ", end="")
        src = global_templates_dir / filename
        dest = home / ".gemini" / filename
        dest.parent.mkdir(parents=True, exist_ok=True)
        
        if not src.exists():
            print("FAIL (source file missing)")
            return
        if dest.exists() and not getattr(sys, "auto_confirm", False):
            choice = input(f"\nFile {dest} already exists. Overwrite? (y/n): ")
            if choice.strip().lower() == "y":
                shutil.copy2(src, dest)
                print("OK")
                ok_count += 1
            else:
                print("SKIP")
        else:
            shutil.copy2(src, dest)
            print("OK")
            ok_count += 1

    deploy_global_file(3, "AGENTS.md")
    deploy_global_file(4, "GEMINI.md")
    deploy_global_file(5, "CLAUDE.md")
    
    # Step 6
    print("Step 6: Copy statusline.py to ~/.agent-config/statusline.py... ", end="")
    agent_config_dir = home / ".agent-config"
    agent_config_dir.mkdir(parents=True, exist_ok=True)
    try:
        shutil.copy2(statusline_src, agent_config_dir / "statusline.py")
        print("OK")
        ok_count += 1
    except Exception:
        print("FAIL")
        
    # Step 7
    print("Step 7: Patch ~/.gemini/antigravity-cli/settings.json... ", end="")
    try:
        settings_path = home / ".gemini" / "antigravity-cli" / "settings.json"
        settings_path.parent.mkdir(parents=True, exist_ok=True)
        data = {}
        if settings_path.exists():
            with open(settings_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        if "statusLine" not in data or not isinstance(data["statusLine"], dict):
            data["statusLine"] = {}
        
        cmd = "python3 ~/.agent-config/statusline.py" if sys.platform != "win32" else "python %USERPROFILE%\\\\.agent-config\\\\statusline.py"
        data["statusLine"].update({
            "type": "custom",
            "command": cmd,
            "enabled": True
        })
        with open(settings_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        print("OK")
        ok_count += 1
    except Exception:
        print("FAIL")
        
    # Step 8
    print("Step 8: Verify statusline execution... ", end="")
    try:
        py_exec = "python3" if sys.platform != "win32" else "python"
        target = agent_config_dir / "statusline.py"
        res = subprocess.run([py_exec, str(target)], capture_output=True, text=True)
        if res.returncode == 0:
            print("OK")
            print(f"Stdout: {res.stdout.strip()}")
            ok_count += 1
        else:
            print("FAIL (execution failed)")
    except Exception:
        print("FAIL")
        
    print(f"Step 9: Exit summary: {ok_count}/8 steps OK.")

if __name__ == "__main__":
    main()
