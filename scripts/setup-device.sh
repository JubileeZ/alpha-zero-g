#!/usr/bin/env bash
set -euo pipefail

# Resolve paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST_PATH="$REPO_ROOT/templates/skills_manifest.txt"
GLOBAL_TEMPLATES_DIR="$REPO_ROOT/templates/global"
STATUSLINE_SRC="$SCRIPT_DIR/statusline.py"

script_OkCount=0

# Step 1: Clone mattpocock/skills to ~/.agent-skills/mattpocock/ (skip if exists)
echo -n "Step 1: Clone mattpocock/skills to ~/.agent-skills/mattpocock/... "
TARGET_SKILLS_DIR="$HOME/.agent-skills/mattpocock"
if [ -d "$TARGET_SKILLS_DIR" ]; then
    echo "SKIP"
else
    if git clone --depth 1 https://github.com/mattpocock/skills.git "$TARGET_SKILLS_DIR" >/dev/null 2>&1; then
        echo "OK"
        script_OkCount=$((script_OkCount + 1))
    else
        echo "FAIL"
    fi
fi

# Step 2: Physically copy the 10 selected skills (read from templates/skills_manifest.txt) to ~/.gemini/antigravity-cli/skills/ (create path if missing)
echo -n "Step 2: Copy selected skills to ~/.gemini/antigravity-cli/skills/... "
DEST_SKILLS_DIR="$HOME/.gemini/antigravity-cli/skills"
mkdir -p "$DEST_SKILLS_DIR"
if [ ! -f "$MANIFEST_PATH" ]; then
    echo "FAIL (manifest missing)"
else
    FAILED=0
    # Read manifest line by line
    while IFS= read -r skill || [ -n "$skill" ]; do
        # Strip comments and whitespace
        skill=$(echo "$skill" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$skill" ] && continue
        
        LOCAL_SRC_SKILL="$REPO_ROOT/templates/skills/$skill"
        DST_SKILL="$DEST_SKILLS_DIR/$skill"
        
        if [ -d "$LOCAL_SRC_SKILL" ]; then
            rm -rf "$DST_SKILL"
            cp -r "$LOCAL_SRC_SKILL" "$DST_SKILL"
        else
            # Search recursively in TARGET_SKILLS_DIR
            SRC_SKILL=$(find "$TARGET_SKILLS_DIR" -type d -name "$skill" -print -quit)
            if [ -n "$SRC_SKILL" ] && [ -d "$SRC_SKILL" ]; then
                rm -rf "$DST_SKILL"
                cp -r "$SRC_SKILL" "$DST_SKILL"
            else
                FAILED=1
            fi
        fi
    done < "$MANIFEST_PATH"
    
    if [ "$FAILED" -eq 0 ]; then
        echo "OK"
        script_OkCount=$((script_OkCount + 1))
    else
        echo "FAIL (some skills missing in source)"
    fi
fi

# Function to deploy global files
deploy_global_file() {
    local step_num="$1"
    local filename="$2"
    echo -n "Step $step_num: Deploy global $filename to ~/.gemini/$filename... "
    local src="$GLOBAL_TEMPLATES_DIR/$filename"
    local dest="$HOME/.gemini/$filename"
    
    mkdir -p "$HOME/.gemini"
    
    if [ ! -f "$src" ]; then
        echo "FAIL (source file missing)"
        return 1
    fi
    
    if [ -f "$dest" ]; then
        # Prompt before overwriting
        echo -n "File $dest already exists. Overwrite? (y/n): " >&2
        if read -r choice; then
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                cp "$src" "$dest"
                echo "OK"
                script_OkCount=$((script_OkCount + 1))
            else
                echo "SKIP"
            fi
        else
            echo "SKIP"
        fi
    else
        cp "$src" "$dest"
        echo "OK"
        script_OkCount=$((script_OkCount + 1))
    fi
}

# Step 3: Deploy global AGENTS.md
deploy_global_file 3 "AGENTS.md"

# Step 4: Deploy global GEMINI.md
deploy_global_file 4 "GEMINI.md"

# Step 5: Deploy global CLAUDE.md
deploy_global_file 5 "CLAUDE.md"

# Step 6: Copy scripts/statusline.py to ~/.agent-config/statusline.py
echo -n "Step 6: Copy statusline.py to ~/.agent-config/statusline.py... "
mkdir -p "$HOME/.agent-config"
if cp "$STATUSLINE_SRC" "$HOME/.agent-config/statusline.py"; then
    echo "OK"
    script_OkCount=$((script_OkCount + 1))
else
    echo "FAIL"
fi

# Step 7: Patch ~/.gemini/antigravity-cli/settings.json using an inline Python command block
echo -n "Step 7: Patch ~/.gemini/antigravity-cli/settings.json... "
if python3 -c "
import os, json
path = os.path.expanduser('~/.gemini/antigravity-cli/settings.json')
os.makedirs(os.path.dirname(path), exist_ok=True)
data = {}
if os.path.exists(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception:
        pass
if 'statusLine' not in data or not isinstance(data['statusLine'], dict):
    data['statusLine'] = {}
data['statusLine'].update({
    'type': 'custom',
    'command': 'python3 ~/.agent-config/statusline.py',
    'enabled': True
})
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2)
"; then
    echo "OK"
    script_OkCount=$((script_OkCount + 1))
else
    echo "FAIL"
fi

# Step 8: Verify by executing python3 ~/.agent-config/statusline.py and print stdout
echo -n "Step 8: Verify statusline execution... "
if [ -f "$HOME/.agent-config/statusline.py" ]; then
    if OUTPUT=$(python3 "$HOME/.agent-config/statusline.py" 2>/dev/null); then
        echo "OK"
        echo "Stdout: $OUTPUT"
        script_OkCount=$((script_OkCount + 1))
    else
        echo "FAIL (execution failed)"
    fi
else
    echo "FAIL (statusline.py not found)"
fi

# Step 9: Print exit summary: N/8 steps OK.
echo "Step 9: Exit summary: $script_OkCount/8 steps OK."
exit 0
