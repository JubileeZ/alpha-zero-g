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

The most reliable memory across context boundaries lives in the filesystem. `agy` reads `GEMINI.md`, `AGENTS.md`, and skills config files at the start of every session.

```
~/.gemini/antigravity-cli/
├── configs/           # JSON configs (thresholds, rules, budgets)
│   ├── deliberation-config.json
│   ├── recursion-limits.json
│   └── consensus-profiles.json
├── hooks/             # lifecycle event handlers
├── skills/            # reusable knowledge modules
├── state/             # Runtime state
├── handoffs/          # multi-session context documents
└── docs/              # system documentation files
``` 

The files under `.agents/` and `~/.gemini/antigravity-cli/` capture errors, decisions, and patterns across sessions. State and policies are managed through explicitly updated `GEMINI.md` files, skills, and version-controlled handoff documents rather than an uncurated log.

### Strategy 2: Proactive Compaction

The `/compact` command summarizes the conversation and frees context space while preserving key decisions, file contents, and task state.

**When to compact:**
- After completing a distinct subtask (feature implemented, bug fixed)
- Before starting a new area of the codebase
- When the agent starts repeating or forgetting earlier context
- Roughly every 25-30 minutes during intensive sessions

Custom compaction instructions can be specified in `GEMINI.md`:

```markdown
# Summary Instructions
When using compact, focus on:
- Recent code changes
- Test results
- Architecture decisions made this session
``` 

The `/cd` command protects the prompt cache. It moves a session to a new working directory mid-stream without breaking the cache that has accumulated over the turn. Before this, changing directories meant a fresh session and a cold cache. For a long-running session that pivots from one repository to a sibling — common in monorepo and multi-service work — `/cd` keeps the expensive cached prefix intact while repointing the filesystem context.

### Strategy 3: Session Handoffs

For tasks spanning multiple sessions, create handoff documents that capture the full state:

```markdown
## Handoff: Deliberation Infrastructure PRD-7
**Status:** Hook wiring complete, 81 Python unit tests passing
**Files changed:** hooks/post-deliberation.sh, hooks/deliberation-pride-check.sh
**Decision:** Placed post-deliberation in PostToolUse:Task, pride-check in Stop
**Blocked:** Spawn budget model needs inheritance instead of depth increment
**Next:** PRD-8 integration tests in tests/test_deliberation_lib.py
``` 

The Status/Files/Decision/Blocked/Next structure provides the successor session with full context at minimal token cost.

### Strategy 4: Fresh-Context Iteration (The Ralph Loop)

For sessions exceeding 60-90 minutes, spawn a fresh instance per iteration. State persists through the filesystem, not through conversational memory. Each iteration gets the full context budget:

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

### The Anti-Patterns

*   **Reading entire files when you need 10 lines:** A single 2,000-line file read consumes 15,000-20,000 tokens. Use line offsets or grep to target reads.
*   **Keeping verbose error output in context:** After debugging a bug, your context holds 40+ stack traces from failed iterations. A single `/compact` after fixing the bug frees that dead weight.
*   **Starting every session by reading every file:** Let glob and grep tools find relevant files on demand, saving 100,000+ tokens of unnecessary pre-loading.

* * *
