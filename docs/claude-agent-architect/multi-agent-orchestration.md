## Multi-Agent Orchestration

Single-agent AI systems have a structural blind spot: they cannot challenge their own assumptions. Multi-agent deliberation forces independent evaluation from multiple perspectives before any decision locks.

> **Cross-tool orchestration (April 2026):** Google open-sourced **Scion** on April 7 — a multi-agent hypervisor that runs Claude Code, Gemini CLI, and other “deep agents” as concurrent processes, each with isolated container, git worktree, and credentials. Runs local, hub, or Kubernetes. Explicit philosophy: “isolation over constraints” — agents run with high autonomy inside boundaries enforced at the infrastructure layer, not in the prompt. This directly extends the subagent-isolation argument across _different tool vendors_. If your workflow spans Claude and OpenAI models, Scion is the first real reference implementation for cross-tool subagents with per-agent worktree + credential isolation.
> 
> **Debate is not a silver bullet:** The M3MAD-Bench research cluster (early 2026) found that multi-agent debate plateaus and can be subverted by misleading consensus — valid arguments lose when other agents confidently assert the wrong answer. Tool-MAD improves this by giving each agent heterogeneous tool access and using Faithfulness/Relevance scores in the judge stage. If you’re building debate-style orchestration, invest in (a) tool heterogeneity per agent and (b) quantitative judge scoring rather than assuming more agents = better answers.

### Managed Multiagent Orchestration and Outcomes (Public Beta)

If you don’t want to build the deliberation infrastructure described below, **Multiagent Orchestration** entered Public Beta in Claude Managed Agents on May 6, 2026. Per Anthropic: “When there is too much work for a single agent to do well, multiagent orchestration lets a lead agent break the job into pieces and delegate each one to a specialist with its own model, prompt, and tools.” Specialists “work in parallel on a shared filesystem and contribute to the lead agent’s overall context.”

Tracing comes in the box. Per Anthropic: “you can also trace every step in the Claude Console: which agent did what, in what order, and why, giving you full visibility into how your task was delegated and executed.”

The companion Public Beta feature is **Outcomes**. Per Anthropic: “you write a rubric describing what success looks like and the agent works toward it. A separate grader evaluates the output against your criteria in its own context window, so it isn’t influenced by the agent’s reasoning.” This is the managed-service version of the two-gate validation pattern documented later in this section: the rubric replaces the hand-written gate, the separate grader replaces the consensus validator.

| Self-Hosted Deliberation (this section) | Managed Multiagent + Outcomes  
---|---|---  
**Specialist routing** | You write the spawn logic | Lead agent breaks the job into pieces  
**Validation** | Two-gate hooks + consensus scoring | Rubric + grader in separate context  
**Tracing** | You instrument it | Claude Console  
**Best for** | Patterns that need full control or specific tool composition | Standard delegation patterns where the validation rubric is the contract  
**Pricing** | Token + harness cost only | Standard tokens plus the Managed Agents session-hour rate (April 8 launch base; see )  
  
Self-hosted deliberation remains the right answer when the validation needs to integrate with your own hook surface (PreToolUse blocking, exit-code semantics, custom dispatchers) or when the harness must run without external dependencies. Managed Multiagent is the right answer when standard delegation plus rubric grading is the contract you actually need.

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
  +-- YES -> Spawn 2 agents with different system prompts
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

**RESEARCH:** Independent agents investigate the topic. Each agent gets a different persona (Technical Architect, Security Analyst, Performance Engineer, and others). Context isolation ensures agents cannot see each other’s findings during research.

**DELIBERATION:** Agents see all research findings and generate alternatives. The Debate agent identifies conflicts. The Synthesis agent combines non-contradictory findings.

**RANKING:** Each agent scores every proposed approach across 5 weighted dimensions:

Dimension | Weight  
---|---  
Impact | 0.25  
Quality | 0.25  
Feasibility | 0.20  
Reusability | 0.15  
Risk | 0.15  
  
### The Two-Gate Validation Architecture

Two validation gates catch problems at different stages:

