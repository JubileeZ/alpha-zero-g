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
        if secs >= 3600:
            return f" ({secs//3600}h {(secs%3600)//60}m)"
        elif secs >= 60:
            return f" ({secs//60}m)"
        elif secs >= 0:
            return f" (<1m)"
        else:
            return ""
    except Exception: return ""

def get_stdin_nonblocking():
    if sys.stdin.isatty(): return ""
    try:
        import platform, time
        end_time = time.time() + 0.05
        if platform.system() == "Windows":
            import ctypes
            from ctypes import wintypes
            hStdin = ctypes.windll.kernel32.GetStdHandle(-10)
            while time.time() < end_time:
                avail = wintypes.DWORD()
                res = ctypes.windll.kernel32.PeekNamedPipe(hStdin, None, 0, None, ctypes.byref(avail), None)
                if res and avail.value > 0:
                    return sys.stdin.read(avail.value).strip()
                time.sleep(0.01)
        else:
            import select
            r, _, _ = select.select([sys.stdin], [], [], 0.05)
            if r: return sys.stdin.readline().strip()
    except Exception: pass
    return ""

def refresh_quota_cache(cache_file: str, usage_bin: str) -> None:
    """Refresh the quota cache file using antigravity-usage if stale (>60s)."""
    try:
        age = time.time() - os.path.getmtime(cache_file) if os.path.exists(cache_file) else 999.0
        if age > 60.0:
            tmp_file = cache_file + ".tmp"
            if not os.path.exists(cache_file) or os.path.getsize(cache_file) == 0:
                # First run: block until we have data
                subprocess.run(
                    [usage_bin, "quota", "--json"],
                    stdout=open(tmp_file, "w"),
                    stderr=subprocess.DEVNULL,
                    timeout=10
                )
                if os.path.exists(tmp_file):
                    os.replace(tmp_file, cache_file)
            else:
                # Subsequent runs: refresh in background with atomic rename
                cmd = f"import subprocess, os; subprocess.run([r'{usage_bin}', 'quota', '--json'], stdout=open(r'{tmp_file}', 'w')); os.replace(r'{tmp_file}', r'{cache_file}')"
                # Use CREATE_NO_WINDOW on Windows to prevent console flashing
                creation_flags = 0x08000000 if sys.platform == "win32" else 0
                subprocess.Popen(
                    [sys.executable, "-c", cmd],
                    stderr=subprocess.DEVNULL,
                    creationflags=creation_flags
                )
    except Exception: pass

def load_quota_models(cache_file: str) -> list:
    """Load model quota data from cache file."""
    if os.path.exists(cache_file) and os.path.getsize(cache_file) > 0:
        try:
            with open(cache_file, "r", encoding="utf-8") as f:
                return json.load(f).get("models", [])
        except Exception: pass
    return []

def pick_family_quota(models: list, family: str) -> dict | None:
    """Pick the highest-tier model from a family for quota display."""
    candidates = [m for m in models if family in m.get("label", "")]
    if not candidates:
        return None
    # Sort by remainingPercentage ascending (show the worst case / lowest remaining)
    candidates.sort(key=lambda m: m.get("remainingPercentage", 1.0))
    return candidates[0]

def main() -> None:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    try:
        project = find_project_name(os.getcwd())
        branch = get_git_branch()
        model_hint = get_model_hint()
        date_str = datetime.now().strftime("%Y-%m-%d")
        
        stdin_data = get_stdin_nonblocking()
            
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
                
                # Context Color Logic based on absolute thresholds
                if used_tokens < 70000:
                    ctx_color = "\033[1;32m" # Green (Safe)
                    ctx_status = "Safe"
                elif used_tokens < 100000:
                    ctx_color = "\033[38;5;208m" # Orange (Caution)
                    ctx_status = "Caution"
                elif used_tokens < 500000:
                    ctx_color = "\033[1;31m" # Red (Degrading)
                    ctx_status = "Degrading"
                else:
                    ctx_color = "\033[1;5;31m" # Flashing Bright Red (Critical)
                    ctx_status = "Critical"
                    
                # Visual progress bar spanning up to 50% of max context
                max_visual = window_size * 0.5
                fraction = min(1.0, used_tokens / max_visual) if max_visual > 0 else 0
                bar_len = 10
                filled = int(round(fraction * bar_len))
                empty = bar_len - filled
                bar_str = "█" * filled + "░" * empty
                
                safe_pct = int((used_tokens / 100000.0) * 100)
                ctx_str = f"Context: {fmt_used}/{fmt_size} ({used_pct}%) // {ctx_color}{safe_pct}% ({ctx_status}) [{bar_str}]\033[0m"
                
                # Quota: try antigravity-usage tool
                cache_file = os.path.join(tempfile.gettempdir(), "antigravity_quota_cache.json")
                usage_bin = shutil.which("antigravity-usage")
                if usage_bin:
                    refresh_quota_cache(cache_file, usage_bin)

                models = load_quota_models(cache_file)
                
                p_part = f"[{project}] {branch} | " if branch else f"[{project}] | "
                
                if models:
                    gemini_pct, gemini_reset = "N/A", ""
                    claude_pct, claude_reset = "N/A", ""
                    
                    g_info = pick_family_quota(models, "Gemini")
                    if g_info:
                        gemini_pct = f"{float(g_info.get('remainingPercentage', 0.0)) * 100:.0f}%"
                        gemini_reset = format_reset_time(g_info.get("timeUntilResetMs"))
                    
                    c_info = pick_family_quota(models, "Claude")
                    if c_info:
                        claude_pct = f"{float(c_info.get('remainingPercentage', 0.0)) * 100:.0f}%"
                        claude_reset = format_reset_time(c_info.get("timeUntilResetMs"))
                    
                    sys.stdout.write(f"{p_part}\033[1;34mModel: {model_name}\033[0m | {ctx_str} | \033[1;33mGemini: {gemini_pct}{gemini_reset} | Claude: {claude_pct}{claude_reset}\033[0m\n")
                else:
                    sys.stdout.write(f"{p_part}\033[1;34mModel: {model_name}\033[0m | {ctx_str}\n")
                return
            except Exception: pass

        print(f"[{project}] {branch} | {model_hint} | {date_str}")
    except Exception:
        try: print(f"[unknown]  | Gemini | {datetime.now().strftime('%Y-%m-%d')}")
        except Exception: pass

if __name__ == "__main__":
    main()
