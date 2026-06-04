#!/usr/bin/env python3
import os
import re
from datetime import datetime

def compact_progress(project_root: str, keep_last: int = 5) -> bool:
    progress_file = os.path.join(project_root, "progress.md")
    archive_dir = os.path.join(project_root, "docs", "archive")
    archive_file = os.path.join(archive_dir, "progress-archive.md")

    if not os.path.exists(progress_file):
        print(f"Error: {progress_file} not found.")
        return False

    with open(progress_file, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the block between "## 2. Active Focus / Current Steps" and "---" or EOF
    pattern = r"(## 2\. Active Focus / Current Steps\s*\n)(.*?)(?=\n---|\Z)"
    match = re.search(pattern, content, re.DOTALL)
    
    if not match:
        print("Could not find Active Focus section.")
        return False
        
    block = match.group(2).strip()
    
    # Split by numbered items. Regex: lines starting with numbers like "1. ", "2. " followed by "**"
    items = re.split(r'\n(?=\d+\.\s+\*\*)', "\n" + block)
    # Remove empty first element if split creates it
    items = [i.strip() for i in items if i.strip()]
    
    if len(items) <= keep_last:
        print(f"Only {len(items)} items found. Nothing to archive.")
        return True
        
    to_archive = items[:-keep_last]
    to_keep = items[-keep_last:]
    
    # Ensure archive dir exists
    os.makedirs(archive_dir, exist_ok=True)
    
    date_str = datetime.now().strftime("%Y-%m-%d")
    archive_entry = f"\n\n### Archived on {date_str}\n\n" + "\n\n".join(to_archive) + "\n"
    
    with open(archive_file, "a", encoding="utf-8") as f:
        f.write(archive_entry)
        
    # Rebuild content
    new_block = "\n\n".join(to_keep)
    new_content = content[:match.start(2)] + new_block + "\n\n" + content[match.end(2):].lstrip()
    
    with open(progress_file, "w", encoding="utf-8") as f:
        f.write(new_content)
        
    print(f"Successfully archived {len(to_archive)} items to {archive_file}. Kept {len(to_keep)} items.")
    return True

if __name__ == "__main__":
    current_dir = os.getcwd()
    while not os.path.exists(os.path.join(current_dir, "progress.md")) and current_dir != os.path.dirname(current_dir):
        current_dir = os.path.dirname(current_dir)
    compact_progress(current_dir)
