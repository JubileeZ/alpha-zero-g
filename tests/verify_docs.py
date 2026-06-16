#!/usr/bin/env python3
import os
import re
import sys

DOCS_DIR = "/Users/jubilee/Alpha-Zero-G/docs/antigravity-agent-architect"
ROUTER_FILE = "/Users/jubilee/Alpha-Zero-G/docs/antigravity-agent-architecture.md"

def check_file_exists(path, referrer):
    if not os.path.exists(path):
        print(f"ERROR: Broken link in {referrer} -> {path} does not exist.")
        return False
    return True

def verify_links(file_path):
    success = True
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Match markdown links like [text](link)
    # Ignore absolute web URLs starting with http/https
    links = re.findall(r'\[([^\]]+)\]\(([^)]+)\)', content)
    for text, link in links:
        # Ignore external links, mailto, etc.
        if link.startswith(("http://", "https://", "mailto:", "#")):
            continue
        
        # Strip anchor from internal links
        target = link.split("#")[0]
        if not target:
            continue
        
        # Link is relative to the file's directory
        target_path = os.path.normpath(os.path.join(os.path.dirname(file_path), target))
        if not check_file_exists(target_path, file_path):
            success = False
            
    return success

def verify_keywords(file_path):
    success = True
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    for i, line in enumerate(lines, 1):
        # Allow mentions of Claude in differences/comparison/migration contexts
        # but warn about general untranslated Claude references
        lower_line = line.lower()
        if "claude" in lower_line or ".claude" in lower_line or "claude.md" in lower_line:
            # Check if this is a comparison table or difference section
            if any(term in lower_line for term in ["difference", "vs", "comparison", "migrat", "port", "blake"]):
                continue
            # Also allow references to "Claude Code" in index.md / differences page if clearly comparing
            print(f"WARNING: Potential untranslated Claude reference in {file_path}:{i} -> {line.strip()}")
            # We don't fail hard on warnings, but we should make sure they are checked.
            
    return success

def main():
    success = True
    
    if not os.path.exists(DOCS_DIR):
        print(f"ERROR: docs directory does not exist: {DOCS_DIR}")
        sys.exit(1)
        
    if not os.path.exists(ROUTER_FILE):
        print(f"ERROR: router file does not exist: {ROUTER_FILE}")
        sys.exit(1)
        
    # Verify router links
    print(f"Verifying router links: {ROUTER_FILE}")
    if not verify_links(ROUTER_FILE):
        success = False
        
    # Verify each markdown file in docs directory
    files = [f for f in os.listdir(DOCS_DIR) if f.endswith(".md")]
    if not files:
        print(f"ERROR: No markdown files found in {DOCS_DIR}")
        success = False
        
    for f in files:
        full_path = os.path.join(DOCS_DIR, f)
        print(f"Verifying {full_path}")
        if not verify_links(full_path):
            success = False
        if not verify_keywords(full_path):
            # We don't block on keyword warning but print it
            pass
            
    if success:
        print("SUCCESS: All internal links are valid.")
        sys.exit(0)
    else:
        print("FAILED: Link or content verification errors found.")
        sys.exit(1)

if __name__ == "__main__":
    main()
