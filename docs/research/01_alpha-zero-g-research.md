# Alpha-Zero-G: Full Research Documentation
> **Session Date:** 2026-05-29
> **Purpose:** Foundational research for AI-assisted analytics & statistical projects
> **Author:** Compiled from agentic coding best practices research (2025–2026)

---

## Table of Contents

1. [The Agentic Coding Landscape](#1-the-agentic-coding-landscape)
2. [Mental Model: How Agentic Coding Works](#2-mental-model-how-agentic-coding-works)
3. [The Three Eras of AI Coding](#3-the-three-eras-of-ai-coding)
4. [Harness Engineering — The Core Concept](#4-harness-engineering--the-core-concept)
5. [Token Management — Deep Dive](#5-token-management--deep-dive)
6. [Memory Systems](#6-memory-systems)
7. [Multi-Agent Patterns & A2A](#7-multi-agent-patterns--a2a)
8. [Model Selection Guide](#8-model-selection-guide)
9. [Tools & Frameworks Landscape](#9-tools--frameworks-landscape)
10. [Google Antigravity Ecosystem](#10-google-antigravity-ecosystem)
11. [Analytics-Specific Best Practices](#11-analytics-specific-best-practices)
12. [Security Considerations](#12-security-considerations)
13. [Package Stack for Analytics](#13-package-stack-for-analytics)

---

## 1. The Agentic Coding Landscape

### What Is Agentic Coding?

Agentic coding is the paradigm shift from AI-as-autocomplete to AI-as-autonomous-developer.
Instead of suggesting the next line, an agent:
- Plans multi-step solutions
- Uses tools (file system, terminal, APIs)
- Executes code and observes results
- Iterates based on feedback
- Works toward a goal with minimal interruption

### Two Fundamental Approaches

| Approach | Description | When to Use |
|---|---|---|
| **Agent as a Tool** | Single LLM with tool-use in a loop | Simple to medium tasks, single-purpose automation |
| **Team of Agents** | Multiple specialized agents with defined roles | Complex, long-running tasks requiring verification |

### The Foundational Formula

```
Output Quality = Model × Harness
```

> Research shows the harness (everything around the model) accounts for **more variance
> than the model itself**. A 22+ point swing on SWE-bench was observed from changing
> only the scaffold, not the model.

---

## 2. Mental Model: How Agentic Coding Works

### The ReAct Loop (Foundation of All Agents)

Every AI coding agent — Claude Code, Cursor, Antigravity CLI — runs a variation of:

```
Thought  → What do I need to do next?
Action   → Call a tool (read file, run code, search)
Observation → See the result
Thought  → What does this tell me?
Action   → Next step...
```

### Agent = Model + Harness

```
┌─────────────────────────────────────────────┐
│                   HARNESS                   │
│                                             │
│  Rules Files    →  AGENTS.md, .cursorrules  │
│  Tools          →  MCP servers, APIs        │
│  Memory         →  Context + external files │
│  Feedback Loop  →  Linters, tests, judges   │
│  Security       →  Guardrails, approvals    │
│  Orchestration  →  Retry, error recovery    │
└─────────────────────────────────────────────┘
                      ↓
                   [ MODEL ]
```

### Why the Harness Matters More Than the Model

- Top 6 frontier models are within **1.3% of each other** on SWE-bench Verified
- The same model with basic vs optimized scaffold = **22+ point difference**
- Switching from Claude Opus to Gemini Pro matters less than fixing your harness

---

## 3. The Three Eras of AI Coding

| Era | Period | Core Question | Analogy | Key Failure Mode |
|---|---|---|---|---|
| **Prompt Engineering** | 2022–2024 | "What should I say?" | Writing the perfect email | Blind prompting, non-determinism |
| **Context Engineering** | 2025 | "What info should I provide?" | Managing your inbox | Context pollution, Lost-in-Middle |
| **Harness Engineering** | 2026+ | "What system should I build?" | Designing the email system | Orchestration bugs, security incidents |

### Key Insight: Each Era Subsumes the Previous

> Harness engineering contains context engineering, which contains prompt engineering.
> Good harness still requires good context, and good context still requires good prompts.
> They don't replace each other — they become nested layers.

### Where Rigor Lives in Each Era

- **Prompt Era:** In the prompt text itself
- **Context Era:** In the context window composition
- **Harness Era:** In the entire system architecture

---

## 4. Harness Engineering — The Core Concept

### The Four-Quadrant Model (Fowler/Böckeler 2026)

```
                    FEEDFORWARD (Pre-guidance)
                            │
          ┌─────────────────┼─────────────────┐
DETERMIN. │   GUIDES        │  COMPUTATIONAL  │ DETERMIN.
          │   AGENTS.md     │  Compilers      │
          │   .cursorrules  │  Type checkers  │
          │   Conventions   │  Linters        │
          ├─────────────────┼─────────────────┤
NON-DET.  │  SYSTEM PROMPTS │  INFERENTIAL    │ NON-DET.
          │  Role defs      │  LLM-as-judge   │
          │  Behavioral     │  Semantic review │
          │  constraints    │  Output scoring  │
          └─────────────────┼─────────────────┘
                            │
                    FEEDBACK (Post-correction)
```

### What Each Quadrant Does

| Quadrant | Purpose | Example |
|---|---|---|
| **Guides** | Steer agent away from bad directions before it starts | `AGENTS.md`: "use polars not pandas for >1M rows" |
| **Computational** | Mechanically catch mistakes after execution | `mypy` catches type errors, `pytest` catches regressions |
| **System Prompts** | Handle nuance deterministic rules can't capture | "Ask for confirmation when deleting data" |
| **Inferential** | Catch "code that runs but is semantically wrong" | Another LLM reviews statistical validity |

### Harness Design Principles

1. **Encode invariants as machine-enforced rules** — Don't write "handle nulls" in a comment. Write a `pandera` schema that fails loudly if nulls appear.
2. **Failures should be immediate and loud** — Silent errors become bigger problems later.
3. **The engineer's role changes** — From typing code to specifying intent and verifying results.
4. **Make the harness rippable** — As models improve, some harness logic becomes unnecessary. Design for easy removal.

### Anthropic's 3-Agent Architecture Pattern

For complex projects, splitting into specialized agents dramatically improves quality:

```
[PLANNER]      → Creates detailed product spec from high-level goal
     ↓
[GENERATOR]    → Implements feature by feature, self-evaluates each sprint
     ↓
[EVALUATOR]    → Runs automated tests, scores output, loops back if needed
     ↑_____________  (loop continues until quality threshold met)
```

> Cost note: Full 3-agent run ≈ 20x more expensive than solo agent.
> Quality improvement: incomparably better for complex features.

---

## 5. Token Management — Deep Dive

### Why Token Management Is Critical

- Context window has cognitive limits — accuracy drops sharply above ~40% full
- Cost scales with token usage (especially output tokens)
- KV-cache efficiency depends on stable prefixes
- Analytics projects face specific challenges: large data, long model outputs

### The Stable Prefix / Variable Suffix Architecture

```
Context Window
┌────────────────────────────────────┐  ← STABLE PREFIX (never change order)
│  System Prompt / AGENTS.md rules   │    KV-cache lives here
│  Project architecture summary      │    10x cost saving on cache hits
│  Tool definitions                  │    Put stable things FIRST
│  Long-term instructions            │
├────────────────────────────────────┤  ← VARIABLE SUFFIX (changes each turn)
│  Current task description          │    New info goes here
│  Relevant code snippets            │    Tool results go here
│  Recent conversation history       │    Latest observations go here
└────────────────────────────────────┘
```

### KV-Cache: The Production Metric That Matters

- When prefix matches previous call → computation reused (cache hit)
- On Claude Sonnet: cache hit = **10x cost reduction**
- **Even one token change in prefix invalidates entire downstream cache**
- Practical rule: Keep system prompts and tool definitions FIXED

### Token Budget Allocation

```
Recommended allocation per session:
├── System rules / AGENTS.md          ~5%
├── Architecture context               ~10%
├── Current task + relevant code       ~30%
├── Tool outputs / test results        ~20%
├── Working buffer (agent reasoning)   ~35%
└── Hard limit: NEVER exceed 70% ──── ⚠️ quality degrades above this
```

### Analytics-Specific Token Rules

| Rule | Why | Implementation |
|---|---|---|
| Never paste full DataFrames | Kills context instantly | Use `.head(5)`, `.describe()`, `.dtypes` |
| Reference files, don't embed | Context efficiency | "See /src/models/scorer.py line 45-67" |
| Use data summaries | Agent needs shape, not rows | Schema + sample + stats summary |
| Chunk long tasks | Prevents context bloat | One feature per session |
| Compress history | Old turns waste space | Summarize into `PROGRESS.md` |
| The 40% rule | Quality drops after 40% | Monitor `/usage` in Antigravity CLI |

### Context Compression Strategy

```
Session Start:
  Fresh context = AGENTS.md + ARCHITECTURE.md + PROGRESS.md
       ↓
During Session:
  Agent works; context fills up with conversation + tool results
       ↓
At ~60% context:
  Summarize completed work into working notes
  Drop old turns, keep summaries
       ↓
End of Session:
  Compress everything into PROGRESS.md
  New decisions → DECISIONS.md
  Git commit all changes
  Next session starts fresh from files
```

---

## 6. Memory Systems

### The Four Types of Agent Memory

| Type | Storage | Persistence | Best For |
|---|---|---|---|
| **In-Context (Working)** | Context window | Current session only | Active task, tool results |
| **File-Based (Persistent)** | Project files, git-tracked | Cross-session | Rules, decisions, progress |
| **Structured (State)** | JSON / SQLite / DB | Queryable | Trade history, signals, portfolio |
| **Semantic (Searchable)** | Vector DB | Similarity search | Code pattern retrieval (future) |

### Essential Memory Files

| File | Purpose | Update Frequency |
|---|---|---|
| `AGENTS.md` | Core rules, conventions, constraints | Rarely (stable prefix) |
| `ARCHITECTURE.md` | System design decisions + rationale | Per major decision |
| `PROGRESS.md` | Session-by-session work log | Every session |
| `DECISIONS.md` | Why specific approaches were chosen | Per key choice |
| `DATA_CONTRACTS.md` | Schema definitions, data sources | Per data source added |
| `MODEL_REGISTRY.md` | All models, versions, performance | Per model iteration |

### Memory Update Protocol

```
Agent Instruction Pattern:

"Before ending this session:
1. Append to PROGRESS.md: what was completed, what's next
2. If any design decision was made → append to DECISIONS.md
3. If any new data source or schema → update DATA_CONTRACTS.md
4. Commit all changes with message: 'session: [brief description]'"
```

### The Agent Amnesia Problem

> LLMs have anterograde amnesia — they cannot accumulate new knowledge
> after training. Each conversation starts from zero.
>
> Solution: External memory files are the agent's persistent brain.
> If it's not written to a file, it doesn't exist next session.

---

## 7. Multi-Agent Patterns & A2A

### Protocol Definitions

| Protocol | Full Name | Purpose | Direction |
|---|---|---|---|
| **MCP** | Model Context Protocol (Anthropic, Nov 2024) | Standardizes agent ↔ tool communication | Vertical |
| **A2A** | Agent-to-Agent Protocol (Google, Apr 2025) | Standardizes agent ↔ agent communication | Horizontal |

### MCP: The "USB Standard" for Tools

Before MCP, every tool integration was custom. MCP standardizes it:
- Slack, GitHub, databases, file systems → all via same protocol
- Build MCP server once → works with all MCP-compatible clients
- Adopted by: Claude, ChatGPT, Cursor, VS Code, Antigravity

### Multi-Agent Patterns (Complexity Order)

**Pattern 1: Single Agent + Tools**
```
User → Agent → [tool1, tool2, tool3] → Output
Best for: Most analytics work, FPL model development
When to use: Default starting point
```

**Pattern 2: Sequential Pipeline**
```
[Data Agent] → [Model Agent] → [Report Agent] → Output
Best for: Crypto signal pipeline (distinct stages)
When to use: When stages are clearly separable
```

**Pattern 3: Orchestrator + Specialists**
```
         [Orchestrator]
        /       |       [Data Spec] [Modeler] [Risk Mgr]
Best for: Complex multi-domain projects
When to use: When a single agent hits its limits
```

**Pattern 4: Swarm (OpenAI pattern)**
```
No central orchestrator — agents hand work to each other
Routine → Handoff → Routine → Handoff
Best for: Customer-facing workflows with domain routing
```

### Andrew Ng's Four Agentic Design Patterns

1. **Reflection** — Model critiques and revises its own output (key: different persona for review)
2. **Tool Use** — Model autonomously decides when to call external tools
3. **Planning** — Decompose complex tasks into subtasks (most brittle pattern)
4. **Multi-Agent** — Specialized agents collaborate (most potential, most complex)

> Key finding: "Wrapping GPT-3.5 in an agentic workflow outperforms
> GPT-4 zero-shot on certain benchmarks." — Andrew Ng, 2024

---

## 8. Model Selection Guide

### Current Benchmark Landscape (2026)

| Model | SWE-bench Verified | Best For | Cost (in/out per 1M) |
|---|---|---|---|
| Claude Opus 4.6 | 80.8% | Complex reasoning, large codebases | $5/$25 |
| Gemini 3.1 Pro | 80.6% | Price/performance, competitive coding | $2/$12 |
| GPT-5.4 | ~80% | Terminal/DevOps, computer use, speed | $2.50/$15 |
| Claude Sonnet 4.6 | 79.6% | Best Claude value | $3/$15 |
| DeepSeek V3.2 | 72-74% | Cheapest self-hosted | $0.28/$0.42 |

### Key Insight: Top 6 Models Within 1.3% of Each Other

> At the frontier, model selection matters less than harness quality.
> A mid-tier model in a great harness beats a frontier model in a bad one.

### Decision Framework for Your Projects

| Task Type | Recommended Model | Reason |
|---|---|---|
| FPL model architecture decisions | Claude Opus 4.6 | Best intent understanding, vague prompts |
| Bulk feature engineering code | Gemini 3.1 Pro | Cost-efficient at 80.6% SWE-bench |
| Statistical validation / code review | GPT-5.4 | Edge case detection, tool search |
| Crypto system design | Claude Opus 4.6 | Complex reasoning, safety awareness |
| High-volume signal generation | Gemini 3.1 Pro | Cost-efficient at scale |

### The Hybrid Workflow

```
New feature / architecture     →  Claude Opus 4.6
Bug fix / known issue          →  Gemini 3.1 Pro (cost-efficient)
Code review / edge cases       →  GPT-5.4
High-volume batch generation   →  Gemini 3.1 Pro
```

---

## 9. Tools & Frameworks Landscape

### Terminal-Based Agents

| Tool | Built By | Best For | Notes |
|---|---|---|---|
| **Antigravity CLI** | Google | Terminal-first, async subagents | Successor to Gemini CLI, built in Go |
| **Claude Code** | Anthropic | Autonomous coding, SWE-bench SOTA | Best agent scaffold (80.9%) |
| **Codex CLI** | OpenAI | Terminal, computer use, DevOps | 75.1% Terminal-Bench |
| **Aider** | Open source | Git-integrated development | Good for iterative coding |

### IDE-Based Agents

| Tool | Best For | Notes |
|---|---|---|
| **Antigravity IDE** | Full agentic IDE, Google ecosystem | Shared harness with CLI |
| **Cursor** | Codebase-wide editing, semantic search | 1.2B ARR, industry standard |
| **Windsurf** | Alternative to Cursor | Acquired by Cognition |
| **GitHub Copilot Agent** | VS Code integration | Good for IDE workflows |

### Multi-Agent Frameworks

| Framework | Style | Complexity | Best For |
|---|---|---|---|
| **LangGraph** | Graph-based orchestration | High | Fine-grained control |
| **AutoGen (Microsoft)** | Conversational multi-agent | Medium | Planner + Executor |
| **CrewAI** | Role-based agent teams | Low-Medium | Easy role definition |
| **OpenAI Agents SDK** | Swarm / Handoff | Medium | Production-ready |
| **Google ADK** | Google ecosystem | Medium | GCP-integrated |
| **Anthropic Agent SDK** | 3-agent architecture | Medium | Quality-focused |

---

## 10. Google Antigravity Ecosystem

### Platform Overview

Google Antigravity (announced Google I/O 2026, May 19) is the successor to Gemini CLI.
One unified agent-first development platform with four surfaces:

```
ANTIGRAVITY PLATFORM
       ↓
Shared Agent Harness (co-optimized with Gemini 3.5 Flash)
       ↓
┌──────────┬──────────┬──────────┬────────────┐
│  CLI     │  IDE     │  SDK     │  2.0 App   │
│ Terminal │ Editor   │ Custom   │ GUI/Desktop│
└──────────┴──────────┴──────────┴────────────┘
```

### The Four Surfaces

| Surface | Position | Best For |
|---|---|---|
| **Antigravity 2.0** | Desktop command center | Managing parallel agents, visualization |
| **Antigravity CLI** | Terminal cockpit | Keyboard-first devs, SSH/remote |
| **Antigravity IDE** | Full agentic editor | IDE-native development |
| **Antigravity SDK** | Programmable harness | Custom agent building |

### Migration from Gemini CLI

- Antigravity CLI available: May 19, 2026
- Gemini CLI consumer sunset: June 18, 2026
- Migration: One-time import of extensions, skills, settings

### Key CLI Commands for Analytics Workflow

```
/skills    → Register & invoke analytics skills
/agents    → View/manage background subagents
/tasks     → Monitor async work (model training)
/mcp       → Connect to external tools
/resume    → Continue previous session
/rewind    → Roll back to checkpoint
/usage     → Monitor token consumption (critical)
/permissions → Control file system access
/model     → Switch models mid-session
```

### Async Subagents — Analytics Game Changer

```
Main session: "Train FPL projection model"
     ↓ spawns background subagents
[Subagent A]: Cross-validation (background)
[Subagent B]: Feature importance plots (background)
[Subagent C]: Historical GW validation (background)
     ↓
Main session continues:
→ Work on transfer optimization solver
→ Subagents report back when done
```

---

## 11. Analytics-Specific Best Practices

### The Analytics Agent Loop

```
1. UNDERSTAND → Business question, data availability, success criteria
2. EXPLORE   → Data quality, distributions, relationships (schema first)
3. DESIGN    → Approach choice, metric definition BEFORE modeling
4. BUILD     → Iterative, test-driven, type-hinted
5. VALIDATE  → Statistical sanity, domain logic, edge cases
6. DOCUMENT  → Update PROGRESS.md, DECISIONS.md, compress session
```

### Data Handling Rules for Agents

```markdown
## AGENT DATA RULES (put in AGENTS.md)

- NEVER load full DataFrame into context — use .head(5), .describe(), .dtypes
- NEVER hardcode file paths — use config or environment variables
- NEVER assume data quality — always validate schema first with pandera
- NEVER skip null/missing value analysis before modeling
- ALWAYS define data contracts before writing transformation code
- ALWAYS use type hints for all function signatures
- ALWAYS write validation tests alongside transformation code
```

### Statistical Modeling Rules

```markdown
## AGENT MODELING RULES (put in AGENTS.md)

- NEVER evaluate model without pre-defined metrics (define first, evaluate second)
- NEVER leak future data into training features (time-series: strict temporal split)
- NEVER compare models without statistical significance testing
- NEVER deploy without baseline comparison (at minimum: mean predictor)
- ALWAYS document assumptions in function docstrings
- ALWAYS include confidence intervals / prediction intervals
- ALWAYS validate outputs against domain knowledge before returning
```

### FPL-Specific Considerations

- Points data is noisy — ensemble approaches outperform single models
- Fixture difficulty is a leading indicator — weight accordingly
- Injury/availability data requires daily refresh
- Budget constraint + transfer limit = constrained optimization problem
- Historical xG/xA data from FBref/Understat more reliable than FPL raw stats

### Crypto Trading Considerations

- Signals must be tested on out-of-sample data before any paper trading
- Transaction costs (fees + slippage) dramatically reduce theoretical returns
- Correlation between assets changes in crisis periods — test for regime changes
- API rate limits are real constraints — build retry logic from day one
- Order execution quality (slippage) must be modeled in backtests

---

## 12. Security Considerations

### The Lethal Trifecta (Willison 2026)

When an agent simultaneously has all three, a security incident is inevitable:

1. **Processes untrusted input** (external data, user input)
2. **Accesses sensitive systems** (API keys, databases, PII)
3. **Can modify state** (send orders, delete files, write to prod)

### The Rule of Two

Allow the agent **at most two** of the three simultaneously.
If all three are needed → **require human-in-the-loop approval**.

```
Example: Crypto Trading Agent

Read market data (1) + Execute orders (3)
→ Access sensitive keys (2) BLOCKED unless human approves

Read market data (1) + Access keys (2)
→ Execute orders (3) BLOCKED — read-only mode, no state change

Analysis mode: (1) + (2) allowed = signal generation only
Execution mode: ALL THREE = requires explicit human confirmation
```

### Prompt Injection Defense

Agents that process external content (web data, user messages, API responses)
are vulnerable to prompt injection — malicious content that hijacks agent behavior.

Mitigations:
- Separate context for untrusted content vs trusted instructions
- Validate all external data before processing
- Never allow external content to modify agent behavior rules
- Log all agent actions for audit

---

## 13. Package Stack for Analytics

### Recommended Stack (2026)

```
FOUNDATION
├── python = "^3.11"
├── pydantic          # Data contracts & API validation (v2)
└── python-dotenv     # Environment management

DATA LAYER
├── pandas            # Core data manipulation
├── polars            # High-performance (>1M rows)
├── numpy             # Numerical computing
└── pandera           # DataFrame schema validation ⭐

STATISTICAL / ML LAYER
├── scipy             # Statistical tests, distributions
├── statsmodels       # Time series, regression, econometrics
├── scikit-learn      # ML pipeline infrastructure
├── xgboost           # Gradient boosting
├── lightgbm          # Alternative gradient boosting
└── optuna            # Hyperparameter optimization

OPTIMIZATION (FPL Solver)
├── pulp              # Linear programming
├── ortools           # Google OR-Tools (more powerful)
└── scipy.optimize    # General optimization

VISUALIZATION
├── matplotlib        # Base plotting
├── seaborn           # Statistical plots
└── plotly            # Interactive dashboards

DATA PIPELINE
├── httpx             # Async API calls
├── tenacity          # Retry logic for APIs ⭐
└── pydantic          # Response validation

CRYPTO TRADING (Future)
├── ccxt              # Unified crypto exchange API ⭐
├── pandas-ta         # Technical indicators
└── vectorbt          # Vectorized backtesting ⭐

TESTING & QUALITY
├── pytest            # Test framework
├── pytest-cov        # Coverage reporting
├── hypothesis        # Property-based testing ⭐
└── pandera           # Data validation in tests

DEVELOPMENT TOOLS
├── ruff              # Linting + formatting (replaces flake8/black/isort) ⭐
├── mypy              # Type checking
├── pre-commit        # Git hooks automation
└── ipykernel         # Jupyter support
```

### Why These Specific Choices

| Package | Why Critical |
|---|---|
| `pandera` | Validates DataFrame schemas — catches agent data errors mechanically |
| `hypothesis` | Generates edge case tests automatically — critical for statistical functions |
| `tenacity` | Handles API retries with exponential backoff — APIs always fail eventually |
| `ccxt` | Abstracts 100+ exchange APIs — crypto project won't be exchange-locked |
| `vectorbt` | Vectorized backtesting — 100x faster than loop-based approaches |
| `ruff` | Replaces 5 tools (flake8, black, isort, pyupgrade, pydocstyle) — fast and unified |
| `ortools` | Google's OR-Tools handles FPL solver constraints better than PuLP at scale |

---

*Document compiled from: Agentic Coding Ecosystem research (2025–2026), Anthropic Building Effective Agents guide, Google Antigravity I/O 2026 announcements, SWE-bench leaderboard data, Mitchell Hashimoto harness engineering research, Simon Willison agent security research, Andrew Ng agentic design patterns.*
