## The Harness Pattern

The harness is not a framework. It is a pattern: a composable set of files, scripts, and conventions that wrap an AI coding agent in deterministic infrastructure. The components:

```
┌──────────────────────────────────────────────────────────────┐
│                   THE ANTIGRAVITY HARNESS                     │
│├──────────────────────────────────────────────────────────────┤
│  ORCHESTRATION                                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  Parallel   │  │  Dynamic   │  │  Browser   │             │
│  │  Subagents  │  │  Planning  │  │  Subagent  │             │
│  └────────────┘  └────────────┘  └────────────┘             │
│  Multi-agent parallel work, on-demand spawning               │
│├──────────────────────────────────────────────────────────────┤
│  EXTENSION LAYER                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Skills   │  │  Hooks   │  │  MCP     │  │ Plugins  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  Domain expertise, deterministic gates, live context,         │
│  bundled tooling                                              │
│├──────────────────────────────────────────────────────────────┤
│  INSTRUCTION LAYER                                            │
│  ┌──────────────────────────────────────────────────────┐    │
│  │       GEMINI.md  +  AGENTS.md  +  .agents/skills/    │    │
│  └──────────────────────────────────────────────────────┘    │
│  Project context, agent policy, cross-session expertise       │
│├──────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │          Main Conversation Context (LLM)              │    │
│  └──────────────────────────────────────────────────────┘    │
│  Your primary interaction; finite context; costs quota        │
└──────────────────────────────────────────────────────────────┘
``` 

**Instruction Layer:** `GEMINI.md` and `AGENTS.md` define what the agent knows about your project. They load automatically at session start and after every compaction. This is the agent’s long-term architectural memory. `GEMINI.md` holds Antigravity-specific overrides and metadata, while `AGENTS.md` remains the cross-tool shared standard.

**Extension Layer:** Skills provide domain expertise that auto-activates based on context. Hooks provide deterministic gates that fire on every matching tool call. MCP configurations and plugins bundle functionality.

**Orchestration Layer:** Multi-agent patterns coordinate independent agents for research, review, and deliberation. Spawn budgets prevent runaway recursion. Consensus validation ensures quality. Subagents are spawned dynamically on demand rather than loaded from static config files.

The key insight: most users work entirely in the Core Layer, watching context bloat and quota limits climb. Power users configure the Instruction and Extension layers, then use the Core Layer only for orchestration and final decisions.

### Managed vs. Self-Hosted Harnesses

Throughout early 2026, the “build your own harness” path was the only real option. In April 2026, that changed. Antigravity CLI (`agy`) runs local orchestrator loops natively; no managed premium token-hour rate is required for baseline harnesses.

OpenAI’s **Agents SDK** update formalized the split — harness and compute as separate layers, with native sandbox providers (Blaxel, Cloudflare, Daytona, E2B, Modal, Runloop, Vercel) and snapshot/rehydrate for surviving container loss.

The deeper SDK surface for the OpenAI side landed in `openai-agents` **Python v0.14.0**: a `SandboxAgent` subclass of `Agent` with `default_manifest`, sandbox instructions, and capabilities; a `Manifest` describing the fresh-workspace contract (files, dirs, local files, Git repos, env, users, mounts); a `SandboxRunConfig` for per-run wiring of sandbox client, live session injection, manifest overrides, snapshots, and materialization concurrency limits. Built-in capabilities cover shell access, filesystem editing, image inspection, skills, sandbox memory, and compaction. Sandbox memory persists extracted lessons across runs and progressively discloses them.

For Python projects that want to embed an agentic runtime as a library, `antigravity-agent-sdk` provides local execution loops, sandbox environment configurations (`allowedDomains`, `deniedDomains`), and MCP server connections.

The architectural fork is now real:

Dimension | Self-hosted harness (this guide’s default) | Managed harness (OpenAI Agents SDK / Cloud Platforms)  
---|---|---  
Operational burden | You run everything | Vendor runs loop, sandbox, state  
Customization | Total — your hooks, your skills, your memory | Bounded — vendor-defined extension points  
Cost model | Token + self-hosted compute | Token + runtime-hour premium  
State durability | You design it | Vendor checkpoints across disconnects  
Agent team orchestration | Build your own | Vendor-provided multi-agent coordination  
  
**When to pick which:** self-hosted remains right for teams that already have infrastructure muscle, want skills/hooks they control, or are optimizing a specific workflow deeply. Managed is right for teams without dedicated platform engineers, when time-to-value matters more than customization, or when agent runs need to survive laptop closures reliably without you building that persistence layer. The two are compatible — you can run a self-hosted harness that _delegates_ specific long-running tasks to Managed Agents via its API.

### What the Harness Looks Like on Disk

```
~/.gemini/antigravity-cli/
├── GEMINI.md                    # Personal global instructions
├── hooks.json                   # User-level hooks and permissions
├── skills/                      # Personal skills
│   ├── code-reviewer/SKILL.md
│   ├── security-auditor/SKILL.md
│   └── api-designer/SKILL.md
├── hooks/                       # Hook scripts
│   ├── validate-shell.sh
│   ├── auto-format.sh
│   └── recursion-guard.sh
├── configs/                     # JSON configuration
│   ├── recursion-limits.json
│   └── deliberation-config.json
├── state/                       # Runtime state
│   ├── recursion-depth.json
│   └── agent-lineage.json
└── handoffs/                    # Session handoff documents
    └── deliberation-prd-7.md

.agents/                         # Project-level (in repo)
├── GEMINI.md                    # Project instructions
├── hooks.json                   # Project hooks config
├── skills/                      # Team-shared skills
└── hooks/                       # Project-level hooks
``` 

Every file in this structure serves a purpose. The `~/.gemini/antigravity-cli/` tree is personal infrastructure that applies to all projects. The `.agents/` tree in each repository is project-specific and shared via git. Together, they form the complete harness.

* * *
