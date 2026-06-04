#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime

def compact_progress_content(content: str, keep_last: int = 5) -> tuple[list[str], str]:
    pattern = r"(## 1\. Milestones Completed\s*\n)(.*?)(?=\n## |\Z)"
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return [], content

    block = match.group(2)

    lines = block.splitlines()
    parsed_items = []
    current_subheading = ""
    
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("###"):
            current_subheading = stripped
        elif stripped.startswith("-") and not stripped.startswith("---"):
            parsed_items.append((current_subheading, line))

    if len(parsed_items) <= keep_last:
        return [], content

    to_archive_items = parsed_items[:-keep_last]
    to_keep_items = parsed_items[-keep_last:]

    archived_list = []
    for sub, item in to_archive_items:
        archived_list.append(item)

    kept_lines = []
    last_sub = None
    for sub, item in to_keep_items:
        if sub and sub != last_sub:
            kept_lines.append("")
            kept_lines.append(sub)
            kept_lines.append("")
            last_sub = sub
        kept_lines.append(item)

    new_block = "\n".join(kept_lines).strip() + "\n"
    
    start_idx = match.start(2)
    end_idx = match.end(2)
    new_content = content[:start_idx] + new_block + content[end_idx:]

    return archived_list, new_content

def main():
    current_dir = os.getcwd()
    while not os.path.exists(os.path.join(current_dir, "progress.md")) and current_dir != os.path.dirname(current_dir):
        current_dir = os.path.dirname(current_dir)
        
    progress_file = os.path.join(current_dir, "progress.md")
    if not os.path.exists(progress_file):
        print("Error: progress.md not found.")
        sys.exit(1)
        
    with open(progress_file, "r", encoding="utf-8") as f:
        content = f.read()
        
    archived, new_content = compact_progress_content(content, keep_last=5)
    
    if not archived:
        print("Nothing to archive (5 or fewer completed milestones).")
        sys.exit(0)
        
    archive_dir = os.path.join(current_dir, "docs", "archive")
    os.makedirs(archive_dir, exist_ok=True)
    
    date_str = datetime.now().strftime("%Y%m%d")
    archive_file = os.path.join(archive_dir, f"progress-{date_str}.md")
    
    archive_entry = f"\n\n### Archived on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n" + "\n".join(archived) + "\n"
    
    with open(archive_file, "a", encoding="utf-8") as f:
        f.write(archive_entry)
        
    with open(progress_file, "w", encoding="utf-8") as f:
        f.write(new_content)
        
    print(f"Successfully archived {len(archived)} items to {archive_file}.")

if __name__ == "__main__":
    main()