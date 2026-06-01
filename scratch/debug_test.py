import sys
import os
import json
from unittest.mock import patch, MagicMock

# Insert repo root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from scripts.statusline import main

def run_debug():
    stdin_json = json.dumps({
        "model": {"display_name": "Mock-Gemini"},
        "context_window": {
            "current_usage": {"input_tokens": 1200000},
            "context_window_size": 2000000,
            "used_percentage": 60.0
        }
    })
    
    # We will run main() directly, but print any caught exception
    # Let's inspect the original main() to see what exception gets raised
    try:
        # Let's run it with patches
        with patch("sys.stdin.isatty", return_value=False), \
             patch("sys.stdin.read", return_value=stdin_json), \
             patch("scripts.statusline.find_project_name", return_value="Proj"), \
             patch("scripts.statusline.get_git_branch", return_value="master"):
            # Let's execute main but capture the prints
            main()
    except Exception as e:
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    run_debug()
