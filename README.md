# Alpha-Zero-G

**The Foundational Agentic Harness for Python & R Analytics**

Alpha-Zero-G is a meta-project that acts as a **boilerplate generator and environment manager** for building analytics and statistical modeling projects alongside Agentic AIs (Antigravity, Cursor, Claude). 

Rather than serving as a software codebase itself, it provides the scripts, templates, and baseline rules to rapidly scaffold and continuously upgrade downstream AI workspaces.

---

## 1. Global Device Setup

Run this once per physical machine (Mac or Windows) to configure your global `~/.gemini/` settings, ensuring that your Antigravity or AI tool configurations are correctly synced to this harness's best practices.

### Mac / Linux
```bash
bash scripts/setup-device.sh
```

### Windows
Open a PowerShell terminal and run:
```powershell
.\scripts\setup-device.ps1
```

---

## 2. Scaffold a New Project

Use the scaffolding tool to instantly generate a pristine workspace for your next idea (e.g. FPL Model or Crypto Bot). It automatically builds the canonical folder structure, deploys AI rules (`AGENTS.md`), copies custom `.agents/skills/`, and initializes Git.

### Mac / Linux
```bash
# Usage: bash scripts/scaffold-project.sh <project-name> --type <python|r|hybrid> [destination-path]
bash scripts/scaffold-project.sh "My New Analytics Project" --type python ../My-New-Project
```

### Windows
```powershell
.\scripts\scaffold-project.ps1 -ProjectName "My New Analytics Project" -Type python -DestinationPath "..\My-New-Project"
```

Once bootstrapped, navigate to the new project and initialize dependencies:
```bash
cd ../My-New-Project
uv sync
```

---

## 3. Upgrade Existing Projects

As Alpha-Zero-G's core rules and templates evolve, you can push updates from this repository to your downstream projects without overwriting your project-specific domain code or logic.

### Mac / Linux
```bash
# Usage: bash scripts/upgrade-project.sh <path-to-existing-project>
bash scripts/upgrade-project.sh ../My-New-Project
```

### Windows
```powershell
.\scripts\upgrade-project.ps1 "..\My-New-Project"
```
