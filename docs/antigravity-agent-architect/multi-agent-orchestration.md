## Multi-Agent Orchestration

Single-agent AI systems have a structural blind spot: they cannot challenge their own assumptions. Multi-agent deliberation forces independent evaluation from multiple perspectives before any decision locks.

> **Cross-tool orchestration:** Google open-sourced **Scion** — a multi-agent hypervisor that runs Antigravity CLI (`agy`), and other “deep agents” as concurrent processes, each with isolated container, git worktree, and credentials. Runs local, hub, or Kubernetes. Explicit philosophy: “isolation over constraints” — agents run with high autonomy inside boundaries enforced at the infrastructure layer, not in the prompt.
> 
> **Debate is not a silver bullet:** The M3MAD-Bench research cluster found that multi-agent debate plateaus and can be subverted by misleading consensus — valid arguments lose when other agents confidently assert the wrong answer. Tool-MAD improves this by giving each agent heterogeneous tool access and using Faithfulness/Relevance scores in the judge stage. If you’re building debate-style orchestration, invest in (a) tool heterogeneity per agent and (b) quantitative judge scoring rather than assuming more agents = better answers.

### Consensus and Verification via Dynamic Subagents

In Antigravity CLI, consensus validation is achieved by spawning parallel dynamic subagents on demand. A lead agent breaks a task into pieces and delegates each one to a specialized runtime instance. The outputs are verified by PreToolUse or Stop hooks returning structured stdout JSON.

The grader evaluations run in their own context windows so they are not influenced by the agent's reasoning.

### Minimum Viable Deliberation

Start with 2 agents and 1 rule: agents must evaluate independently before seeing each other’s work.

```
Decision arrives
  |
  v
Confidence check: is this risky, ambiguous, or irreversible?
  |
  +-- NO  -> Single agent decides (normal flow)
  |
  +-- YES -> Spawn 2 agents with different prompts
             Agent A: "Argue FOR this approach"
             Agent B: "Argue AGAINST this approach"
             |
             v
             Compare findings
             |
             +-- Agreement with different reasoning -> Proceed
             +-- Genuine disagreement -> Investigate the conflict
             +-- Agreement with same reasoning -> Suspect herding
``` 

This pattern covers 80% of the value. Everything else adds incremental improvement.

### The Confidence Trigger

Not every task needs deliberation. A confidence scoring module evaluates four dimensions:

  1. **Ambiguity** \- Does the query have multiple valid interpretations?
  2. **Domain complexity** \- Does it require specialized knowledge?
  3. **Stakes** \- Is the decision reversible?
  4. **Context dependency** \- Does it require understanding the broader system?

The score maps to three levels:

Level | Threshold | Action  
---|---|---  
HIGH | 0.85+ | Proceed without deliberation  
MEDIUM | 0.70-0.84 | Proceed with confidence note logged  
LOW | Below 0.70 | Trigger full multi-agent deliberation  
  
The threshold adapts by task type. Security decisions require 0.85 consensus. Documentation changes need only 0.50. This prevents over-engineering simple tasks while ensuring risky decisions get scrutiny.

### The State Machine

Seven phases, each gated by the previous:

```
IDLE -> RESEARCH -> DELIBERATION -> RANKING -> PRD_GENERATION -> COMPLETE
                                                                    |
                                                              (or FAILED)
``` 

*   **RESEARCH:** Independent agents investigate the topic. Each agent gets a different persona (Technical Architect, Security Analyst, Performance Engineer, etc.). Context isolation ensures agents cannot see each other’s findings.
*   **DELIBERATION:** Agents see all research findings and generate alternatives. The Debate agent identifies conflicts.
*   **RANKING:** Each agent scores every proposed approach across 5 weighted dimensions (Impact, Quality, Feasibility, Reusability, Risk).

### The Two-Gate Validation Architecture

Two validation gates catch problems at different stages using hooks:

*   **Gate 1: Consensus Validation** (PostToolUse hook). Runs immediately after each deliberation agent completes, verifying consensus score against the task-adaptive threshold.
*   **Gate 2: Pride Check** (Stop hook). Runs before the session can close, ensuring diverse methods are represented and contradictions are documented.

### Why Agreement Is Dangerous

Without structural incentives for disagreement, agents converge toward the most confident-sounding initial response regardless of correctness. Liang et al. identified the root cause as “Degeneration-of-Thought”: once an LLM establishes confidence in a position, self-reflection cannot generate novel counterarguments, making multi-agent evaluation structurally necessary.

Independence is the critical design constraint. Two agents evaluating the same deployment strategy with visibility into each other’s findings produced scores of 0.45 and 0.48. Same agents without visibility: 0.45 and 0.72. The gap between 0.48 and 0.72 is the cost of her herd effect.

### Detecting Fake Agreement

A conformity detection module tracks patterns suggesting agents are agreeing without genuine evaluation:

*   **Score clustering:** Every agent scoring within a tight range signals shared context contamination rather than independent assessment.
*   **Boilerplate dissent:** Agents copying each other’s concern language.
*   **Absent minority perspectives:** Unanimous approval from personas with conflicting priorities (e.g. Security Analyst vs Performance Engineer).

### Cost of Deliberation

Each research agent processes context and generates findings, consuming API tokens. Multi-agent runs scale the token consumption accordingly.

Whether this is worth the token expense depends on what a bad decision costs. The system triggers deliberation on roughly 10% of decisions, focused on high-risk domains.

### When to Deliberate

Deliberate | Skip  
---|---  
Security architecture | Documentation typos  
Database schema design | Variable renaming  
API contract changes | Log message updates  
Deployment strategies | Comment rewordings  
Dependency upgrades | Test fixture updates  
  
* * *
