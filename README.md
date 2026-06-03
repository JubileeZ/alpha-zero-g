# Alpha-Zero-G

**The Foundational Agentic Harness for Python & R Analytics**

Alpha-Zero-G is a meta-project that acts as a **boilerplate generator and environment manager** for building analytics and statistical modeling projects alongside Agentic AIs (Antigravity, Cursor, Claude). 

Rather than serving as a software codebase itself, it provides the scripts, templates, and baseline rules to rapidly scaffold and continuously upgrade downstream AI workspaces.

---

## 1. Global Device Setup

Run this once per physical machine (Mac or Windows) to configure your global `~/.gemini/` settings, ensuring that your Antigravity or AI tool configurations are correctly synced to this harness's best practices.

### All Platforms (Mac, Linux, Windows)
```bash
uv run python scripts/setup-device.py
```

---

## 2. Scaffold a New Project

Use the scaffolding tool to instantly generate a pristine workspace for your next idea (e.g. FPL Model or Crypto Bot). It automatically builds the canonical folder structure, deploys AI rules (`AGENTS.md`), copies custom `.agents/skills/`, and initializes Git.

### All Platforms (Mac, Linux, Windows)
```bash
# Usage: uv run python scripts/scaffold.py <project-name> <python|r|hybrid> [destination-path]
uv run python scripts/scaffold.py "My New Analytics Project" python ../My-New-Project
```

Once bootstrapped, navigate to the new project and initialize dependencies:
```bash
cd ../My-New-Project
uv sync
```

---

## 3. Upgrade Existing Projects

As Alpha-Zero-G's core rules and templates evolve, you can push updates from this repository to your downstream projects without overwriting your project-specific domain code or logic.

### All Platforms (Mac, Linux, Windows)
```bash
# Usage: uv run python scripts/upgrade-project.py
# Must be run from inside the target project directory
cd ../My-New-Project
uv run python ../Alpha-Zero-G/scripts/upgrade-project.py
```
