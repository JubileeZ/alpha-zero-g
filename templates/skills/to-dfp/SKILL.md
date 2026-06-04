---
name: to-dfp
description: Generates a parallel execution dependency flow plan (DFP) from active GitHub issues. Use when the user wants to organize, layer, or plan the execution sequence of open issues or wants to generate a dependency flow plan.
readOnlyHint: true
---

# Dependency Flow Planner (to-dfp)

## Quick start

Generate the dependency flow plan for the active workspace:

```bash
python3 ~/.gemini/antigravity-cli/skills/to-dfp/scripts/dfp_planner.py
```

## Workflows

### 1. Fetch & Map Active Issues
1. Run the `dfp_planner.py` script.
2. The script queries open issues using `gh` CLI, extracts blockers from `Blocked by` or `Depends on` body sections, and ignores already closed dependencies.
3. Kahn's topological sort layers issues by parallel execution order.

### 2. Output the Sequence
The planner outputs:
- **Active Epics**: List of major epics.
- **Parallel Execution Layers**: Groups of issues that can run in parallel without blockers.
- **Mermaid Dependency Graph**: Visual flowchart of the execution graph.

### 3. Share & Execute
Provide the generated Markdown to the user or save it as an artifact (`dependency_flow_plan.md`) to share with orchestrator and subagents.
