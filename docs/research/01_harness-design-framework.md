# Alpha-Zero-G: Harness Design Framework
**Strategic Research & Theoretical Blueprint — v1.0**

Alpha-Zero-G is a foundational meta-project. Its goal is to design, test, and establish the golden standard for AI-assisted software and analytics development workflows. This document compiles our comprehensive research on the theoretical principles of **Harness Engineering**, memory architectures, token optimization, and agentic design patterns.

---

## Table of Contents

1. [The Paradigms: Prompt vs. Context vs. Harness Engineering](#1-the-paradigms-prompt-vs-context-vs-harness-engineering)
2. [The Foundational Formula & The ReAct Loop](#2-the-foundational-formula--the-react-loop)
3. [Antigravity Rule File Hierarchy](#3-antigravity-rule-file-hierarchy)
4. [Permissions: Policy vs. Hard Enforcement](#4-permissions-policy-vs-hard-enforcement)
5. [Token & Context Management Protocols](#5-token--context-management-protocols)
6. [Security Rules & The Willison "Lethal Trifecta"](#6-security-rules--the-willison-lethal-trifecta)
7. [Multi-Agent Architectures & Memory Systems](#7-multi-agent-architectures--memory-systems)
8. [High-Performance Analytics Package Stack](#8-high-performance-analytics-package-stack)
9. [Key Reference Material & Reading List](#9-key-reference-material--reading-list)

---

## 1. The Paradigms: Prompt vs. Context vs. Harness Engineering

Think of the three disciplines of AI assistance as nested layers, not competing alternatives. Each represents an evolutionary era in how developers collaborate with Large Language Models.

```
┌─────────────────────────────────┐
│      HARNESS ENGINEERING        │  ← 2026+  System-level (the rails & office)
│  ┌───────────────────────────┐  │
│  │    CONTEXT ENGINEERING    │  │  ← 2025   Session-level (the email attachments)
│  │  ┌─────────────────────┐  │  │
│  │  │  PROMPT ENGINEERING │  │  │  ← 2022   Message-level (the email text)
│  │  └─────────────────────┘  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### 1.1 Prompt Engineering (2022–2024)
*   **Definition:** Crafting the specific instruction set that elicits the best model response for a single turn.
*   **Best Practices:** Delineating inputs with XML tags (`<context>`, `<task>`), defining positive constraints ("do X" over "don't do Y"), requesting step-by-step reasoning, and providing negative examples.
*   **Limitation:** Fails on multi-step, complex software tasks since it is fundamentally stateless.

### 1.2 Context Engineering (2025)
*   **Definition:** Curating *which* information the agent has access to at each step across a session.
*   **Key Insight:** Larger context windows (e.g., 200k+ tokens) do not solve the problem. Models degrade in reasoning quality when bloated with irrelevant data (the "needle-in-a-haystack" degradation).
*   **Best Practices:** Establishing a dynamic dictionary (`docs/DATA_DICT.md`), maintaining a glossary (`CONTEXT.md`), exposing directory structures cleanly (`find`, `grep`), and utilizing modular, on-demand skills instead of heavy system instructions.

### 1.3 Harness Engineering (2026+)
*   **Definition:** Designing the entire *operating environment* an agent operates in—tools, memory systems, programmatic safety hooks, feedback loops, and multi-agent coordination.
*   **Key Insight:** Most "agent failures" are diagnosed at the wrong layer. Teams blame the prompt or model when the failure was actually caused by a weak harness lacking execution sensors, linting gates, retry strategies, or state tracking.

---

## 2. The Foundational Formula & The ReAct Loop

### 2.1 The Formula

The effectiveness of an autonomous coding assistant is defined by:

$$\text{Output Quality} = \text{Model} \times \text{Harness}$$

> **SWE-bench Takeaway:** Changing *only* the harness scaffolding (giving the agent structured testing loops, directory maps, and recovery commands) resulted in up to a **22+ point performance swing** on SWE-bench using the exact same LLM weights. The harness accounts for more variance in output quality than the model's parameters alone.

### 2.2 The ReAct Loop (Thought → Action → Observation)

Every modern agentic interface runs a variation of the Reason-Act cycle:

```
Thought  → "What is my goal and what tool do I need next?"
Action   → "Call a tool (e.g. read_file, run_command)."
Observation → "Analyze the terminal output, build logs, or test errors."
Thought  → "What did this tell me? How do I adjust my plan?"
```

---

## 3. Antigravity Rule File Hierarchy

Antigravity consolidates and merges multiple configuration sources at session start. Understanding the precedence prevents configuration collisions:

```
   SYSTEM RULES (DeepMind Immutable Baseline — cannot be modified)
        ↓
   GEMINI.md (Antigravity-specific overrides — highest user priority)
        ↓
   AGENTS.md (Cross-tool shared rules — read by Antigravity, Claude Code, Cursor)
        ↓
   .agents/rules/*.md (Workspace supplements — organized by concern)
        ↓
   Nested AGENTS.md (Scoped strictly to specific folders)
```

*   **Global vs. Workspace Scope:**
    *   **Global (`~/.gemini/`):** Contains preferences that should be true across *all* projects on a developer's machine (personal styling choices, stuck-recovery rules, safety overrides).
    *   **Workspace (`<project-root>/`):** Scoped strictly to the active repository (domain rules, path schemas, architectural limits).

---

## 4. Permissions: Policy vs. Hard Enforcement

One of the most important harness engineering principles is distinguishing **behavioral policy** from **programmatic enforcement**.

| Mechanism | Type | How it Works | Reliability |
|---|---|---|---|
| **`AGENTS.md` Permissions** | Behavioral (Soft) | Prompt-based guidelines telling the LLM what it *should* do. | Probabilistic — The agent intends to follow policy but can make mistakes. |
| **OS File Permissions** | Enforced (Hard) | Operating System kernels blocking system writes. | Deterministic — Absolute enforcement. |
| **Antigravity Hooks** | Enforced (Hard) | JSON-defined lifecycle interceptors executing before/after tool calls. | Deterministic — Absolute enforcement. |

### 4.1 Recommended Denylist Enforcements
Rather than locking the agent in a highly restrictive allowlist that constantly breaks the engineering flow, utilize a **Default-Allow policy** with a strict **Denylist of dangerous operations** enforced programmatically via `.agents/hooks.json`:

1.  **Block Programmatically (Never Allow):**
    *   Force-pushing to protected branches (`git push --force`).
    *   Modifying internal `.git/` folder contents directly.
    *   Executing recursive deletions outside of `tmp/` or project-scoped test folders (`rm -rf /` or `rm -rf ~`).
    *   Exposing `.env` files or system secrets in chat logs.
2.  **Require Human-in-the-Loop (Interactive Confirmation):**
    *   Deleting any persistent source file (outside of standard scratch areas).
    *   Modifying project configurations under `config/` or harness rules under `.agents/`.
    *   Executing external API actions (such as sending production orders or altering remote servers).
    *   Installing software packages globally on the host OS.

---

## 5. Token & Context Management Protocols

Agent intelligence degrades rapidly as the active context window fills up with redundant data. Protect the context window via strict behavioral rails:

*   **Reference, Don't Embed:** Point to specific files and line numbers (e.g. `src/pipeline.py#L102-L140`) instead of copy-pasting code blocks in chat.
*   **Summarize Data:** NEVER output complete large DataFrames or raw matrices. Always use `.head(5)`, `.describe()`, and `.dtypes` to inspect schemas and distributions.
*   **Narrow Slices:** Work on one small, verifiable task at a time. Do not attempt to refactor multiple separate components in a single session.
*   **Context Health Thresholds:**
    *   `< 40%:` ✅ Healthy — continue normal development.
    *   `40-60%:` ⚠️ Watch — begin summarizing completed milestones and preparing for transition.
    *   `60-70%:` 🔶 High — compress session logs, avoid repetitive terminal output, and rely strictly on file writes.
    *   `> 70%:` 🔴 Critical — output quality begins to degrade; finalize the current step, update progress logs, and request a session compaction.

---

## 6. Security Rules & The Willison "Lethal Trifecta"

### 6.1 The Lethal Trifecta (Willison, 2026)
A security vulnerability is created whenever an AI agent has access to all three of the following capabilities simultaneously:

1.  **Processes Untrusted Input** (e.g., parsing third-party API payloads, scraping external web pages, reading user messages).
2.  **Accesses Sensitive Systems** (e.g., API keys, system environments, databases).
3.  **Can Modify State** (e.g., executing transactions, writing to production databases, deleting files).

### 6.2 The Rule of Two
To prevent unauthorized agent behavior or prompt injection attacks, the harness must enforce the **Rule of Two**: *Allow the agent at most two of the three legs of the Lethal Trifecta at any time.*
If all three are required, a **hard human-in-the-loop validation gate** must intercept the transaction.

---

## 7. Multi-Agent Architectures & Memory Systems

Complex engineering tasks are best solved by separating responsibilities across multiple coordinate agents.

*   **Sequential Subagents:** Used when subtasks touch shared repository states or sequential files. This avoids merge conflicts and ensures logical alignment.
*   **Parallel Subagents:** Excellent for independent, read-only tasks (e.g. researching three different external documentation sites or running separate lint checks).
*   **The Session Memory Standard:** Agents have no natural persistence between runs. Therefore, session state must be persisted as structured files in the repository:
    *   `progress.md` (active task lists and sequence logs) represents *working volatile memory*.
    *   `docs/adr/` (Immutable Architectural Decision Records) represents *long-term, immutable memory*.

---

## 8. High-Performance Analytics Package Stack

For data science, mathematical optimization, and machine learning projects, a pristine package stack ensures speed, validation, and typing safety:

```
┌────────────────────────────────────────────────────────┐
│                      APPLICATIONS                      │
│      (Downstream Modeling, FPL, Crypto Solvers)        │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│                      QUALITY GATES                     │
│   mypy (Typing)   pandera (Schemas)   pytest (Suite)   │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│                     ANALYTICS LAYER                    │
│      pandas (Core)   polars (Scale)   numpy (Math)     │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│                    FOUNDATION LAYER                    │
│    pydantic (Settings)   python-dotenv (Environment)   │
└────────────────────────────────────────────────────────┘
```

*   **Foundation:** `pydantic>=2.7.0` (settings/contracts) and `pydantic-settings` to enforce type-checked environment parameters.
*   **Data Validation:** `pandera>=0.20.0` to validate dataframe columns, data types, and values prior to modeling.
*   **Scale:** `polars>=0.20.0` for high-speed computation on datasets exceeding 1,000,000 rows.

---

## 9. Key Reference Material & Reading List

For further study into the design of advanced agent harnesses:

1.  **`mattpocock/skills` (GitHub):** The golden standard for formatting on-demand agent rules and tool specifications.
2.  **Anthropic Coding Trends Report:** Comprehensive benchmarks on harness setups showing prompt-bloat mitigation.
3.  **Google Codelabs: "Autonomous AI Developer Pipelines":** Detailed setups for programmatic rule integration with `AGENTS.md`.
4.  **`awesome-harness-engineering` (GitHub):** Curated list of production-grade agent environments and sandboxes.

---
*Alpha-Zero-G Strategy Document | Compiled 2026*
