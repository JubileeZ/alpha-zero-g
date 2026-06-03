# Alpha-Zero-G

**The Foundational Agentic Harness for Python & R Analytics**

Alpha-Zero-G is a meta-project that acts as a **boilerplate generator and environment manager** for building analytics and statistical modeling projects alongside Agentic AIs (Antigravity, Cursor, Claude). 

Rather than serving as a software codebase itself, it provides the scripts, templates, and baseline rules to rapidly scaffold and continuously upgrade downstream AI workspaces.

---

## 1. Global Device Setup

Run this once per physical machine (Mac or Windows) to configure your global `~/.gemini/` settings, ensuring that your Antigravity or AI tool configurations are correctly synced to this harness's best practices.

```bash
bash scripts/setup-device.sh
# OR on Windows: .\scripts\setup-device.ps1
```

---

## 2. Scaffold a New Project

Use the scaffolding tool to instantly generate a pristine workspace for your next idea (e.g. FPL Model or Crypto Bot). It automatically builds the canonical folder structure, deploys AI rules (`AGENTS.md`), copies custom `.agents/skills/`, and initializes Git.

```bash
# Usage: bash scripts/scaffold-project.sh <destination-path> "[Project Name]" <type: python|r|hybrid>
bash scripts/scaffold-project.sh ../My-New-Project "My New Analytics Project" python
```

Once bootstrapped, navigate to the new project and initialize dependencies:
```bash
cd ../My-New-Project
uv sync
```

---

## 3. Upgrade Existing Projects

As Alpha-Zero-G's core rules and templates evolve, you can push updates from this repository to your downstream projects without overwriting your project-specific domain code or logic.

```bash
# Usage: bash scripts/upgrade-project.sh <path-to-existing-project>
bash scripts/upgrade-project.sh ../My-New-Project
```

*(Note: All scripts have `.ps1` equivalents for native Windows PowerShell execution).*
