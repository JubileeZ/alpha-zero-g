## The Harness Pattern

The harness is not a framework. It is a pattern: a composable set of files, scripts, and conventions that wrap an AI coding agent in deterministic infrastructure. The components:

```
┌──────────────────────────────────────────────────────────────┐
│                      THE HARNESS PATTERN                      │
├──────────────────────────────────────────────────────────────┤
│  ORCHESTRATION                                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │   Agent     │  │   Agent    │  │  Consensus │             │
│  │   Teams     │  │  Spawning  │  │  Validation│             │
│  └────────────┘  └────────────┘  └────────────┘             │
│  Multi-agent deliberation, parallel research, voting          │
├──────────────────────────────────────────────────────────────┤
│  EXTENSION LAYER                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Skills   │  │  Hooks   │  │  Memory  │  │  Agents  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│  Domain expertise, deterministic gates, persistent state,     │
│  specialized subagents                                        │
├──────────────────────────────────────────────────────────────┤
│  INSTRUCTION LAYER                                            │
│  ┌──────────────────────────────────────────────────────┐    │
│  │     CLAUDE.md  +  .claude/rules/  +  MEMORY.md       │    │
│  └──────────────────────────────────────────────────────┘    │
│  Project context, operational policy, cross-session memory    │
├──────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │           Main Conversation Context (LLM)             │    │
│  └──────────────────────────────────────────────────────┘    │
│  Your primary interaction; finite context; costs money        │
└──────────────────────────────────────────────────────────────┘
``` 

**Instruction Layer:** CLAUDE.md files and rules directories define what the agent knows about your project. They load automatically at session start and after every compaction. This is the agent’s long-term architectural memory.

**Extension Layer:** Skills provide domain expertise that auto-activates based on context. Hooks provide deterministic gates that fire on every matching tool call. Memory files persist state across sessions. Custom agents provide specialized subagent configurations.

**Orchestration Layer:** Multi-agent patterns coordinate independent agents for research, review, and deliberation. Spawn budgets prevent runaway recursion. Consensus validation ensures quality.

The key insight: most users work entirely in the Core Layer, watching context bloat and costs climb. Power users configure the Instruction and Extension layers, then use the Core Layer only for orchestration and final decisions.

### Managed vs. Self-Hosted Harnesses (April 2026)

Throughout early 2026, the “build your own harness” path was the only real option. In April 2026, that changed. Anthropic shipped **Claude Managed Agents** in public beta (April 8): harness loop + tool execution + sandbox container + state persistence as a REST API, billed at standard tokens plus $0.08/session-hour. OpenAI’s **Agents SDK** update (April 16) formalized the same split — harness and compute as separate layers, with native sandbox providers (Blaxel, Cloudflare, Daytona, E2B, Modal, Runloop, Vercel) and snapshot/rehydrate for surviving container loss.

The deeper SDK surface for the OpenAI side landed in `openai-agents` **Python v0.14.0** (released April 15, 2026; announced April 16): a `SandboxAgent` subclass of `Agent` with `default_manifest`, sandbox instructions, and capabilities; a `Manifest` describing the fresh-workspace contract (files, dirs, local files, Git repos, env, users, mounts); a `SandboxRunConfig` for per-run wiring of sandbox client, live session injection, manifest overrides, snapshots, and materialization concurrency limits. Built-in capabilities cover shell access, filesystem editing, image inspection, skills, sandbox memory, and compaction. Sandbox memory persists extracted lessons across runs and progressively discloses them; workspaces support local files, Git repo entries, and remote mounts (S3, R2, GCS, Azure Blob, S3 Files); snapshots are portable across providers. Backends: `UnixLocalSandboxClient`, `DockerSandboxClient`, and hosted clients for Blaxel, Cloudflare, Daytona, E2B, Modal, Runloop, and Vercel via optional extras.

For Python projects that want to embed the Claude Code runtime as a library — between “shell out to `claude`” and “REST API to Managed Agents” — **`claude-agent-sdk-python`** is the third option. The April 28-29 series (v0.1.69 → v0.1.71) bumped the bundled CLI to v2.1.123, raised the floor on the `mcp` dependency to `>=1.19.0` (older versions silently dropped `CallToolResult` returns from in-process MCP tools, leaving the model with a validation-error blob), and brought `SandboxNetworkConfig` to schema parity with the TypeScript SDK (`allowedDomains`, `deniedDomains`, `allowManagedDomainsOnly`, `allowMachLookup`).

If your harness includes a voice or realtime layer, `openai-agents-python` v0.17.0 (May 8, 2026) updated `RealtimeAgent` to default to `gpt-realtime-2`. Existing realtime sessions pick up the new default automatically; pin the previous model explicitly if you need to hold the old behavior for evaluation.

The architectural fork is now real:

Dimension | Self-hosted harness (this guide’s default) | Managed harness (Claude Managed Agents / OpenAI Agents SDK)  
---|---|---  
Operational burden | You run everything | Vendor runs loop, sandbox, state  
Customization | Total — your hooks, your skills, your memory | Bounded — vendor-defined extension points  
Cost model | Token + self-hosted compute | Token + runtime-hour premium  
State durability | You design it | Vendor checkpoints across disconnects  
Agent team orchestration | Build your own | Vendor-provided multi-agent coordination  
  
**When to pick which:** self-hosted remains right for teams that already have infrastructure muscle, want skills/hooks they control, or are optimizing a specific workflow deeply. Managed is right for teams without dedicated platform engineers, when time-to-value matters more than customization, or when agent runs need to survive laptop closures reliably without you building that persistence layer. The two are compatible — you can run a self-hosted harness that _delegates_ specific long-running tasks to Managed Agents via its REST API.

### What the Harness Looks Like on Disk

```
~/.claude/
├── CLAUDE.md                    # Personal global instructions
├── settings.json                # User-level hooks and permissions
├── skills/                      # Personal skills (44+)
│   ├── code-reviewer/SKILL.md
│   ├── security-auditor/SKILL.md
│   └── api-designer/SKILL.md
├── agents/                      # Custom subagent definitions
│   ├── security-reviewer.md
│   └── code-explorer.md
├── rules/                       # Categorized rule files
│   ├── security.md
│   ├── testing.md
│   └── git-workflow.md
├── hooks/                       # Hook scripts
│   ├── validate-bash.sh
│   ├── auto-format.sh
│   └── recursion-guard.sh
├── configs/                     # JSON configuration
│   ├── recursion-limits.json
│   └── deliberation-config.json
├── state/                       # Runtime state
│   ├── recursion-depth.json
│   └── agent-lineage.json
├── handoffs/                    # Session handoff documents
│   └── deliberation-prd-7.md
└── projects/                    # Per-project memory
    └── {project}/memory/MEMORY.md

.claude/                         # Project-level (in repo)
├── CLAUDE.md                    # Project instructions
├── settings.json                # Project hooks
├── skills/                      # Team-shared skills
├── agents/                      # Team-shared agents
└── rules/                       # Project rules
``` 

Every file in this structure serves a purpose. The `~/.claude/` tree is personal infrastructure that applies to all projects. The `.claude/` tree in each repository is project-specific and shared via git. Together, they form the complete harness.

* * *