**Gate 1: Consensus Validation** (PostToolUse hook). Runs immediately after each deliberation agent completes: 1\. Phase must have reached at least RANKING 2\. Minimum 2 agents completed (configurable) 3\. Consensus score meets the task-adaptive threshold 4\. If any agent dissented, concerns must be documented

**Gate 2: Pride Check** (Stop hook). Runs before the session can close: 1\. Diverse methods: multiple unique personas represented 2\. Contradiction transparency: dissents have documented reasons 3\. Complexity handling: at least 2 alternatives generated 4\. Consensus confidence: classified as strong (above 0.85) or moderate (0.70-0.84) 5\. Improvement evidence: final confidence exceeds initial confidence

Two hooks at different lifecycle points match how failures actually occur: some are instant (bad score) and some are gradual (low diversity, missing dissent documentation).

### Why Agreement Is Dangerous

Charlan Nemeth studied minority dissent from 1986 through her 2018 book _In Defense of Troublemakers_. Groups with dissenters make better decisions than groups that reach quick agreement. The dissenter does not need to be right. The act of disagreement forces the majority to examine assumptions they would otherwise skip.

Wu et al. tested whether LLM agents can genuinely debate and found that without structural incentives for disagreement, agents converge toward the most confident-sounding initial response regardless of correctness. Liang et al. identified the root cause as “Degeneration-of-Thought”: once an LLM establishes confidence in a position, self-reflection cannot generate novel counterarguments, making multi-agent evaluation structurally necessary.

Independence is the critical design constraint. Two agents evaluating the same deployment strategy with visibility into each other’s findings produced scores of 0.45 and 0.48. Same agents without visibility: 0.45 and 0.72. The gap between 0.48 and 0.72 is the cost of herding.

### Detecting Fake Agreement

A conformity detection module tracks patterns suggesting agents are agreeing without genuine evaluation:

**Score clustering:** Every agent scoring within 0.3 points on a 10-point scale signals shared context contamination rather than independent assessment. When five agents evaluating an authentication refactor all scored security risk between 7.1 and 7.4, re-running with fresh context isolation spread the scores to 5.8-8.9.

**Boilerplate dissent:** Agents copying each other’s concern language rather than generating independent objections.

**Absent minority perspectives:** Unanimous approval from personas with conflicting priorities (a Security Analyst and a Performance Engineer rarely agree on everything).

The conformity detector catches the obvious cases (roughly 10-15% of deliberations where agents converge too quickly). For the remaining 85-90%, the consensus and pride check gates provide sufficient validation.

### What Didn’t Work in Deliberation

**Free-form debate rounds.** Three rounds of back-and-forth text for a database indexing discussion produced 7,500 tokens of debate. Round 1: genuine disagreement. Round 2: restated positions. Round 3: identical arguments in different words. Structured dimension scoring replaced free-form debate, dropping cost by 60% while improving ranking quality.

**Single validation gate.** The first implementation ran one validation hook at session end. An agent completed deliberation with a 0.52 consensus score (below threshold), then continued on unrelated tasks for 20 minutes before the session-end hook flagged the failure. Splitting into two gates (one at task completion, one at session end) caught the same problems at different lifecycle points.

### Cost of Deliberation

Each research agent processes roughly 5,000 tokens of context and generates 2,000-3,000 tokens of findings. With 3 agents, that is 15,000-24,000 additional tokens per decision. With 10 agents, roughly 50,000-80,000 tokens.

At current Opus pricing, a 3-agent deliberation costs approximately $0.68-0.90. A 10-agent deliberation costs $2.25-3.00. The system triggers deliberation on roughly 10% of decisions, so the amortized cost across all decisions is $0.23-0.30 per session. Whether that is worth it depends on what a bad decision costs.

### When to Deliberate

Deliberate | Skip  
---|---  
Security architecture | Documentation typos  
Database schema design | Variable renaming  
API contract changes | Log message updates  
Deployment strategies | Comment rewording  
Dependency upgrades | Test fixture updates  
  
* * *
