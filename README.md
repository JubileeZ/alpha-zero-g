# Alpha-Zero-G

**The Foundational Agentic Harness for Python & R Analytics**

Alpha-Zero-G is a highly engineered, cross-tool development environment (a "harness") designed for building analytics and statistical modeling projects alongside Agentic AIs (such as Antigravity, Cursor, and Claude Code). 

Rather than serving as a software codebase, it defines the structures, rules, and safety parameters that allow AI agents to work autonomously, safely, and continuously across sessions without regression.

---

## Harness Rule Hierarchy

This harness is built around a layered hierarchy of rule files that guide the AI's actions:

```
  SYSTEM RULES (Immutable Deepmind rules)
       ↓
  GEMINI.md (Antigravity-specific local/global overrides)
       ↓
  AGENTS.md (Cross-tool standard rules for Cursor/Claude/Gemini)
       ↓
  .agents/rules/*.md (Granular concern-scoped rules)
```

---

## Directory Structure

When cloned to start a new project, this harness establishes the following structure:

```
<project-root>/
│
├── AGENTS.md                    # Core cross-tool navigation map
├── GEMINI.md                    # Antigravity session-specific overrides
├── CONTEXT.md                   # Project glossary (domain-specific jargon)
│
├── features.json                # Structured feature requirements and status
├── progress.md                  # Human & Agent session state log
├── init.sh                      # Deterministic project bootstrap script
├── pyproject.toml               # Python dependencies (managed by uv)
│
├── .agents/
│   └── hooks.json               # Hard enforcement rules (blocking/confirmations)
│
└── docs/                        # Project System of Record
    ├── architecture.md          # Structural layers & data flow maps
    ├── beliefs.md               # Operating principles and decisions
    ├── quality.md               # Quality metrics & compliance tracking
    ├── DATA_DICT.md             # Columns, data types, and units dictionary
    ├── MODEL_NOTES.md           # Model assumptions and training states
    └── design/                  # Technical design documents
        └── INDEX.md             # Design document registry
```

---

## The Golden Path Developer Workflow

To ensure high-performance, deterministic development and perfect session continuity when pair-programming with AI agents, always follow the exact multi-phase cycle below:

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  1. BOOT  │ ──> │ 2. GRILL  │ ──> │  3. SPEC  │ ──> │ 4. SLICE  │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
                                                            │
