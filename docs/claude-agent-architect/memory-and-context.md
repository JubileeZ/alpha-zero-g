## Memory and Context

Every AI conversation operates within a finite context window. As the conversation grows, the system compresses earlier turns to make room for new content. The compression is lossy. Architectural decisions documented in turn 3 may not survive to turn 15.

### The Three Mechanisms of Multi-Turn Collapse

The MSR/Salesforce study identified three independent mechanisms, each requiring a different intervention:

Mechanism | What Happens | Intervention  
---|---|---  
**Context compression** | Earlier information discarded to fit new content | State checkpointing to filesystem  
**Reasoning coherence loss** | Model contradicts its own earlier decisions across turns | Fresh-context iteration (Ralph loop)  
**Coordination failure** | Multiple agents hold different state snapshots | Shared state protocols between agents  
  
### Strategy 1: Filesystem as Memory

The most reliable memory across context boundaries lives in the filesystem. Claude Code reads `CLAUDE.md` and memory files at the start of every session and after every compaction.

```
~/.claude/
├── configs/           # 14 JSON configs (thresholds, rules, budgets)
│   ├── deliberation-config.json
│   ├── recursion-limits.json
│   └── consensus-profiles.json
├── hooks/             # 95 lifecycle event handlers
├── skills/            # 44 reusable knowledge modules
├── state/             # Runtime state (recursion depth, agent lineage)
├── handoffs/          # 49 multi-session context documents
├── docs/              # 40+ system documentation files
└── projects/          # Per-project memory directories
    └── {project}/memory/
        └── MEMORY.md  # Always loaded into context
``` 

The `MEMORY.md` file captures errors, decisions, and patterns across sessions. When you discover that `((VAR++))` fails with `set -e` in bash when VAR is 0, you record it. Three sessions later, when you encounter a similar integer edge case in Python, the MEMORY.md entry surfaces the pattern.

**Auto Memory (v2.1.32+):** Claude Code automatically records and recalls project context. As you work, Claude writes observations to `~/.claude/projects/{project-path}/memory/MEMORY.md`. Auto memory loads the first 200 lines into your system prompt at session start. Keep it concise and link to separate topic files for detailed notes.

**Memory curation over memory volume (May 2026):** A recent arXiv preprint on LLM-agent cooperation frames expanded recall as a possible failure mode: in the authors’ experiments, longer visible history degraded cooperation in 18 of 28 model-game settings. Treat this as a design warning, not a finished law. The production rule is already clear enough: keep `MEMORY.md` short, link out to details, and put decision-ready summaries in handoffs. Raw transcript dumps, tool logs, and long recall feeds belong in searchable storage, not automatically in the active prompt.

### Strategy 2: Proactive Compaction

Claude Code’s `/compact` command summarizes the conversation and frees context space while preserving key decisions, file contents, and task state.

**When to compact:** \- After completing a distinct subtask (feature implemented, bug fixed) \- Before starting a new area of the codebase \- When Claude starts repeating or forgetting earlier context \- Roughly every 25-30 minutes during intensive sessions

Custom compaction instructions in CLAUDE.md:

```
# Summary Instructions
When using compact, focus on:
- Recent code changes
- Test results
- Architecture decisions made this session
``` 

Compaction protects the conversation; the `/cd` command (Claude Code v2.1.169) protects the _prompt cache_. It moves a session to a new working directory mid-stream without breaking the cache that has accumulated over the turn. Before this, changing directories meant a fresh session and a cold cache. For a long-running session that pivots from one repository to a sibling — common in monorepo and multi-service work — `/cd` keeps the expensive cached prefix intact while repointing the filesystem context.

### Strategy 3: Session Handoffs

For tasks spanning multiple sessions, create handoff documents that capture the full state:

```
## Handoff: Deliberation Infrastructure PRD-7
**Status:** Hook wiring complete, 81 Python unit tests passing
**Files changed:** hooks/post-deliberation.sh, hooks/deliberation-pride-check.sh
**Decision:** Placed post-deliberation in PostToolUse:Task, pride-check in Stop
**Blocked:** Spawn budget model needs inheritance instead of depth increment
**Next:** PRD-8 integration tests in tests/test_deliberation_lib.py
``` 

The Status/Files/Decision/Blocked/Next structure provides the successor session with full context at minimal token cost. Starting a new session with `claude -c` (continue) or reading the handoff document goes straight to implementation.

### Strategy 4: Fresh-Context Iteration (The Ralph Loop)

For sessions exceeding 60-90 minutes, spawn a fresh Claude instance per iteration. State persists through the filesystem, not through conversational memory. Each iteration gets the full context budget:

```
Iteration 1: [200K tokens] -> writes code, creates files, updates state
Iteration 2: [200K tokens] -> reads state from disk, continues
Iteration 3: [200K tokens] -> reads updated state, continues
...
Iteration N: [200K tokens] -> reads final state, verifies criteria
``` 

Compare with a single long session:

```
Minute 0:   [200K tokens available] -> productive
Minute 30:  [150K tokens available] -> somewhat productive
Minute 60:  [100K tokens available] -> degraded
Minute 90:  [50K tokens available]  -> significantly degraded
Minute 120: [compressed, lossy]     -> errors accumulate
``` 

The fresh-context-per-iteration approach trades 15-20% overhead for the orient step (reading state files, scanning git history) against full cognitive resources per iteration. The cost-benefit calculation: for sessions under 60 minutes, a single conversation is more efficient. Beyond 90 minutes, fresh-context produces higher-quality output despite the overhead.

### Strategy 5: Managed Memory Curation (Dreaming)

Anthropic’s Claude Managed Agents added **Dreaming** as a Research Preview on May 6, 2026. Per Anthropic: “Dreaming is a scheduled process that reviews your agent sessions and memory stores, extracts patterns, and curates memories so your agents improve over time.”

Dreaming runs in the background between sessions, not on the critical path. It complements rather than replaces the filesystem-as-memory pattern: your `MEMORY.md` file remains the load-bearing surface; Dreaming writes curated memory entries into the Managed Agents memory store, which the agent reads at session start. The two patterns coexist for harnesses that mix self-hosted filesystem state with managed-side curation.

| Filesystem Memory | Dreaming (Managed)  
---|---|---  
**Where memory lives** | Your repo, version-controlled | Anthropic-managed memory store  
**When it updates** | You write entries by hand or via hooks | Background process between sessions  
**What it captures** | Decisions, errors, patterns you flag | Patterns extracted from session history  
**Best for** | Project-specific institutional knowledge | Cross-session pattern discovery you would not catch by hand  
  
Dreaming is in Research Preview, so behavior may change. The session-handoffs and CLAUDE.md patterns documented above remain the authoritative memory mechanism for self-hosted harnesses.

### The Anti-Patterns

**Reading entire files when you need 10 lines.** A single 2,000-line file read consumes 15,000-20,000 tokens. Use line offsets: `Read file.py offset=100 limit=20` saves the vast majority of that cost.

**Keeping verbose error output in context.** After debugging a bug, your context holds 40+ stack traces from failed iterations. A single `/compact` after fixing the bug frees that dead weight.

**Starting every session by reading every file.** Let Claude Code’s glob and grep tools find relevant files on demand, saving 100,000+ tokens of unnecessary pre-loading.

* * *
