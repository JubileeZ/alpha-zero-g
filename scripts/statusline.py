#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import shutil
import time
import tempfile
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
            except Exception: pass
        parent = os.path.dirname(curr)
        if parent == curr: break
        curr = parent
    return os.path.basename(os.path.abspath(start_dir)) or "unknown"

def get_git_branch() -> str:
    try:
        return subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True, check=True).stdout.strip()
    except Exception: return ""

def get_model_hint(settings_path: str = None) -> str:
    try:
        path = settings_path or os.path.expanduser("~/.gemini/antigravity-cli/settings.json")
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f).get("model", "Gemini")
    except Exception: return "Gemini"

def format_tokens(val) -> str:
    try:
        val = int(val)
        return f"{val/1e6:.1f}M" if val >= 1e6 else (f"{val/1e3:.0f}k" if val >= 1e3 else str(val))
    except Exception: return str(val)

def format_reset_time(time_ms) -> str:
    try:
        secs = int(time_ms) // 1000
        return f" ({secs//3600}h {(secs%3600)//60}m)" if secs >= 3600 else (f" ({secs//60}m)" if secs > 0 else "")
    except Exception: return ""

def main() -> None:
    try:
        project = find_project_name(os.getcwd())
        branch = get_git_branch()
        model_hint = get_model_hint()
        date_str = datetime.now().strftime("%Y-%m-%d")
        
        stdin_data = ""
        if not sys.stdin.isatty():
            try: stdin_data = sys.stdin.read().strip()
            except Exception: pass
            
        if stdin_data:
            try:
                payload = json.loads(stdin_data)
                model_name = payload.get("model", {}).get("display_name", "Unknown")
                ctx = payload.get("context_window", {})
                window_size = ctx.get("context_window_size", 0)
                used_percentage = ctx.get("used_percentage", 0.0)
                
                # Calculate active used tokens based on percentage of max context
                used_tokens = int((used_percentage / 100.0) * window_size) if window_size > 0 else 0
                used_pct = f"{used_percentage:.1f}"
                
                fmt_used = format_tokens(used_tokens)
                fmt_size = format_tokens(window_size)
                
                cache_file = os.path.join(tempfile.gettempdir(), "antigravity_quota_cache.json")
                usage_bin = shutil.which("antigravity-usage")
                if usage_bin:
                    age = time.time() - os.path.getmtime(cache_file) if os.path.exists(cache_file) else 999.0
                    if age > 60.0:
                        try:
                            if not os.path.exists(cache_file) or os.path.getsize(cache_file) == 0:
                                subprocess.run([usage_bin, "--json"], stdout=open(cache_file, "w"), stderr=subprocess.DEVNULL)
                            else:
                                subprocess.Popen([usage_bin, "--json"], stdout=open(cache_file, "w"), stderr=subprocess.DEVNULL)
                        except Exception: pass

                gemini_pct, gemini_reset, claude_pct, claude_reset = "0.0%", "", "0.0%", ""
                if os.path.exists(cache_file) and os.path.getsize(cache_file) > 0:
                    try:
                        with open(cache_file, "r", encoding="utf-8") as f:
                            models = json.load(f).get("models", [])
                        g_info = next((m for m in models if "Gemini" in m.get("label", "")), None)
                        if g_info:
                            gemini_pct = f"{float(g_info.get('remainingPercentage', 0.0)) * 100:.1f}%"
                            gemini_reset = format_reset_time(g_info.get("timeUntilResetMs"))
                        c_info = next((m for m in models if "Claude" in m.get("label", "")), None)
                        if c_info:
                            claude_pct = f"{float(c_info.get('remainingPercentage', 0.0)) * 100:.1f}%"
                            claude_reset = format_reset_time(c_info.get("timeUntilResetMs"))
                    except Exception: pass

                p_part = f"[{project}] {branch} | " if branch else f"[{project}] | "
                sys.stdout.write(f"{p_part}\033[1;34mModel: {model_name}\033[0m | \033[1;32mContext: {fmt_used}/{fmt_size} ({used_pct}%)\033[0m | \033[1;33mGemini: {gemini_pct}{gemini_reset} | Claude: {claude_pct}{claude_reset}\033[0m\n")
                return
            except Exception: pass

        print(f"[{project}] {branch} | {model_hint} | {date_str}")
    except Exception:
        try: print(f"[unknown]  | Gemini | {datetime.now().strftime('%Y-%m-%d')}")
        except Exception: pass

if __name__ == "__main__":
    main()
