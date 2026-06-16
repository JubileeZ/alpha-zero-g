## Decision Framework

When to use each mechanism:

Problem | Use | Why  
---|---|---  
Format code after every edit | **PostToolUse hook** | Must happen every time, deterministically  
Block dangerous bash commands | **PreToolUse hook** | Must block before execution, exit code 2  
Apply security review patterns | **Skill** | Domain expertise that auto-activates on context  
Explore codebase without polluting context | **Explore subagent** | Isolated context, returns summary only  
Run experimental refactoring safely | **Worktree-isolated subagent** | Changes can be discarded if they fail  
Review code from multiple perspectives | **Parallel subagents** or **Agent Team** | Independent evaluation prevents blind spots  
Decide on irreversible architecture | **Multi-agent deliberation** | Confidence trigger + consensus validation  
Persist decisions across sessions | **MEMORY.md** | Filesystem survives context boundaries  
Share team standards | **Project CLAUDE.md + .claude/rules/** | Git-distributed, loads automatically  
Define project build/test commands | **CLAUDE.md** | Command-first instructions the agent can verify  
Run long autonomous development | **Ralph loop** (fresh-context iteration) | Full context budget per iteration, filesystem state  
Notify Slack when session ends | **Async Stop hook** | Non-blocking, does not slow the session  
Validate quality before commit | **PreToolUse hook on git commit** | Block the commit if lint/tests fail  
Enforce completion criteria | **Stop hook** | Prevent agent from stopping before task is done  
  
### Skills vs Hooks vs Subagents

Dimension | Skills | Hooks | Subagents  
---|---|---|---  
**Invocation** | Automatic (LLM reasoning) | Deterministic (event-driven) | Explicit or auto-delegated  
**Guarantee** | Probabilistic (model decides) | Deterministic (always fires) | Deterministic (isolated context)  
**Context cost** | Injected into main context | Zero (runs outside LLM) | Separate context window  
**Token cost** | Description budget (1% of window, fallback 8,000 characters) | Zero | Full context per subagent  
**Best for** | Domain expertise | Policy enforcement | Focused work, exploration  
  
* * *
