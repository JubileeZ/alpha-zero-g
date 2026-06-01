#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
from collections import defaultdict, deque

def run_command(cmd):
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return res.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error running command {' '.join(cmd)}: {e.stderr}", file=sys.stderr)
        return None

def main():
    # 1. Fetch open issues from GitHub
    cmd = ["gh", "issue", "list", "--state", "open", "--json", "number,title,body,labels", "--limit", "100"]
    output = run_command(cmd)
    if not output:
        print("Failed to fetch issues or no open issues found.")
        sys.exit(1)
        
    try:
        issues = json.loads(output)
    except Exception as e:
        print(f"Failed to parse issues JSON: {e}")
        sys.exit(1)
        
    # Map from issue number to issue info
    issue_map = {}
    epics = []
    ready_tasks = []
    all_tasks = []
    
    for issue in issues:
        num = issue["number"]
        title = issue["title"]
        labels = [l["name"] for l in issue.get("labels", [])]
        
        is_epic = "epic" in title.lower() or any("epic" in l.lower() for l in labels)
        is_ready = "ready-for-agent" in labels
        
        issue_info = {
            "number": num,
            "title": title,
            "body": issue.get("body") or "",
            "labels": labels,
            "is_epic": is_epic,
            "is_ready": is_ready
        }
        
        issue_map[num] = issue_info
        if is_epic:
            epics.append(num)
        else:
            all_tasks.append(num)
            if is_ready:
                ready_tasks.append(num)

    # 2. Parse dependencies for all tasks
    dependencies = defaultdict(set)
    dependents = defaultdict(set)
    
    for num in all_tasks:
        body = issue_map[num]["body"]
        blocked_by_section = ""
        match = re.search(r'(?:#+\s*(?:Blocked\s+by|Depends\s+on|Dependencies)[^\n]*)([\s\S]*?)(\n#|$)', body, re.IGNORECASE)
        if match:
            blocked_by_section = match.group(1)
        else:
            blocked_by_section = body
            
        if match:
            refs = re.findall(r'#(\d+)', blocked_by_section)
        else:
            refs = []
            for phrase_match in re.finditer(r'(?:blocked\s+by|depends\s+on)\s*(?:[^\n]*?)#(\d+)', body, re.IGNORECASE):
                refs.append(phrase_match.group(1))
                
        for ref in refs:
            ref_num = int(ref)
            if ref_num in issue_map and ref_num != num and ref_num not in epics:
                dependencies[num].add(ref_num)
                dependents[ref_num].add(num)

    # Kahn's algorithm for topological sorting of ready tasks
    in_degree = {num: len(dependencies[num]) for num in ready_tasks}
    queue = deque([num for num in ready_tasks if in_degree[num] == 0])
    
    layers = []
    visited = set()
    
    while queue:
        layer = []
        for _ in range(len(queue)):
            num = queue.popleft()
            layer.append(num)
            visited.add(num)
        layers.append(layer)
        
        next_candidates = []
        for num in layer:
            for dep in dependents[num]:
                if dep in ready_tasks and dep not in visited:
                    in_degree[dep] -= 1
                    if in_degree[dep] == 0:
                        next_candidates.append(dep)
        next_candidates.sort()
        queue.extend(next_candidates)
        
    unvisited = [num for num in ready_tasks if num not in visited]
    
    # Separate circular dependencies from issues blocked by non-ready tasks
    blocked_by_non_ready = []
    circular = []
    for num in unvisited:
        non_ready_blockers = [b for b in dependencies[num] if b not in ready_tasks]
        if non_ready_blockers:
            blocked_by_non_ready.append((num, non_ready_blockers))
        else:
            circular.append(num)
            
    # 3. Format Output
    out = []
    out.append("# Dependency Flow Plan (DFP)")
    out.append("\nThis plan organizes active ready-for-agent issues into parallel execution layers.")
    
    if epics:
        out.append("\n## Active Epics")
        for epic_num in epics:
            info = issue_map[epic_num]
            out.append(f"- **Issue #{epic_num}**: {info['title']}")
            
    out.append("\n## Parallel Execution Layers")
    for i, layer in enumerate(layers):
        out.append(f"\n### Layer {i+1} (Run in Parallel)")
        out.append("Issues in this layer are ready for agent and have no outstanding blockers:")
        for num in layer:
            info = issue_map[num]
            blockers_str = ""
            if dependencies[num]:
                blockers_str = " (after " + ", ".join(f"#{b}" for b in sorted(dependencies[num])) + ")"
            out.append(f"- [ ] **Issue #{num}**: {info['title']}{blockers_str}")
            
    if blocked_by_non_ready:
        out.append("\n## ⏳ Blocked by Non-Ready Issues")
        out.append("The following issues are labeled `ready-for-agent` but depend on open issues that are NOT yet ready:")
        for num, blockers in sorted(blocked_by_non_ready):
            info = issue_map[num]
            blockers_str = ", ".join(f"#{b}: {issue_map[b]['title']}" for b in sorted(blockers))
            out.append(f"- **Issue #{num}**: {info['title']} (Blocked by: {blockers_str})")
            
    if circular:
        out.append("\n## ⚠️ Warning: Circular Dependencies Detected")
        out.append("The following ready issues have circular dependencies and could not be layered:")
        for num in sorted(circular):
            info = issue_map[num]
            blockers = sorted(dependencies[num])
            out.append(f"- **Issue #{num}**: {info['title']} (Blocked by: {', '.join(f'#{b}' for b in blockers)})")
            
    # 4. Generate Mermaid Diagram for ready and blocker tasks
    scheduled_set = visited.union(unvisited)
    all_related_tasks = set(scheduled_set)
    for num in scheduled_set:
        all_related_tasks.update(dependencies[num])
        
    out.append("\n## Dependency Graph (Mermaid)")
    out.append("```mermaid")
    out.append("graph TD")
    out.append("  %% Define nodes")
    for num in sorted(all_related_tasks):
        info = issue_map[num]
        title_esc = info['title'].replace('"', '\\"')
        if info["is_ready"]:
            out.append(f'  I{num}["#{num}: {title_esc}"]')
        else:
            out.append(f'  I{num}["#{num} (NOT READY): {title_esc}"]:::notready')
            
    out.append("\n  %% Define dependencies")
    has_edges = False
    for num in sorted(scheduled_set):
        for blocker in sorted(dependencies[num]):
            out.append(f"  I{blocker} --> I{num}")
            has_edges = True
            
    out.append("\n  %% Styles")
    out.append("  classDef notready fill:#f9f,stroke:#333,stroke-width:2px,stroke-dasharray: 5 5;")
    if not has_edges:
        out.append("  %% No dependencies found. All ready issues can run in parallel!")
    out.append("```")
    
    output_str = "\n".join(out) + "\n"
    
    # Print to stdout
    print(output_str, end="")
    
    # Write to dependency_flow_plan.md in workspace root
    try:
        root_dir = os.path.abspath(os.getcwd())
        while True:
            if os.path.exists(os.path.join(root_dir, "AGENTS.md")) or os.path.exists(os.path.join(root_dir, ".git")):
                break
            parent = os.path.dirname(root_dir)
            if parent == root_dir:
                root_dir = os.path.abspath(os.getcwd())
                break
            root_dir = parent
            
        plan_path = os.path.join(root_dir, "dependency_flow_plan.md")
        with open(plan_path, "w") as f:
            f.write(output_str)
    except Exception as e:
        print(f"\nWarning: Failed to write dependency_flow_plan.md: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