┌───────────┐     ┌───────────┐     ┌───────────┐           ▼
│8. HANDOFF │ <── │7.REFACTOR │ <── │ 6. VERIFY │ <── │  5. SHIP  │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
```

### 1. BOOT (Session Startup)
* **Actions:** Open this workspace and run the idempotent local bootstrapper:
  ```bash
  bash init.sh
  ```
* **Why:** This synchronizes your virtual environment and runs smoke sensors to ensure a clean, green baseline before touching any files.

### 2. GRILL (Domain & Plan Alignment)
* **Command:** `/grill-with-docs` (general logic) or `/grill-analytics` (for statistical audits).
* **Actions:** Relentlessly stress-test your ideas. Identify edge cases, specify model objectives, align column/feature names with `docs/DATA_DICT.md`, and update your domain glossary `CONTEXT.md` inline. Record hard trade-offs in `docs/adr/`.
* **Example:** *"grilling the feature extraction parameters for FPL prediction to ensure zero lookahead bias."*

### 3. SPEC (Formal System Design)
* **Command:** `/spec-model`
* **Actions:** Propose and compile a comprehensive design specification inside `docs/design/` or `docs/MODEL_NOTES.md`. Get explicit approval on the interface, mathematical formulations, and validation splits before writing code.

### 4. SLICE (Tracer Bullet Slicing)
* **Command:** `/to-issues`
* **Actions:** Break the approved design spec down into thin, independent vertical slices (tracer bullets) that cut end-to-end through every layer (schema, code, tests). List these in `features.json`.

### 5. SHIP (TDD Execution)
* **Command:** `/tdd`
* **Actions:** Run the test-driven development loop (Red-Green-Refactor) for one slice at a time. Write a behavior-based test in `tests/`, watch it fail (Red), write minimal code to pass (Green), then refactor.
* **Troubleshooting:** If a hard bug or regression occurs, divert immediately to `/diagnose` to systematically reproduce, instrument, and fix.

### 6. VERIFY (Statistical & Sanity Checks)
* **Command:** `/validate-output`
* **Actions:** Conduct post-modeling validation checks. Assert output shape, check null counts, verify against naive baselines, and test model predictions for stationarity or leakage.

### 7. REFACTOR (Architecture Deepening)
* **Command:** `/improve-codebase-architecture`
* **Actions:** Clean up architectural coupling, extract duplication, move complexity behind deep modules, and verify all tests remain fully green.

### 8. HANDOFF (Session Transition)
* **Command:** `/handoff`
* **Actions:** Compact the current session's milestones, modified files, and next actions into the checklist in `progress.md` so the next session can orient and resume immediately.

---

## Getting Started

To initialize the project environment (whether on a local machine, or a fresh container / remote workspace), run:

```bash
bash init.sh
```

This bootstrap script will:
1. Detect and install the `uv` package manager if missing.
2. Synchronize Python virtual environments matching `pyproject.toml` (targeting Python 3.12).
3. Detect if R is used and initialize `renv` or `pak` package managers if statistical scripts are present.
4. Execute smoke tests to verify the system works before letting the agent make changes.

---

## Continuous Documentation Synchronization

To prevent documentation decay as development proceeds, the harness enforces a **Documentation Synchronisation Protocol** (detailed in `AGENTS.md` and custom skills). 

Whenever the agent finishes a feature slice, runs a backtest, or completes a modeling phase, it must automatically:
1. **Sync State:** Update `progress.md` (session logs) and `features.json` (requirements list).
2. **Update Specifications:** Capture architectural updates in `docs/beliefs.md`.
3. **Reflect Schemas:** Document new columns or boundaries in `docs/DATA_DICT.md`.
4. **Log Experiments:** Record training runs, loss curves, and backtest shapes in `docs/MODEL_NOTES.md`.

This ensures that any fresh AI session inherits an accurate, real-time map of the project's state.

---

## Bootstrapping a New Project (The User Journey)

Alpha-Zero-G comes with an automated project generator script `create-project.sh` located at the root. This script copies templates, builds the workspace directories, and automatically customizes paths and names for your new project.

### Quick Start: Bootstrapping a New Project

To create a new workspace (e.g., your FPL Model or Crypto Bot), run the following command from the root of the Alpha-Zero-G project:

```bash
bash create-project.sh <destination-path> "[Project Name]"
```

#### Example 1: Creating a Fantasy Premier League Model
Run this to bootstrap a new FPL model directory in your parent directory:
```bash
bash create-project.sh ../FPL-Model "Fantasy Premier League Score Projections"
```

---

### Step-by-Step User Journey

Once you execute the bootstrapping command above, complete the following three quick steps:

#### Step 1: Navigate and Initialize Environment
CD into your newly created directory and run the local bootstrapper script:
```bash
cd ../FPL-Model
bash init.sh
```
*This will automatically install `uv`, create a Python 3.12 virtual environment, sync your data science and ML packages, check for R environments, and run validation checks.*

#### Step 2: Customize Your Domain Context
Open your new project in your editor and customize these two files to reflect your new statistical focus:
- **`CONTEXT.md`**: Define your project's custom glossary (e.g., expected goals, order book, volatility).
- **`docs/DATA_DICT.md`**: Define your target prediction schemas and column requirements.

#### Step 3: Run the Initializer Agent
Start an AI coding session in the new folder and trigger the setup loop:
> *"I want to begin implementing our predictions model. Review AGENTS.md and let's run /grill-analytics to stress-test our approach."*

---

