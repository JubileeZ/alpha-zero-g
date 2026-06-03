import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import json
import subprocess
from unittest.mock import patch, MagicMock
import pytest
from scripts.statusline import find_project_name, get_git_branch, get_model_hint, main


def test_find_project_name_agents_md(tmp_path):
    # Test upwards traversal finding AGENTS.md
    agents_file = tmp_path / "AGENTS.md"
    agents_file.write_text("# Project: TestProj\nOther contents")
    sub_dir = tmp_path / "src" / "nested"
    sub_dir.mkdir(parents=True)
    
    assert find_project_name(str(sub_dir)) == "TestProj"

def test_find_project_name_fallback(tmp_path):
    # Fallback to directory name when no AGENTS.md or no "# Project:"
    sub_dir = tmp_path / "some-folder"
    sub_dir.mkdir()
    assert find_project_name(str(sub_dir)) == "some-folder"

def test_get_git_branch_success():
    with patch("subprocess.run") as mock_run:
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = "main\n"
        mock_run.return_value = mock_proc
        assert get_git_branch() == "main"

def test_get_git_branch_failure():
    with patch("subprocess.run", side_effect=Exception("git error")):
        assert get_git_branch() == ""

def test_get_model_hint_success(tmp_path):
    settings = tmp_path / "settings.json"
    settings.write_text(json.dumps({"model": "Claude-3-Opus"}))
    assert get_model_hint(str(settings)) == "Claude-3-Opus"

def test_get_model_hint_fallback(tmp_path):
    # Fallback to "Gemini" if missing or invalid
    assert get_model_hint(str(tmp_path / "nonexistent.json")) == "Gemini"
    
    bad_json = tmp_path / "bad.json"
    bad_json.write_text("invalid json")
    assert get_model_hint(str(bad_json)) == "Gemini"

def test_main_block_no_crash(capsys):
    # Ensure standard successful run
    with patch("scripts.statusline.find_project_name", return_value="Proj"), \
         patch("scripts.statusline.get_git_branch", return_value="feat/branch"), \
         patch("scripts.statusline.get_model_hint", return_value="Gemini"):
        main()
        captured = capsys.readouterr()
        assert "[Proj] feat/branch | Gemini |" in captured.out

def test_main_block_extreme_error_safety(capsys):
    # Ensure absolutely no crash even if everything throws exceptions
    with patch("scripts.statusline.find_project_name", side_effect=RuntimeError("Fatal name error")):
        try:
            main()
        except Exception as e:
            pytest.fail(f"main() raised an exception: {e}")
        captured = capsys.readouterr()
        # Even on error, it must output exactly one line (might be empty/fallback or crash-resistant output)
        assert len(captured.out.splitlines()) <= 1

def test_format_tokens():
    from scripts.statusline import format_tokens
    assert format_tokens(2500000) == "2.5M"
    assert format_tokens(1000000) == "1.0M"
    assert format_tokens(5000) == "5k"
    assert format_tokens(500) == "500"
    assert format_tokens("invalid") == "invalid"

def test_format_reset_time():
    from scripts.statusline import format_reset_time
    assert format_reset_time(3720000) == " (1h 2m)"
    assert format_reset_time(120000) == " (2m)"
    assert format_reset_time(0) == " (<1m)"
    assert format_reset_time(None) == ""
    assert format_reset_time("bad") == ""

def test_main_with_stdin_rich_json(capsys, tmp_path):
    # Mock sys.stdin.isatty to return False, and mock read to return rich JSON
    stdin_json = json.dumps({
        "model": {"display_name": "Mock-Gemini"},
        "context_window": {
            "current_usage": {"input_tokens": 1200000},
            "context_window_size": 2000000,
            "used_percentage": 60.0
        }
    })
    
    # Mock quota cache file
    cache_file = tmp_path / "antigravity_quota_cache.json"
    cache_file.write_text(json.dumps({
        "models": [
            {"label": "Gemini-1.5", "remainingPercentage": 0.854, "timeUntilResetMs": 3720000},
            {"label": "Claude-3", "remainingPercentage": 0.902, "timeUntilResetMs": 120000}
        ]
    }))
    
    # Mock AI credits file
    credits_file = tmp_path / "g1_credits.txt"
    credits_file.write_text("150.50")
    
    original_open = open
    original_exists = os.path.exists
    original_getsize = os.path.getsize

    def mock_exists(p):
        path_str = str(p)
        if "antigravity_quota_cache.json" in path_str or "g1_credits.txt" in path_str:
            return True
        return original_exists(p)

    def mock_getsize(p):
        path_str = str(p)
        if "antigravity_quota_cache.json" in path_str:
            return original_getsize(cache_file)
        return original_getsize(p)

    def mock_open(p, *args, **kwargs):
        path_str = str(p)
        if "antigravity_quota_cache.json" in path_str:
            return original_open(cache_file, *args, **kwargs)
        elif "g1_credits.txt" in path_str:
            return original_open(credits_file, *args, **kwargs)
        return original_open(p, *args, **kwargs)

    with patch("scripts.statusline.get_stdin_nonblocking", return_value=stdin_json), \
         patch("scripts.statusline.find_project_name", return_value="Proj"), \
         patch("scripts.statusline.get_git_branch", return_value="master"), \
         patch("os.path.exists", side_effect=mock_exists), \
         patch("os.path.getsize", side_effect=mock_getsize), \
         patch("builtins.open", MagicMock(side_effect=mock_open)), \
         patch("os.environ.get", return_value=""):
        
        main()
        captured = capsys.readouterr()
        
        # Verify custom layout with colors is printed
        assert "[Proj] master | " in captured.out
        assert "Model: Mock-Gemini" in captured.out
        assert "Context: 1.2M/2.0M / " in captured.out
        assert "800% to Degrading (Critical)" in captured.out
        assert "Gemini: 85%" in captured.out
        assert "Claude: 90%" in captured.out
