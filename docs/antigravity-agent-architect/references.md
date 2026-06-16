## References

[^1]: * Andrej Karpathy on “claws” as a new layer on top of LLM agents. [HN discussion](https://news.ycombinator.com/item?id=47096253) (406 points, 917 comments).

[^2]: * Author’s implementation. 84 hooks, 48 skills, ~15,000 lines of orchestration. Documented in [Antigravity CLI as Infrastructure](https://agentpedia.codes/blog/antigravity-cli-deep-dive).

[^3]: * Google Cloud, “Antigravity CLI Hooks: JSON Protocol.” [cloud.google.com/antigravity-cli/docs/hooks](https://cloud.google.com/antigravity-cli/docs/hooks). Output `{"decision":"deny", "reason":"..."}` to block, exit code 0 is standard.

[^4]: * Google Cloud, “Extend Antigravity with Skills.” [cloud.google.com/antigravity-cli/docs/skills](https://cloud.google.com/antigravity-cli/docs/skills). Skill structure, frontmatter fields, LLM-based matching, and 1% / 8,000-character description budget.

[^5]: * Google Cloud, “Antigravity CLI Dynamic Subagents.” [cloud.google.com/antigravity-cli/docs/subagents](https://cloud.google.com/antigravity-cli/docs/subagents). Dynamic spawning, workspace isolation.

[^6]: * Google Cloud, “Antigravity CLI Documentation.” [cloud.google.com/antigravity-cli/docs](https://cloud.google.com/antigravity-cli/docs). Memory patterns, GEMINI.md, AGENTS.md.

[^7]: * Author’s multi-agent deliberation system. 10 research personas, 7-phase state machine, 141 tests. Documented in [Multi-Agent Deliberation on Antigravity CLI](https://agentpedia.codes/blog/antigravity-cli-deep-dive).

[^8]: * Simon Willison, “Writing code is cheap now.” [Agentic Engineering Patterns](https://simonwillison.net/guides/agentic-engineering-patterns/code-is-cheap/).

[^9]: * Laban, Philippe, et al., “LLMs Get Lost In Multi-Turn Conversation,” arXiv:2505.06120, May 2025. Microsoft Research and Salesforce. 15 LLMs, 200,000+ conversations, 39% average performance drop.

[^10]: * Mikhail Shilkov, “Inside Antigravity CLI Skills: Structure, Prompts, Invocation.” Independent analysis of skill discovery, context injection, and `available_skills` prompt section.

[^11]: * Antigravity CLI Constants and Budgets.

[^12]: * Google Cloud, “Skill Authoring Best Practices.” 500-line limit, supporting files, naming conventions.

[^13]: * Google Cloud, “Antigravity CLI Hooks: Lifecycle Events.” 29 documented lifecycle events, hook types, matcher behavior, async hooks, HTTP hooks, prompt hooks, agent hooks, and MCP tool hooks.

[^14]: * Author’s Antigravity CLI hooks tutorial. 5 production hooks from scratch. Documented in [Antigravity CLI Hooks Tutorial](https://agentpedia.codes/blog/antigravity-cli-deep-dive).

[^15]: * Author’s context window management across 50 sessions. Documented in [Context Window Management](https://agentpedia.codes/blog/antigravity-cli-deep-dive).

[^16]: * Author’s Ralph Loop implementation. Fresh-context iteration with filesystem state, spawn budgets. Documented in [The Ralph Loop](https://agentpedia.codes/blog/antigravity-cli-deep-dive).

[^17]: * Author’s deliberation system architecture. 3,500 lines of Python, 12 modules, confidence trigger, consensus validation. Documented in [Building AI Systems: From RAG to Agents](https://agentpedia.codes/blog/antigravity-cli-deep-dive).

[^18]: * Nemeth, Charlan, _In Defense of Troublemakers: The Power of Dissent in Life and Business_ , Basic Books, 2018.

[^19]: * Wu, H., Li, Z., and Li, L., “Can LLM Agents Really Debate?” [arXiv:2511.07784](https://arxiv.org/abs/2511.07784), 2025.

[^20]: * Liang, T. et al., “Encouraging Divergent Thinking in Large Language Models through Multi-Agent Debate,” _EMNLP 2024_.

[^21]: * Author’s AGENTS.md analysis across real-world repositories. Documented in [AGENTS.md Patterns](https://agentpedia.codes/blog/antigravity-cli-deep-dive). See also: GitHub Blog, “How to Write a Great agents.md: Lessons from Over 2,500 Repositories.”

[^22]: * Author’s quality loop and evidence gate methodology. Part of the Jiro Craftsmanship system.

[^51]: * Google Cloud, “Dynamic Agent Platform Overview”. Managed runtime environment for subagents, sandboxing, session state checkpointing.

[^52]: * OpenAI, “openai-agents Python v0.14.0 release notes”. Introduces Sandbox Agents SDK surface: SandboxAgent, Manifest, SandboxRunConfig.

[^53]: * Google Cloud, “Scion: Multi-Agent Hypervisor”. Open-sourced April 7, 2026. Orchestrates Antigravity CLI and other deep agents as isolated processes.

[^54]: * Multi-agent debate research cluster, Q1–Q2 2026. Wu et al., “Can LLM Agents Really Debate?” (arXiv 2511.07784); M3MAD-Bench; Tool-MAD.

[^55]: * Google Cloud, “Our framework for developing safe and trustworthy agents.” MCP donation to Linux Foundation’s Agentic AI Foundation.

[^56]: * Permiso Security, “SandyClaw: First Dynamic Sandbox for AI Agent Skills.” skill execution sandbox with Sigma/YARA/Nova/Snort detection.

[^57]: * Google Cloud Next 2026 announcements regarding Gemini models, agent architecture and ADK v1.0.

[^58]: * OpenAI, “Custom instructions with AGENTS.md”. Codex reads global and project AGENTS.md.

[^59]: * OpenAI, “Agent Skills”. Codex skills use SKILL.md.

[^60]: * OpenAI, “Codex Hooks”. Codex hooks support command hooks.

[^61]: * OpenAI, “Codex Subagents”. Codex supports explicit parallel subagent workflows.

[^62]: * Google Cloud, “Dynamic Orchestration in Antigravity CLI”. Dynamic subagent spawning, run-time prompt routing, and session-state management.

* * *
