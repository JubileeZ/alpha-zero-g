---
name: lightweight-teamwork
description: Guidance on utilizing lightweight sequential subagents with Gemini 3.5 Flash and logging verification command output.
---

# Lightweight Teamwork Skill

This skill governs how agents interact with subagents to execute tasks efficiently.

## Core Rules

1. **Sequential Execution**: Agents must work sequentially (Planning -> Implementing -> Verifying) using separate, short-lived `invoke_subagent` calls. You must work in a sequential manner and are explicitly forbidden from running subagents in parallel.
2. **Cheaper and Faster Models by Default**: Subagents should be configured to use cheaper/faster models (like Gemini 3.5 Flash) by default. Ensure you either change the setting using `/model gemini-3.5-flash` or specify the model-constraint text (e.g. "flash" or "gemini-3.5-flash") inside the prompt parameter of the subagent invocation.
3. **Verify and Prevent Self-Certification**: To prevent self-certification, subagents must log the exact test command and test output. The calling agent must verify the output and context to ensure correctness.
